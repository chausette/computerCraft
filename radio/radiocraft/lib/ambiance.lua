-- RadioCraft - Ambiance Manager
-- Gère les stations d'ambiance avec sons vanilla

local Ambiance = {}
Ambiance.__index = Ambiance

-- Définition des stations
Ambiance.STATIONS = {
    nature = {
        name = "Nature",
        icon = "*",
        sounds = {
            {sound = "minecraft:entity.chicken.ambient", weight = 3, minDelay = 20, maxDelay = 60},
            {sound = "minecraft:entity.cow.ambient", weight = 2, minDelay = 30, maxDelay = 80},
            {sound = "minecraft:entity.pig.ambient", weight = 2, minDelay = 30, maxDelay = 80},
            {sound = "minecraft:entity.wolf.ambient", weight = 1, minDelay = 50, maxDelay = 120},
        }
    },
    cave = {
        name = "Grotte",
        icon = "O",
        sounds = {
            {sound = "minecraft:ambient.cave", weight = 3, minDelay = 30, maxDelay = 80},
            {sound = "minecraft:entity.bat.ambient", weight = 3, minDelay = 20, maxDelay = 60},
            {sound = "minecraft:block.stone.break", weight = 2, minDelay = 40, maxDelay = 100},
        }
    },
    nether = {
        name = "Nether",
        icon = "!",
        sounds = {
            {sound = "minecraft:entity.ghast.ambient", weight = 2, minDelay = 40, maxDelay = 100},
            {sound = "minecraft:entity.blaze.ambient", weight = 2, minDelay = 30, maxDelay = 80},
            {sound = "minecraft:entity.piglin.ambient", weight = 2, minDelay = 30, maxDelay = 80},
            {sound = "minecraft:block.fire.ambient", weight = 3, minDelay = 20, maxDelay = 50},
        }
    },
    spooky = {
        name = "Horreur",
        icon = "X",
        sounds = {
            {sound = "minecraft:ambient.cave", weight = 3, minDelay = 20, maxDelay = 50},
            {sound = "minecraft:entity.zombie.ambient", weight = 2, minDelay = 30, maxDelay = 70},
            {sound = "minecraft:entity.skeleton.ambient", weight = 2, minDelay = 30, maxDelay = 70},
            {sound = "minecraft:entity.creeper.primed", weight = 1, minDelay = 60, maxDelay = 150},
        }
    },
    village = {
        name = "Village",
        icon = "^",
        sounds = {
            {sound = "minecraft:entity.villager.ambient", weight = 4, minDelay = 15, maxDelay = 40},
            {sound = "minecraft:entity.villager.trade", weight = 2, minDelay = 30, maxDelay = 70},
            {sound = "minecraft:entity.chicken.ambient", weight = 3, minDelay = 20, maxDelay = 50},
            {sound = "minecraft:entity.cow.ambient", weight = 2, minDelay = 25, maxDelay = 60},
        }
    },
    peaceful = {
        name = "Calme",
        icon = "-",
        sounds = {
            {sound = "minecraft:block.note_block.harp", weight = 4, minDelay = 15, maxDelay = 40},
            {sound = "minecraft:block.note_block.chime", weight = 3, minDelay = 20, maxDelay = 50},
            {sound = "minecraft:block.note_block.bell", weight = 2, minDelay = 25, maxDelay = 60},
            {sound = "minecraft:entity.experience_orb.pickup", weight = 2, minDelay = 30, maxDelay = 70},
        }
    }
}

function Ambiance.new(speakers)
    local self = setmetatable({}, Ambiance)
    self.speakers = speakers
    self.currentStation = nil
    self.isPlaying = false
    self.volume = 0.5
    self.soundTimers = {}
    self.onStationChange = nil
    return self
end

-- Liste les stations disponibles
function Ambiance:getStations()
    local list = {}
    for id, station in pairs(Ambiance.STATIONS) do
        table.insert(list, {
            id = id,
            name = station.name,
            icon = station.icon
        })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- Démarre une station
function Ambiance:play(stationId)
    local station = Ambiance.STATIONS[stationId]
    if not station then
        return false, "Station inconnue"
    end
    
    self:stop()
    
    self.currentStation = {
        id = stationId,
        name = station.name,
        sounds = station.sounds
    }
    self.isPlaying = true
    
    -- Initialise les timers pour chaque son (démarrer rapidement)
    self.soundTimers = {}
    for i, soundDef in ipairs(station.sounds) do
        -- Premier son plus rapide pour feedback immédiat
        self.soundTimers[i] = math.random(5, 20)
    end
    
    print("[Ambiance] Station '" .. station.name .. "' demarree")
    
    if self.onStationChange then
        self.onStationChange(self.currentStation)
    end
    
    return true
end

-- Arrête la station
function Ambiance:stop()
    self.isPlaying = false
    self.currentStation = nil
    self.soundTimers = {}
end

-- Update (à appeler chaque tick)
function Ambiance:update()
    if not self.isPlaying or not self.currentStation then
        return
    end
    
    for i, soundDef in ipairs(self.currentStation.sounds) do
        self.soundTimers[i] = self.soundTimers[i] - 1
        
        if self.soundTimers[i] <= 0 then
            -- Joue le son
            local pitch = 0.8 + math.random() * 0.4 -- Variation de pitch
            local played = self.speakers:playSound(soundDef.sound, self.volume, pitch)
            
            -- Reset le timer
            self.soundTimers[i] = math.random(soundDef.minDelay, soundDef.maxDelay)
        end
    end
end

-- Volume
function Ambiance:setVolume(vol)
    self.volume = math.max(0, math.min(1, vol))
end

function Ambiance:getVolume()
    return self.volume
end

-- Getters
function Ambiance:getCurrentStation()
    return self.currentStation
end

function Ambiance:getIsPlaying()
    return self.isPlaying
end

-- Toggle play/stop
function Ambiance:toggle(stationId)
    if self.isPlaying and self.currentStation and self.currentStation.id == stationId then
        self:stop()
        return false
    else
        self:play(stationId)
        return true
    end
end

return Ambiance
