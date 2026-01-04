-- ============================================
-- Potion Maker - Module Inventaire
-- Gestion des coffres et tri automatique
-- ============================================

local Inventory = {}

-- Références aux coffres (initialisées par init)
local chests = {}

-- Initialiser les références aux coffres
function Inventory.init(config)
    chests = {
        input = config.peripherals.chests.input and peripheral.wrap(config.peripherals.chests.input),
        water = config.peripherals.chests.water_bottles and peripheral.wrap(config.peripherals.chests.water_bottles),
        ingredients = config.peripherals.chests.ingredients and peripheral.wrap(config.peripherals.chests.ingredients),
        potions = config.peripherals.chests.potions and peripheral.wrap(config.peripherals.chests.potions),
        output = config.peripherals.chests.output and peripheral.wrap(config.peripherals.chests.output)
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
function Inventory.getChestName(config, chestType)
    return config.peripherals.chests[chestType]
end

-- Lister le contenu d'un coffre
function Inventory.list(chestType)
    local chest = chests[chestType]
    if not chest then return {} end
    
    local items = chest.list()
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
    
    return chest.getItemDetail(slot)
end

-- Compter un item spécifique dans un coffre
function Inventory.countItem(chestType, itemId, nbt)
    local items = Inventory.list(chestType)
    local count = 0
    
    for _, item in pairs(items) do
        if item.name == itemId then
            if nbt then
                -- Vérifier le NBT si spécifié
                local detail = Inventory.getItemDetail(chestType, item.slot)
                if detail and detail.nbt and textutils.serialise(detail.nbt):find(nbt) then
                    count = count + item.count
                end
            else
                count = count + item.count
            end
        end
    end
    
    return count
end

-- Compter les fioles d'eau
function Inventory.countWaterBottles()
    return Inventory.countItem("water", "minecraft:potion", "water")
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
        local key = item.name
        
        -- Construire une clé unique basée sur le NBT
        if detail and detail.nbt then
            key = key .. ":" .. textutils.serialise(detail.nbt)
        end
        
        if stock[key] then
            stock[key].count = stock[key].count + item.count
        else
            stock[key] = {
                name = item.name,
                count = item.count,
                nbt = detail and detail.nbt,
                displayName = detail and detail.displayName or item.name
            }
        end
    end
    
    return stock
end

-- Transférer des items d'un coffre à un autre
function Inventory.transfer(fromChest, toChest, slot, count, toSlot)
    local from = chests[fromChest]
    local toName = nil
    
    -- Obtenir le nom du coffre destination pour pushItems
    if toChest == "input" then toName = "input"
    elseif toChest == "water" then toName = "water_bottles"
    elseif toChest == "ingredients" then toName = "ingredients"
    elseif toChest == "potions" then toName = "potions"
    elseif toChest == "output" then toName = "output"
    end
    
    if not from then return 0 end
    
    -- Utiliser le nom du périphérique pour le transfert
    -- pushItems attend le nom du périphérique réseau
    return from.pushItems(peripheral.getName(chests[toChest]), slot, count, toSlot)
end

-- Trouver un slot contenant un item spécifique
function Inventory.findItem(chestType, itemId, nbt)
    local items = Inventory.list(chestType)
    
    for slot, item in pairs(items) do
        if item.name == itemId then
            if nbt then
                local detail = Inventory.getItemDetail(chestType, slot)
                if detail and detail.nbt then
                    local nbtStr = textutils.serialise(detail.nbt)
                    if nbtStr:find(nbt) then
                        return slot, item
                    end
                end
            else
                return slot, item
            end
        end
    end
    
    return nil, nil
end

-- Trouver tous les slots contenant un item
function Inventory.findAllItems(chestType, itemId, nbt)
    local items = Inventory.list(chestType)
    local found = {}
    
    for slot, item in pairs(items) do
        if item.name == itemId then
            if nbt then
                local detail = Inventory.getItemDetail(chestType, slot)
                if detail and detail.nbt then
                    local nbtStr = textutils.serialise(detail.nbt)
                    if nbtStr:find(nbt) then
                        table.insert(found, { slot = slot, item = item })
                    end
                end
            else
                table.insert(found, { slot = slot, item = item })
            end
        end
    end
    
    return found
end

-- Tri automatique du coffre input
function Inventory.sortInput(config)
    local items = Inventory.list("input")
    local sorted = {
        water = 0,
        ingredients = 0,
        potions = 0
    }
    
    for slot, item in pairs(items) do
        local detail = Inventory.getItemDetail("input", slot)
        local targetChest = nil
        
        -- Fioles d'eau
        if item.name == "minecraft:potion" then
            if detail and detail.nbt then
                local nbtStr = textutils.serialise(detail.nbt)
                if nbtStr:find("water") then
                    targetChest = "water"
                else
                    -- Autre potion -> stockage potions
                    targetChest = "potions"
                end
            end
        -- Splash potion ou lingering -> stockage potions
        elseif item.name == "minecraft:splash_potion" or item.name == "minecraft:lingering_potion" then
            targetChest = "potions"
        -- Fioles vides -> considérées comme ingrédients ou eau
        elseif item.name == "minecraft:glass_bottle" then
            targetChest = "water"
        -- Tout le reste -> ingrédients
        else
            targetChest = "ingredients"
        end
        
        if targetChest then
            local inputChest = peripheral.wrap(config.peripherals.chests.input)
            local targetName = config.peripherals.chests[targetChest == "water" and "water_bottles" or targetChest]
            
            local transferred = inputChest.pushItems(targetName, slot)
            
            if transferred > 0 then
                sorted[targetChest] = sorted[targetChest] + transferred
            end
        end
    end
    
    return sorted
end

-- Extraire des items vers l'alambic
function Inventory.extractToBrewingStand(chestType, slot, brewingStandName, brewSlot, count)
    local chest = chests[chestType]
    if not chest then return 0 end
    
    return chest.pushItems(brewingStandName, slot, count, brewSlot)
end

-- Récupérer des items depuis l'alambic
function Inventory.extractFromBrewingStand(brewingStandName, brewSlot, chestType, count)
    local chest = chests[chestType]
    if not chest then return 0 end
    
    return chest.pullItems(brewingStandName, brewSlot, count)
end

-- Distribuer des potions vers output
function Inventory.distributePotion(itemId, nbt, count)
    local remaining = count
    local slots = Inventory.findAllItems("potions", itemId, nbt)
    
    for _, slotInfo in ipairs(slots) do
        if remaining <= 0 then break end
        
        local toTransfer = math.min(remaining, slotInfo.item.count)
        local potionsChest = chests.potions
        local outputName = peripheral.getName(chests.output)
        
        local transferred = potionsChest.pushItems(outputName, slotInfo.slot, toTransfer)
        remaining = remaining - transferred
    end
    
    return count - remaining
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
    
    return chest.size()
end

-- Obtenir le nombre de slots libres
function Inventory.getFreeSlots(chestType)
    local chest = chests[chestType]
    if not chest then return 0 end
    
    local total = chest.size()
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
