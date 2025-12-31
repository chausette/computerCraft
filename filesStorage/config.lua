-- ============================================
-- CONFIGURATION DU SYSTEME DE STOCKAGE
-- Modifiez ce fichier pour personnaliser
-- ============================================

local config = {}

-- === NOMS DES PERIPHERIQUES ===
-- Modifiez selon votre installation
config.INPUT_CHEST = "minecraft:chest_0"      -- Coffre d'entrée
config.OUTPUT_CHEST = "minecraft:chest_1"     -- Coffre de sortie
config.MODEM_SIDE = "back"                    -- Côté du modem sans fil
config.MONITOR_NAME = "monitor_0"             -- Moniteur principal

-- === PROTOCOLE RESEAU ===
config.PROTOCOL = "storage_system"
config.SERVER_ID = "storage_server"

-- === CATEGORIES D'ITEMS ===
-- Chaque catégorie a un nom et une liste de patterns pour identifier les items
-- Les patterns utilisent string.find (recherche partielle)
config.categories = {
    {
        name = "Minerais & Lingots",
        color = colors.yellow,
        patterns = {
            "ore", "ingot", "nugget", "raw_", "diamond", "emerald",
            "coal", "lapis", "redstone", "quartz", "amethyst",
            "copper", "iron", "gold", "netherite"
        }
    },
    {
        name = "Blocs",
        color = colors.brown,
        patterns = {
            "stone", "dirt", "grass", "sand", "gravel", "cobblestone",
            "brick", "planks", "log", "wood", "concrete", "terracotta",
            "glass", "wool", "deepslate", "granite", "diorite", "andesite",
            "basalt", "blackstone", "calcite", "tuff", "obsidian"
        }
    },
    {
        name = "Nourriture",
        color = colors.red,
        patterns = {
            "apple", "bread", "beef", "pork", "chicken", "mutton",
            "cod", "salmon", "carrot", "potato", "beetroot", "melon",
            "berry", "cookie", "cake", "pie", "stew", "soup",
            "golden_apple", "honey", "sugar", "egg", "milk"
        }
    },
    {
        name = "Outils & Armes",
        color = colors.lightGray,
        patterns = {
            "pickaxe", "axe", "shovel", "hoe", "sword", "bow",
            "crossbow", "trident", "shield", "fishing_rod",
            "flint_and_steel", "shears", "brush", "spyglass"
        }
    },
    {
        name = "Armures",
        color = colors.cyan,
        patterns = {
            "helmet", "chestplate", "leggings", "boots",
            "horse_armor", "elytra", "turtle_helmet"
        }
    },
    {
        name = "Redstone",
        color = colors.red,
        patterns = {
            "redstone", "repeater", "comparator", "piston",
            "observer", "hopper", "dropper", "dispenser",
            "lever", "button", "pressure_plate", "tripwire",
            "daylight_detector", "target", "sculk_sensor"
        }
    },
    {
        name = "Potions & Enchant",
        color = colors.magenta,
        patterns = {
            "potion", "enchanted", "book", "experience",
            "blaze", "nether_wart", "ghast_tear", "magma_cream",
            "brewing", "cauldron", "end_crystal"
        }
    },
    {
        name = "Plantes & Nature",
        color = colors.green,
        patterns = {
            "sapling", "leaves", "flower", "seed", "wheat",
            "cactus", "bamboo", "vine", "lily", "mushroom",
            "fern", "moss", "azalea", "dripleaf", "spore"
        }
    },
    {
        name = "Divers",
        color = colors.white,
        patterns = {} -- Catégorie par défaut pour tout le reste
    }
}

-- === FAVORIS ===
-- Liste des items favoris (noms Minecraft)
config.favorites = {
    "minecraft:torch",
    "minecraft:cobblestone",
    "minecraft:oak_planks",
    "minecraft:iron_ingot",
    "minecraft:diamond",
    "minecraft:bread",
    "minecraft:coal"
}

-- === COFFRES DE STOCKAGE ===
-- Liste des coffres de stockage (ajoutez-en selon vos besoins)
-- Format: {name = "nom_peripherique", category = "nom_categorie" ou nil pour auto}
config.storage_chests = {
    {name = "minecraft:chest_2", category = nil},
    {name = "minecraft:chest_3", category = nil},
    {name = "minecraft:chest_4", category = nil},
    {name = "minecraft:chest_5", category = nil},
    -- Ajoutez d'autres coffres ici
}

-- === PARAMETRES D'AFFICHAGE ===
config.display = {
    refresh_rate = 2,           -- Rafraîchissement écran (secondes)
    items_per_page = 10,        -- Items par page sur pocket
    monitor_scale = 0.5,        -- Échelle du moniteur (0.5 - 5)
}

-- === ALERTES DE STOCK ===
-- Items à surveiller avec quantité minimum
config.stock_alerts = {
    ["minecraft:torch"] = 64,
    ["minecraft:coal"] = 32,
}

-- === FONCTIONS UTILITAIRES ===

-- Sauvegarde la config dans un fichier
function config.save()
    local file = fs.open("storage_data/config_save.lua", "w")
    if file then
        file.write("return " .. textutils.serialize({
            favorites = config.favorites,
            storage_chests = config.storage_chests,
            categories = config.categories,
            stock_alerts = config.stock_alerts
        }))
        file.close()
        return true
    end
    return false
end

-- Charge la config sauvegardée
function config.load()
    if fs.exists("storage_data/config_save.lua") then
        local data = dofile("storage_data/config_save.lua")
        if data then
            if data.favorites then config.favorites = data.favorites end
            if data.storage_chests then config.storage_chests = data.storage_chests end
            if data.categories then config.categories = data.categories end
            if data.stock_alerts then config.stock_alerts = data.stock_alerts end
            return true
        end
    end
    return false
end

-- Ajoute un coffre de stockage
function config.addChest(name, category)
    table.insert(config.storage_chests, {name = name, category = category})
    config.save()
end

-- Supprime un coffre de stockage
function config.removeChest(name)
    for i, chest in ipairs(config.storage_chests) do
        if chest.name == name then
            table.remove(config.storage_chests, i)
            config.save()
            return true
        end
    end
    return false
end

-- Ajoute un favori
function config.addFavorite(itemName)
    for _, fav in ipairs(config.favorites) do
        if fav == itemName then return false end
    end
    table.insert(config.favorites, itemName)
    config.save()
    return true
end

-- Supprime un favori
function config.removeFavorite(itemName)
    for i, fav in ipairs(config.favorites) do
        if fav == itemName then
            table.remove(config.favorites, i)
            config.save()
            return true
        end
    end
    return false
end

-- Ajoute une catégorie
function config.addCategory(name, colorVal, patterns)
    table.insert(config.categories, #config.categories, {
        name = name,
        color = colorVal or colors.white,
        patterns = patterns or {}
    })
    config.save()
end

-- Ajoute un pattern à une catégorie
function config.addPatternToCategory(categoryName, pattern)
    for _, cat in ipairs(config.categories) do
        if cat.name == categoryName then
            table.insert(cat.patterns, pattern)
            config.save()
            return true
        end
    end
    return false
end

return config
