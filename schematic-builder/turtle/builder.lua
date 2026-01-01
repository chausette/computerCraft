-- ============================================
-- BUILDER.lua - Programme principal Turtle
-- Construction de schematics avec GPS
-- ============================================

-- Charge les modules
local movement = require("movement")
local nbt = require("nbt")

-- ============================================
-- CONFIGURATION
-- ============================================

local config = {
    -- Communication
    serverChannel = 300,
    turtleChannel = 301,
    
    -- Coffres (configures via le serveur)
    fuelChest = nil,      -- {x, y, z}
    materialChest = nil,  -- {x, y, z}
    
    -- Construction
    buildStart = nil,     -- {x, y, z}
    buildDirection = 0,   -- 0=nord, 1=est, 2=sud, 3=ouest
    
    -- Seuils
    minFuel = 500,
    
    -- Mapping des slots
    slotMapping = {}      -- {blockId = slot}
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
    status = "idle"
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
        local message = {
            type = msgType,
            data = data,
            turtle = os.getComputerID()
        }
        modem.transmit(config.serverChannel, config.turtleChannel, message)
    end
end

local function sendStatus()
    sendToServer("status", {
        x = movement.x,
        y = movement.y,
        z = movement.z,
        facing = movement.facing,
        fuel = movement.getFuel(),
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
-- GESTION DES RESSOURCES
-- ============================================

-- Va au coffre de fuel et fait le plein
local function refuelFromChest()
    if not config.fuelChest then
        return false, "Coffre fuel non configure"
    end
    
    state.status = "refuel"
    sendStatus()
    
    -- Sauvegarde position actuelle
    local returnX, returnY, returnZ = movement.x, movement.y, movement.z
    local returnFacing = movement.facing
    
    -- Va au coffre
    local success, err = movement.goTo(
        config.fuelChest.x,
        config.fuelChest.y,
        config.fuelChest.z,
        true
    )
    
    if not success then
        return false, "Impossible d'atteindre le coffre fuel: " .. err
    end
    
    -- Prend du fuel
    turtle.select(16)  -- Utilise le slot 16 pour le fuel
    for _, side in ipairs({"front", "top", "bottom"}) do
        local suckFunc = side == "top" and turtle.suckUp or 
                        (side == "bottom" and turtle.suckDown or turtle.suck)
        
        -- Essaie de tourner vers le coffre
        for i = 1, 4 do
            if suckFunc(64) then
                movement.refuel()
                break
            end
            if side == "front" then
                movement.turnRight()
            end
        end
    end
    
    -- Refuel
    movement.refuel()
    turtle.select(1)
    
    -- Retourne a la position de construction
    movement.goTo(returnX, returnY, returnZ, true)
    movement.face(returnFacing)
    
    state.status = "building"
    return true
end

-- Compte les items d'un type dans l'inventaire
local function countItem(blockId)
    local slot = config.slotMapping[blockId]
    if not slot then return 0 end
    
    turtle.select(slot)
    return turtle.getItemCount()
end

-- Va chercher des materiaux
local function getMaterialsFromChest()
    if not config.materialChest then
        return false, "Coffre materiaux non configure"
    end
    
    state.status = "materiaux"
    sendStatus()
    
    -- Sauvegarde position
    local returnX, returnY, returnZ = movement.x, movement.y, movement.z
    local returnFacing = movement.facing
    
    -- Va au coffre
    local success, err = movement.goTo(
        config.materialChest.x,
        config.materialChest.y,
        config.materialChest.z,
        true
    )
    
    if not success then
        return false, "Impossible d'atteindre le coffre materiaux: " .. err
    end
    
    -- Pour chaque slot configure, prend des items
    for blockId, slot in pairs(config.slotMapping) do
        turtle.select(slot)
        local count = turtle.getItemCount()
        local needed = 64 - count
        
        if needed > 0 then
            -- Essaie de prendre des items
            for _, side in ipairs({"front", "top", "bottom"}) do
                local suckFunc = side == "top" and turtle.suckUp or 
                                (side == "bottom" and turtle.suckDown or turtle.suck)
                
                for i = 1, 4 do
                    if suckFunc(needed) then
                        break
                    end
                    if side == "front" then
                        movement.turnRight()
                    end
                end
            end
        end
    end
    
    turtle.select(1)
    
    -- Retourne
    movement.goTo(returnX, returnY, returnZ, true)
    movement.face(returnFacing)
    
    state.status = "building"
    return true
end

-- ============================================
-- CONSTRUCTION
-- ============================================

-- Transforme les coordonnees selon la direction de construction
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

-- Place un bloc a la position actuelle (en dessous de la turtle)
local function placeBlock(blockId)
    local slot = config.slotMapping[blockId]
    if not slot then
        return false, "Pas de slot pour le bloc " .. blockId
    end
    
    turtle.select(slot)
    
    if turtle.getItemCount() == 0 then
        -- Va chercher des materiaux
        getMaterialsFromChest()
        turtle.select(slot)
        
        if turtle.getItemCount() == 0 then
            return false, "Plus de materiaux pour le bloc " .. blockId
        end
    end
    
    -- Place en dessous
    return turtle.placeDown()
end

-- Construit une couche
local function buildLayer(layerY)
    local sch = state.schematic
    state.currentLayer = layerY
    
    -- Parcourt la couche en serpentin pour optimiser les deplacements
    local reverse = false
    
    for z = 0, sch.length - 1 do
        local startX = reverse and (sch.width - 1) or 0
        local endX = reverse and -1 or sch.width
        local stepX = reverse and -1 or 1
        
        for x = startX, endX - stepX, stepX do
            -- Verifie pause
            if state.paused then
                state.status = "pause"
                sendStatus()
                while state.paused do
                    os.pullEvent("rednet_message")
                end
                state.status = "building"
            end
            
            -- Verifie fuel
            if movement.getFuel() < config.minFuel then
                refuelFromChest()
            end
            
            -- Obtient le bloc a placer
            local blockId = nbt.getBlock(sch, x, layerY, z)
            state.currentBlock = state.currentBlock + 1
            
            if blockId ~= 0 then
                -- Calcule la position monde
                local worldX, worldY, worldZ = transformCoords(x, layerY, z)
                
                -- La turtle doit etre AU-DESSUS du bloc a placer
                local success, err = movement.goTo(worldX, worldY + 1, worldZ, true)
                
                if success then
                    if placeBlock(blockId) then
                        state.placedBlocks = state.placedBlocks + 1
                    end
                end
            end
            
            -- Envoie le status regulierement
            if state.currentBlock % 10 == 0 then
                sendStatus()
            end
        end
        
        reverse = not reverse
    end
end

-- Lance la construction complete
local function buildSchematic()
    if not state.schematic then
        return false, "Pas de schematic charge"
    end
    
    if not config.buildStart then
        return false, "Position de depart non configuree"
    end
    
    state.building = true
    state.paused = false
    state.currentLayer = 0
    state.currentBlock = 0
    state.placedBlocks = 0
    state.totalBlocks = state.schematic.width * state.schematic.height * state.schematic.length
    state.status = "building"
    
    sendStatus()
    
    -- Construit couche par couche
    for y = 0, state.schematic.height - 1 do
        buildLayer(y)
    end
    
    state.building = false
    state.status = "termine"
    sendStatus()
    
    return true
end

-- ============================================
-- GESTION DES MESSAGES
-- ============================================

local function handleMessage(message)
    if type(message) ~= "table" then return end
    
    local msgType = message.type
    local data = message.data
    
    if msgType == "ping" then
        sendStatus()
        
    elseif msgType == "load_schematic" then
        local sch, err = nbt.loadSchematic(data.path)
        if sch then
            state.schematic = sch
            state.totalBlocks = sch.width * sch.height * sch.length
            local materials = nbt.getMaterialList(sch)
            sendToServer("schematic_loaded", {
                width = sch.width,
                height = sch.height,
                length = sch.length,
                totalBlocks = state.totalBlocks,
                materials = materials
            })
        else
            sendToServer("error", {message = err})
        end
        
    elseif msgType == "set_config" then
        if data.fuelChest then config.fuelChest = data.fuelChest end
        if data.materialChest then config.materialChest = data.materialChest end
        if data.buildStart then config.buildStart = data.buildStart end
        if data.buildDirection then config.buildDirection = data.buildDirection end
        if data.slotMapping then config.slotMapping = data.slotMapping end
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
        state.building = false
        state.paused = false
        state.status = "arrete"
        sendStatus()
        
    elseif msgType == "go_to" then
        movement.goTo(data.x, data.y, data.z, true)
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
                sendToServer("error", {message = "Echec calibration direction"})
            end
        else
            sendToServer("error", {message = "GPS non disponible"})
        end
    end
end

-- ============================================
-- BOUCLE PRINCIPALE
-- ============================================

local function main()
    print("=================================")
    print("   TURTLE BUILDER v1.0")
    print("=================================")
    print("")
    
    -- Trouve le modem
    if not findModem() then
        print("ERREUR: Pas de modem trouve!")
        return
    end
    print("Modem trouve")
    
    -- Localisation GPS
    print("Localisation GPS...")
    if movement.locate() then
        print("Position: " .. movement.x .. ", " .. movement.y .. ", " .. movement.z)
        
        print("Calibration direction...")
        if movement.calibrate() then
            print("Direction: " .. movement.getFacingName())
        else
            print("ATTENTION: Calibration echouee")
        end
    else
        print("ATTENTION: GPS non disponible")
        print("Utilisation position relative")
    end
    
    print("")
    print("En attente du serveur...")
    print("Canal: " .. config.turtleChannel)
    
    -- Envoie un status initial
    sendStatus()
    
    -- Boucle principale
    while true do
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        if channel == config.turtleChannel then
            handleMessage(message)
        end
    end
end

-- Lance le programme
main()
