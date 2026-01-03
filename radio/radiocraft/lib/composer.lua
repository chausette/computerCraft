-- RadioCraft - Composer
-- Éditeur de mélodies noteblock

local Composer = {}
Composer.__index = Composer

-- Instruments disponibles
Composer.INSTRUMENTS = {
    {id = "harp", name = "Harpe", key = "H"},
    {id = "bass", name = "Basse", key = "B"},
    {id = "basedrum", name = "Grosse caisse", key = "D"},
    {id = "snare", name = "Caisse claire", key = "S"},
    {id = "hat", name = "Hi-hat", key = "T"},
    {id = "bell", name = "Cloche", key = "L"},
    {id = "flute", name = "Flûte", key = "F"},
    {id = "chime", name = "Carillon", key = "C"},
    {id = "guitar", name = "Guitare", key = "G"},
    {id = "xylophone", name = "Xylophone", key = "X"},
    {id = "iron_xylophone", name = "Vibraphone", key = "V"},
    {id = "cow_bell", name = "Cloche vache", key = "W"},
    {id = "didgeridoo", name = "Didgeridoo", key = "I"},
    {id = "bit", name = "Bit", key = "8"},
    {id = "banjo", name = "Banjo", key = "J"},
    {id = "pling", name = "Pling", key = "P"},
}

-- Notes (noms pour affichage)
Composer.NOTE_NAMES = {
    "F#", "G", "G#", "A", "A#", "B", 
    "C", "C#", "D", "D#", "E", "F",
    "F#", "G", "G#", "A", "A#", "B",
    "C", "C#", "D", "D#", "E", "F", "F#"
}

function Composer.new(speakers)
    local self = setmetatable({}, Composer)
    self.speakers = speakers
    
    -- Composition actuelle
    self.composition = {
        name = "Nouvelle composition",
        author = "Unknown",
        bpm = 120,
        tracks = {}
    }
    
    -- État de l'éditeur
    self.currentTrack = 1
    self.currentTick = 0
    self.viewOffset = 0
    self.cursorPitch = 12
    self.isPlaying = false
    self.isRecording = false
    
    -- Callbacks
    self.onUpdate = nil
    
    return self
end

-- Crée une nouvelle composition
function Composer:new()
    self.composition = {
        name = "Nouvelle composition",
        author = "Unknown",
        bpm = 120,
        tracks = {}
    }
    self.currentTrack = 1
    self.currentTick = 0
    self:addTrack("harp")
end

-- Ajoute une piste
function Composer:addTrack(instrument)
    table.insert(self.composition.tracks, {
        instrument = instrument or "harp",
        notes = {}
    })
    return #self.composition.tracks
end

-- Supprime une piste
function Composer:removeTrack(index)
    if #self.composition.tracks > 1 then
        table.remove(self.composition.tracks, index)
        if self.currentTrack > #self.composition.tracks then
            self.currentTrack = #self.composition.tracks
        end
        return true
    end
    return false
end

-- Change l'instrument d'une piste
function Composer:setTrackInstrument(trackIndex, instrument)
    if self.composition.tracks[trackIndex] then
        self.composition.tracks[trackIndex].instrument = instrument
        return true
    end
    return false
end

-- Ajoute une note
function Composer:addNote(tick, pitch, volume, trackIndex)
    trackIndex = trackIndex or self.currentTrack
    pitch = pitch or self.cursorPitch
    volume = volume or 1
    tick = tick or self.currentTick
    
    local track = self.composition.tracks[trackIndex]
    if not track then return false end
    
    -- Vérifie si une note existe déjà à cette position
    for i, note in ipairs(track.notes) do
        if note.t == tick and note.p == pitch then
            -- Note déjà présente, on la supprime (toggle)
            table.remove(track.notes, i)
            return false
        end
    end
    
    -- Ajoute la note
    table.insert(track.notes, {t = tick, p = pitch, v = volume})
    
    -- Trie par tick
    table.sort(track.notes, function(a, b) return a.t < b.t end)
    
    -- Preview
    if self.speakers then
        self.speakers:playNote(track.instrument, volume, pitch)
    end
    
    return true
end

-- Supprime une note
function Composer:removeNote(tick, pitch, trackIndex)
    trackIndex = trackIndex or self.currentTrack
    local track = self.composition.tracks[trackIndex]
    if not track then return false end
    
    for i, note in ipairs(track.notes) do
        if note.t == tick and note.p == pitch then
            table.remove(track.notes, i)
            return true
        end
    end
    return false
end

-- Récupère les notes à un tick donné
function Composer:getNotesAtTick(tick, trackIndex)
    local notes = {}
    
    if trackIndex then
        local track = self.composition.tracks[trackIndex]
        if track then
            for _, note in ipairs(track.notes) do
                if note.t == tick then
                    table.insert(notes, {
                        pitch = note.p,
                        volume = note.v,
                        instrument = track.instrument,
                        track = trackIndex
                    })
                end
            end
        end
    else
        for ti, track in ipairs(self.composition.tracks) do
            for _, note in ipairs(track.notes) do
                if note.t == tick then
                    table.insert(notes, {
                        pitch = note.p,
                        volume = note.v,
                        instrument = track.instrument,
                        track = ti
                    })
                end
            end
        end
    end
    
    return notes
end

-- Calcule la durée totale
function Composer:getDuration()
    local maxTick = 0
    for _, track in ipairs(self.composition.tracks) do
        for _, note in ipairs(track.notes) do
            maxTick = math.max(maxTick, note.t)
        end
    end
    return maxTick + 10 -- Ajoute un peu de silence à la fin
end

-- Navigation
function Composer:moveCursor(dx, dy)
    self.currentTick = math.max(0, self.currentTick + (dx or 0))
    self.cursorPitch = math.max(0, math.min(24, self.cursorPitch + (dy or 0)))
    
    -- Preview de la note
    if dy and dy ~= 0 and self.speakers then
        local track = self.composition.tracks[self.currentTrack]
        if track then
            self.speakers:playNote(track.instrument, 0.5, self.cursorPitch)
        end
    end
end

function Composer:nextTrack()
    self.currentTrack = self.currentTrack + 1
    if self.currentTrack > #self.composition.tracks then
        self.currentTrack = 1
    end
end

function Composer:prevTrack()
    self.currentTrack = self.currentTrack - 1
    if self.currentTrack < 1 then
        self.currentTrack = #self.composition.tracks
    end
end

-- Sauvegarde en format .rcm
function Composer:save(path)
    local data = {
        format = "rcm",
        version = 1,
        name = self.composition.name,
        author = self.composition.author,
        bpm = self.composition.bpm,
        duration = self:getDuration(),
        tracks = {}
    }
    
    for _, track in ipairs(self.composition.tracks) do
        if #track.notes > 0 then
            table.insert(data.tracks, {
                instrument = track.instrument,
                notes = track.notes
            })
        end
    end
    
    -- Génère le Lua
    local lines = {
        "-- RadioCraft Music File",
        "-- " .. data.name .. " by " .. data.author,
        "return {",
        '  format = "rcm",',
        '  version = ' .. data.version .. ',',
        '  name = "' .. data.name .. '",',
        '  author = "' .. data.author .. '",',
        '  bpm = ' .. data.bpm .. ',',
        '  duration = ' .. data.duration .. ',',
        "  tracks = {"
    }
    
    for _, track in ipairs(data.tracks) do
        table.insert(lines, "    {")
        table.insert(lines, '      instrument = "' .. track.instrument .. '",')
        table.insert(lines, "      notes = {")
        
        local noteStrs = {}
        for _, note in ipairs(track.notes) do
            table.insert(noteStrs, "{t=" .. note.t .. ",p=" .. note.p .. ",v=" .. note.v .. "}")
        end
        
        -- 5 notes par ligne
        for i = 1, #noteStrs, 5 do
            local chunk = {}
            for j = i, math.min(i + 4, #noteStrs) do
                table.insert(chunk, noteStrs[j])
            end
            table.insert(lines, "        " .. table.concat(chunk, ",") .. ",")
        end
        
        table.insert(lines, "      }")
        table.insert(lines, "    },")
    end
    
    table.insert(lines, "  }")
    table.insert(lines, "}")
    
    local file = fs.open(path, "w")
    file.write(table.concat(lines, "\n"))
    file.close()
    
    return true
end

-- Charge un fichier .rcm
function Composer:load(path)
    if not fs.exists(path) then
        return false, "Fichier non trouvé"
    end
    
    local func, err = loadfile(path)
    if not func then
        return false, "Erreur de parsing"
    end
    
    local ok, data = pcall(func)
    if not ok or not data then
        return false, "Erreur de chargement"
    end
    
    self.composition = {
        name = data.name or "Sans nom",
        author = data.author or "Unknown",
        bpm = data.bpm or 120,
        tracks = {}
    }
    
    for _, track in ipairs(data.tracks or {}) do
        local newTrack = {
            instrument = track.instrument or "harp",
            notes = {}
        }
        for _, note in ipairs(track.notes or {}) do
            table.insert(newTrack.notes, {
                t = note.t or note.tick or 0,
                p = note.p or note.pitch or 12,
                v = note.v or note.vol or 1
            })
        end
        table.insert(self.composition.tracks, newTrack)
    end
    
    if #self.composition.tracks == 0 then
        self:addTrack("harp")
    end
    
    self.currentTrack = 1
    self.currentTick = 0
    
    return true
end

-- Sauvegarde sur disquette
function Composer:saveToDisk(filename)
    local diskPath = "/disk/songs"
    
    if not fs.exists("/disk") then
        return false, "Pas de disquette insérée"
    end
    
    if not fs.exists(diskPath) then
        fs.makeDir(diskPath)
    end
    
    local path = diskPath .. "/" .. filename
    if not string.find(filename, "%.rcm$") then
        path = path .. ".rcm"
    end
    
    return self:save(path)
end

-- Charge depuis disquette
function Composer:loadFromDisk(filename)
    local path = "/disk/songs/" .. filename
    if not string.find(filename, "%.rcm$") then
        path = path .. ".rcm"
    end
    return self:load(path)
end

-- Liste les fichiers sur disquette
function Composer:listDiskSongs()
    local songs = {}
    local diskPath = "/disk/songs"
    
    if fs.exists(diskPath) and fs.isDir(diskPath) then
        for _, file in ipairs(fs.list(diskPath)) do
            if string.find(file, "%.rcm$") then
                table.insert(songs, file)
            end
        end
    end
    
    return songs
end

-- Getters
function Composer:getComposition()
    return self.composition
end

function Composer:getCurrentTrack()
    return self.currentTrack
end

function Composer:getTracks()
    return self.composition.tracks
end

function Composer:getTrackCount()
    return #self.composition.tracks
end

function Composer:setName(name)
    self.composition.name = name
end

function Composer:setAuthor(author)
    self.composition.author = author
end

function Composer:setBPM(bpm)
    self.composition.bpm = math.max(30, math.min(300, bpm))
end

-- Récupère le nom de la note
function Composer:getNoteName(pitch)
    return Composer.NOTE_NAMES[pitch + 1] or "?"
end

return Composer
