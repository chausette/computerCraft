-- ============================================
-- BUILDER.lua - Programme principal Turtle
-- Version 2.0 - Gestion materiaux amelioree
-- ============================================

local movement = require("movement")
local nbt = require("nbt")

-- ============================================
-- CONFIGURATION
-- ============================================

local config = {
    serverChannel = 300,
    turtleChannel = 301,
    fuelChest = nil,
    materialChest = nil,
    buildStart = nil,
    buildDirection = 0,
    minFuel = 500,
    slotMapping = {}
}

-- ============================================
-- ETAT
-- ============================================

local state = {
    schematic = nil,
    currentLayer = 0,
    currentBlock = 0,
    totalBlocks = 0,
    placedBlocks = 0,
    paused = false,
    building = false,
    stopping = false,
    status = "idle",
    fuelEstimate = 0,
    missingMaterials = {}
}

-- ============================================
-- COMMUNICATION
-- ============================================

local modem = nil

local function findModem()
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
            modem = peripheral.wrap(side)
            modem.open(config.turtleChannel)
            return true
        end
    end
    return false
end

local function sendToServer(msgType, data)
    if modem then
        modem.transmit(config.serverChannel, config.turtleChannel, {
            type = msgType,
            data = data,
            turtle = os.getComputerID()
        })
    end
end

local function sendStatus()
    sendToServer("status", {
        x = movement.x,
        y = movement.y,
        z = movement.z,
        facing = movement.facing,
        fuel = movement.getFuel(),
        fuelEstimate = state.fuelEstimate,
        layer = state.currentLayer,
        block = state.currentBlock,
        totalBlocks = state.totalBlocks,
        placedBlocks = state.placedBlocks,
        status = state.status,
        paused = state.paused,
        building = state.building
    })
end

-- ============================================
-- CALCULS
-- ============================================

-- Estime le fuel necessaire pour construire
local function estimateFuel()
    if not state.schematic or not config.buildStart then
        return 0
    end
    
    local sch = state.schematic
    local fuel = 0
    
    -- Distance turtle -> depart
    fuel = fuel + math.abs(movement.x - config.buildStart.x)
    fuel = fuel + math.abs(movement.y - config.buildStart.y)
    fuel = fuel + math.abs(movement.z - config.buildStart.z)
    
    -- Parcours serpentin pour chaque couche
    for y = 0, sch.height - 1 do
        -- Deplacement horizontal par couche (serpentin)
        fuel = fuel + sch.width * sch.length
        -- Deplacement vertical entre couches
        fuel = fuel + 1
    end
    
    -- Retours potentiels aux coffres (estimation)
    local trips = math.ceil(state.totalBlocks / 64) * 2
    if config.fuelChest then
        local fuelDist = math.abs(config.buildStart.x - config.fuelChest.x)
                       + math.abs(config.buildStart.y - config.fuelChest.y)
                       + math.abs(config.buildStart.z - config.fuelChest.z)
        fuel = fuel + (fuelDist * 2 * math.ceil(fuel / 5000))
    end
    
    if config.materialChest then
        local matDist = math.abs(config.buildStart.x - config.materialChest.x)
                      + math.abs(config.buildStart.y - config.materialChest.y)
                      + math.abs(config.buildStart.z - config.materialChest.z)
        fuel = fuel + (matDist * 2 * trips)
    end
    
    -- Marge de securite 20%
    return math.ceil(fuel * 1.2)
end

-- Compte les materiaux necessaires pour une couche
local function countLayerMaterials(layerY)
    local sch = state.schematic
    local counts = {}
    
    for z = 0, sch.length - 1 do
        for x = 0, sch.width - 1 do
            local blockId = nbt.getBlock(sch, x, layerY, z)
            if blockId ~= 0 then
                counts[blockId] = (counts[blockId] or 0) + 1
            end
        end
    end
    
    return counts
end

-- Compte les items dans l'inventaire par slot
local function getInventory()
    local inv = {}
    for slot = 1, 16 do
        local count = turtle.getItemCount(slot)
        if count > 0 then
            inv[slot] = count
        end
    end
    return inv
end

-- Verifie si on a assez de materiaux pour une couche
local function checkLayerMaterials(layerY)
    local needed = countLayerMaterials(layerY)
    local missing = {}
    local hasMissing = false
    
    for blockId, count in pairs(needed) do
        local slot = config.slotMapping[blockId]
        if slot then
            turtle.select(slot)
            local have = turtle.getItemCount()
            if have < count then
                missing[blockId] = count - have
                hasMissing = true
            end
        else
            missing[blockId] = count
            hasMissing = true
        end
    end
    
    return not hasMissing, missing, needed
end

-- ============================================
-- GESTION DES RESSOURCES
-- ============================================

local function refuelFromChest()
    if not config.fuelChest then
        return false, "Coffre fuel non configure"
    end
    
    state.status = "refuel"
    sendStatus()
    
    local returnX, returnY, returnZ = movement.x, movement.y, movement.z
    local returnFacing = movement.facing
    
    local success, err = movement.goTo(
        config.fuelChest.x,
        config.fuelChest.y,
        config.fuelChest.z,
        true
    )
    
    if not success then
        return false, "Impossible d'atteindre le coffre fuel"
    end
    
    -- Prend du fuel (slot 16)
    turtle.select(16)
    for i = 1, 4 do
        if turtle.suck(64) then break end
        turtle.turnRight()
    end
    turtle.suckUp(64)
    turtle.suckDown(64)
    
    movement.refuel()
    turtle.select(1)
    
    movement.goTo(returnX, returnY, returnZ, true)
    movement.face(returnFacing)
    
    state.status = "building"
    return true
end

local function getMaterialsFromChest()
    if not config.materialChest then
        return false, "Coffre materiaux non configure"
    end
    
    state.status = "materiaux"
    sendStatus()
    
    local returnX, returnY, returnZ = movement.x, movement.y, movement.z
    local returnFacing = movement.facing
    
    local success, err = movement.goTo(
        config.materialChest.x,
        config.materialChest.y,
        config.materialChest.z,
        true
    )
    
    if not success then
        return false, "Impossible d'atteindre le coffre materiaux"
    end
    
    -- Pour chaque slot, remplir
    for blockId, slot in pairs(config.slotMapping) do
        turtle.select(slot)
        local count = turtle.getItemCount()
        local needed = 64 - count
        
        if needed > 0 then
            for i = 1, 4 do
                local taken = turtle.suck(needed)
                if taken then break end
                turtle.turnRight()
            end
            turtle.suckUp(needed)
            turtle.suckDown(needed)
        end
    end
    
    turtle.select(1)
    movement.goTo(returnX, returnY, returnZ, true)
    movement.face(returnFacing)
    
    state.status = "building"
    return true
end

-- ============================================
-- CONSTRUCTION
-- ============================================

local function transformCoords(localX, localY, localZ)
    local worldX, worldY, worldZ
    
    worldY = config.buildStart.y + localY
    
    if config.buildDirection == 0 then -- Nord
        worldX = config.buildStart.x + localX
        worldZ = config.buildStart.z - localZ
    elseif config.buildDirection == 1 then -- Est
        worldX = config.buildStart.x + localZ
        worldZ = config.buildStart.z + localX
    elseif config.buildDirection == 2 then -- Sud
        worldX = config.buildStart.x - localX
        worldZ = config.buildStart.z + localZ
    else -- Ouest
        worldX = config.buildStart.x - localZ
        worldZ = config.buildStart.z - localX
    end
    
    return worldX, worldY, worldZ
end

local function placeBlock(blockId)
    local slot = config.slotMapping[blockId]
    if not slot then
        return false, "Pas de slot"
    end
    
    turtle.select(slot)
    
    if turtle.getItemCount() == 0 then
        return false, "Slot vide"
    end
    
    return turtle.placeDown()
end

-- Verifie les evenements pendant la construction
local function checkEvents()
    while true do
        local event, p1, p2, p3, msg = os.pullEvent()
        
        if event == "modem_message" and p2 == config.turtleChannel then
            if type(msg) == "table" then
                if msg.type == "pause" then
                    state.paused = true
                    state.status = "pause"
                    sendStatus()
                elseif msg.type == "resume" then
                    state.paused = false
                    state.status = "building"
                    sendStatus()
                    return
                elseif msg.type == "stop" then
                    state.stopping = true
                    state.paused = false
                    return
                elseif msg.type == "ping" then
                    sendStatus()
                elseif msg.type == "continue_build" then
                    -- Le serveur dit de continuer apres avoir rempli les materiaux
                    return
                end
            end
        end
        
        -- Si pas en pause, sort de la boucle
        if not state.paused then
            return
        end
    end
end

-- Attend que l'utilisateur fournisse les materiaux manquants
local function waitForMaterials(missing, layerY)
    state.status = "attente_mat"
    state.missingMaterials = missing
    
    -- Envoie la liste des materiaux manquants au serveur
    local missingList = {}
    for blockId, count in pairs(missing) do
        local blockName = "?"
        if state.schematic and state.schematic.palette then
            blockName = state.schematic.palette[blockId] or ("bloc_" .. blockId)
        end
        table.insert(missingList, {
            id = blockId,
            name = blockName,
            count = count,
            slot = config.slotMapping[blockId]
        })
    end
    
    sendToServer("missing_materials", {
        layer = layerY,
        materials = missingList
    })
    
    -- Attend une reponse
    while true do
        local event, p1, p2, p3, msg = os.pullEvent("modem_message")
        
        if p2 == config.turtleChannel and type(msg) == "table" then
            if msg.type == "continue_build" then
                state.status = "building"
                state.missingMaterials = {}
                return true
            elseif msg.type == "stop" then
                state.stopping = true
                return false
            elseif msg.type == "ping" then
                sendStatus()
            end
        end
    end
end

local function buildLayer(layerY)
    local sch = state.schematic
    state.currentLayer = layerY
    
    -- Verifie les materiaux pour cette couche
    local hasAll, missing, needed = checkLayerMaterials(layerY)
    
    if not hasAll then
        -- Essaie d'abord le coffre
        if config.materialChest then
            getMaterialsFromChest()
            hasAll, missing, needed = checkLayerMaterials(layerY)
        end
        
        -- Si toujours manquant, attend l'utilisateur
        if not hasAll then
            if not waitForMaterials(missing, layerY) then
                return false -- Stop demande
            end
        end
    end
    
    -- Construction en serpentin
    local reverse = false
    
    for z = 0, sch.length - 1 do
        -- Verifie stop
        if state.stopping then
            return false
        end
        
        local startX = reverse and (sch.width - 1) or 0
        local endX = reverse and -1 or sch.width
        local stepX = reverse and -1 or 1
        
        for x = startX, endX - stepX, stepX do
            -- Verifie stop
            if state.stopping then
                return false
            end
            
            -- Verifie pause (non bloquant)
            if state.paused then
                checkEvents()
                if state.stopping then
                    return false
                end
            end
            
            -- Verifie fuel
            if movement.getFuel() < config.minFuel then
                refuelFromChest()
            end
            
            local blockId = nbt.getBlock(sch, x, layerY, z)
            state.currentBlock = state.currentBlock + 1
            
            if blockId ~= 0 then
                local worldX, worldY, worldZ = transformCoords(x, layerY, z)
                
                -- Turtle AU-DESSUS du bloc
                local success = movement.goTo(worldX, worldY + 1, worldZ, true)
                
                if success then
                    local placed, err = placeBlock(blockId)
                    if placed then
                        state.placedBlocks = state.placedBlocks + 1
                    elseif err == "Slot vide" then
                        -- Plus de materiaux, va chercher
                        getMaterialsFromChest()
                        if placeBlock(blockId) then
                            state.placedBlocks = state.placedBlocks + 1
                        end
                    end
                end
            end
            
            if state.currentBlock % 10 == 0 then
                sendStatus()
            end
        end
        
        reverse = not reverse
    end
    
    return true
end

local function buildSchematic()
    if not state.schematic then
        return false, "Pas de schematic"
    end
    
    if not config.buildStart then
        return false, "Position non configuree"
    end
    
    state.building = true
    state.paused = false
    state.stopping = false
    state.currentLayer = 0
    state.currentBlock = 0
    state.placedBlocks = 0
    state.totalBlocks = state.schematic.width * state.schematic.height * state.schematic.length
    state.fuelEstimate = estimateFuel()
    state.status = "building"
    
    sendStatus()
    
    for y = 0, state.schematic.height - 1 do
        if not buildLayer(y) then
            break -- Stop ou erreur
        end
    end
    
    state.building = false
    state.stopping = false
    
    if state.placedBlocks >= state.totalBlocks then
        state.status = "termine"
    else
        state.status = "arrete"
    end
    
    sendStatus()
    return true
end

-- ============================================
-- GESTION DES MESSAGES
-- ============================================

local function handleMessage(message)
    if type(message) ~= "table" then return end
    
    local msgType = message.type
    local data = message.data or {}
    
    if msgType == "ping" then
        sendStatus()
        
    elseif msgType == "load_schematic_data" then
        local content = data.content
        
        if not content then
            sendToServer("error", {message = "Pas de contenu"})
            return
        end
        
        local tempPath = "temp_schematic.json"
        local file = fs.open(tempPath, "w")
        if file then
            file.write(content)
            file.close()
            
            local sch, err = nbt.loadSchematic(tempPath)
            fs.delete(tempPath)
            
            if sch then
                state.schematic = sch
                state.totalBlocks = sch.width * sch.height * sch.length
                state.fuelEstimate = estimateFuel()
                
                -- Compte tous les materiaux avec quantites
                local materials = {}
                local counts = {}
                
                for y = 0, sch.height - 1 do
                    for z = 0, sch.length - 1 do
                        for x = 0, sch.width - 1 do
                            local blockId = nbt.getBlock(sch, x, y, z)
                            if blockId ~= 0 then
                                counts[blockId] = (counts[blockId] or 0) + 1
                            end
                        end
                    end
                end
                
                -- Convertit en liste triee
                for blockId, count in pairs(counts) do
                    local name = sch.palette[blockId] or ("bloc_" .. blockId)
                    table.insert(materials, {
                        id = blockId,
                        name = name,
                        count = count
                    })
                end
                
                -- Trie par quantite decroissante
                table.sort(materials, function(a, b) return a.count > b.count end)
                
                sendToServer("schematic_loaded", {
                    width = sch.width,
                    height = sch.height,
                    length = sch.length,
                    totalBlocks = state.totalBlocks,
                    fuelEstimate = state.fuelEstimate,
                    materials = materials
                })
            else
                sendToServer("error", {message = err or "Erreur parsing"})
            end
        else
            sendToServer("error", {message = "Erreur ecriture"})
        end
        
    elseif msgType == "set_config" then
        if data.fuelChest then config.fuelChest = data.fuelChest end
        if data.materialChest then config.materialChest = data.materialChest end
        if data.buildStart then config.buildStart = data.buildStart end
        if data.buildDirection then config.buildDirection = data.buildDirection end
        if data.slotMapping then config.slotMapping = data.slotMapping end
        state.fuelEstimate = estimateFuel()
        sendToServer("config_updated", config)
        
    elseif msgType == "start_build" then
        buildSchematic()
        
    elseif msgType == "pause" then
        state.paused = true
        state.status = "pause"
        sendStatus()
        
    elseif msgType == "resume" then
        state.paused = false
        state.status = "building"
        sendStatus()
        
    elseif msgType == "stop" then
        state.stopping = true
        state.paused = false
        state.building = false
        state.status = "arrete"
        sendStatus()
        
    elseif msgType == "calibrate" then
        if movement.locate() then
            if movement.calibrate() then
                sendToServer("calibrated", {
                    x = movement.x,
                    y = movement.y,
                    z = movement.z,
                    facing = movement.facing
                })
            else
                sendToServer("error", {message = "Echec calibration"})
            end
        else
            sendToServer("error", {message = "GPS non disponible"})
        end
        
    elseif msgType == "set_position" then
        movement.setPos(data.x or 0, data.y or 0, data.z or 0)
        if data.facing then
            movement.setFacing(data.facing)
        end
        sendToServer("position_set", {
            x = movement.x,
            y = movement.y,
            z = movement.z,
            facing = movement.facing
        })
        sendStatus()
    end
end

-- ============================================
-- MAIN
-- ============================================

local function main()
    print("=================================")
    print("   TURTLE BUILDER v2.0")
    print("=================================")
    print("")
    
    if not findModem() then
        print("ERREUR: Pas de modem!")
        return
    end
    print("Modem OK - Canal " .. config.turtleChannel)
    
    print("Localisation GPS...")
    if movement.locate() then
        print("Position: " .. movement.x .. "," .. movement.y .. "," .. movement.z)
        
        if movement.calibrate() then
            print("Direction: " .. movement.getFacingName())
        else
            print("Direction: Nord (defaut)")
        end
    else
        print("GPS non disponible")
        print("Config via serveur")
    end
    
    print("")
    print("En attente du serveur...")
    
    sendStatus()
    
    while true do
        local event, side, channel, reply, message = os.pullEvent("modem_message")
        
        if channel == config.turtleChannel then
            handleMessage(message)
        end
    end
end

main()
