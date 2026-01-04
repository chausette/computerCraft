-- ============================================
-- Potion Maker - Module Sound
-- Gestion du speaker
-- ============================================

local Sound = {}

-- Référence au speaker
local speaker = nil

-- Sons disponibles
local sounds = {
    -- Potion terminée
    complete = {
        { note = "harp", pitch = 12 },
        { note = "harp", pitch = 16 },
        { note = "harp", pitch = 20 }
    },
    
    -- Stock bas
    warning = {
        { note = "bit", pitch = 8 },
        { note = "bit", pitch = 6 }
    },
    
    -- Erreur
    error = {
        { note = "bass", pitch = 4 },
        { note = "bass", pitch = 2 },
        { note = "bass", pitch = 1 }
    },
    
    -- Notification
    notify = {
        { note = "bell", pitch = 12 }
    },
    
    -- Commande reçue
    order = {
        { note = "chime", pitch = 16 },
        { note = "chime", pitch = 20 }
    },
    
    -- Clic interface
    click = {
        { note = "hat", pitch = 20 }
    },
    
    -- Démarrage
    startup = {
        { note = "harp", pitch = 8 },
        { note = "harp", pitch = 12 },
        { note = "harp", pitch = 16 },
        { note = "harp", pitch = 20 }
    }
}

-- Initialiser le speaker
function Sound.init(config)
    if config.peripherals.speaker then
        speaker = peripheral.wrap(config.peripherals.speaker)
    end
    
    if not speaker then
        -- Essayer de trouver un speaker
        speaker = peripheral.find("speaker")
    end
    
    return speaker ~= nil
end

-- Jouer une séquence de notes
function Sound.play(soundName)
    if not speaker then return false end
    
    local sequence = sounds[soundName]
    if not sequence then return false end
    
    for _, note in ipairs(sequence) do
        speaker.playNote(note.note, 1, note.pitch)
        sleep(0.15)
    end
    
    return true
end

-- Jouer un son Minecraft
function Sound.playMinecraft(soundName, volume, pitch)
    if not speaker then return false end
    
    volume = volume or 1
    pitch = pitch or 1
    
    return speaker.playSound(soundName, volume, pitch)
end

-- Sons spécifiques

function Sound.potionComplete()
    Sound.play("complete")
end

function Sound.lowStock()
    Sound.play("warning")
end

function Sound.error()
    Sound.play("error")
end

function Sound.orderReceived()
    Sound.play("order")
end

function Sound.click()
    if speaker then
        speaker.playNote("hat", 0.5, 20)
    end
end

function Sound.startup()
    Sound.play("startup")
end

function Sound.notify()
    Sound.play("notify")
end

-- Jouer une note unique
function Sound.note(instrument, pitch, volume)
    if not speaker then return false end
    
    instrument = instrument or "harp"
    pitch = pitch or 12
    volume = volume or 1
    
    return speaker.playNote(instrument, volume, pitch)
end

-- Vérifier si le speaker est disponible
function Sound.isAvailable()
    return speaker ~= nil
end

-- Ajouter un son personnalisé
function Sound.addSound(name, sequence)
    sounds[name] = sequence
end

-- Liste des sons disponibles
function Sound.list()
    local list = {}
    for name, _ in pairs(sounds) do
        table.insert(list, name)
    end
    return list
end

return Sound
