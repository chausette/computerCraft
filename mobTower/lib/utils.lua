-- ============================================
-- MOB TOWER MANAGER v1.1 - Utils Library
-- Fonctions utilitaires communes
-- Version 1.21 NeoForge
-- ============================================

local utils = {}

-- Côtés disponibles pour redstone
utils.SIDES = {
    "top", "bottom", "left", "right", "front", "back"
}

-- Items rares (pour alertes)
utils.RARE_ITEMS = {
    ["minecraft:zombie_head"] = true,
    ["minecraft:skeleton_skull"] = true,
    ["minecraft:creeper_head"] = true,
    ["minecraft:wither_skeleton_skull"] = true,
    ["minecraft:music_disc_13"] = true,
    ["minecraft:music_disc_cat"] = true,
    ["minecraft:music_disc_blocks"] = true,
    ["minecraft:music_disc_chirp"] = true,
    ["minecraft:music_disc_far"] = true,
    ["minecraft:music_disc_mall"] = true,
    ["minecraft:music_disc_mellohi"] = true,
    ["minecraft:music_disc_stal"] = true,
    ["minecraft:music_disc_strad"] = true,
    ["minecraft:music_disc_ward"] = true,
    ["minecraft:music_disc_11"] = true,
    ["minecraft:music_disc_wait"] = true,
    ["minecraft:music_disc_pigstep"] = true,
    ["minecraft:music_disc_otherside"] = true,
    ["minecraft:trident"] = true,
    ["minecraft:totem_of_undying"] = true,
    ["minecraft:nautilus_shell"] = true,
}

-- Items enchantés sont aussi rares
function utils.isRareItem(itemName, nbt)
    if utils.RARE_ITEMS[itemName] then
        return true
    end
    if nbt and (nbt.Enchantments or nbt.StoredEnchantments) then
        return true
    end
    if string.find(itemName, "_helmet") or
       string.find(itemName, "_chestplate") or
       string.find(itemName, "_leggings") or
       string.find(itemName, "_boots") or
       string.find(itemName, "_sword") or
       string.find(itemName, "bow") then
        return true
    end
    return false
end

-- Liste des items à trier
utils.SORTABLE_ITEMS = {
    { id = "minecraft:rotten_flesh", name = "Rotten Flesh" },
    { id = "minecraft:iron_ingot", name = "Iron Ingot" },
    { id = "minecraft:carrot", name = "Carrot" },
    { id = "minecraft:potato", name = "Potato" },
    { id = "minecraft:bone", name = "Bone" },
    { id = "minecraft:arrow", name = "Arrow" },
    { id = "minecraft:bow", name = "Bow" },
    { id = "minecraft:gunpowder", name = "Gunpowder" },
    { id = "minecraft:ender_pearl", name = "Ender Pearl" },
    { id = "minecraft:redstone", name = "Redstone Dust" },
    { id = "minecraft:glowstone_dust", name = "Glowstone Dust" },
    { id = "minecraft:sugar", name = "Sugar" },
    { id = "minecraft:glass_bottle", name = "Glass Bottle" },
    { id = "minecraft:stick", name = "Stick" },
    { id = "minecraft:string", name = "String" },
    { id = "_helmet", name = "Helmets (all)", pattern = true },
    { id = "_chestplate", name = "Chestplates (all)", pattern = true },
    { id = "_leggings", name = "Leggings (all)", pattern = true },
    { id = "_boots", name = "Boots (all)", pattern = true },
    { id = "_sword", name = "Swords (all)", pattern = true },
    { id = "_head", name = "Mob Heads", pattern = true },
    { id = "_skull", name = "Skulls", pattern = true },
    { id = "music_disc", name = "Music Discs", pattern = true },
}

-- Formater un nombre avec séparateurs
function utils.formatNumber(n)
    if n == nil then return "0" end
    local formatted = tostring(math.floor(n))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

-- Formater le temps (secondes -> HH:MM:SS)
function utils.formatTime(seconds)
    if seconds == nil then seconds = 0 end
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

-- Formater timestamp -> HH:MM
function utils.formatTimestamp(timestamp)
    if timestamp == nil then return "--:--" end
    local date = os.date("*t", timestamp)
    if date then
        return string.format("%02d:%02d", date.hour, date.min)
    end
    return "--:--"
end

-- Sauvegarder une table dans un fichier
function utils.saveTable(filename, tbl)
    local file = fs.open(filename, "w")
    if file then
        file.write(textutils.serialize(tbl))
        file.close()
        return true
    end
    return false
end

-- Charger une table depuis un fichier
function utils.loadTable(filename)
    if fs.exists(filename) then
        local file = fs.open(filename, "r")
        if file then
            local data = file.readAll()
            file.close()
            local success, result = pcall(textutils.unserialize, data)
            if success and result then
                return result
            end
        end
    end
    return nil
end

-- Obtenir le nom court d'un item
function utils.getShortName(itemId)
    if itemId == nil then return "Unknown" end
    local name = itemId:gsub("minecraft:", "")
    name = name:gsub("_", " ")
    name = name:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    return name
end

-- Tronquer une chaîne
function utils.truncate(text, maxLen)
    if #text <= maxLen then
        return text
    end
    return string.sub(text, 1, maxLen - 2) .. ".."
end

-- Créer un dossier si n'existe pas
function utils.ensureDir(path)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
end

-- Logger simple
local logFile = nil
function utils.log(message)
    if logFile == nil then
        utils.ensureDir("/mobTower/data")
        logFile = fs.open("/mobTower/data/debug.log", "a")
    end
    if logFile then
        logFile.write("[" .. os.date("%H:%M:%S") .. "] " .. tostring(message) .. "\n")
        logFile.flush()
    end
end

function utils.closeLog()
    if logFile then
        logFile.close()
        logFile = nil
    end
end

return utils
