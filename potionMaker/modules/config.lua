-- ============================================
-- Potion Maker - Module Configuration
-- ============================================

local Config = {}

local CONFIG_PATH = "data/config.json"

-- Configuration par défaut
local defaultConfig = {
    peripherals = {
        monitor = nil,
        speaker = nil,
        brewing_stands = {},
        chests = {
            input = nil,
            water_bottles = nil,
            ingredients = nil,
            potions = nil,
            output = nil
        }
    },
    network = {
        protocol = "potion_network",
        channel = 500
    },
    alerts = {
        low_stock_threshold = 5
    },
    version = "1.0.0"
}

-- Charger la configuration
function Config.load()
    if not fs.exists(CONFIG_PATH) then
        return nil
    end
    
    local file = fs.open(CONFIG_PATH, "r")
    if not file then
        return nil
    end
    
    local content = file.readAll()
    file.close()
    
    local ok, data = pcall(textutils.unserialiseJSON, content)
    if ok and data then
        -- Fusionner avec les valeurs par défaut
        return Config.merge(defaultConfig, data)
    end
    
    return nil
end

-- Sauvegarder la configuration
function Config.save(config)
    -- Créer le dossier data si nécessaire
    if not fs.exists("data") then
        fs.makeDir("data")
    end
    
    local file = fs.open(CONFIG_PATH, "w")
    if not file then
        return false
    end
    
    file.write(textutils.serialiseJSON(config))
    file.close()
    return true
end

-- Fusionner deux tables (deep merge)
function Config.merge(default, override)
    local result = {}
    
    for k, v in pairs(default) do
        if type(v) == "table" and type(override[k]) == "table" then
            result[k] = Config.merge(v, override[k])
        elseif override[k] ~= nil then
            result[k] = override[k]
        else
            result[k] = v
        end
    end
    
    -- Ajouter les clés qui n'existent pas dans default
    for k, v in pairs(override) do
        if result[k] == nil then
            result[k] = v
        end
    end
    
    return result
end

-- Obtenir la configuration par défaut
function Config.getDefault()
    return defaultConfig
end

-- Vérifier si la configuration est valide
function Config.validate(config)
    local errors = {}
    
    if not config.peripherals then
        table.insert(errors, "Pas de peripheriques configures")
        return false, errors
    end
    
    if not config.peripherals.monitor then
        table.insert(errors, "Moniteur non configure")
    end
    
    if not config.peripherals.brewing_stands or #config.peripherals.brewing_stands == 0 then
        table.insert(errors, "Aucun alambic configure")
    end
    
    local chests = config.peripherals.chests
    if not chests then
        table.insert(errors, "Coffres non configures")
    else
        if not chests.input then table.insert(errors, "Coffre INPUT non configure") end
        if not chests.water_bottles then table.insert(errors, "Coffre FIOLES non configure") end
        if not chests.ingredients then table.insert(errors, "Coffre INGREDIENTS non configure") end
        if not chests.potions then table.insert(errors, "Coffre POTIONS non configure") end
        if not chests.output then table.insert(errors, "Coffre OUTPUT non configure") end
    end
    
    if #errors > 0 then
        return false, errors
    end
    
    return true, {}
end

-- Vérifier si la configuration existe
function Config.exists()
    return fs.exists(CONFIG_PATH)
end

-- Supprimer la configuration
function Config.delete()
    if fs.exists(CONFIG_PATH) then
        fs.delete(CONFIG_PATH)
        return true
    end
    return false
end

-- Obtenir une valeur spécifique
function Config.get(config, path)
    local parts = {}
    for part in path:gmatch("[^.]+") do
        table.insert(parts, part)
    end
    
    local current = config
    for _, part in ipairs(parts) do
        if type(current) ~= "table" then
            return nil
        end
        current = current[part]
    end
    
    return current
end

-- Définir une valeur spécifique
function Config.set(config, path, value)
    local parts = {}
    for part in path:gmatch("[^.]+") do
        table.insert(parts, part)
    end
    
    local current = config
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end
    
    current[parts[#parts]] = value
    return config
end

return Config
