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
    self:discover()
    return self
end

-- Découvre tous les speakers connectés
function Speakers:discover()
    self.speakers = {}
    
    -- Cherche les speakers directement attachés
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "speaker" then
            table.insert(self.speakers, {
                name = name,
                peripheral = peripheral.wrap(name),
                zone = "default"
            })
        end
    end
    
    -- Log
    print("[Speakers] " .. #self.speakers .. " speaker(s) trouvé(s)")
    
    return #self.speakers
end

-- Assigne un speaker à une zone
function Speakers:setZone(speakerName, zoneName)
    for _, speaker in ipairs(self.speakers) do
        if speaker.name == speakerName then
            speaker.zone = zoneName
            if not self.zoneVolumes[zoneName] then
                self.zoneVolumes[zoneName] = 1.0
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
    
    for _, speaker in ipairs(self.speakers) do
        if zone == nil or speaker.zone == zone then
            local effectiveVol = volume * self:getEffectiveVolume(speaker.zone)
            if effectiveVol > 0 then
                speaker.peripheral.playSound(sound, effectiveVol, pitch)
            end
        end
    end
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
    
    for _, speaker in ipairs(self.speakers) do
        if zone == nil or speaker.zone == zone then
            local effectiveVol = volume * self:getEffectiveVolume(speaker.zone)
            if effectiveVol > 0 then
                speaker.peripheral.playNote(instrument, effectiveVol, pitch)
            end
        end
    end
end

-- Stop tous les sons (si supporté)
function Speakers:stopAll()
    -- Note: les speakers CC ne supportent pas vraiment le stop
    -- On peut juste arrêter d'envoyer des sons
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
    -- Compte les speakers par zone
    for _, speaker in ipairs(self.speakers) do
        for _, zone in ipairs(zones) do
            if zone.name == speaker.zone then
                zone.count = zone.count + 1
            end
        end
    end
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
    file.write(textutils.serialize(config))
    file.close()
end

-- Charge la config des zones
function Speakers:loadConfig(path)
    if not fs.exists(path) then return false end
    
    local file = fs.open(path, "r")
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
