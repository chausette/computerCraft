-- ============================================
-- Potion Maker - Module Network
-- Communication avec Pocket Computers
-- ============================================

local Network = {}

local Queue = require("modules.queue")
local Recipes = require("modules.recipes")
local Brewing = require("modules.brewing")
local Inventory = require("modules.inventory")

-- Configuration
local config = nil
local recipes = nil
local modem = nil

local PROTOCOL = "potion_network"
local CHANNEL = 500

-- Initialiser le réseau
function Network.init(cfg, rec)
    config = cfg
    recipes = rec
    
    PROTOCOL = config.network.protocol or PROTOCOL
    CHANNEL = config.network.channel or CHANNEL
    
    -- Chercher un modem
    modem = peripheral.find("modem")
    
    if modem then
        modem.open(CHANNEL)
        rednet.host(PROTOCOL, "potion_server")
        return true
    end
    
    return false
end

-- Fermer le réseau
function Network.close()
    if modem then
        modem.close(CHANNEL)
        rednet.unhost(PROTOCOL)
    end
end

-- Traiter une requête
function Network.handleRequest(senderId, message)
    if type(message) ~= "table" then
        return { success = false, error = "Format invalide" }
    end
    
    local action = message.action
    
    if action == "ping" then
        return { success = true, message = "pong", server = "Potion Maker" }
        
    elseif action == "getStatus" then
        return Network.getStatus()
        
    elseif action == "getPotions" then
        return Network.getPotionsList()
        
    elseif action == "getQueue" then
        return Network.getQueueInfo()
        
    elseif action == "getStock" then
        return Network.getStockInfo()
        
    elseif action == "order" then
        return Network.placeOrder(message, senderId)
        
    elseif action == "distribute" then
        return Network.requestDistribution(message)
        
    elseif action == "cancelOrder" then
        return Network.cancelOrder(message.orderId)
        
    else
        return { success = false, error = "Action inconnue: " .. tostring(action) }
    end
end

-- Obtenir le statut général
function Network.getStatus()
    local stands = Brewing.getStatus()
    local counts = Queue.count()
    
    return {
        success = true,
        data = {
            brewing_stands = stands,
            queue = counts,
            server_time = os.epoch("utc")
        }
    }
end

-- Obtenir la liste des potions disponibles
function Network.getPotionsList()
    local potions = Recipes.getPotionList(recipes)
    
    return {
        success = true,
        data = {
            potions = potions
        }
    }
end

-- Obtenir les infos de la file d'attente
function Network.getQueueInfo()
    local pending = Queue.getPending()
    local processing = Queue.getProcessing()
    local completed = Queue.getCompleted(10)
    local counts = Queue.count()
    
    -- Enrichir avec les noms
    local enrichQueue = function(list)
        local enriched = {}
        for _, cmd in ipairs(list) do
            local enrichedCmd = {}
            for k, v in pairs(cmd) do
                enrichedCmd[k] = v
            end
            enrichedCmd.potionName = Recipes.getFullPotionName(recipes, cmd.potion, cmd.variant, cmd.form)
            table.insert(enriched, enrichedCmd)
        end
        return enriched
    end
    
    return {
        success = true,
        data = {
            pending = enrichQueue(pending),
            processing = enrichQueue(processing),
            completed = enrichQueue(completed),
            counts = counts
        }
    }
end

-- Obtenir les infos de stock
function Network.getStockInfo()
    local waterBottles = Inventory.countWaterBottles()
    local ingredients = Inventory.getIngredientsStock()
    local potions = Inventory.getPotionsStock()
    
    return {
        success = true,
        data = {
            water_bottles = waterBottles,
            ingredients = ingredients,
            potions = potions,
            low_stock_threshold = config.alerts.low_stock_threshold
        }
    }
end

-- Passer une commande
function Network.placeOrder(message, senderId)
    local potion = message.potion
    local variant = message.variant or "normal"
    local form = message.form or "normal"
    local quantity = message.quantity or 3
    
    -- Validation
    if not potion then
        return { success = false, error = "Potion non specifiee" }
    end
    
    -- Vérifier que la potion existe
    local potionInfo = recipes.potions[potion]
    if not potionInfo then
        return { success = false, error = "Potion inconnue: " .. potion }
    end
    
    -- Vérifier les variants
    if variant == "extended" and not potionInfo.can_extend then
        return { success = false, error = "Cette potion ne peut pas etre prolongee" }
    end
    
    if variant == "amplified" and not potionInfo.can_amplify then
        return { success = false, error = "Cette potion ne peut pas etre renforcee" }
    end
    
    -- Calculer les ingrédients nécessaires
    local required, err = Recipes.calculateIngredients(recipes, potion, variant, form, quantity)
    if not required then
        return { success = false, error = err }
    end
    
    -- Vérifier le stock
    local hasWater, waterCount = Inventory.hasWaterBottles(required.water_bottles)
    if not hasWater then
        return {
            success = false,
            error = "Pas assez de fioles d'eau",
            details = { needed = required.water_bottles, available = waterCount }
        }
    end
    
    local hasIngr, missing = Inventory.hasIngredients(required.ingredients)
    if not hasIngr then
        return {
            success = false,
            error = "Ingredients manquants",
            details = missing
        }
    end
    
    -- Ajouter à la file
    local orderId = Queue.add({
        potion = potion,
        variant = variant,
        form = form,
        quantity = quantity,
        source = "pocket:" .. tostring(senderId)
    })
    
    local position = Queue.getPosition(orderId)
    
    return {
        success = true,
        data = {
            orderId = orderId,
            position = position,
            potionName = Recipes.getFullPotionName(recipes, potion, variant, form),
            quantity = quantity
        }
    }
end

-- Demander une distribution
function Network.requestDistribution(message)
    local itemId = message.itemId
    local nbt = message.nbt
    local count = message.count or 1
    
    if not itemId then
        return { success = false, error = "Item non specifie" }
    end
    
    local distributed = Inventory.distributePotion(itemId, nbt, count)
    
    return {
        success = true,
        data = {
            distributed = distributed,
            requested = count
        }
    }
end

-- Annuler une commande
function Network.cancelOrder(orderId)
    if not orderId then
        return { success = false, error = "ID de commande non specifie" }
    end
    
    local order = Queue.getById(orderId)
    if not order then
        return { success = false, error = "Commande non trouvee" }
    end
    
    if order.status ~= "pending" then
        return { success = false, error = "Seules les commandes en attente peuvent etre annulees" }
    end
    
    Queue.cancel(orderId)
    
    return {
        success = true,
        message = "Commande annulee"
    }
end

-- Envoyer une notification à tous les clients
function Network.broadcast(message)
    if modem then
        rednet.broadcast(message, PROTOCOL)
    end
end

-- Notifier un client spécifique
function Network.notify(clientId, message)
    if modem then
        rednet.send(clientId, message, PROTOCOL)
    end
end

-- Boucle d'écoute (à exécuter en parallel)
function Network.listen(onRequest)
    while true do
        local senderId, message = rednet.receive(PROTOCOL, 1)
        
        if senderId and message then
            local response = Network.handleRequest(senderId, message)
            Network.notify(senderId, response)
            
            if onRequest then
                onRequest(senderId, message, response)
            end
        end
    end
end

-- Obtenir les infos du réseau
function Network.getInfo()
    return {
        protocol = PROTOCOL,
        channel = CHANNEL,
        modem = modem ~= nil
    }
end

return Network
