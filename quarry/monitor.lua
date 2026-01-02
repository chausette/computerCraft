-- ============================================
-- MONITOR.lua - Surveillance Turtle sur Pocket
-- Affiche les infos de quarry/fill en temps reel
-- ============================================

local VERSION = "1.0"
local LISTEN_CHANNEL = 400

-- ============================================
-- VARIABLES
-- ============================================

local modem = nil
local lastData = nil
local lastUpdate = 0
local running = true

-- Turtles suivies (par ID)
local turtles = {}

-- Mode d'affichage
local displayMode = "single"  -- "single" ou "list"
local selectedTurtle = nil

-- ============================================
-- INITIALISATION
-- ============================================

local function findModem()
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back", "back"}) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
            modem = peripheral.wrap(side)
            modem.open(LISTEN_CHANNEL)
            return true
        end
    end
    return false
end

-- ============================================
-- AFFICHAGE
-- ============================================

local W, H = term.getSize()

local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

local function color(c)
    if term.isColor() then
        term.setTextColor(c)
    end
end

local function bg(c)
    if term.isColor() then
        term.setBackgroundColor(c)
    end
end

local function write(x, y, text)
    term.setCursorPos(x, y)
    term.write(text)
end

local function centerText(y, text)
    local x = math.floor((W - #text) / 2) + 1
    write(x, y, text)
end

local function progressBar(x, y, width, percent, fgColor, bgColor)
    local filled = math.floor(width * percent / 100)
    
    term.setCursorPos(x, y)
    bg(fgColor or colors.lime)
    term.write(string.rep(" ", filled))
    bg(bgColor or colors.gray)
    term.write(string.rep(" ", width - filled))
    bg(colors.black)
end

local function drawHeader()
    bg(colors.blue)
    color(colors.white)
    write(1, 1, string.rep(" ", W))
    centerText(1, "TURTLE MONITOR")
    bg(colors.black)
end

local function formatTime(seconds)
    if not seconds or seconds < 0 then
        return "--:--"
    end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

local function drawNoData()
    clear()
    drawHeader()
    
    color(colors.yellow)
    centerText(4, "En attente...")
    
    color(colors.lightGray)
    centerText(6, "Canal: " .. LISTEN_CHANNEL)
    centerText(8, "Aucune turtle")
    centerText(9, "detectee")
    
    color(colors.gray)
    centerText(H - 1, "Q = Quitter")
end

local function drawSingleTurtle(data)
    clear()
    drawHeader()
    
    local y = 3
    
    -- Nom et programme
    color(colors.yellow)
    local name = data.turtleName or ("ID:" .. (data.turtleId or "?"))
    if #name > W - 2 then
        name = name:sub(1, W - 4) .. ".."
    end
    write(1, y, name)
    
    color(colors.cyan)
    local prog = string.upper(data.program or "?")
    write(W - #prog, y, prog)
    y = y + 1
    
    -- Ligne separatrice
    color(colors.gray)
    write(1, y, string.rep("-", W))
    y = y + 1
    
    -- Status
    local status = data.status or "?"
    local statusColor = colors.white
    if status == "mining" or status == "filling" then
        statusColor = colors.lime
    elseif status == "idle" or status == "paused" then
        statusColor = colors.yellow
    elseif status == "refuel" or status == "materiaux" then
        statusColor = colors.orange
    elseif status == "done" then
        statusColor = colors.lime
    elseif status == "no_fuel" or status == "no_materials" then
        statusColor = colors.red
    end
    
    color(colors.lightGray)
    write(1, y, "Status:")
    color(statusColor)
    write(9, y, status)
    y = y + 1
    
    -- Progression
    local progress = data.progress or 0
    color(colors.lightGray)
    write(1, y, "Progres:")
    color(colors.white)
    write(10, y, string.format("%d%%", progress))
    y = y + 1
    
    -- Barre de progression
    progressBar(1, y, W, progress, colors.lime, colors.gray)
    y = y + 1
    
    -- Blocs
    color(colors.lightGray)
    write(1, y, "Blocs:")
    color(colors.white)
    local blocksLabel = data.program == "fill" and "places" or "mines"
    local blocksCount = data.program == "fill" and (data.blocksPlaced or 0) or (data.blocksMined or 0)
    write(8, y, string.format("%d/%d", blocksCount, data.totalBlocks or 0))
    y = y + 1
    
    -- Tranche
    color(colors.lightGray)
    write(1, y, "Tranche:")
    color(colors.white)
    write(10, y, string.format("Z=%d (%d/%d)", 
        data.currentSliceZ or 0,
        data.sliceCurrent or 0,
        data.sliceTotal or 0))
    y = y + 1
    
    -- Position
    color(colors.lightGray)
    write(1, y, "Pos:")
    color(colors.white)
    write(6, y, string.format("%d,%d,%d", data.x or 0, data.y or 0, data.z or 0))
    y = y + 1
    
    -- Direction
    color(colors.lightGray)
    write(1, y, "Dir:")
    color(colors.white)
    write(6, y, data.facingName or "?")
    y = y + 1
    
    -- Fuel
    color(colors.lightGray)
    write(1, y, "Fuel:")
    local fuelPercent = 0
    if data.fuelMax and data.fuelMax > 0 then
        fuelPercent = math.floor((data.fuel or 0) / data.fuelMax * 100)
    end
    local fuelColor = colors.lime
    if (data.fuel or 0) < 500 then
        fuelColor = colors.red
    elseif (data.fuel or 0) < 1000 then
        fuelColor = colors.orange
    end
    color(fuelColor)
    write(7, y, string.format("%d", data.fuel or 0))
    y = y + 1
    
    -- Materiau (pour fill)
    if data.program == "fill" then
        color(colors.lightGray)
        write(1, y, "Mat:")
        color(colors.white)
        local mat = (data.material or "?"):gsub("minecraft:", "")
        write(6, y, mat)
        color(colors.gray)
        write(W - 5, y, string.format("x%d", data.materialCount or 0))
        y = y + 1
    end
    
    -- Temps
    color(colors.lightGray)
    write(1, y, "Temps:")
    color(colors.white)
    write(8, y, data.elapsedFormatted or "--:--")
    y = y + 1
    
    -- ETA
    color(colors.lightGray)
    write(1, y, "ETA:")
    color(colors.cyan)
    write(6, y, data.etaFormatted or "--:--")
    y = y + 1
    
    -- Zone
    if data.zone then
        y = y + 1
        color(colors.gray)
        write(1, y, string.format("Zone: %dx%dx%d", 
            data.zone.width or 0, 
            data.zone.height or 0, 
            data.zone.length or 0))
    end
    
    -- Footer
    color(colors.gray)
    write(1, H, "Q=Quit")
    
    -- Derniere MAJ
    local age = os.clock() - lastUpdate
    if age > 10 then
        color(colors.red)
        write(W - 7, H, "OLD " .. math.floor(age) .. "s")
    else
        color(colors.green)
        write(W - 2, H, "OK")
    end
end

local function drawTurtleList()
    clear()
    drawHeader()
    
    local y = 3
    
    color(colors.yellow)
    write(1, y, "Turtles detectees:")
    y = y + 1
    
    color(colors.gray)
    write(1, y, string.rep("-", W))
    y = y + 1
    
    local count = 0
    for id, data in pairs(turtles) do
        count = count + 1
        if y < H - 1 then
            local age = os.clock() - (data.lastSeen or 0)
            
            -- Indicateur actif
            if age < 5 then
                color(colors.lime)
                write(1, y, "*")
            else
                color(colors.red)
                write(1, y, "!")
            end
            
            -- ID
            color(colors.white)
            write(3, y, tostring(id))
            
            -- Programme
            color(colors.cyan)
            local prog = (data.program or "?"):sub(1, 1):upper()
            write(8, y, prog)
            
            -- Progression
            color(colors.yellow)
            write(10, y, string.format("%3d%%", data.progress or 0))
            
            y = y + 1
        end
    end
    
    if count == 0 then
        color(colors.lightGray)
        centerText(y + 1, "Aucune turtle")
    end
    
    -- Footer
    color(colors.gray)
    write(1, H, "Q=Quit L=Liste S=Single")
end

local function draw()
    if not lastData then
        drawNoData()
    elseif displayMode == "list" then
        drawTurtleList()
    else
        drawSingleTurtle(lastData)
    end
end

-- ============================================
-- GESTION DES MESSAGES
-- ============================================

local function handleMessage(msg)
    if type(msg) ~= "table" then return end
    if msg.type ~= "status" then return end
    
    local id = msg.turtleId
    if not id then return end
    
    -- Met a jour la liste des turtles
    msg.lastSeen = os.clock()
    turtles[id] = msg
    
    -- Met a jour les donnees affichees
    if not selectedTurtle or selectedTurtle == id then
        lastData = msg
        lastUpdate = os.clock()
    end
    
    draw()
end

-- ============================================
-- BOUCLE PRINCIPALE
-- ============================================

local function listenLoop()
    while running do
        local event, side, channel, reply, msg = os.pullEvent()
        
        if event == "modem_message" and channel == LISTEN_CHANNEL then
            handleMessage(msg)
            
        elseif event == "key" then
            local key = side  -- Dans key event, le 2eme param est la touche
            
            if key == keys.q then
                running = false
                
            elseif key == keys.l then
                displayMode = "list"
                draw()
                
            elseif key == keys.s then
                displayMode = "single"
                draw()
                
            elseif key == keys.r then
                -- Rafraichir
                draw()
            end
            
        elseif event == "timer" then
            -- Rafraichit l'affichage periodiquement
            draw()
        end
    end
end

local function timerLoop()
    while running do
        os.startTimer(2)
        sleep(2)
        draw()
    end
end

-- ============================================
-- MAIN
-- ============================================

local function main()
    clear()
    
    color(colors.yellow)
    print("================================")
    print("   TURTLE MONITOR v" .. VERSION)
    print("================================")
    color(colors.white)
    print("")
    
    -- Cherche le modem
    if not findModem() then
        color(colors.red)
        print("ERREUR: Pas de modem!")
        print("")
        print("Ce programme necessite")
        print("un modem wireless.")
        color(colors.white)
        return
    end
    
    color(colors.lime)
    print("Modem trouve!")
    print("Canal: " .. LISTEN_CHANNEL)
    color(colors.white)
    print("")
    print("En attente de donnees...")
    print("")
    color(colors.lightGray)
    print("Commandes:")
    print("  Q = Quitter")
    print("  L = Liste turtles")
    print("  S = Vue single")
    print("  R = Rafraichir")
    
    sleep(2)
    
    -- Lance les boucles en parallele
    parallel.waitForAny(listenLoop, timerLoop)
    
    clear()
    print("Monitor arrete.")
end

main()
