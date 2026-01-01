-- ============================================
-- SERVER.lua - Serveur Schematic Builder
-- Version 1.1
-- ============================================

local ui = require("ui")

-- ============================================
-- CONFIG
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
-- STATE
-- ============================================

local state = {
    x = 0, y = 0, z = 0,
    facing = 0,
    fuel = 0,
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
    screen = "main",
    selectedFile = nil,
    materialPage = 1
}

-- ============================================
-- MODEM
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

local function send(msgType, data)
    if modem then
        modem.transmit(config.turtleChannel, config.serverChannel, {
            type = msgType,
            data = data
        })
    end
end

-- ============================================
-- FICHIERS
-- ============================================

local function loadConfig()
    if fs.exists("config.txt") then
        local f = fs.open("config.txt", "r")
        if f then
            local data = textutils.unserialize(f.readAll())
            f.close()
            if data then
                for k, v in pairs(data) do
                    config[k] = v
                end
            end
        end
    end
end

local function saveConfig()
    local f = fs.open("config.txt", "w")
    if f then
        f.write(textutils.serialize(config))
        f.close()
    end
end

local function listSchematics()
    local files = {}
    if not fs.exists(config.schematicsFolder) then
        fs.makeDir(config.schematicsFolder)
    end
    for _, name in ipairs(fs.list(config.schematicsFolder)) do
        if not fs.isDir(config.schematicsFolder .. "/" .. name) then
            table.insert(files, name)
        end
    end
    table.sort(files)
    return files
end

-- ============================================
-- REFRESH SCREEN
-- ============================================

local function refresh()
    if state.screen == "main" then
        ui.drawMain(state)
    elseif state.screen == "chests" then
        ui.drawChests(config)
    elseif state.screen == "position" then
        ui.drawPosition(config)
    elseif state.screen == "schematics" then
        ui.drawSchematics(listSchematics(), state.selectedFile)
    elseif state.screen == "materials" then
        ui.drawMaterials(state.materials, config.slotMapping, state.materialPage)
    end
end

-- ============================================
-- HANDLERS
-- ============================================

local function handleMain(clicked)
    if clicked == "load" then
        state.screen = "schematics"
        state.selectedFile = nil
        
    elseif clicked == "chests" then
        state.screen = "chests"
        
    elseif clicked == "position" then
        state.screen = "position"
        
    elseif clicked == "materials" then
        state.screen = "materials"
        state.materialPage = 1
        
    elseif clicked == "build" then
        if state.building then
            send("stop", {})
            state.building = false
        elseif state.schematic then
            send("set_config", {
                fuelChest = config.fuelChest,
                materialChest = config.materialChest,
                buildStart = config.buildStart,
                buildDirection = config.buildDirection,
                slotMapping = config.slotMapping
            })
            sleep(0.1)
            send("start_build", {})
            state.building = true
        end
        
    elseif clicked == "pause" then
        if state.building then
            state.paused = not state.paused
            send(state.paused and "pause" or "resume", {})
        end
    end
    refresh()
end

local function handleChests(clicked)
    if clicked == "back" then
        state.screen = "main"
        
    elseif clicked == "save" then
        saveConfig()
        state.screen = "main"
        
    elseif clicked == "fx" then
        local v = ui.numberInput("Fuel X", config.fuelChest and config.fuelChest.x or 0)
        if v then config.fuelChest = config.fuelChest or {}; config.fuelChest.x = v end
        
    elseif clicked == "fy" then
        local v = ui.numberInput("Fuel Y", config.fuelChest and config.fuelChest.y or 0)
        if v then config.fuelChest = config.fuelChest or {}; config.fuelChest.y = v end
        
    elseif clicked == "fz" then
        local v = ui.numberInput("Fuel Z", config.fuelChest and config.fuelChest.z or 0)
        if v then config.fuelChest = config.fuelChest or {}; config.fuelChest.z = v end
        
    elseif clicked == "mx" then
        local v = ui.numberInput("Mat X", config.materialChest and config.materialChest.x or 0)
        if v then config.materialChest = config.materialChest or {}; config.materialChest.x = v end
        
    elseif clicked == "my" then
        local v = ui.numberInput("Mat Y", config.materialChest and config.materialChest.y or 0)
        if v then config.materialChest = config.materialChest or {}; config.materialChest.y = v end
        
    elseif clicked == "mz" then
        local v = ui.numberInput("Mat Z", config.materialChest and config.materialChest.z or 0)
        if v then config.materialChest = config.materialChest or {}; config.materialChest.z = v end
    end
    refresh()
end

local function handlePosition(clicked)
    if clicked == "back" then
        state.screen = "main"
        
    elseif clicked == "save" then
        saveConfig()
        state.screen = "main"
        
    elseif clicked == "sx" then
        local v = ui.numberInput("Start X", config.buildStart and config.buildStart.x or 0)
        if v then config.buildStart = config.buildStart or {}; config.buildStart.x = v end
        
    elseif clicked == "sy" then
        local v = ui.numberInput("Start Y", config.buildStart and config.buildStart.y or 0)
        if v then config.buildStart = config.buildStart or {}; config.buildStart.y = v end
        
    elseif clicked == "sz" then
        local v = ui.numberInput("Start Z", config.buildStart and config.buildStart.z or 0)
        if v then config.buildStart = config.buildStart or {}; config.buildStart.z = v end
        
    elseif clicked and clicked:match("^dir%d$") then
        config.buildDirection = tonumber(clicked:sub(4)) or 0
    end
    refresh()
end

local function handleSchematics(clicked)
    if clicked == "back" then
        state.screen = "main"
        
    elseif clicked == "loadfile" then
        if state.selectedFile then
            local files = listSchematics()
            local name = files[state.selectedFile]
            if name then
                send("load_schematic", {path = config.schematicsFolder .. "/" .. name})
                state.schematicName = name
            end
        end
        state.screen = "main"
        
    elseif clicked and clicked:match("^item%d+$") then
        state.selectedFile = tonumber(clicked:sub(5))
    end
    refresh()
end

local function handleMaterials(clicked)
    if clicked == "back" then
        state.screen = "main"
        
    elseif clicked == "save" then
        saveConfig()
        state.screen = "main"
        
    elseif clicked == "nextpage" then
        local W, H = ui.getSize()
        local perPage = H - 4
        local totalPages = math.ceil(#state.materials / perPage)
        state.materialPage = (state.materialPage % totalPages) + 1
        
    elseif clicked and clicked:match("^slot%d+$") then
        local id = tonumber(clicked:sub(5))
        local v = ui.numberInput("Slot 1-16", config.slotMapping[id] or 1)
        if v and v >= 1 and v <= 16 then
            config.slotMapping[id] = v
        end
    end
    refresh()
end

local function handleClick(x, y)
    local clicked = ui.checkClick(x, y)
    if not clicked then return end
    
    if state.screen == "main" then handleMain(clicked)
    elseif state.screen == "chests" then handleChests(clicked)
    elseif state.screen == "position" then handlePosition(clicked)
    elseif state.screen == "schematics" then handleSchematics(clicked)
    elseif state.screen == "materials" then handleMaterials(clicked)
    end
end

-- ============================================
-- MESSAGES TURTLE
-- ============================================

local function handleMessage(msg)
    if type(msg) ~= "table" then return end
    
    if msg.type == "status" then
        local d = msg.data
        state.x = d.x or state.x
        state.y = d.y or state.y
        state.z = d.z or state.z
        state.facing = d.facing or state.facing
        state.fuel = d.fuel or state.fuel
        state.layer = d.layer or state.layer
        state.totalBlocks = d.totalBlocks or state.totalBlocks
        state.placedBlocks = d.placedBlocks or state.placedBlocks
        state.status = d.status or state.status
        state.paused = d.paused or false
        state.building = d.building or false
        if state.screen == "main" then refresh() end
        
    elseif msg.type == "schematic_loaded" then
        local d = msg.data
        state.schematic = true
        state.schematicWidth = d.width
        state.schematicHeight = d.height
        state.schematicLength = d.length
        state.totalBlocks = d.totalBlocks
        state.materials = d.materials
        state.status = "pret"
        for i, mat in ipairs(state.materials) do
            if i <= 16 and not config.slotMapping[mat.id] then
                config.slotMapping[mat.id] = i
            end
        end
        if state.screen == "main" then refresh() end
        
    elseif msg.type == "error" then
        state.status = "err:" .. (msg.data.message or "?"):sub(1, 12)
        if state.screen == "main" then refresh() end
        
    elseif msg.type == "calibrated" or msg.type == "position_set" then
        local d = msg.data
        state.x = d.x
        state.y = d.y
        state.z = d.z
        state.facing = d.facing
        state.status = "calibre"
        refresh()
    end
end

-- ============================================
-- BOUCLES
-- ============================================

local function eventLoop()
    while true do
        local event, p1, p2, p3, p4 = os.pullEvent()
        
        if event == "monitor_touch" then
            handleClick(p2, p3)
            
        elseif event == "modem_message" and p2 == config.serverChannel then
            handleMessage(p4)
            
        elseif event == "key" then
            if p1 == keys.q then return
            elseif p1 == keys.r then refresh()
            elseif p1 == keys.p then send("ping", {})
            elseif p1 == keys.c then send("calibrate", {})
            end
        end
    end
end

local function pingLoop()
    while true do
        send("ping", {})
        sleep(5)
    end
end

-- ============================================
-- MAIN
-- ============================================

local function main()
    term.clear()
    term.setCursorPos(1, 1)
    
    print("SCHEMATIC BUILDER SERVER v1.1")
    print(string.rep("-", 30))
    
    loadConfig()
    print("Config OK")
    
    if not findModem() then
        print("ERREUR: Modem non trouve!")
        return
    end
    print("Modem: " .. config.serverChannel .. "/" .. config.turtleChannel)
    
    local ok, err = ui.init()
    if not ok then
        print("ERREUR: " .. err)
        return
    end
    local W, H = ui.getSize()
    print("Moniteur: " .. W .. "x" .. H)
    
    if not fs.exists(config.schematicsFolder) then
        fs.makeDir(config.schematicsFolder)
    end
    
    print("")
    print("Q=Quit R=Refresh P=Ping C=Calib")
    print("")
    
    state.screen = "main"
    refresh()
    send("ping", {})
    
    parallel.waitForAny(eventLoop, pingLoop)
    
    ui.clear()
    term.clear()
end

main()
