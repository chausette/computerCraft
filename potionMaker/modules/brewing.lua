-- ============================================
-- Potion Maker - Module Brewing
-- Contrôle des alambics
-- Version corrigée
-- ============================================

local Brewing = {}

local Inventory = require("modules.inventory")

-- État des alambics
local brewingStands = {}
local config = nil

-- Slots de l'alambic (ComputerCraft)
local SLOTS = {
    INGREDIENT = 1,
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
                status = "idle",
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
    
    local ok, result = pcall(function()
        if p.getBrewTime then
            return p.getBrewTime() or 0
        end
        return 0
    end)
    
    if ok then
        brewTime = result
    end
    
    -- Vérifier le contenu des slots
    local items = {}
    pcall(function()
        items = p.list() or {}
    end)
    
    stand.bottles = {
        items[SLOTS.BOTTLE_1] ~= nil,
        items[SLOTS.BOTTLE_2] ~= nil,
        items[SLOTS.BOTTLE_3] ~= nil
    }
    
    local hasIngredient = items[SLOTS.INGREDIENT] ~= nil
    
    -- Déterminer le statut
    if brewTime > 0 then
        stand.status = "brewing"
        stand.progress = math.floor((400 - brewTime) / 400 * 100)
    elseif hasIngredient and (stand.bottles[1] or stand.bottles[2] or stand.bottles[3]) then
        stand.status = "waiting"
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
    
    local ok, items = pcall(function() return stand.peripheral.list() end)
    if not ok or not items then return false, 0 end
    
    if items[SLOTS.FUEL] then
        return true, items[SLOTS.FUEL].count
    end
    
    return false, 0
end

-- Ajouter du fuel à un alambic
function Brewing.addFuel(standIndex, count)
    local stand = brewingStands[standIndex]
    if not stand then return 0 end
    
    local slot = Inventory.findItem("ingredients", "minecraft:blaze_powder")
    if not slot then return 0 end
    
    local chest = Inventory.getChest("ingredients")
    if not chest then return 0 end
    
    local ok, result = pcall(function()
        return chest.pushItems(stand.name, slot, count or 64, SLOTS.FUEL)
    end)
    
    return ok and result or 0
end

-- Charger les fioles d'eau dans un alambic (CORRIGÉ)
function Brewing.loadWaterBottles(standIndex, count)
    local stand = brewingStands[standIndex]
    if not stand then return 0 end
    
    local loaded = 0
    local targetSlots = { SLOTS.BOTTLE_1, SLOTS.BOTTLE_2, SLOTS.BOTTLE_3 }
    
    local chest = Inventory.getChest("water")
    if not chest then return 0 end
    
    local chestName = Inventory.getChestName("water")
    if not chestName then return 0 end
    
    -- Lister les potions dans le coffre d'eau
    local items = Inventory.list("water")
    
    for _, targetSlot in ipairs(targetSlots) do
        if loaded >= count then break end
        if loaded >= 3 then break end
        
        -- Vérifier si le slot de l'alambic est vide
        local standItems = {}
        pcall(function() standItems = stand.peripheral.list() or {} end)
        
        if not standItems[targetSlot] then
            -- Chercher une fiole d'eau à transférer
            for slot, item in pairs(items) do
                if item.name == "minecraft:potion" and item.count > 0 then
                    local ok, transferred = pcall(function()
                        return chest.pushItems(stand.name, slot, 1, targetSlot)
                    end)
                    
                    if ok and transferred and transferred > 0 then
                        loaded = loaded + 1
                        item.count = item.count - 1
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
    if not chest then return 0 end
    
    local ok, result = pcall(function()
        return chest.pushItems(stand.name, slot, count or 1, SLOTS.INGREDIENT)
    end)
    
    return ok and result or 0
end

-- Récupérer les potions d'un alambic
function Brewing.unloadBottles(standIndex, targetChest)
    local stand = brewingStands[standIndex]
    if not stand then return 0 end
    
    local unloaded = 0
    local sourceSlots = { SLOTS.BOTTLE_1, SLOTS.BOTTLE_2, SLOTS.BOTTLE_3 }
    
    local chest = Inventory.getChest(targetChest)
    if not chest then return 0 end
    
    for _, sourceSlot in ipairs(sourceSlots) do
        local ok, transferred = pcall(function()
            return chest.pullItems(stand.name, sourceSlot)
        end)
        
        if ok and transferred then
            unloaded = unloaded + transferred
        end
    end
    
    return unloaded
end

-- Attendre qu'un alambic termine
function Brewing.waitForCompletion(standIndex, timeout)
    local stand = brewingStands[standIndex]
    if not stand then return false end
    
    local startTime = os.clock()
    timeout = timeout or 30
    
    while os.clock() - startTime < timeout do
        Brewing.updateStandStatus(standIndex)
        
        if stand.status == "idle" then
            return true
        end
        
        sleep(0.5)
    end
    
    return false
end

-- Exécuter une étape de brassage (CORRIGÉ)
function Brewing.executeStep(standIndex, step, quantity)
    local stand = brewingStands[standIndex]
    if not stand then return false, "Alambic invalide" end
    
    stand.currentStep = step.description
    
    if step.type == "source" then
        -- Charger les fioles d'eau
        local loaded = Brewing.loadWaterBottles(standIndex, quantity)
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
        sleep(1)
        
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
