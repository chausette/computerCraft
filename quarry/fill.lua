-- ============================================
-- FILL.lua - Programme de remplissage de zone
-- Version 2.0 - Avec reprise et monitoring
-- ============================================

local VERSION = "2.0"
local SAVE_FILE = "fill_save.txt"
local MONITOR_CHANNEL = 400

-- ============================================
-- CONFIGURATION
-- ============================================

local config = {
    pos1 = nil,
    pos2 = nil,
    chestPos = nil,
    fuelChestPos = nil,
    fuelSlot = 16,
    materialSlots = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15},
    material = "minecraft:dirt",  -- ou minecraft:cobblestone
    minFuel = 100,
}

-- ============================================
-- ETAT
-- ============================================

local state = {
    x = 0,
    y = 0,
    z = 0,
    facing = 0,
    
    hasGPS = false,
    running = false,
    
    currentSliceZ = nil,
    currentY = nil,
    currentX = nil,
    fillStarted = false,
    
    zone = nil,
    
    blocksPlaced = 0,
    totalBlocks = 0,
    startTime = 0,
    status = "idle",
}

-- ============================================
-- DIRECTIONS
-- ============================================

local NORTH, EAST, SOUTH, WEST = 0, 1, 2, 3
local dirNames = {"Nord (-Z)", "Est (+X)", "Sud (+Z)", "Ouest (-X)"}
local dirVectors = {
    [0] = {x = 0, z = -1},
    [1] = {x = 1, z = 0},
    [2] = {x = 0, z = 1},
    [3] = {x = -1, z = 0},
}

-- ============================================
-- COMMUNICATION WIRELESS
-- ============================================

local modem = nil

local function findModem()
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
            local m = peripheral.wrap(side)
            if m.isWireless and m.isWireless() then
                modem = m
                return true
            end
        end
    end
    return false
end

local function sendStatus()
    if not modem then return end
    
    local progress = 0
    if state.totalBlocks > 0 then
        progress = math.floor((state.blocksPlaced / state.totalBlocks) * 100)
    end
    
    local elapsed = os.clock() - state.startTime
    
    local data = {
        type = "status",
        program = "fill",
        version = VERSION,
        turtleId = os.getComputerID(),
        turtleName = os.getComputerLabel() or ("Turtle_" .. os.getComputerID()),
        
        -- Position
        x = state.x,
        y = state.y,
        z = state.z,
        facing = state.facing,
        facingName = dirNames[state.facing + 1],
        
        -- Progression
        status = state.status,
        blocksPlaced = state.blocksPlaced,
        totalBlocks = state.totalBlocks,
        progress = progress,
        
        -- Tranche
        currentSliceZ = state.currentSliceZ,
        currentY = state.currentY,
        sliceTotal = state.zone and (state.zone.maxZ - state.zone.minZ + 1) or 0,
        sliceCurrent = state.zone and state.currentSliceZ and 
                      (state.currentSliceZ - state.zone.minZ + 1) or 0,
        
        -- Zone
        zone = state.zone,
        
        -- Ressources
        fuel = turtle.getFuelLevel(),
        fuelMax = turtle.getFuelLimit(),
        material = config.material,
        materialCount = 0,  -- Mis à jour ci-dessous
        
        -- Temps
        elapsed = elapsed,
        elapsedFormatted = string.format("%d:%02d", math.floor(elapsed/60), math.floor(elapsed%60)),
        
        -- ETA
        eta = 0,
        etaFormatted = "--:--",
    }
    
    -- Compte les materiaux
    local matCount = 0
    for _, slot in ipairs(config.materialSlots) do
        matCount = matCount + turtle.getItemCount(slot)
    end
    data.materialCount = matCount
    
    -- Calcul ETA
    if state.blocksPlaced > 0 and elapsed > 0 then
        local blocksPerSec = state.blocksPlaced / elapsed
        local remaining = state.totalBlocks - state.blocksPlaced
        if blocksPerSec > 0 then
            data.eta = remaining / blocksPerSec
            data.etaFormatted = string.format("%d:%02d", 
                math.floor(data.eta/60), math.floor(data.eta%60))
        end
    end
    
    modem.transmit(MONITOR_CHANNEL, MONITOR_CHANNEL, data)
end

-- ============================================
-- SAUVEGARDE / CHARGEMENT
-- ============================================

local function saveState()
    local data = {
        version = VERSION,
        config = config,
        state = {
            x = state.x,
            y = state.y,
            z = state.z,
            facing = state.facing,
            currentSliceZ = state.currentSliceZ,
            currentY = state.currentY,
            currentX = state.currentX,
            fillStarted = state.fillStarted,
            blocksPlaced = state.blocksPlaced,
            totalBlocks = state.totalBlocks,
            startTime = state.startTime,
            zone = state.zone,
        }
    }
    
    local file = fs.open(SAVE_FILE, "w")
    if file then
        file.write(textutils.serialize(data))
        file.close()
        return true
    end
    return false
end

local function loadState()
    if not fs.exists(SAVE_FILE) then
        return false
    end
    
    local file = fs.open(SAVE_FILE, "r")
    if file then
        local content = file.readAll()
        file.close()
        
        local data = textutils.unserialize(content)
        if data then
            config = data.config or config
            
            if data.state then
                state.x = data.state.x or 0
                state.y = data.state.y or 0
                state.z = data.state.z or 0
                state.facing = data.state.facing or 0
                state.currentSliceZ = data.state.currentSliceZ
                state.currentY = data.state.currentY
                state.currentX = data.state.currentX
                state.fillStarted = data.state.fillStarted or false
                state.blocksPlaced = data.state.blocksPlaced or 0
                state.totalBlocks = data.state.totalBlocks or 0
                state.startTime = data.state.startTime or os.clock()
                state.zone = data.state.zone
            end
            
            return true
        end
    end
    return false
end

local function deleteSave()
    if fs.exists(SAVE_FILE) then
        fs.delete(SAVE_FILE)
    end
end

-- ============================================
-- AFFICHAGE
-- ============================================

local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

local function color(c)
    if term.isColor() then
        term.setTextColor(c)
    end
end

local function printHeader()
    clear()
    color(colors.yellow)
    print("================================")
    print("   FILL v" .. VERSION)
    print("================================")
    color(colors.white)
    print("")
end

local function printStatus()
    local elapsed = os.clock() - state.startTime
    local mins = math.floor(elapsed / 60)
    local secs = math.floor(elapsed % 60)
    
    local progress = 0
    if state.totalBlocks > 0 then
        progress = math.floor((state.blocksPlaced / state.totalBlocks) * 100)
    end
    
    clear()
    color(colors.yellow)
    print("=== FILL EN COURS ===")
    color(colors.white)
    print("")
    print(string.format("Position: %d, %d, %d", state.x, state.y, state.z))
    print(string.format("Tranche: Z=%d", state.currentSliceZ or 0))
    print(string.format("Progression: %d%% (%d/%d)", 
        progress, state.blocksPlaced, state.totalBlocks))
    print(string.format("Fuel: %d", turtle.getFuelLevel()))
    print(string.format("Temps: %d:%02d", mins, secs))
    print("")
    color(colors.lightGray)
    print("Ctrl+T pour arreter")
    print("(Reprise auto au relancement)")
end

-- ============================================
-- MOUVEMENT
-- ============================================

local function updatePos(dx, dy, dz)
    state.x = state.x + dx
    state.y = state.y + dy
    state.z = state.z + dz
end

local function turnLeft()
    turtle.turnLeft()
    state.facing = (state.facing - 1) % 4
end

local function turnRight()
    turtle.turnRight()
    state.facing = (state.facing + 1) % 4
end

local function face(dir)
    while state.facing ~= dir do
        turnRight()
    end
end

local function forward()
    if turtle.forward() then
        local vec = dirVectors[state.facing]
        updatePos(vec.x, 0, vec.z)
        return true
    end
    return false
end

local function up()
    if turtle.up() then
        updatePos(0, 1, 0)
        return true
    end
    return false
end

local function down()
    if turtle.down() then
        updatePos(0, -1, 0)
        return true
    end
    return false
end

local function digForward()
    while turtle.detect() do
        turtle.dig()
        sleep(0.05)
    end
    return forward()
end

local function digUp()
    while turtle.detectUp() do
        turtle.digUp()
        sleep(0.05)
    end
    return up()
end

local function digDown()
    if turtle.detectDown() then
        turtle.digDown()
    end
    return down()
end

-- ============================================
-- NAVIGATION
-- ============================================

local function goTo(targetX, targetY, targetZ)
    while state.y < targetY do
        digUp()
    end
    
    if targetX > state.x then
        face(EAST)
        while state.x < targetX do
            digForward()
        end
    elseif targetX < state.x then
        face(WEST)
        while state.x > targetX do
            digForward()
        end
    end
    
    if targetZ > state.z then
        face(SOUTH)
        while state.z < targetZ do
            digForward()
        end
    elseif targetZ < state.z then
        face(NORTH)
        while state.z > targetZ do
            digForward()
        end
    end
    
    while state.y > targetY do
        digDown()
    end
    
    return state.x == targetX and state.y == targetY and state.z == targetZ
end

-- ============================================
-- GPS
-- ============================================

local function tryGPS()
    local x, y, z = gps.locate(2)
    if x then
        state.x = math.floor(x)
        state.y = math.floor(y)
        state.z = math.floor(z)
        state.hasGPS = true
        return true
    end
    return false
end

local function calibrateDirection()
    local startX, startZ = state.x, state.z
    
    for attempt = 1, 4 do
        if turtle.forward() then
            if tryGPS() then
                local dx = state.x - startX
                local dz = state.z - startZ
                
                if dz == -1 then state.facing = NORTH
                elseif dx == 1 then state.facing = EAST
                elseif dz == 1 then state.facing = SOUTH
                elseif dx == -1 then state.facing = WEST
                end
                
                turtle.back()
                state.x = startX
                state.z = startZ
                return true
            end
            turtle.back()
        end
        turtle.turnRight()
    end
    
    return false
end

-- ============================================
-- INVENTAIRE & FUEL
-- ============================================

local function getMaterialCount()
    local count = 0
    for _, slot in ipairs(config.materialSlots) do
        count = count + turtle.getItemCount(slot)
    end
    return count
end

local function selectMaterial()
    for _, slot in ipairs(config.materialSlots) do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            return true
        end
    end
    return false
end

local function refuel()
    local needed = config.minFuel - turtle.getFuelLevel()
    if needed <= 0 then return true end
    
    turtle.select(config.fuelSlot)
    if turtle.getItemCount() > 0 then
        turtle.refuel()
    end
    
    if turtle.getFuelLevel() < config.minFuel and config.fuelChestPos then
        state.status = "refuel"
        sendStatus()
        
        local returnX, returnY, returnZ = state.x, state.y, state.z
        goTo(config.fuelChestPos.x, config.fuelChestPos.y, config.fuelChestPos.z)
        
        turtle.select(config.fuelSlot)
        for i = 1, 4 do
            turtle.suck(64)
            turtle.turnRight()
        end
        turtle.suckUp(64)
        turtle.suckDown(64)
        turtle.refuel()
        
        goTo(returnX, returnY, returnZ)
        state.status = "filling"
    end
    
    turtle.select(1)
    return turtle.getFuelLevel() >= config.minFuel
end

local function getMaterialsFromChest()
    if not config.chestPos then return false end
    
    state.status = "materiaux"
    sendStatus()
    
    local returnX, returnY, returnZ = state.x, state.y, state.z
    local returnFacing = state.facing
    
    goTo(config.chestPos.x, config.chestPos.y, config.chestPos.z)
    
    -- Remplit tous les slots materiaux
    for _, slot in ipairs(config.materialSlots) do
        turtle.select(slot)
        local count = turtle.getItemCount()
        local needed = 64 - count
        
        if needed > 0 then
            for i = 1, 4 do
                if turtle.suck(needed) then break end
                turtle.turnRight()
            end
            turtle.suckUp(needed)
            turtle.suckDown(needed)
        end
    end
    
    turtle.select(1)
    goTo(returnX, returnY, returnZ)
    face(returnFacing)
    
    state.status = "filling"
    return getMaterialCount() > 0
end

local function checkFuel()
    if turtle.getFuelLevel() < config.minFuel then
        if not refuel() then
            return false
        end
    end
    return true
end

local function checkMaterials()
    if getMaterialCount() < 10 then
        if config.chestPos then
            getMaterialsFromChest()
        end
        
        if getMaterialCount() == 0 then
            return false
        end
    end
    return true
end

-- ============================================
-- CALCULS
-- ============================================

local function calculateFuelNeeded(p1, p2, chestPos)
    local minX = math.min(p1.x, p2.x)
    local maxX = math.max(p1.x, p2.x)
    local minY = math.min(p1.y, p2.y)
    local maxY = math.max(p1.y, p2.y)
    local minZ = math.min(p1.z, p2.z)
    local maxZ = math.max(p1.z, p2.z)
    
    local width = maxX - minX + 1
    local height = maxY - minY + 1
    local length = maxZ - minZ + 1
    
    local volume = width * height * length
    local fuel = volume
    
    local trips = math.ceil(volume / (15 * 64))
    if chestPos then
        local distToChest = math.abs(minX - chestPos.x) 
                         + math.abs(minY - chestPos.y) 
                         + math.abs(minZ - chestPos.z)
        fuel = fuel + (trips * distToChest * 2)
    end
    
    return math.ceil(fuel * 1.3), volume
end

local function getZoneInfo(p1, p2)
    local minX = math.min(p1.x, p2.x)
    local maxX = math.max(p1.x, p2.x)
    local minY = math.min(p1.y, p2.y)
    local maxY = math.max(p1.y, p2.y)
    local minZ = math.min(p1.z, p2.z)
    local maxZ = math.max(p1.z, p2.z)
    
    return {
        minX = minX, maxX = maxX,
        minY = minY, maxY = maxY,
        minZ = minZ, maxZ = maxZ,
        width = maxX - minX + 1,
        height = maxY - minY + 1,
        length = maxZ - minZ + 1,
    }
end

-- ============================================
-- REMPLISSAGE
-- ============================================

local function placeBlock()
    if not selectMaterial() then
        return false
    end
    
    -- Place en dessous
    if turtle.placeDown() then
        state.blocksPlaced = state.blocksPlaced + 1
        return true
    end
    
    -- Si deja un bloc, on considere comme place
    if turtle.detectDown() then
        return true
    end
    
    return false
end

local function fillSlice(zone, sliceZ)
    state.currentSliceZ = sliceZ
    saveState()
    
    local reverse = ((sliceZ - zone.minZ) % 2 == 1)
    
    -- Remplit de BAS en HAUT
    for y = zone.minY, zone.maxY do
        state.currentY = y
        
        local startX = reverse and zone.maxX or zone.minX
        local endX = reverse and zone.minX or zone.maxX
        local stepX = reverse and -1 or 1
        
        -- La turtle doit etre AU-DESSUS du bloc a placer
        goTo(startX, y + 1, sliceZ)
        
        local x = startX
        while true do
            state.currentX = x
            
            if state.blocksPlaced % 20 == 0 then
                saveState()
                sendStatus()
            end
            
            -- Place le bloc en dessous
            if not placeBlock() then
                -- Plus de materiaux, va chercher
                if not checkMaterials() then
                    state.status = "no_materials"
                    sendStatus()
                    saveState()
                    return false
                end
                placeBlock()
            end
            
            if not checkFuel() then
                state.status = "no_fuel"
                sendStatus()
                saveState()
                return false
            end
            
            if x == endX then break end
            
            if stepX > 0 then
                face(EAST)
            else
                face(WEST)
            end
            digForward()
            
            x = x + stepX
        end
        
        reverse = not reverse
        
        if state.blocksPlaced % 50 == 0 then
            printStatus()
        end
    end
    
    saveState()
    return true
end

local function fillZone(resumeFromZ)
    local zone = state.zone
    
    if not resumeFromZ then
        print(string.format("Zone: %dx%dx%d", zone.width, zone.height, zone.length))
        state.totalBlocks = zone.width * zone.height * zone.length
        print(string.format("Blocs a placer: %d", state.totalBlocks))
        print("")
    end
    
    state.running = true
    state.fillStarted = true
    state.status = "filling"
    
    if state.startTime == 0 then
        state.startTime = os.clock()
    end
    
    local startZ = resumeFromZ or zone.minZ
    
    sendStatus()
    
    for z = startZ, zone.maxZ do
        if not state.running then break end
        
        print(string.format("Tranche Z=%d (%d/%d)", z, z - zone.minZ + 1, zone.length))
        
        if not fillSlice(zone, z) then
            print("Arret: ressources insuffisantes")
            saveState()
            break
        end
    end
    
    if state.currentSliceZ and state.currentSliceZ >= zone.maxZ then
        print("Retour au point de depart...")
        goTo(config.chestPos.x, config.chestPos.y, config.chestPos.z)
        
        deleteSave()
        state.fillStarted = false
        state.status = "done"
    else
        state.status = "paused"
        saveState()
    end
    
    sendStatus()
    state.running = false
end

-- ============================================
-- INTERFACE UTILISATEUR
-- ============================================

local function readNumber(prompt, default)
    while true do
        if default then
            io.write(prompt .. " [" .. default .. "]: ")
        else
            io.write(prompt .. ": ")
        end
        
        local input = read()
        
        if input == "" and default then
            return default
        end
        
        local num = tonumber(input)
        if num then
            return math.floor(num)
        end
        
        color(colors.red)
        print("Entrez un nombre valide!")
        color(colors.white)
    end
end

local function readCoords(prompt)
    print(prompt)
    local x = readNumber("  X")
    local y = readNumber("  Y")
    local z = readNumber("  Z")
    return {x = x, y = y, z = z}
end

local function askYesNo(prompt, default)
    local defStr = default and "[O/n]" or "[o/N]"
    io.write(prompt .. " " .. defStr .. ": ")
    local input = read():lower()
    
    if input == "" then
        return default
    end
    return input == "o" or input == "oui" or input == "y" or input == "yes"
end

local function chooseMaterial()
    print("")
    color(colors.cyan)
    print("Materiau a utiliser:")
    color(colors.white)
    print("  1. Dirt (terre)")
    print("  2. Cobblestone")
    print("")
    
    io.write("Choix [1]: ")
    local input = read()
    
    if input == "2" then
        config.material = "minecraft:cobblestone"
        return "Cobblestone"
    else
        config.material = "minecraft:dirt"
        return "Dirt"
    end
end

local function setupManual()
    printHeader()
    
    print("Configuration:")
    print("")
    
    color(colors.cyan)
    print("Position actuelle de la turtle:")
    color(colors.white)
    
    if state.hasGPS then
        print(string.format("  GPS: %d, %d, %d", state.x, state.y, state.z))
        if not askYesNo("Utiliser GPS?", true) then
            state.x = readNumber("  X", state.x)
            state.y = readNumber("  Y", state.y)
            state.z = readNumber("  Z", state.z)
        end
    else
        print("  (GPS non disponible)")
        state.x = readNumber("  X", 0)
        state.y = readNumber("  Y", 64)
        state.z = readNumber("  Z", 0)
    end
    
    print("")
    color(colors.cyan)
    print("Direction actuelle:")
    color(colors.white)
    print("  0=Nord(-Z) 1=Est(+X) 2=Sud(+Z) 3=Ouest(-X)")
    state.facing = readNumber("  Direction", state.facing)
    
    local materialName = chooseMaterial()
    
    print("")
    color(colors.cyan)
    config.pos1 = readCoords("Coin 1 de la zone:")
    color(colors.white)
    
    print("")
    color(colors.cyan)
    config.pos2 = readCoords("Coin 2 de la zone:")
    color(colors.white)
    
    config.chestPos = {x = state.x, y = state.y, z = state.z}
    
    print("")
    if askYesNo("Configurer un coffre materiaux?", true) then
        config.chestPos = readCoords("Position coffre materiaux:")
    end
    
    print("")
    if askYesNo("Configurer un coffre fuel?", false) then
        config.fuelChestPos = readCoords("Position coffre fuel:")
    end
    
    state.zone = getZoneInfo(config.pos1, config.pos2)
    
    return true
end

local function confirmStart()
    local zone = state.zone
    local fuelNeeded, volume = calculateFuelNeeded(config.pos1, config.pos2, config.chestPos)
    local currentFuel = turtle.getFuelLevel()
    
    printHeader()
    
    color(colors.cyan)
    print("Resume:")
    color(colors.white)
    print(string.format("  Zone: %d x %d x %d", zone.width, zone.height, zone.length))
    print(string.format("  Blocs a placer: %d", volume))
    print(string.format("  Materiau: %s", config.material:gsub("minecraft:", "")))
    print("")
    
    color(colors.cyan)
    print("Fuel:")
    color(colors.white)
    print(string.format("  Actuel: %d", currentFuel))
    print(string.format("  Estime necessaire: %d", fuelNeeded))
    
    if currentFuel < fuelNeeded then
        color(colors.orange)
        print(string.format("  ATTENTION: Il manque ~%d!", fuelNeeded - currentFuel))
        color(colors.white)
    else
        color(colors.lime)
        print("  OK - Fuel suffisant")
        color(colors.white)
    end
    
    print("")
    local matCount = getMaterialCount()
    color(colors.cyan)
    print("Materiaux:")
    color(colors.white)
    print(string.format("  En inventaire: %d", matCount))
    print(string.format("  Necessaires: %d", volume))
    
    if matCount < volume and not config.chestPos then
        color(colors.orange)
        print("  ATTENTION: Pas assez + pas de coffre!")
        color(colors.white)
    end
    
    print("")
    color(colors.yellow)
    print("IMPORTANT:")
    print("  - Mets le materiau slots 1-15")
    print("  - Fuel dans le slot 16")
    color(colors.white)
    print("")
    
    return askYesNo("Demarrer le remplissage?", true)
end

local function confirmResume()
    printHeader()
    
    color(colors.lime)
    print("Sauvegarde trouvee!")
    color(colors.white)
    print("")
    
    if state.zone then
        print(string.format("Zone: %dx%dx%d", 
            state.zone.width, state.zone.height, state.zone.length))
        print(string.format("Materiau: %s", config.material:gsub("minecraft:", "")))
        print(string.format("Position: %d, %d, %d", state.x, state.y, state.z))
        print(string.format("Tranche: Z=%d / %d", 
            state.currentSliceZ or state.zone.minZ, state.zone.maxZ))
        print(string.format("Blocs places: %d / %d", 
            state.blocksPlaced, state.totalBlocks))
        
        local remaining = state.totalBlocks - state.blocksPlaced
        print(string.format("Blocs restants: %d", remaining))
    end
    
    print("")
    
    color(colors.cyan)
    print("Que voulez-vous faire?")
    color(colors.white)
    print("  1. Reprendre le remplissage")
    print("  2. Nouvelle configuration")
    print("  3. Annuler")
    print("")
    
    io.write("Choix [1]: ")
    local input = read()
    
    if input == "2" then
        deleteSave()
        return "new"
    elseif input == "3" then
        return "cancel"
    else
        return "resume"
    end
end

-- ============================================
-- PROGRAMME PRINCIPAL
-- ============================================

local function main()
    printHeader()
    
    -- Cherche modem wireless
    if findModem() then
        print("Modem wireless trouve")
        print("Canal monitoring: " .. MONITOR_CHANNEL)
    else
        print("Pas de modem wireless")
    end
    print("")
    
    -- Verifie le fuel
    if turtle.getFuelLevel() == 0 then
        color(colors.red)
        print("ERREUR: Pas de fuel!")
        print("Mets du charbon dans le slot 16")
        print("et tape: refuel 16")
        color(colors.white)
        return
    end
    
    -- Verifie si sauvegarde existe
    local hasSave = loadState()
    
    if hasSave and state.fillStarted then
        local choice = confirmResume()
        
        if choice == "resume" then
            printHeader()
            color(colors.lime)
            print("Reprise du remplissage...")
            color(colors.white)
            print("")
            
            if tryGPS() then
                print("GPS: Position mise a jour")
                if calibrateDirection() then
                    print("Direction: " .. dirNames[state.facing + 1])
                end
            end
            
            sleep(1)
            fillZone(state.currentSliceZ)
            
            printHeader()
            if not state.fillStarted then
                color(colors.lime)
                print("REMPLISSAGE TERMINE!")
            else
                color(colors.orange)
                print("REMPLISSAGE INTERROMPU")
                print("")
                print("Relancez 'fill' pour reprendre")
            end
            color(colors.white)
            print("")
            print(string.format("Blocs places: %d", state.blocksPlaced))
            return
            
        elseif choice == "cancel" then
            print("Annule.")
            return
        end
    end
    
    -- Nouvelle configuration
    print("Recherche GPS...")
    if tryGPS() then
        color(colors.lime)
        print("GPS OK: " .. state.x .. ", " .. state.y .. ", " .. state.z)
        color(colors.white)
        
        print("Calibration direction...")
        if calibrateDirection() then
            print("Direction: " .. dirNames[state.facing + 1])
        else
            print("Calibration echouee, config manuelle")
            state.facing = readNumber("Direction (0-3)", 0)
        end
    else
        color(colors.orange)
        print("GPS non disponible - Mode manuel")
        color(colors.white)
    end
    
    print("")
    
    if not setupManual() then
        return
    end
    
    if not confirmStart() then
        print("Annule.")
        return
    end
    
    printHeader()
    color(colors.lime)
    print("Demarrage du remplissage...")
    color(colors.white)
    print("")
    
    state.startTime = os.clock()
    state.totalBlocks = state.zone.width * state.zone.height * state.zone.length
    saveState()
    
    sleep(1)
    fillZone()
    
    printHeader()
    if not state.fillStarted then
        color(colors.lime)
        print("REMPLISSAGE TERMINE!")
    else
        color(colors.orange)
        print("REMPLISSAGE INTERROMPU")
        print("")
        print("Relancez 'fill' pour reprendre")
    end
    color(colors.white)
    print("")
    print(string.format("Blocs places: %d", state.blocksPlaced))
    
    local elapsed = os.clock() - state.startTime
    print(string.format("Temps: %d:%02d", math.floor(elapsed/60), math.floor(elapsed%60)))
end

main()
