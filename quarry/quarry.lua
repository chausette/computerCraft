-- ============================================
-- QUARRY.lua - Programme de minage de zone
-- Turtle creuse entre 2 coordonnees
-- ============================================

local VERSION = "1.0"

-- ============================================
-- CONFIGURATION
-- ============================================

local config = {
    -- Coordonnees de la zone (definies par l'utilisateur)
    pos1 = nil,  -- {x, y, z}
    pos2 = nil,  -- {x, y, z}
    
    -- Position du coffre de depot (point de depart)
    chestPos = nil,  -- {x, y, z}
    fuelChestPos = nil, -- {x, y, z} optionnel
    
    -- Slots
    fuelSlot = 16,
    chestSlot = 15,  -- Pour poser le coffre
    
    -- Seuils
    minFuel = 100,
    minFreeSlots = 2,
}

-- ============================================
-- ETAT
-- ============================================

local state = {
    x = 0,
    y = 0,
    z = 0,
    facing = 0,  -- 0=Nord(-Z), 1=Est(+X), 2=Sud(+Z), 3=Ouest(-X)
    
    hasGPS = false,
    running = false,
    
    -- Stats
    blocksMined = 0,
    startTime = 0,
    fuelUsed = 0,
}

-- ============================================
-- DIRECTIONS
-- ============================================

local NORTH, EAST, SOUTH, WEST = 0, 1, 2, 3
local dirNames = {"Nord (-Z)", "Est (+X)", "Sud (+Z)", "Ouest (-X)"}
local dirVectors = {
    [0] = {x = 0, z = -1},   -- Nord
    [1] = {x = 1, z = 0},    -- Est
    [2] = {x = 0, z = 1},    -- Sud
    [3] = {x = -1, z = 0},   -- Ouest
}

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
    print("   QUARRY MINER v" .. VERSION)
    print("================================")
    color(colors.white)
    print("")
end

local function printStatus()
    local elapsed = os.clock() - state.startTime
    local mins = math.floor(elapsed / 60)
    local secs = math.floor(elapsed % 60)
    
    clear()
    color(colors.yellow)
    print("=== QUARRY EN COURS ===")
    color(colors.white)
    print("")
    print(string.format("Position: %d, %d, %d", state.x, state.y, state.z))
    print(string.format("Blocs mines: %d", state.blocksMined))
    print(string.format("Fuel: %d", turtle.getFuelLevel()))
    print(string.format("Temps: %d:%02d", mins, secs))
    print("")
    color(colors.lightGray)
    print("Ctrl+T pour arreter")
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

local function back()
    if turtle.back() then
        local vec = dirVectors[state.facing]
        updatePos(-vec.x, 0, -vec.z)
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

-- Creuse et avance
local function digForward()
    while turtle.detect() do
        turtle.dig()
        state.blocksMined = state.blocksMined + 1
        sleep(0.05)  -- Pour le gravier/sable
    end
    return forward()
end

local function digUp()
    while turtle.detectUp() do
        turtle.digUp()
        state.blocksMined = state.blocksMined + 1
        sleep(0.05)
    end
    return up()
end

local function digDown()
    if turtle.detectDown() then
        turtle.digDown()
        state.blocksMined = state.blocksMined + 1
    end
    return down()
end

-- ============================================
-- NAVIGATION
-- ============================================

local function goTo(targetX, targetY, targetZ, digBlocks)
    digBlocks = digBlocks ~= false
    
    -- Monte d'abord si necessaire (pour eviter les obstacles)
    while state.y < targetY do
        if digBlocks then digUp() else up() end
    end
    
    -- Deplacement X
    if targetX > state.x then
        face(EAST)
        while state.x < targetX do
            if digBlocks then digForward() else forward() end
        end
    elseif targetX < state.x then
        face(WEST)
        while state.x > targetX do
            if digBlocks then digForward() else forward() end
        end
    end
    
    -- Deplacement Z
    if targetZ > state.z then
        face(SOUTH)
        while state.z < targetZ do
            if digBlocks then digForward() else forward() end
        end
    elseif targetZ < state.z then
        face(NORTH)
        while state.z > targetZ do
            if digBlocks then digForward() else forward() end
        end
    end
    
    -- Descend si necessaire
    while state.y > targetY do
        if digBlocks then digDown() else down() end
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
    
    -- Essaie d'avancer
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

local function getFreeSlots()
    local free = 0
    for slot = 1, 14 do
        if turtle.getItemCount(slot) == 0 then
            free = free + 1
        end
    end
    return free
end

local function refuel()
    local needed = config.minFuel - turtle.getFuelLevel()
    if needed <= 0 then return true end
    
    -- Essaie le slot fuel
    turtle.select(config.fuelSlot)
    if turtle.getItemCount() > 0 then
        turtle.refuel()
    end
    
    -- Si toujours pas assez et coffre fuel configure
    if turtle.getFuelLevel() < config.minFuel and config.fuelChestPos then
        local returnX, returnY, returnZ = state.x, state.y, state.z
        goTo(config.fuelChestPos.x, config.fuelChestPos.y, config.fuelChestPos.z, true)
        
        turtle.select(config.fuelSlot)
        for i = 1, 4 do
            turtle.suck(64)
            turtle.turnRight()
        end
        turtle.suckUp(64)
        turtle.suckDown(64)
        turtle.refuel()
        
        goTo(returnX, returnY, returnZ, true)
    end
    
    turtle.select(1)
    return turtle.getFuelLevel() >= config.minFuel
end

local function depositItems()
    if not config.chestPos then return false end
    
    local returnX, returnY, returnZ = state.x, state.y, state.z
    local returnFacing = state.facing
    
    goTo(config.chestPos.x, config.chestPos.y, config.chestPos.z, true)
    
    -- Depose dans le coffre (essaie toutes les directions)
    for slot = 1, 14 do
        if turtle.getItemCount(slot) > 0 then
            turtle.select(slot)
            
            -- Essaie de deposer
            if not turtle.dropDown() then
                for i = 1, 4 do
                    if turtle.drop() then break end
                    turnRight()
                end
            end
        end
    end
    
    turtle.select(1)
    goTo(returnX, returnY, returnZ, true)
    face(returnFacing)
    
    return true
end

local function checkInventory()
    if getFreeSlots() < config.minFreeSlots then
        print("Inventaire plein, depot...")
        depositItems()
    end
end

local function checkFuel()
    if turtle.getFuelLevel() < config.minFuel then
        print("Fuel bas, rechargement...")
        if not refuel() then
            print("ATTENTION: Fuel insuffisant!")
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
    
    -- Deplacements dans la zone
    local fuel = volume
    
    -- Retours au coffre (estimation: 1 retour tous les 14*64 blocs)
    local trips = math.ceil(volume / (14 * 64))
    if chestPos then
        local distToChest = math.abs(minX - chestPos.x) 
                         + math.abs(minY - chestPos.y) 
                         + math.abs(minZ - chestPos.z)
        fuel = fuel + (trips * distToChest * 2)
    end
    
    -- Marge de securite 30%
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
-- MINAGE (TRANCHE PAR TRANCHE)
-- ============================================

local function mineSlice(zone, sliceZ)
    -- Mine une tranche X/Y a la position Z donnee
    local reverse = false
    
    for y = zone.maxY, zone.minY, -1 do
        local startX = reverse and zone.maxX or zone.minX
        local endX = reverse and zone.minX or zone.maxX
        local stepX = reverse and -1 or 1
        
        -- Va au debut de la ligne
        goTo(startX, y, sliceZ, true)
        
        -- Mine la ligne
        local x = startX
        while true do
            -- Creuse le bloc actuel (si pas deja fait par goTo)
            if turtle.detectDown() then
                turtle.digDown()
                state.blocksMined = state.blocksMined + 1
            end
            
            -- Verifie inventaire et fuel
            checkInventory()
            if not checkFuel() then
                return false
            end
            
            -- Avance au prochain bloc
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
        
        -- Mise a jour status
        if state.blocksMined % 50 == 0 then
            printStatus()
        end
    end
    
    return true
end

local function mineZone()
    local zone = getZoneInfo(config.pos1, config.pos2)
    
    print(string.format("Zone: %dx%dx%d", zone.width, zone.height, zone.length))
    print(string.format("Volume: %d blocs", zone.width * zone.height * zone.length))
    print("")
    
    state.running = true
    state.startTime = os.clock()
    state.blocksMined = 0
    
    -- Mine tranche par tranche (de minZ a maxZ)
    for z = zone.minZ, zone.maxZ do
        if not state.running then break end
        
        print(string.format("Tranche Z=%d (%d/%d)", z, z - zone.minZ + 1, zone.length))
        
        if not mineSlice(zone, z) then
            print("Arret: probleme de fuel")
            break
        end
    end
    
    -- Retour au coffre
    print("Retour au depot...")
    goTo(config.chestPos.x, config.chestPos.y, config.chestPos.z, true)
    depositItems()
    
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

local function setupManual()
    printHeader()
    
    print("Configuration manuelle:")
    print("")
    
    -- Position actuelle
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
    
    -- Direction
    print("")
    color(colors.cyan)
    print("Direction actuelle:")
    color(colors.white)
    print("  0=Nord(-Z) 1=Est(+X) 2=Sud(+Z) 3=Ouest(-X)")
    state.facing = readNumber("  Direction", state.facing)
    
    -- Coin 1 de la zone
    print("")
    color(colors.cyan)
    config.pos1 = readCoords("Coin 1 de la zone:")
    color(colors.white)
    
    -- Coin 2 de la zone
    print("")
    color(colors.cyan)
    config.pos2 = readCoords("Coin 2 de la zone:")
    color(colors.white)
    
    -- Coffre de depot = position actuelle
    config.chestPos = {x = state.x, y = state.y, z = state.z}
    
    -- Coffre fuel optionnel
    print("")
    if askYesNo("Configurer un coffre fuel?", false) then
        config.fuelChestPos = readCoords("Position coffre fuel:")
    end
    
    return true
end

local function confirmStart()
    local zone = getZoneInfo(config.pos1, config.pos2)
    local fuelNeeded, volume = calculateFuelNeeded(config.pos1, config.pos2, config.chestPos)
    local currentFuel = turtle.getFuelLevel()
    
    printHeader()
    
    color(colors.cyan)
    print("Resume:")
    color(colors.white)
    print(string.format("  Zone: %d x %d x %d", zone.width, zone.height, zone.length))
    print(string.format("  Volume: %d blocs", volume))
    print(string.format("  De (%d,%d,%d) a (%d,%d,%d)", 
        zone.minX, zone.minY, zone.minZ,
        zone.maxX, zone.maxY, zone.maxZ))
    print("")
    
    color(colors.cyan)
    print("Fuel:")
    color(colors.white)
    print(string.format("  Actuel: %d", currentFuel))
    print(string.format("  Estime necessaire: %d", fuelNeeded))
    
    if currentFuel < fuelNeeded then
        color(colors.orange)
        print(string.format("  ATTENTION: Il manque ~%d fuel!", fuelNeeded - currentFuel))
        color(colors.white)
    else
        color(colors.lime)
        print("  OK - Fuel suffisant")
        color(colors.white)
    end
    
    print("")
    color(colors.cyan)
    print("Coffre depot:")
    color(colors.white)
    print(string.format("  Position: %d, %d, %d", config.chestPos.x, config.chestPos.y, config.chestPos.z))
    print("")
    
    color(colors.yellow)
    print("IMPORTANT:")
    print("  - Place un coffre SOUS la turtle")
    print("  - Fuel dans le slot 16")
    color(colors.white)
    print("")
    
    return askYesNo("Demarrer le minage?", true)
end

-- ============================================
-- PROGRAMME PRINCIPAL
-- ============================================

local function main()
    printHeader()
    
    -- Verifie le fuel
    if turtle.getFuelLevel() == 0 then
        color(colors.red)
        print("ERREUR: Pas de fuel!")
        print("Mets du charbon dans le slot 16")
        print("et tape: refuel 16")
        color(colors.white)
        return
    end
    
    -- Essaie le GPS
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
    
    -- Configuration
    if not setupManual() then
        return
    end
    
    -- Confirmation
    if not confirmStart() then
        print("Annule.")
        return
    end
    
    -- Demarrage
    printHeader()
    color(colors.lime)
    print("Demarrage du minage...")
    color(colors.white)
    print("")
    
    -- Verifie/pose le coffre
    print("Verification du coffre de depot...")
    turtle.select(1)
    if not turtle.detectDown() then
        -- Cherche un coffre dans l'inventaire
        for slot = 1, 16 do
            turtle.select(slot)
            local item = turtle.getItemDetail()
            if item and item.name:find("chest") then
                print("Pose du coffre...")
                turtle.placeDown()
                break
            end
        end
    end
    turtle.select(1)
    
    sleep(1)
    
    -- Lance le minage
    mineZone()
    
    -- Termine
    printHeader()
    color(colors.lime)
    print("MINAGE TERMINE!")
    color(colors.white)
    print("")
    print(string.format("Blocs mines: %d", state.blocksMined))
    print(string.format("Fuel utilise: %d", state.fuelUsed))
    
    local elapsed = os.clock() - state.startTime
    local mins = math.floor(elapsed / 60)
    local secs = math.floor(elapsed % 60)
    print(string.format("Temps: %d:%02d", mins, secs))
end

-- Lance le programme
main()