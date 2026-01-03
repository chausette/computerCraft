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
            {sound = "minecraft:ambient.cave", weight = 1, minDelay = 100, maxDelay = 300},
            {sound = "minecraft:entity.bat.ambient", weight = 2, minDelay = 60, maxDelay = 200},
            {sound = "minecraft:block.grass.step", weight = 3, minDelay = 20, maxDelay = 60},
            {sound = "minecraft:entity.bee.loop", weight = 1, minDelay = 200, maxDelay = 400},
            {sound = "minecraft:entity.parrot.ambient", weight = 2, minDelay = 80, maxDelay = 180},
            {sound = "minecraft:entity.wolf.ambient", weight = 1, minDelay = 150, maxDelay = 350},
        }
    },
    cave = {
        name = "Grotte",
        icon = "O",
        sounds = {
            {sound = "minecraft:ambient.cave", weight = 5, minDelay = 60, maxDelay = 180},
            {sound = "minecraft:entity.bat.ambient", weight = 3, minDelay = 40, maxDelay = 120},
            {sound = "minecraft:block.stone.step", weight = 2, minDelay = 30, maxDelay = 80},
            {sound = "minecraft:block.gravel.step", weight = 2, minDelay = 40, maxDelay = 100},
            {sound = "minecraft:entity.bat.takeoff", weight = 1, minDelay = 100, maxDelay = 250},
            {sound = "minecraft:block.pointed_dripstone.drip_water", weight = 4, minDelay = 20, maxDelay = 60},
        }
    },
    nether = {
        name = "Nether",
        icon = "!",
        sounds = {
            {sound = "minecraft:ambient.nether_wastes.loop", weight = 3, minDelay = 100, maxDelay = 200},
            {sound = "minecraft:ambient.soul_sand_valley.loop", weight = 2, minDelay = 120, maxDelay = 240},
            {sound = "minecraft:entity.ghast.ambient", weight = 2, minDelay = 80, maxDelay = 200},
            {sound = "minecraft:entity.blaze.ambient", weight = 2, minDelay = 60, maxDelay = 150},
            {sound = "minecraft:entity.piglin.ambient", weight = 1, minDelay = 100, maxDelay = 250},
            {sound = "minecraft:block.fire.ambient", weight = 4, minDelay = 30, maxDelay = 80},
        }
    },
    ocean = {
        name = "Ocean",
        icon = "~",
        sounds = {
            {sound = "minecraft:ambient.underwater.loop", weight = 5, minDelay = 100, maxDelay = 200},
            {sound = "minecraft:entity.dolphin.ambient_water", weight = 2, minDelay = 80, maxDelay = 180},
            {sound = "minecraft:entity.fish.swim", weight = 3, minDelay = 40, maxDelay = 100},
            {sound = "minecraft:entity.squid.ambient", weight = 2, minDelay = 60, maxDelay = 150},
            {sound = "minecraft:block.bubble_column.bubble_pop", weight = 3, minDelay = 30, maxDelay = 80},
        }
    },
    rain = {
        name = "Pluie",
        icon = ",",
        sounds = {
            {sound = "minecraft:weather.rain", weight = 5, minDelay = 60, maxDelay = 120},
            {sound = "minecraft:weather.rain.above", weight = 4, minDelay = 80, maxDelay = 150},
            {sound = "minecraft:entity.lightning_bolt.thunder", weight = 1, minDelay = 200, maxDelay = 600},
            {sound = "minecraft:block.wet_grass.step", weight = 2, minDelay = 40, maxDelay = 100},
        }
    },
    end_dimension = {
        name = "End",
        icon = "#",
        sounds = {
            {sound = "minecraft:ambient.basalt_deltas.loop", weight = 3, minDelay = 100, maxDelay = 200},
            {sound = "minecraft:entity.enderman.ambient", weight = 2, minDelay = 80, maxDelay = 200},
            {sound = "minecraft:entity.enderman.teleport", weight = 1, minDelay = 120, maxDelay = 300},
            {sound = "minecraft:entity.shulker.ambient", weight = 2, minDelay = 100, maxDelay = 220},
            {sound = "minecraft:block.end_portal.spawn", weight = 1, minDelay = 300, maxDelay = 600},
        }
    },
    spooky = {
        name = "Horreur",
        icon = "X",
        sounds = {
            {sound = "minecraft:ambient.cave", weight = 4, minDelay = 40, maxDelay = 100},
            {sound = "minecraft:entity.ghast.scream", weight = 1, minDelay = 150, maxDelay = 400},
            {sound = "minecraft:entity.phantom.ambient", weight = 2, minDelay = 80, maxDelay = 200},
            {sound = "minecraft:entity.zombie.ambient", weight = 2, minDelay = 60, maxDelay = 150},
            {sound = "minecraft:entity.skeleton.ambient", weight = 2, minDelay = 70, maxDelay = 160},
            {sound = "minecraft:entity.witch.ambient", weight = 1, minDelay = 100, maxDelay = 250},
            {sound = "minecraft:entity.warden.heartbeat", weight = 3, minDelay = 30, maxDelay = 60},
        }
    },
    village = {
        name = "Village",
        icon = "^",
        sounds = {
            {sound = "minecraft:entity.villager.ambient", weight = 4, minDelay = 40, maxDelay = 100},
            {sound = "minecraft:entity.villager.trade", weight = 2, minDelay = 80, maxDelay = 180},
            {sound = "minecraft:block.anvil.use", weight = 1, minDelay = 120, maxDelay = 300},
            {sound = "minecraft:entity.chicken.ambient", weight = 3, minDelay = 50, maxDelay = 120},
            {sound = "minecraft:entity.cow.ambient", weight = 2, minDelay = 60, maxDelay = 140},
            {sound = "minecraft:entity.pig.ambient", weight = 2, minDelay = 70, maxDelay = 150},
            {sound = "minecraft:block.campfire.crackle", weight = 3, minDelay = 40, maxDelay = 80},
        }
    },
    peaceful = {
        name = "Calme",
        icon = "-",
        sounds = {
            {sound = "minecraft:block.amethyst_block.chime", weight = 3, minDelay = 60, maxDelay = 150},
            {sound = "minecraft:block.azalea_leaves.place", weight = 2, minDelay = 80, maxDelay = 180},
            {sound = "minecraft:entity.allay.ambient_without_item", weight = 2, minDelay = 100, maxDelay = 220},
            {sound = "minecraft:entity.axolotl.idle_air", weight = 2, minDelay = 90, maxDelay = 200},
            {sound = "minecraft:block.flowering_azalea.place", weight = 2, minDelay = 100, maxDelay = 200},
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
    
    -- Initialise les timers pour chaque son
    self.soundTimers = {}
    for i, soundDef in ipairs(station.sounds) do
        self.soundTimers[i] = math.random(soundDef.minDelay, soundDef.maxDelay)
    end
    
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
            self.speakers:playSound(soundDef.sound, self.volume, pitch)
            
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
