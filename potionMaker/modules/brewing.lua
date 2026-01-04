-- ============================================
-- Potion Maker - Module Brewing
-- Contrôle des alambics
-- ============================================

local Brewing = {}

local Inventory = require("modules.inventory")

-- État des alambics
local brewingStands = {}
local config = nil

-- Slots de l'alambic (Minecraft)
-- 0: Ingrédient (haut)
-- 1: Blaze powder (fuel)
-- 2, 3, 4: Fioles (bas gauche, milieu, droite)
local SLOTS = {
    INGREDIENT = 1,  -- ComputerCraft commence à 1
    FUEL = 2,
    BOTTLE_1 = 3,
    BOTTLE_2 = 4,
    BOTTLE_3 = 5
}

-- Initialiser les alambics
function Brewing.init(cfg)
    config = cfg
    brewingStands = {}
    
    for i, standName in ipairs(config.peripherals.brewing_stands) do
        local stand = peripheral.wrap(standName)
        if stand then
            brewingStands[i] = {
                name = standName,
                peripheral = stand,
                status = "idle",  -- idle, brewing, waiting
                currentStep = nil,
                progress = 0,
                bottles = { false, false, false }
            }
        end
    end
    
    return #brewingStands > 0, "Alambics initialises: " .. #brewingStands
end

-- Obtenir le nombre d'alambics
function Brewing.getCount()
    return #brewingStands
end

-- Obtenir l'état de tous les alambics
function Brewing.getStatus()
    local status = {}
    
    for i, stand in ipairs(brewingStands) do
        -- Mettre à jour l'état depuis le périphérique
        Brewing.updateStandStatus(i)
        
        status[i] = {
            name = stand.name,
            status = stand.status,
            progress = stand.progress,
            currentStep = stand.currentStep
        }
    end
    
    return status
end

-- Mettre à jour l'état d'un alambic
function Brewing.updateStandStatus(standIndex)
    local stand = brewingStands[standIndex]
    if not stand then return end
    
    local p = stand.peripheral
    if not p then return end
    
    -- Lire le temps de brassage restant
    local brewTime = 0
    
    -- Essayer différentes méthodes selon l'API disponible
    if p.getBrewTime then
        brewTime = p.getBrewTime() or 0
    end
    
    -- Vérifier le contenu des slots
    local items = p.list()
    stand.bottles = {
        items[SLOTS.BOTTLE_1] ~= nil,
        items[SLOTS.BOTTLE_2] ~= nil,
        items[SLOTS.BOTTLE_3] ~= nil
    }
    
    local hasIngredient = items[SLOTS.INGREDIENT] ~= nil
    local hasFuel = items[SLOTS.FUEL] ~= nil
    
    -- Déterminer le statut
    if brewTime > 0 then
        stand.status = "brewing"
        stand.progress = math.floor((400 - brewTime) / 400 * 100)
    elseif hasIngredient and (stand.bottles[1] or stand.bottles[2] or stand.bottles[3]) then
        stand.status = "waiting" -- En attente de fuel ou bug
        stand.progress = 0
    else
        stand.status = "idle"
        stand.progress = 0
    end
end

-- Trouver un alambic disponible
function Brewing.findAvailableStand()
    for i, stand in ipairs(brewingStands) do
        Brewing.updateStandStatus(i)
        if stand.status == "idle" then
            return i, stand
        end
    end
    return nil, nil
end

-- Vérifier si un alambic a du fuel
function Brewing.hasFuel(standIndex)
    local stand = brewingStands[standIndex]
    if not stand then return false, 0 end
    
    local items = stand.peripheral.list()
    if items[SLOTS.FUEL] then
        return true, items[SLOTS.FUEL].count
    end
    
    return false, 0
end

-- Ajouter du fuel à un alambic
function Brewing.addFuel(standIndex, count)
    local stand = brewingStands[standIndex]
    if not stand then return 0 end
    
    -- Chercher du blaze powder dans les ingrédients
    local slot = Inventory.findItem("ingredients", "minecraft:blaze_powder")
    if not slot then return 0 end
    
    local chest = Inventory.getChest("ingredients")
    return chest.pushItems(stand.name, slot, count or 64, SLOTS.FUEL)
end

-- Charger les fioles dans un alambic
function Brewing.loadBottles(standIndex, chestType, itemId, nbt, count)
    local stand = brewingStands[standIndex]
    if not stand then return 0 end
    
    local loaded = 0
    local targetSlots = { SLOTS.BOTTLE_1, SLOTS.BOTTLE_2, SLOTS.BOTTLE_3 }
    local slots = Inventory.findAllItems(chestType, itemId, nbt)
    
    local chestName = chestType == "water" and "water_bottles" or chestType
    local chest = peripheral.wrap(config.peripherals.chests[chestName])
    
    for _, targetSlot in ipairs(targetSlots) do
        if loaded >= count then break end
        if loaded >= 3 then break end
        
        -- Vérifier si le slot est vide
        local standItems = stand.peripheral.list()
        if not standItems[targetSlot] then
            -- Chercher un item à transférer
            for _, slotInfo in ipairs(slots) do
                if slotInfo.item.count > 0 then
                    local transferred = chest.pushItems(stand.name, slotInfo.slot, 1, targetSlot)
                    if transferred > 0 then
                        loaded = loaded + 1
                        slotInfo.item.count = slotInfo.item.count - 1
                        break
                    end
                end
            end
        end
    end
    
    return loaded
end

-- Charger un ingrédient dans un alambic
function Brewing.loadIngredient(standIndex, ingredientId, count)
    local stand = brewingStands[standIndex]
    if not stand then return 0 end
    
    local slot = Inventory.findItem("ingredients", ingredientId)
    if not slot then return 0 end
    
    local chest = Inventory.getChest("ingredients")
    return chest.pushItems(stand.name, slot, count or 1, SLOTS.INGREDIENT)
end

-- Récupérer les potions d'un alambic
function Brewing.unloadBottles(standIndex, targetChest)
    local stand = brewingStands[standIndex]
    if not stand then return 0 end
    
    local unloaded = 0
    local sourceSlots = { SLOTS.BOTTLE_1, SLOTS.BOTTLE_2, SLOTS.BOTTLE_3 }
    
    local chestName = targetChest == "water" and "water_bottles" or targetChest
    local chest = peripheral.wrap(config.peripherals.chests[chestName])
    
    for _, sourceSlot in ipairs(sourceSlots) do
        local transferred = chest.pullItems(stand.name, sourceSlot)
        unloaded = unloaded + transferred
    end
    
    return unloaded
end

-- Attendre qu'un alambic termine
function Brewing.waitForCompletion(standIndex, timeout)
    local stand = brewingStands[standIndex]
    if not stand then return false end
    
    local startTime = os.clock()
    timeout = timeout or 30 -- 30 secondes par défaut
    
    while os.clock() - startTime < timeout do
        Brewing.updateStandStatus(standIndex)
        
        if stand.status == "idle" then
            return true
        end
        
        sleep(0.5)
    end
    
    return false -- Timeout
end

-- Exécuter une étape de brassage
function Brewing.executeStep(standIndex, step, quantity)
    local stand = brewingStands[standIndex]
    if not stand then return false, "Alambic invalide" end
    
    stand.currentStep = step.description
    
    if step.type == "source" then
        -- Charger les fioles d'eau
        local loaded = Brewing.loadBottles(standIndex, "water", "minecraft:potion", "water", quantity)
        if loaded < quantity then
            return false, "Pas assez de fioles d'eau (charge: " .. loaded .. "/" .. quantity .. ")"
        end
        return true, nil
        
    elseif step.type == "brew" then
        -- Vérifier le fuel
        local hasFuel, fuelCount = Brewing.hasFuel(standIndex)
        if not hasFuel then
            local added = Brewing.addFuel(standIndex, 1)
            if added == 0 then
                return false, "Pas de blaze powder pour le fuel"
            end
        end
        
        -- Charger l'ingrédient
        local loaded = Brewing.loadIngredient(standIndex, step.ingredient, 1)
        if loaded == 0 then
            return false, "Ingredient non disponible: " .. step.ingredient
        end
        
        -- Attendre la fin du brassage
        sleep(0.5) -- Petit délai pour que le brassage démarre
        
        local completed = Brewing.waitForCompletion(standIndex, 25)
        if not completed then
            return false, "Timeout lors du brassage"
        end
        
        return true, nil
    end
    
    return false, "Type d'etape inconnu: " .. (step.type or "nil")
end

-- Exécuter une recette complète sur un alambic
function Brewing.executeRecipe(standIndex, steps, quantity)
    local stand = brewingStands[standIndex]
    if not stand then return false, "Alambic invalide" end
    
    stand.status = "brewing"
    
    for i, step in ipairs(steps) do
        local ok, err = Brewing.executeStep(standIndex, step, quantity)
        if not ok then
            stand.status = "idle"
            stand.currentStep = nil
            return false, "Etape " .. i .. " echouee: " .. (err or "erreur inconnue")
        end
    end
    
    -- Récupérer les potions terminées
    local unloaded = Brewing.unloadBottles(standIndex, "potions")
    
    stand.status = "idle"
    stand.currentStep = nil
    
    return true, unloaded
end

-- Obtenir les infos d'un alambic
function Brewing.getStandInfo(standIndex)
    local stand = brewingStands[standIndex]
    if not stand then return nil end
    
    Brewing.updateStandStatus(standIndex)
    
    return {
        name = stand.name,
        status = stand.status,
        progress = stand.progress,
        currentStep = stand.currentStep,
        bottles = stand.bottles
    }
end

-- Définir le statut d'un alambic
function Brewing.setStatus(standIndex, status, step)
    local stand = brewingStands[standIndex]
    if not stand then return end
    
    stand.status = status
    stand.currentStep = step
end

-- Vérifier si tous les alambics sont idle
function Brewing.allIdle()
    for i = 1, #brewingStands do
        Brewing.updateStandStatus(i)
        if brewingStands[i].status ~= "idle" then
            return false
        end
    end
    return true
end

return Brewing
