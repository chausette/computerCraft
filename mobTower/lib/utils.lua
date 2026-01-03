-- ============================================
-- MOB TOWER MANAGER - Utils Library
-- Fonctions utilitaires communes
-- ============================================

local utils = {}

-- Couleurs bundled cable
utils.COLORS = {
    white = colors.white,
    orange = colors.orange,
    magenta = colors.magenta,
    lightBlue = colors.lightBlue,
    yellow = colors.yellow,
    lime = colors.lime,
    pink = colors.pink,
    gray = colors.gray,
    lightGray = colors.lightGray,
    cyan = colors.cyan,
    purple = colors.purple,
    blue = colors.blue,
    brown = colors.brown,
    green = colors.green,
    red = colors.red,
    black = colors.black
}

-- Liste des couleurs pour le menu
utils.COLOR_NAMES = {
    "white", "orange", "magenta", "lightBlue", "yellow", "lime",
    "pink", "gray", "lightGray", "cyan", "purple", "blue",
    "brown", "green", "red", "black"
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
    -- Vérifie si l'item est enchanté
    if nbt and (nbt.Enchantments or nbt.StoredEnchantments) then
        return true
    end
    -- Armures et armes
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
    return string.format("%02d:%02d", date.hour, date.min)
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

-- Deep copy d'une table
function utils.deepCopy(orig)
    local copy
    if type(orig) == 'table' then
        copy = {}
        for k, v in pairs(orig) do
            copy[utils.deepCopy(k)] = utils.deepCopy(v)
        end
        setmetatable(copy, utils.deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Merger deux tables
function utils.mergeTables(t1, t2)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(t1[k]) == "table" then
            utils.mergeTables(t1[k], v)
        else
            t1[k] = v
        end
    end
    return t1
end

-- Obtenir le nom court d'un item
function utils.getShortName(itemId)
    if itemId == nil then return "Unknown" end
    local name = itemId:gsub("minecraft:", "")
    name = name:gsub("_", " ")
    -- Capitalize first letter of each word
    name = name:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)
    return name
end

-- Centrer une chaîne
function utils.centerText(text, width)
    local padding = math.floor((width - #text) / 2)
    if padding < 0 then padding = 0 end
    return string.rep(" ", padding) .. text
end

-- Tronquer une chaîne
function utils.truncate(text, maxLen)
    if #text <= maxLen then
        return text
    end
    return string.sub(text, 1, maxLen - 2) .. ".."
end

-- Pad à droite
function utils.padRight(text, width)
    if #text >= width then
        return string.sub(text, 1, width)
    end
    return text .. string.rep(" ", width - #text)
end

-- Pad à gauche
function utils.padLeft(text, width)
    if #text >= width then
        return string.sub(text, 1, width)
    end
    return string.rep(" ", width - #text) .. text
end

-- Créer une barre de progression
function utils.progressBar(current, max, width)
    if max == 0 then max = 1 end
    local percent = current / max
    if percent > 1 then percent = 1 end
    local filled = math.floor(percent * width)
    local empty = width - filled
    return string.rep("\127", filled) .. string.rep("\176", empty)
end

-- Obtenir le timestamp actuel
function utils.getTimestamp()
    return os.epoch("utc") / 1000
end

-- Vérifier si un fichier existe
function utils.fileExists(path)
    return fs.exists(path)
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
        utils.ensureDir("mobTower/data")
        logFile = fs.open("mobTower/data/debug.log", "a")
    end
    if logFile then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        logFile.write("[" .. timestamp .. "] " .. message .. "\n")
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
