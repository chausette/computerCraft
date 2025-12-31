-- ============================================
-- MODULE RESEAU
-- Gère la communication entre serveur et clients
-- ============================================

local network = {}
local config = require("config")

network.isServer = false
network.modem = nil

-- === INITIALISATION ===

function network.init(isServer)
    network.isServer = isServer
    
    -- Cherche un modem
    local modemSide = nil
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.getType(side) == "modem" then
            modemSide = side
            break
        end
    end
    
    if not modemSide then
        -- Cherche un modem sur le réseau câblé
        for _, name in ipairs(peripheral.getNames()) do
            if peripheral.getType(name) == "modem" then
                modemSide = name
                break
            end
        end
    end
    
    if modemSide then
        network.modem = peripheral.wrap(modemSide)
        rednet.open(modemSide)
        
        if isServer then
            rednet.host(config.PROTOCOL, config.SERVER_ID)
        end
        
        return true
    end
    
    return false
end

-- === COMMUNICATION SERVEUR ===

-- Envoie une réponse au client
function network.sendResponse(clientId, response)
    rednet.send(clientId, response, config.PROTOCOL)
end

-- Attend une requête (serveur)
function network.waitForRequest(timeout)
    local senderId, message = rednet.receive(config.PROTOCOL, timeout)
    if senderId and message then
        return senderId, message
    end
    return nil, nil
end

-- === COMMUNICATION CLIENT ===

-- Trouve le serveur
function network.findServer()
    local serverId = rednet.lookup(config.PROTOCOL, config.SERVER_ID)
    return serverId
end

-- Envoie une requête au serveur
function network.sendRequest(request)
    local serverId = network.findServer()
    if not serverId then
        return nil, "Serveur non trouvé"
    end
    
    rednet.send(serverId, request, config.PROTOCOL)
    
    local senderId, response = rednet.receive(config.PROTOCOL, 5)
    if senderId == serverId then
        return response, nil
    end
    
    return nil, "Timeout - pas de réponse"
end

-- === TYPES DE REQUETES ===

network.REQUEST = {
    -- Inventaire
    GET_INVENTORY = "get_inventory",
    GET_BY_CATEGORY = "get_by_category",
    GET_FAVORITES = "get_favorites",
    SEARCH = "search",
    GET_STATS = "get_stats",
    
    -- Actions
    RETRIEVE_ITEM = "retrieve_item",
    SORT_INPUT = "sort_input",
    EMPTY_INPUT = "empty_input",
    
    -- Configuration
    ADD_FAVORITE = "add_favorite",
    REMOVE_FAVORITE = "remove_favorite",
    ADD_CHEST = "add_chest",
    REMOVE_CHEST = "remove_chest",
    UPDATE_CHEST = "update_chest",
    GET_CHEST_INFO = "get_chest_info",
    LIST_CHESTS = "list_chests",
    GET_CATEGORIES = "get_categories",
    ADD_CATEGORY = "add_category",
    ADD_PATTERN = "add_pattern",
    
    -- Alertes
    GET_ALERTS = "get_alerts"
}

-- === GESTIONNAIRE DE REQUETES (SERVEUR) ===

function network.handleRequest(storage, request)
    local response = {success = false, error = "Requête inconnue"}
    
    if request.type == network.REQUEST.GET_INVENTORY then
        response = {
            success = true,
            data = storage.inventory
        }
        
    elseif request.type == network.REQUEST.GET_BY_CATEGORY then
        response = {
            success = true,
            data = storage.getByCategory()
        }
        
    elseif request.type == network.REQUEST.GET_FAVORITES then
        response = {
            success = true,
            data = storage.getFavorites()
        }
        
    elseif request.type == network.REQUEST.SEARCH then
        response = {
            success = true,
            data = storage.search(request.query or "")
        }
        
    elseif request.type == network.REQUEST.GET_STATS then
        local stats = storage.getStats()
        stats.uniqueItems = storage.countUniqueItems()
        response = {
            success = true,
            data = stats
        }
        
    elseif request.type == network.REQUEST.RETRIEVE_ITEM then
        local count, err = storage.retrieveItem(request.itemName, request.count or 1)
        response = {
            success = err == nil,
            data = count,
            error = err
        }
        
    elseif request.type == network.REQUEST.SORT_INPUT then
        local count, err = storage.sortInputChest()
        response = {
            success = err == nil,
            data = count,
            error = err
        }
        
    elseif request.type == network.REQUEST.EMPTY_INPUT then
        local count, err = storage.emptyInputChest()
        response = {
            success = true,
            data = count,
            error = err
        }
        
    elseif request.type == network.REQUEST.ADD_FAVORITE then
        local ok = config.addFavorite(request.itemName)
        response = {
            success = ok,
            error = ok and nil or "Déjà en favoris"
        }
        
    elseif request.type == network.REQUEST.REMOVE_FAVORITE then
        local ok = config.removeFavorite(request.itemName)
        response = {
            success = ok,
            error = ok and nil or "Non trouvé"
        }
        
    elseif request.type == network.REQUEST.ADD_CHEST then
        config.addChest(request.chestName, request.category, request.itemLock)
        storage.scanAll()
        response = {success = true}
        
    elseif request.type == network.REQUEST.REMOVE_CHEST then
        local ok = config.removeChest(request.chestName)
        storage.scanAll()
        response = {
            success = ok,
            error = ok and nil or "Coffre non trouvé"
        }
    
    elseif request.type == network.REQUEST.UPDATE_CHEST then
        local ok = config.updateChestRestriction(request.chestName, request.category, request.itemLock)
        if ok then
            storage.scanAll()
        end
        response = {
            success = ok,
            error = ok and nil or "Coffre non trouvé"
        }
    
    elseif request.type == network.REQUEST.GET_CHEST_INFO then
        local info = config.getChestInfo(request.chestName)
        response = {
            success = info ~= nil,
            data = info,
            error = info and nil or "Coffre non trouvé"
        }
        
    elseif request.type == network.REQUEST.LIST_CHESTS then
        response = {
            success = true,
            data = storage.listConnectedChests()
        }
        
    elseif request.type == network.REQUEST.GET_CATEGORIES then
        response = {
            success = true,
            data = config.categories
        }
        
    elseif request.type == network.REQUEST.ADD_CATEGORY then
        config.addCategory(request.name, request.color, request.patterns)
        storage.scanAll()
        response = {success = true}
        
    elseif request.type == network.REQUEST.ADD_PATTERN then
        local ok = config.addPatternToCategory(request.categoryName, request.pattern)
        storage.scanAll()
        response = {
            success = ok,
            error = ok and nil or "Catégorie non trouvée"
        }
        
    elseif request.type == network.REQUEST.GET_ALERTS then
        response = {
            success = true,
            data = storage.checkAlerts()
        }
    end
    
    return response
end

return network
