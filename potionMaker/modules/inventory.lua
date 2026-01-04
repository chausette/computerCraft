-- ============================================
-- Potion Maker - Module Inventaire
-- Gestion des coffres et tri automatique
-- Version corrigée pour MC 1.21
-- ============================================

local Inventory = {}

-- Références aux coffres (initialisées par init)
local chests = {}
local chestNames = {}

-- Initialiser les références aux coffres
function Inventory.init(config)
    chestNames = {
        input = config.peripherals.chests.input,
        water = config.peripherals.chests.water_bottles,
        ingredients = config.peripherals.chests.ingredients,
        potions = config.peripherals.chests.potions,
        output = config.peripherals.chests.output
    }
    
    chests = {
        input = chestNames.input and peripheral.wrap(chestNames.input),
        water = chestNames.water and peripheral.wrap(chestNames.water),
        ingredients = chestNames.ingredients and peripheral.wrap(chestNames.ingredients),
        potions = chestNames.potions and peripheral.wrap(chestNames.potions),
        output = chestNames.output and peripheral.wrap(chestNames.output)
    }
    
    -- Vérifier les connexions
    for name, chest in pairs(chests) do
        if not chest then
            return false, "Coffre " .. name .. " non connecte"
        end
    end
    
    return true, nil
end

-- Obtenir le nom du périphérique pour les transferts
function Inventory.getChestName(chestType)
    return chestNames[chestType]
end

-- Lister le contenu d'un coffre
function Inventory.list(chestType)
    local chest = chests[chestType]
    if not chest then return {} end
    
    local ok, items = pcall(function() return chest.list() end)
    if not ok or not items then return {} end
    
    local result = {}
    
    for slot, item in pairs(items) do
        result[slot] = {
            name = item.name,
            count = item.count,
            nbt = item.nbt,
            slot = slot
        }
    end
    
    return result
end

-- Obtenir les détails d'un item
function Inventory.getItemDetail(chestType, slot)
    local chest = chests[chestType]
    if not chest then return nil end
    
    local ok, detail = pcall(function() return chest.getItemDetail(slot) end)
    if ok then return detail end
    return nil
end

-- Vérifier si une potion est une fiole d'eau
function Inventory.isWaterBottle(detail)
    if not detail then return false end
    if detail.name ~= "minecraft:potion" then return false end
    
    -- Méthode 1: Vérifier le displayName
    local displayName = detail.displayName or ""
    if displayName:lower():find("water") or displayName:lower():find("eau") then
        return true
    end
    
    -- Méthode 2: Vérifier le NBT (format peut varier)
    if detail.nbt then
        local nbtStr = textutils.serialise(detail.nbt)
        if nbtStr:find("water") then
            return true
        end
    end
    
    -- Méthode 3: Vérifier le tag (MC 1.21+)
    if detail.tags then
        for tag, _ in pairs(detail.tags) do
            if tag:find("water") then
                return true
            end
        end
    end
    
    return false
end

-- Compter les fioles d'eau (VERSION CORRIGÉE)
function Inventory.countWaterBottles()
    local items = Inventory.list("water")
    local count = 0
    
    for slot, item in pairs(items) do
        -- Option 1: Si c'est une potion, vérifier si c'est de l'eau
        if item.name == "minecraft:potion" then
            local detail = Inventory.getItemDetail("water", slot)
            if Inventory.isWaterBottle(detail) then
                count = count + item.count
            end
        end
    end
    
    -- Si on ne trouve rien avec la vérification stricte,
    -- compter toutes les potions du coffre d'eau (car c'est dédié)
    if count == 0 then
        for slot, item in pairs(items) do
            if item.name == "minecraft:potion" then
                count = count + item.count
            end
        end
    end
    
    return count
end

-- Compter un item spécifique dans un coffre
function Inventory.countItem(chestType, itemId)
    local items = Inventory.list(chestType)
    local count = 0
    
    for _, item in pairs(items) do
        if item.name == itemId then
            count = count + item.count
        end
    end
    
    return count
end

-- Compter un ingrédient
function Inventory.countIngredient(ingredientId)
    return Inventory.countItem("ingredients", ingredientId)
end

-- Obtenir le stock complet des ingrédients
function Inventory.getIngredientsStock()
    local items = Inventory.list("ingredients")
    local stock = {}
    
    for _, item in pairs(items) do
        if stock[item.name] then
            stock[item.name] = stock[item.name] + item.count
        else
            stock[item.name] = item.count
        end
    end
    
    return stock
end

-- Obtenir le stock des potions
function Inventory.getPotionsStock()
    local items = Inventory.list("potions")
    local stock = {}
    
    for slot, item in pairs(items) do
        local detail = Inventory.getItemDetail("potions", slot)
        
        -- Utiliser le displayName comme clé
        local displayName = "Potion"
        if detail and detail.displayName then
            displayName = detail.displayName
        end
        
        local key = displayName
        
        if stock[key] then
            stock[key].count = stock[key].count + item.count
            table.insert(stock[key].slots, slot)
        else
            stock[key] = {
                name = item.name,
                count = item.count,
                displayName = displayName,
                slots = { slot }
            }
        end
    end
    
    return stock
end

-- Trouver un slot contenant un item spécifique
function Inventory.findItem(chestType, itemId)
    local items = Inventory.list(chestType)
    
    for slot, item in pairs(items) do
        if item.name == itemId then
            return slot, item
        end
    end
    
    return nil, nil
end

-- Trouver une fiole d'eau
function Inventory.findWaterBottle()
    local items = Inventory.list("water")
    
    for slot, item in pairs(items) do
        if item.name == "minecraft:potion" then
            local detail = Inventory.getItemDetail("water", slot)
            if Inventory.isWaterBottle(detail) or true then -- Fallback: accepter toute potion du coffre eau
                return slot, item
            end
        end
    end
    
    return nil, nil
end

-- Trouver tous les slots contenant un item
function Inventory.findAllItems(chestType, itemId)
    local items = Inventory.list(chestType)
    local found = {}
    
    for slot, item in pairs(items) do
        if item.name == itemId then
            table.insert(found, { slot = slot, item = item })
        end
    end
    
    return found
end

-- Tri automatique du coffre input
function Inventory.sortInput(config)
    local inputChest = chests.input
    if not inputChest then return { water = 0, ingredients = 0, potions = 0 } end
    
    local items = Inventory.list("input")
    local sorted = {
        water = 0,
        ingredients = 0,
        potions = 0
    }
    
    for slot, item in pairs(items) do
        local detail = Inventory.getItemDetail("input", slot)
        local targetName = nil
        
        -- Fioles d'eau
        if item.name == "minecraft:potion" and Inventory.isWaterBottle(detail) then
            targetName = chestNames.water
            sorted.water = sorted.water + item.count
        -- Splash potion ou lingering -> stockage potions
        elseif item.name == "minecraft:splash_potion" or item.name == "minecraft:lingering_potion" then
            targetName = chestNames.potions
            sorted.potions = sorted.potions + item.count
        -- Autre potion -> stockage potions
        elseif item.name == "minecraft:potion" then
            targetName = chestNames.potions
            sorted.potions = sorted.potions + item.count
        -- Fioles vides -> coffre eau
        elseif item.name == "minecraft:glass_bottle" then
            targetName = chestNames.water
            sorted.water = sorted.water + item.count
        -- Tout le reste -> ingrédients
        else
            targetName = chestNames.ingredients
            sorted.ingredients = sorted.ingredients + item.count
        end
        
        if targetName then
            pcall(function()
                inputChest.pushItems(targetName, slot)
            end)
        end
    end
    
    return sorted
end

-- Distribuer des potions vers output (VERSION CORRIGÉE)
function Inventory.distributePotion(displayName, count)
    local potionsChest = chests.potions
    local outputName = chestNames.output
    
    if not potionsChest or not outputName then 
        return 0 
    end
    
    local remaining = count
    local items = Inventory.list("potions")
    
    for slot, item in pairs(items) do
        if remaining <= 0 then break end
        
        local detail = Inventory.getItemDetail("potions", slot)
        local itemDisplayName = detail and detail.displayName or "Potion"
        
        -- Comparer les noms
        if itemDisplayName == displayName or displayName == nil then
            local toTransfer = math.min(remaining, item.count)
            local ok, transferred = pcall(function()
                return potionsChest.pushItems(outputName, slot, toTransfer)
            end)
            
            if ok and transferred then
                remaining = remaining - transferred
            end
        end
    end
    
    return count - remaining
end

-- Distribuer toutes les potions d'un type vers output
function Inventory.distributeAllOfType(displayName)
    local stock = Inventory.getPotionsStock()
    local potionInfo = stock[displayName]
    
    if potionInfo then
        return Inventory.distributePotion(displayName, potionInfo.count)
    end
    
    return 0
end

-- Extraire des items vers l'alambic
function Inventory.extractToBrewingStand(chestType, slot, brewingStandName, brewSlot, count)
    local chest = chests[chestType]
    if not chest then return 0 end
    
    local ok, result = pcall(function()
        return chest.pushItems(brewingStandName, slot, count, brewSlot)
    end)
    
    return ok and result or 0
end

-- Récupérer des items depuis l'alambic
function Inventory.extractFromBrewingStand(brewingStandName, brewSlot, chestType, count)
    local chest = chests[chestType]
    if not chest then return 0 end
    
    local ok, result = pcall(function()
        return chest.pullItems(brewingStandName, brewSlot, count)
    end)
    
    return ok and result or 0
end

-- Vérifier si on a assez d'ingrédients
function Inventory.hasIngredients(ingredientsList)
    local missing = {}
    
    for ingredientId, needed in pairs(ingredientsList) do
        local available = Inventory.countIngredient(ingredientId)
        if available < needed then
            table.insert(missing, {
                id = ingredientId,
                needed = needed,
                available = available,
                missing = needed - available
            })
        end
    end
    
    return #missing == 0, missing
end

-- Vérifier si on a assez de fioles d'eau
function Inventory.hasWaterBottles(count)
    local available = Inventory.countWaterBottles()
    return available >= count, available
end

-- Obtenir la taille d'un coffre
function Inventory.getSize(chestType)
    local chest = chests[chestType]
    if not chest then return 0 end
    
    local ok, size = pcall(function() return chest.size() end)
    return ok and size or 0
end

-- Obtenir le nombre de slots libres
function Inventory.getFreeSlots(chestType)
    local total = Inventory.getSize(chestType)
    local items = Inventory.list(chestType)
    local used = 0
    
    for _ in pairs(items) do
        used = used + 1
    end
    
    return total - used
end

-- Exposer les coffres pour usage externe
function Inventory.getChest(chestType)
    return chests[chestType]
end

return Inventory
