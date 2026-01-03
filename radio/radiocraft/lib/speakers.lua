-- RadioCraft - Speakers Manager
-- Gère multiple speakers via wired modem

local Speakers = {}
Speakers.__index = Speakers

-- Liste des instruments noteblock disponibles
Speakers.INSTRUMENTS = {
    "harp", "bass", "basedrum", "snare", "hat", "bell",
    "flute", "chime", "guitar", "xylophone", "iron_xylophone",
    "cow_bell", "didgeridoo", "bit", "banjo", "pling"
}

function Speakers.new()
    local self = setmetatable({}, Speakers)
    self.speakers = {}
    self.zones = {}
    self.masterVolume = 1.0
    self.zoneVolumes = {}
    self.debug = false
    self:discover()
    return self
end

-- Découvre tous les speakers connectés
function Speakers:discover()
    self.speakers = {}
    
    -- Cherche les speakers directement attachés et via modem
    for _, name in ipairs(peripheral.getNames()) do
        local pType = peripheral.getType(name)
        if pType == "speaker" then
            local spk = peripheral.wrap(name)
            if spk then
                table.insert(self.speakers, {
                    name = name,
                    peripheral = spk,
                    zone = "default"
                })
                if self.debug then
                    print("[Speakers] Trouve: " .. name)
                end
            end
        end
    end
    
    -- Initialise la zone par défaut
    if not self.zoneVolumes["default"] then
        self.zoneVolumes["default"] = 1.0
    end
    
    -- Log
    print("[Speakers] " .. #self.speakers .. " speaker(s) trouve(s)")
    
    return #self.speakers
end

-- Active/désactive le debug
function Speakers:setDebug(enabled)
    self.debug = enabled
end

-- Assigne un speaker à une zone
function Speakers:setZone(speakerName, zoneName)
    for _, speaker in ipairs(self.speakers) do
        if speaker.name == speakerName then
            speaker.zone = zoneName
            if not self.zoneVolumes[zoneName] then
                self.zoneVolumes[zoneName] = 1.0
            end
            if self.debug then
                print("[Speakers] " .. speakerName .. " -> zone " .. zoneName)
            end
            return true
        end
    end
    return false
end

-- Configure le volume d'une zone
function Speakers:setZoneVolume(zoneName, volume)
    self.zoneVolumes[zoneName] = math.max(0, math.min(1, volume))
end

-- Configure le volume master
function Speakers:setMasterVolume(volume)
    self.masterVolume = math.max(0, math.min(1, volume))
end

-- Récupère le volume effectif pour une zone
function Speakers:getEffectiveVolume(zoneName)
    local zoneVol = self.zoneVolumes[zoneName] or 1.0
    return self.masterVolume * zoneVol
end

-- Joue un son sur tous les speakers (ou une zone spécifique)
function Speakers:playSound(sound, volume, pitch, zone)
    volume = volume or 1.0
    pitch = pitch or 1.0
    
    local played = 0
    
    for _, speaker in ipairs(self.speakers) do
        if zone == nil or speaker.zone == zone then
            local effectiveVol = volume * self:getEffectiveVolume(speaker.zone)
            if effectiveVol > 0 then
                local ok, err = pcall(function()
                    speaker.peripheral.playSound(sound, effectiveVol, pitch)
                end)
                if ok then
                    played = played + 1
                elseif self.debug then
                    print("[Speakers] Erreur playSound: " .. tostring(err))
                end
            end
        end
    end
    
    if self.debug then
        print("[Speakers] playSound '" .. sound .. "' sur " .. played .. " speaker(s)")
    end
    
    return played > 0
end

-- Joue une note sur tous les speakers (ou une zone spécifique)
function Speakers:playNote(instrument, volume, pitch, zone)
    volume = volume or 1.0
    pitch = pitch or 12
    
    -- Valide l'instrument
    local validInstrument = false
    for _, inst in ipairs(self.INSTRUMENTS) do
        if inst == instrument then
            validInstrument = true
            break
        end
    end
    
    if not validInstrument then
        instrument = "harp"
    end
    
    -- Assure que pitch est dans la bonne plage (0-24)
    pitch = math.max(0, math.min(24, pitch))
    
    local played = 0
    
    for _, speaker in ipairs(self.speakers) do
        if zone == nil or speaker.zone == zone then
            local effectiveVol = volume * self:getEffectiveVolume(speaker.zone)
            if effectiveVol > 0 then
                local ok, err = pcall(function()
                    speaker.peripheral.playNote(instrument, effectiveVol, pitch)
                end)
                if ok then
                    played = played + 1
                elseif self.debug then
                    print("[Speakers] Erreur playNote: " .. tostring(err))
                end
            end
        end
    end
    
    if self.debug then
        print("[Speakers] playNote '" .. instrument .. "' pitch=" .. pitch .. " sur " .. played .. " speaker(s)")
    end
    
    return played > 0
end

-- Stop tous les sons (si supporté)
function Speakers:stopAll()
    for _, speaker in ipairs(self.speakers) do
        pcall(function()
            if speaker.peripheral.stop then
                speaker.peripheral.stop()
            end
        end)
    end
end

-- Liste tous les speakers
function Speakers:list()
    local list = {}
    for _, speaker in ipairs(self.speakers) do
        table.insert(list, {
            name = speaker.name,
            zone = speaker.zone
        })
    end
    return list
end

-- Liste les zones
function Speakers:listZones()
    local zones = {}
    local seen = {}
    
    -- D'abord, collecte toutes les zones des speakers
    for _, speaker in ipairs(self.speakers) do
        if not seen[speaker.zone] then
            seen[speaker.zone] = true
            table.insert(zones, {
                name = speaker.zone,
                volume = self.zoneVolumes[speaker.zone] or 1.0,
                count = 0
            })
        end
    end
    
    -- Ajoute les zones configurées mais sans speaker
    for zoneName, vol in pairs(self.zoneVolumes) do
        if not seen[zoneName] then
            seen[zoneName] = true
            table.insert(zones, {
                name = zoneName,
                volume = vol,
                count = 0
            })
        end
    end
    
    -- Compte les speakers par zone
    for _, speaker in ipairs(self.speakers) do
        for _, zone in ipairs(zones) do
            if zone.name == speaker.zone then
                zone.count = zone.count + 1
            end
        end
    end
    
    -- Trie par nom
    table.sort(zones, function(a, b) return a.name < b.name end)
    
    return zones
end

-- Nombre de speakers
function Speakers:count()
    return #self.speakers
end

-- Sauvegarde la config des zones
function Speakers:saveConfig(path)
    local config = {
        masterVolume = self.masterVolume,
        zoneVolumes = self.zoneVolumes,
        speakerZones = {}
    }
    for _, speaker in ipairs(self.speakers) do
        config.speakerZones[speaker.name] = speaker.zone
    end
    
    local file = fs.open(path, "w")
    if file then
        file.write(textutils.serialize(config))
        file.close()
        return true
    end
    return false
end

-- Charge la config des zones
function Speakers:loadConfig(path)
    if not fs.exists(path) then return false end
    
    local file = fs.open(path, "r")
    if not file then return false end
    
    local content = file.readAll()
    file.close()
    
    local config = textutils.unserialize(content)
    if config then
        self.masterVolume = config.masterVolume or 1.0
        self.zoneVolumes = config.zoneVolumes or {}
        
        if config.speakerZones then
            for _, speaker in ipairs(self.speakers) do
                if config.speakerZones[speaker.name] then
                    speaker.zone = config.speakerZones[speaker.name]
                end
            end
        end
        return true
    end
    return false
end

return Speakers
