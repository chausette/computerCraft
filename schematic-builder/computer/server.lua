-- ============================================
-- SERVER.lua - Programme principal serveur
-- Advanced Computer avec moniteur 3x2
-- ============================================

local ui = require("ui")

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
    slotMapping = {},
    
    schematicsFolder = "schematics"
}

-- ============================================
-- ETAT
-- ============================================

local state = {
    -- Turtle
    x = 0, y = 0, z = 0,
    facing = 0,
    fuel = 0,
    
    -- Construction
    schematic = nil,
    schematicName = nil,
    schematicWidth = 0,
    schematicHeight = 0,
    schematicLength = 0,
    materials = {},
    
    layer = 0,
    totalBlocks = 0,
    placedBlocks = 0,
    
    status = "deconnecte",
    paused = false,
    building = false,
    
    -- UI
    currentScreen = "main",
    selectedSchematic = nil
}

-- ============================================
-- COMMUNICATION
-- ============================================

local modem = nil

local function findModem()
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
            modem = peripheral.wrap(side)
            modem.open(config.serverChannel)
            return true
        end
    end
    return false
end

local function sendToTurtle(msgType, data)
    if modem then
        local message = {
            type = msgType,
            data = data
        }
        modem.transmit(config.turtleChannel, config.serverChannel, message)
    end
end

-- ============================================
-- GESTION DES FICHIERS
-- ============================================

local function loadConfig()
    if fs.exists("config.txt") then
        local file = fs.open("config.txt", "r")
        if file then
            local content = file.readAll()
            file.close()
            local loaded = textutils.unserialize(content)
            if loaded then
                for k, v in pairs(loaded) do
                    config[k] = v
                end
            end
        end
    end
end

local function saveConfig()
    local file = fs.open("config.txt", "w")
    if file then
        file.write(textutils.serialize(config))
        file.close()
    end
end

local function listSchematics()
    local files = {}
    
    if not fs.exists(config.schematicsFolder) then
        fs.makeDir(config.schematicsFolder)
    end
    
    local list = fs.list(config.schematicsFolder)
    for _, name in ipairs(list) do
        local path = config.schematicsFolder .. "/" .. name
        if not fs.isDir(path) then
            table.insert(files, name)
        end
    end
    
    table.sort(files)
    return files
end

-- ============================================
-- GESTION DES ECRANS
-- ============================================

local function refreshScreen()
    if state.currentScreen == "main" then
        ui.drawMainMenu(state)
    elseif state.currentScreen == "chests" then
        ui.drawChestConfig(config)
    elseif state.currentScreen == "position" then
        ui.drawPositionConfig(config)
    elseif state.currentScreen == "schematics" then
        local files = listSchematics()
        ui.drawSchematicList(files, state.selectedSchematic)
    elseif state.currentScreen == "materials" then
        ui.drawMaterialConfig(state.materials, config.slotMapping)
    end
end

local function handleMainScreen(clicked)
    if clicked == "load" then
        state.currentScreen = "schematics"
        state.selectedSchematic = nil
        refreshScreen()
        
    elseif clicked == "chests" then
        state.currentScreen = "chests"
        refreshScreen()
        
    elseif clicked == "position" then
        state.currentScreen = "position"
        refreshScreen()
        
    elseif clicked == "materials" then
        state.currentScreen = "materials"
        refreshScreen()
        
    elseif clicked == "build" then
        if state.building then
            sendToTurtle("stop", {})
            state.building = false
        else
            if state.schematic then
                sendToTurtle("set_config", {
                    fuelChest = config.fuelChest,
                    materialChest = config.materialChest,
                    buildStart = config.buildStart,
                    buildDirection = config.buildDirection,
                    slotMapping = config.slotMapping
                })
                sleep(0.2)
                sendToTurtle("start_build", {})
                state.building = true
            end
        end
        refreshScreen()
        
    elseif clicked == "pause" then
        if state.building then
            if state.paused then
                sendToTurtle("resume", {})
                state.paused = false
            else
                sendToTurtle("pause", {})
                state.paused = true
            end
        end
        refreshScreen()
    end
end

local function handleChestScreen(clicked, x, y)
    if clicked == "back" then
        state.currentScreen = "main"
        refreshScreen()
        
    elseif clicked == "save" then
        saveConfig()
        state.currentScreen = "main"
        refreshScreen()
        
    elseif clicked == "fuel_x" then
        local val = ui.showNumberInput("Coffre Fuel - X", 
            config.fuelChest and config.fuelChest.x or 0)
        if val then
            config.fuelChest = config.fuelChest or {}
            config.fuelChest.x = val
        end
        refreshScreen()
        
    elseif clicked == "fuel_y" then
        local val = ui.showNumberInput("Coffre Fuel - Y",
            config.fuelChest and config.fuelChest.y or 0)
        if val then
            config.fuelChest = config.fuelChest or {}
            config.fuelChest.y = val
        end
        refreshScreen()
        
    elseif clicked == "fuel_z" then
        local val = ui.showNumberInput("Coffre Fuel - Z",
            config.fuelChest and config.fuelChest.z or 0)
        if val then
            config.fuelChest = config.fuelChest or {}
            config.fuelChest.z = val
        end
        refreshScreen()
        
    elseif clicked == "mat_x" then
        local val = ui.showNumberInput("Coffre Materiaux - X",
            config.materialChest and config.materialChest.x or 0)
        if val then
            config.materialChest = config.materialChest or {}
            config.materialChest.x = val
        end
        refreshScreen()
        
    elseif clicked == "mat_y" then
        local val = ui.showNumberInput("Coffre Materiaux - Y",
            config.materialChest and config.materialChest.y or 0)
        if val then
            config.materialChest = config.materialChest or {}
            config.materialChest.y = val
        end
        refreshScreen()
        
    elseif clicked == "mat_z" then
        local val = ui.showNumberInput("Coffre Materiaux - Z",
            config.materialChest and config.materialChest.z or 0)
        if val then
            config.materialChest = config.materialChest or {}
            config.materialChest.z = val
        end
        refreshScreen()
    end
end

local function handlePositionScreen(clicked, x, y)
    if clicked == "back" then
        state.currentScreen = "main"
        refreshScreen()
        
    elseif clicked == "save" then
        saveConfig()
        state.currentScreen = "main"
        refreshScreen()
        
    elseif clicked == "start_x" then
        local val = ui.showNumberInput("Position depart - X",
            config.buildStart and config.buildStart.x or 0)
        if val then
            config.buildStart = config.buildStart or {}
            config.buildStart.x = val
        end
        refreshScreen()
        
    elseif clicked == "start_y" then
        local val = ui.showNumberInput("Position depart - Y",
            config.buildStart and config.buildStart.y or 0)
        if val then
            config.buildStart = config.buildStart or {}
            config.buildStart.y = val
        end
        refreshScreen()
        
    elseif clicked == "start_z" then
        local val = ui.showNumberInput("Position depart - Z",
            config.buildStart and config.buildStart.z or 0)
        if val then
            config.buildStart = config.buildStart or {}
            config.buildStart.z = val
        end
        refreshScreen()
        
    elseif clicked and clicked:match("^dir_") then
        config.buildDirection = tonumber(clicked:sub(5))
        refreshScreen()
    end
end

local function handleSchematicScreen(clicked, x, y)
    if clicked == "back" then
        state.currentScreen = "main"
        refreshScreen()
        
    elseif clicked == "load" then
        if state.selectedSchematic then
            local files = listSchematics()
            local filename = files[state.selectedSchematic]
            if filename then
                local path = config.schematicsFolder .. "/" .. filename
                sendToTurtle("load_schematic", {path = path})
                state.schematicName = filename
            end
        end
        state.currentScreen = "main"
        refreshScreen()
        
    elseif clicked and clicked:match("^item_") then
        local index = tonumber(clicked:sub(6))
        state.selectedSchematic = index
        refreshScreen()
    end
end

local function handleMaterialScreen(clicked, x, y)
    if clicked == "back" then
        state.currentScreen = "main"
        refreshScreen()
        
    elseif clicked == "save" then
        saveConfig()
        state.currentScreen = "main"
        refreshScreen()
        
    elseif clicked and clicked:match("^slot_") then
        local blockId = tonumber(clicked:sub(6))
        local currentSlot = config.slotMapping[blockId] or 1
        local val = ui.showNumberInput("Slot pour bloc " .. blockId, currentSlot)
        if val and val >= 1 and val <= 16 then
            config.slotMapping[blockId] = val
        end
        refreshScreen()
    end
end

local function handleClick(x, y)
    local clicked = ui.checkClick(x, y)
    if not clicked then return end
    
    if state.currentScreen == "main" then
        handleMainScreen(clicked)
    elseif state.currentScreen == "chests" then
        handleChestScreen(clicked, x, y)
    elseif state.currentScreen == "position" then
        handlePositionScreen(clicked, x, y)
    elseif state.currentScreen == "schematics" then
        handleSchematicScreen(clicked, x, y)
    elseif state.currentScreen == "materials" then
        handleMaterialScreen(clicked, x, y)
    end
end

-- ============================================
-- GESTION DES MESSAGES TURTLE
-- ============================================

local function handleTurtleMessage(message)
    if type(message) ~= "table" then return end
    
    local msgType = message.type
    local data = message.data
    
    if msgType == "status" then
        state.x = data.x or state.x
        state.y = data.y or state.y
        state.z = data.z or state.z
        state.facing = data.facing or state.facing
        state.fuel = data.fuel or state.fuel
        state.layer = data.layer or state.layer
        state.totalBlocks = data.totalBlocks or state.totalBlocks
        state.placedBlocks = data.placedBlocks or state.placedBlocks
        state.status = data.status or state.status
        state.paused = data.paused or false
        state.building = data.building or false
        
        if state.currentScreen == "main" then
            refreshScreen()
        end
        
    elseif msgType == "schematic_loaded" then
        state.schematic = true
        state.schematicWidth = data.width
        state.schematicHeight = data.height
        state.schematicLength = data.length
        state.totalBlocks = data.totalBlocks
        state.materials = data.materials
        state.status = "pret"
        
        -- Auto-assigne les slots
        for i, mat in ipairs(state.materials) do
            if i <= 16 and not config.slotMapping[mat.id] then
                config.slotMapping[mat.id] = i
            end
        end
        
        if state.currentScreen == "main" then
            refreshScreen()
        end
        
    elseif msgType == "error" then
        state.status = "erreur: " .. (data.message or "inconnue")
        if state.currentScreen == "main" then
            refreshScreen()
        end
        
    elseif msgType == "calibrated" then
        state.x = data.x
        state.y = data.y
        state.z = data.z
        state.facing = data.facing
        state.status = "calibre"
        refreshScreen()
        
    elseif msgType == "config_updated" then
        state.status = "config OK"
        refreshScreen()
    end
end

-- ============================================
-- BOUCLE PRINCIPALE
-- ============================================

local function eventLoop()
    while true do
        local event, p1, p2, p3, p4, p5 = os.pullEvent()
        
        if event == "monitor_touch" then
            handleClick(p2, p3)
            
        elseif event == "modem_message" then
            local channel = p2
            local message = p4
            if channel == config.serverChannel then
                handleTurtleMessage(message)
            end
            
        elseif event == "key" then
            local key = p1
            if key == keys.q then
                return
            elseif key == keys.r then
                refreshScreen()
            elseif key == keys.p then
                sendToTurtle("ping", {})
            end
        end
    end
end

local function pingLoop()
    while true do
        sendToTurtle("ping", {})
        sleep(5)
    end
end

-- ============================================
-- DEMARRAGE
-- ============================================

local function main()
    term.clear()
    term.setCursorPos(1, 1)
    print("=================================")
    print("   SCHEMATIC BUILDER SERVER")
    print("=================================")
    print("")
    
    -- Charge la config
    loadConfig()
    print("Configuration chargee")
    
    -- Trouve le modem
    if not findModem() then
        print("ERREUR: Pas de modem trouve!")
        return
    end
    print("Modem trouve - Canal " .. config.serverChannel)
    
    -- Initialise l'interface
    local success, err = ui.init()
    if not success then
        print("ERREUR: " .. err)
        return
    end
    print("Moniteur initialise")
    
    -- Cree le dossier schematics
    if not fs.exists(config.schematicsFolder) then
        fs.makeDir(config.schematicsFolder)
    end
    print("Dossier schematics: " .. config.schematicsFolder)
    
    print("")
    print("Interface prete!")
    print("Touches: Q=Quitter, R=Rafraichir, P=Ping")
    print("")
    
    -- Affiche l'ecran principal
    state.currentScreen = "main"
    refreshScreen()
    
    -- Ping initial
    sendToTurtle("ping", {})
    
    -- Lance les boucles
    parallel.waitForAny(eventLoop, pingLoop)
    
    -- Nettoyage
    ui.clear()
    term.clear()
    print("Serveur arrete.")
end

main()
