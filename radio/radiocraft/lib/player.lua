-- RadioCraft - Music Player
-- Lecteur de fichiers .rcm et disques vanilla

local Player = {}
Player.__index = Player

-- États du lecteur
Player.STATE_STOPPED = "stopped"
Player.STATE_PLAYING = "playing"
Player.STATE_PAUSED = "paused"

function Player.new(speakers)
    local self = setmetatable({}, Player)
    self.speakers = speakers
    self.state = Player.STATE_STOPPED
    self.currentTrack = nil
    self.currentTick = 0
    self.queue = {}
    self.shuffle = false
    self.repeatMode = "none" -- none, one, all
    self.playbackSpeed = 1.0
    self.onTrackChange = nil
    self.onStateChange = nil
    self.onProgress = nil
    return self
end

-- Charge un fichier .rcm
function Player:loadRCM(path)
    if not fs.exists(path) then
        return nil, "Fichier non trouvé"
    end
    
    local func, err = loadfile(path)
    if not func then
        return nil, "Erreur de parsing: " .. tostring(err)
    end
    
    local ok, data = pcall(func)
    if not ok then
        return nil, "Erreur d'exécution: " .. tostring(data)
    end
    
    if not data or data.format ~= "rcm" then
        return nil, "Format invalide"
    end
    
    return data
end

-- Joue un fichier .rcm
function Player:playRCM(path)
    local data, err = self:loadRCM(path)
    if not data then
        return false, err
    end
    
    self.currentTrack = {
        type = "rcm",
        path = path,
        data = data,
        name = data.name or fs.getName(path),
        author = data.author or "Unknown",
        duration = data.duration or 0
    }
    
    self.currentTick = 0
    self.state = Player.STATE_PLAYING
    
    if self.onTrackChange then
        self.onTrackChange(self.currentTrack)
    end
    if self.onStateChange then
        self.onStateChange(self.state)
    end
    
    return true
end

-- Joue un disque vanilla
function Player:playDisc(discName)
    -- Liste des disques Minecraft
    local discs = {
        ["minecraft:music_disc_13"] = {name = "13", author = "C418", duration = 178*20},
        ["minecraft:music_disc_cat"] = {name = "Cat", author = "C418", duration = 185*20},
        ["minecraft:music_disc_blocks"] = {name = "Blocks", author = "C418", duration = 345*20},
        ["minecraft:music_disc_chirp"] = {name = "Chirp", author = "C418", duration = 185*20},
        ["minecraft:music_disc_far"] = {name = "Far", author = "C418", duration = 174*20},
        ["minecraft:music_disc_mall"] = {name = "Mall", author = "C418", duration = 197*20},
        ["minecraft:music_disc_mellohi"] = {name = "Mellohi", author = "C418", duration = 96*20},
        ["minecraft:music_disc_stal"] = {name = "Stal", author = "C418", duration = 150*20},
        ["minecraft:music_disc_strad"] = {name = "Strad", author = "C418", duration = 188*20},
        ["minecraft:music_disc_ward"] = {name = "Ward", author = "C418", duration = 251*20},
        ["minecraft:music_disc_11"] = {name = "11", author = "C418", duration = 71*20},
        ["minecraft:music_disc_wait"] = {name = "Wait", author = "C418", duration = 238*20},
        ["minecraft:music_disc_otherside"] = {name = "Otherside", author = "Lena Raine", duration = 195*20},
        ["minecraft:music_disc_5"] = {name = "5", author = "Samuel Åberg", duration = 178*20},
        ["minecraft:music_disc_pigstep"] = {name = "Pigstep", author = "Lena Raine", duration = 149*20},
        ["minecraft:music_disc_relic"] = {name = "Relic", author = "Aaron Cherof", duration = 218*20},
    }
    
    local soundName = discName
    if not string.find(discName, ":") then
        soundName = "minecraft:music_disc." .. discName
    end
    
    local discInfo = discs[soundName] or {name = discName, author = "Unknown", duration = 180*20}
    
    self.currentTrack = {
        type = "disc",
        sound = soundName,
        name = discInfo.name,
        author = discInfo.author,
        duration = discInfo.duration
    }
    
    self.currentTick = 0
    self.state = Player.STATE_PLAYING
    
    -- Joue le son
    self.speakers:playSound(soundName, 1, 1)
    
    if self.onTrackChange then
        self.onTrackChange(self.currentTrack)
    end
    if self.onStateChange then
        self.onStateChange(self.state)
    end
    
    return true
end

-- Met à jour le lecteur (à appeler dans une boucle)
function Player:update()
    if self.state ~= Player.STATE_PLAYING then
        return
    end
    
    if not self.currentTrack then
        self.state = Player.STATE_STOPPED
        return
    end
    
    -- Pour les disques, on suit juste le temps
    if self.currentTrack.type == "disc" then
        self.currentTick = self.currentTick + 1
        
        if self.currentTick >= self.currentTrack.duration then
            self:onTrackEnd()
        end
        
        if self.onProgress then
            self.onProgress(self.currentTick, self.currentTrack.duration)
        end
        return
    end
    
    -- Pour les .rcm, on joue les notes
    if self.currentTrack.type == "rcm" then
        local data = self.currentTrack.data
        
        -- Joue toutes les notes au tick actuel
        for _, track in ipairs(data.tracks) do
            for _, note in ipairs(track.notes) do
                if note.t == self.currentTick or note.tick == self.currentTick then
                    local pitch = note.p or note.pitch or 12
                    local vol = note.v or note.vol or 1
                    self.speakers:playNote(track.instrument, vol, pitch)
                end
            end
        end
        
        self.currentTick = self.currentTick + 1
        
        if self.currentTick >= self.currentTrack.duration then
            self:onTrackEnd()
        end
        
        if self.onProgress then
            self.onProgress(self.currentTick, self.currentTrack.duration)
        end
    end
end

-- Gère la fin d'une piste
function Player:onTrackEnd()
    if self.repeatMode == "one" then
        self.currentTick = 0
        if self.currentTrack.type == "disc" then
            self.speakers:playSound(self.currentTrack.sound, 1, 1)
        end
    elseif #self.queue > 0 then
        self:playNext()
    elseif self.repeatMode == "all" and self.currentTrack then
        self.currentTick = 0
        if self.currentTrack.type == "disc" then
            self.speakers:playSound(self.currentTrack.sound, 1, 1)
        end
    else
        self.state = Player.STATE_STOPPED
        if self.onStateChange then
            self.onStateChange(self.state)
        end
    end
end

-- Pause
function Player:pause()
    if self.state == Player.STATE_PLAYING then
        self.state = Player.STATE_PAUSED
        if self.onStateChange then
            self.onStateChange(self.state)
        end
    end
end

-- Resume
function Player:resume()
    if self.state == Player.STATE_PAUSED then
        self.state = Player.STATE_PLAYING
        
        -- Relance le son pour les disques (approximatif)
        if self.currentTrack and self.currentTrack.type == "disc" then
            self.speakers:playSound(self.currentTrack.sound, 1, 1)
        end
        
        if self.onStateChange then
            self.onStateChange(self.state)
        end
    end
end

-- Toggle pause
function Player:togglePause()
    if self.state == Player.STATE_PLAYING then
        self:pause()
    elseif self.state == Player.STATE_PAUSED then
        self:resume()
    end
end

-- Stop
function Player:stop()
    self.state = Player.STATE_STOPPED
    self.currentTrack = nil
    self.currentTick = 0
    self.speakers:stopAll()
    
    if self.onStateChange then
        self.onStateChange(self.state)
    end
end

-- Ajoute à la queue
function Player:addToQueue(item)
    table.insert(self.queue, item)
end

-- Joue le suivant
function Player:playNext()
    if #self.queue == 0 then
        self:stop()
        return false
    end
    
    local nextIndex = 1
    if self.shuffle then
        nextIndex = math.random(1, #self.queue)
    end
    
    local next = table.remove(self.queue, nextIndex)
    
    if next.type == "disc" then
        return self:playDisc(next.sound or next.name)
    elseif next.type == "rcm" then
        return self:playRCM(next.path)
    end
    
    return false
end

-- Joue le précédent (restart si > 3 secondes)
function Player:playPrevious()
    if self.currentTick > 60 then -- Plus de 3 secondes
        self.currentTick = 0
        if self.currentTrack and self.currentTrack.type == "disc" then
            self.speakers:playSound(self.currentTrack.sound, 1, 1)
        end
        return true
    end
    return false
end

-- Seek (pour les .rcm uniquement)
function Player:seek(tick)
    if self.currentTrack and self.currentTrack.type == "rcm" then
        self.currentTick = math.max(0, math.min(tick, self.currentTrack.duration))
        return true
    end
    return false
end

-- Toggle shuffle
function Player:toggleShuffle()
    self.shuffle = not self.shuffle
    return self.shuffle
end

-- Cycle repeat mode
function Player:cycleRepeat()
    if self.repeatMode == "none" then
        self.repeatMode = "one"
    elseif self.repeatMode == "one" then
        self.repeatMode = "all"
    else
        self.repeatMode = "none"
    end
    return self.repeatMode
end

-- Getters
function Player:getState()
    return self.state
end

function Player:getCurrentTrack()
    return self.currentTrack
end

function Player:getProgress()
    if not self.currentTrack then
        return 0, 0
    end
    return self.currentTick, self.currentTrack.duration
end

function Player:getQueue()
    return self.queue
end

function Player:isPlaying()
    return self.state == Player.STATE_PLAYING
end

function Player:isPaused()
    return self.state == Player.STATE_PAUSED
end

function Player:isStopped()
    return self.state == Player.STATE_STOPPED
end

-- Formatte le temps en mm:ss
function Player.formatTime(ticks)
    local seconds = math.floor(ticks / 20)
    local minutes = math.floor(seconds / 60)
    seconds = seconds % 60
    return string.format("%d:%02d", minutes, seconds)
end

return Player
