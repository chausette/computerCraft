-- ============================================
-- MODULE DE GESTION DU STOCKAGE
-- Gère l'inventaire, le tri et les transferts
-- ============================================

local storage = {}
local config = require("config")

-- Cache de l'inventaire global
storage.inventory = {}
storage.lastUpdate = 0

-- === FONCTIONS UTILITAIRES ===

-- Obtient le nom lisible d'un item
function storage.getDisplayName(itemName)
    -- Retire le namespace (minecraft:, modid:, etc.)
    local name = itemName:gsub("^[^:]+:", "")
    -- Remplace les underscores par des espaces et met en majuscule
    name = name:gsub("_", " ")
    name = name:gsub("(%a)([%w]*)", function(a, b) 
        return string.upper(a) .. b 
    end)
    return name
end

-- Détermine la catégorie d'un item
function storage.getCategory(itemName)
    local lowerName = itemName:lower()
    
    for _, category in ipairs(config.categories) do
        for _, pattern in ipairs(category.patterns) do
            if lowerName:find(pattern:lower()) then
                return category.name
            end
        end
    end
    
    -- Catégorie par défaut (dernière = Divers)
    return config.categories[#config.categories].name
end

-- Obtient la couleur d'une catégorie
function storage.getCategoryColor(categoryName)
    for _, category in ipairs(config.categories) do
        if category.name == categoryName then
            return category.color
        end
    end
    return colors.white
end

-- === GESTION DE L'INVENTAIRE ===

-- Scanne tous les coffres et met à jour l'inventaire
function storage.scanAll()
    storage.inventory = {}
    local totalItems = 0
    local totalSlots = 0
    local usedSlots = 0
    
    -- Scanne les coffres de stockage
    for _, chestConfig in ipairs(config.storage_chests) do
        local chest = peripheral.wrap(chestConfig.name)
        if chest then
            local items = chest.list()
            local size = chest.size()
            totalSlots = totalSlots + size
            
            for slot, item in pairs(items) do
                usedSlots = usedSlots + 1
                local key = item.name
                
                if not storage.inventory[key] then
                    storage.inventory[key] = {
                        name = item.name,
                        displayName = storage.getDisplayName(item.name),
                        category = storage.getCategory(item.name),
                        count = 0,
                        locations = {}
                    }
                end
                
                storage.inventory[key].count = storage.inventory[key].count + item.count
                totalItems = totalItems + item.count
                
                table.insert(storage.inventory[key].locations, {
                    chest = chestConfig.name,
                    slot = slot,
                    count = item.count
                })
            end
        end
    end
    
    storage.lastUpdate = os.clock()
    storage.totalItems = totalItems
    storage.totalSlots = totalSlots
    storage.usedSlots = usedSlots
    
    return storage.inventory
end

-- Obtient l'inventaire trié par catégorie
function storage.getByCategory()
    local byCategory = {}
    
    -- Initialise les catégories
    for _, cat in ipairs(config.categories) do
        byCategory[cat.name] = {
            name = cat.name,
            color = cat.color,
            items = {}
        }
    end
    
    -- Trie les items
    for _, item in pairs(storage.inventory) do
        local catName = item.category
        if byCategory[catName] then
            table.insert(byCategory[catName].items, item)
        end
    end
    
    -- Trie les items par nom dans chaque catégorie
    for _, cat in pairs(byCategory) do
        table.sort(cat.items, function(a, b)
            return a.displayName < b.displayName
        end)
    end
    
    return byCategory
end

-- Recherche des items
function storage.search(query)
    local results = {}
    local lowerQuery = query:lower()
    
    for _, item in pairs(storage.inventory) do
        if item.name:lower():find(lowerQuery) or 
           item.displayName:lower():find(lowerQuery) then
            table.insert(results, item)
        end
    end
    
    table.sort(results, function(a, b)
        return a.displayName < b.displayName
    end)
    
    return results
end

-- Obtient les favoris avec leurs quantités
function storage.getFavorites()
    local favorites = {}
    
    for _, favName in ipairs(config.favorites) do
        local item = storage.inventory[favName]
        if item then
            table.insert(favorites, {
                name = item.name,
                displayName = item.displayName,
                count = item.count,
                inStock = true
            })
        else
            table.insert(favorites, {
                name = favName,
                displayName = storage.getDisplayName(favName),
                count = 0,
                inStock = false
            })
        end
    end
    
    return favorites
end

-- === TRANSFERT D'ITEMS ===

-- Vérifie si un coffre accepte un item
function storage.chestAcceptsItem(chestConfig, itemName, itemCategory)
    -- Si le coffre est verrouillé sur un item spécifique
    if chestConfig.itemLock then
        return chestConfig.itemLock == itemName
    end
    
    -- Si le coffre est restreint à une catégorie
    if chestConfig.category then
        return chestConfig.category == itemCategory
    end
    
    -- Pas de restriction
    return true
end

-- Trouve le meilleur coffre pour stocker un item
function storage.findStorageChest(itemName)
    local category = storage.getCategory(itemName)
    
    -- D'abord, cherche un coffre verrouillé sur cet item avec de la place
    for _, chestConfig in ipairs(config.storage_chests) do
        if chestConfig.itemLock == itemName then
            local chest = peripheral.wrap(chestConfig.name)
            if chest then
                local items = chest.list()
                local size = chest.size()
                -- Cherche un slot avec cet item ou vide
                for slot = 1, size do
                    if not items[slot] then
                        return chestConfig.name, slot
                    elseif items[slot].name == itemName and items[slot].count < 64 then
                        return chestConfig.name, slot
                    end
                end
            end
        end
    end
    
    -- Ensuite, cherche un coffre de la bonne catégorie qui contient déjà cet item
    for _, chestConfig in ipairs(config.storage_chests) do
        if storage.chestAcceptsItem(chestConfig, itemName, category) then
            local chest = peripheral.wrap(chestConfig.name)
            if chest then
                local items = chest.list()
                for slot, item in pairs(items) do
                    if item.name == itemName and item.count < 64 then
                        return chestConfig.name, slot
                    end
                end
            end
        end
    end
    
    -- Sinon, cherche un coffre de la bonne catégorie avec de la place
    for _, chestConfig in ipairs(config.storage_chests) do
        if storage.chestAcceptsItem(chestConfig, itemName, category) then
            local chest = peripheral.wrap(chestConfig.name)
            if chest then
                local items = chest.list()
                local size = chest.size()
                for slot = 1, size do
                    if not items[slot] then
                        return chestConfig.name, slot
                    end
                end
            end
        end
    end
    
    return nil, nil
end

-- Transfère un item vers le coffre de sortie
function storage.retrieveItem(itemName, count)
    local retrieved = 0
    local item = storage.inventory[itemName]
    
    if not item then
        return 0, "Item non trouvé"
    end
    
    local outputChest = peripheral.wrap(config.OUTPUT_CHEST)
    if not outputChest then
        return 0, "Coffre de sortie non trouvé"
    end
    
    -- Parcourt les emplacements de l'item
    for _, loc in ipairs(item.locations) do
        if retrieved >= count then break end
        
        local sourceChest = peripheral.wrap(loc.chest)
        if sourceChest then
            local toTransfer = math.min(count - retrieved, loc.count)
            local transferred = sourceChest.pushItems(
                config.OUTPUT_CHEST, 
                loc.slot, 
                toTransfer
            )
            retrieved = retrieved + transferred
        end
    end
    
    -- Met à jour l'inventaire
    storage.scanAll()
    
    return retrieved, nil
end

-- Trie le coffre d'entrée vers les coffres de stockage
function storage.sortInputChest()
    local inputChest = peripheral.wrap(config.INPUT_CHEST)
    if not inputChest then
        return 0, "Coffre d'entrée non trouvé"
    end
    
    local sorted = 0
    local items = inputChest.list()
    
    for slot, item in pairs(items) do
        local targetChest, targetSlot = storage.findStorageChest(item.name)
        
        if targetChest then
            local transferred = inputChest.pushItems(targetChest, slot)
            sorted = sorted + transferred
        end
    end
    
    -- Met à jour l'inventaire
    storage.scanAll()
    
    return sorted, nil
end

-- Vide complètement le coffre d'entrée
function storage.emptyInputChest()
    local count, err = storage.sortInputChest()
    
    -- Vérifie s'il reste des items
    local inputChest = peripheral.wrap(config.INPUT_CHEST)
    if inputChest then
        local remaining = inputChest.list()
        local remainingCount = 0
        for _ in pairs(remaining) do
            remainingCount = remainingCount + 1
        end
        
        if remainingCount > 0 then
            return count, "Certains items n'ont pas pu être triés (stockage plein?)"
        end
    end
    
    return count, err
end

-- === STATISTIQUES ===

function storage.getStats()
    return {
        totalItems = storage.totalItems or 0,
        totalSlots = storage.totalSlots or 0,
        usedSlots = storage.usedSlots or 0,
        freeSlots = (storage.totalSlots or 0) - (storage.usedSlots or 0),
        uniqueItems = 0,
        lastUpdate = storage.lastUpdate
    }
end

-- Compte les items uniques
function storage.countUniqueItems()
    local count = 0
    for _ in pairs(storage.inventory) do
        count = count + 1
    end
    return count
end

-- Vérifie les alertes de stock
function storage.checkAlerts()
    local alerts = {}
    
    for itemName, minQty in pairs(config.stock_alerts) do
        -- Seulement si le seuil est > 0
        if minQty and minQty > 0 then
            local item = storage.inventory[itemName]
            local currentQty = item and item.count or 0
            
            if currentQty < minQty then
                table.insert(alerts, {
                    name = itemName,
                    displayName = storage.getDisplayName(itemName),
                    current = currentQty,
                    minimum = minQty
                })
            end
        end
    end
    
    return alerts
end

-- === GESTION DES COFFRES ===

-- Liste tous les coffres connectés (pour configuration)
function storage.listConnectedChests()
    local chests = {}
    local peripherals = peripheral.getNames()
    
    for _, name in ipairs(peripherals) do
        local pType = peripheral.getType(name)
        if pType and (pType:find("chest") or pType:find("barrel") or 
                      pType:find("shulker") or pType == "inventory") then
            local isUsed = false
            local isSystem = false
            local category = nil
            local itemLock = nil
            
            -- Vérifie si c'est un coffre système
            if name == config.INPUT_CHEST or name == config.OUTPUT_CHEST then
                isSystem = true
                isUsed = true
            end
            
            -- Vérifie si c'est un coffre de stockage et récupère ses infos
            for _, sc in ipairs(config.storage_chests) do
                if sc.name == name then
                    isUsed = true
                    category = sc.category
                    itemLock = sc.itemLock
                    break
                end
            end
            
            -- Compte les slots utilisés
            local chest = peripheral.wrap(name)
            local size = 0
            local used = 0
            if chest then
                size = chest.size() or 0
                local items = chest.list()
                for _ in pairs(items) do
                    used = used + 1
                end
            end
            
            table.insert(chests, {
                name = name,
                type = pType,
                isUsed = isUsed,
                isSystem = isSystem,
                isStorage = isUsed and not isSystem,
                size = size,
                used = used,
                category = category,
                itemLock = itemLock
            })
        end
    end
    
    table.sort(chests, function(a, b) return a.name < b.name end)
    return chests
end

-- === LECTURE DISQUETTE COLONIE ===

-- Lit les données d'une disquette colonie
function storage.readColonyDisk()
    -- Cherche un lecteur de disque sur le réseau
    local diskDrive = nil
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == "drive" then
            diskDrive = name
            break
        end
    end
    
    if not diskDrive then
        return nil, "Aucun lecteur de disque trouve"
    end
    
    -- Vérifie si un disque est présent
    if not disk.isPresent(diskDrive) then
        return nil, "Aucun disque dans le lecteur"
    end
    
    local mountPath = disk.getMountPath(diskDrive)
    if not mountPath then
        return nil, "Disque non monte"
    end
    
    -- Cherche un fichier JSON
    local jsonFile = nil
    local files = fs.list(mountPath)
    for _, file in ipairs(files) do
        if file:match("%.json$") then
            jsonFile = mountPath .. "/" .. file
            break
        end
    end
    
    if not jsonFile then
        return nil, "Aucun fichier .json sur le disque"
    end
    
    -- Lit le fichier
    local file = fs.open(jsonFile, "r")
    if not file then
        return nil, "Impossible de lire le fichier"
    end
    
    local content = file.readAll()
    file.close()
    
    -- Parse le JSON
    local data = textutils.unserialiseJSON(content)
    if not data then
        return nil, "Format JSON invalide"
    end
    
    return data, nil
end

return storage
