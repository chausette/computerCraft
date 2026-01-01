-- ============================================
-- INSTALLER.lua - Installateur & Updater
-- Schematic Builder pour ComputerCraft
-- ============================================
-- wget run https://raw.githubusercontent.com/chausette/computerCraft/master/schematic-builder/installer.lua
-- ============================================

local VERSION = "1.1"

-- ===========================================
-- CONFIGURATION
-- ===========================================

local GITHUB_USER = "chausette"
local GITHUB_REPO = "computerCraft"
local GITHUB_BRANCH = "master"
local GITHUB_DIRECTORY = "schematic-builder"

local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/" .. GITHUB_DIRECTORY .. "/"

-- ===========================================
-- AFFICHAGE
-- ===========================================

local function setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

local function setBgColor(color)
    if term.isColor() then
        term.setBackgroundColor(color)
    end
end

local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    setBgColor(colors.blue)
    setColor(colors.white)
    term.clearLine()
    print("  SCHEMATIC BUILDER v" .. VERSION)
    setBgColor(colors.black)
    print("")
end

local function printOK(msg)
    setColor(colors.lime)
    print("[OK] " .. msg)
    setColor(colors.white)
end

local function printErr(msg)
    setColor(colors.red)
    print("[X] " .. msg)
    setColor(colors.white)
end

local function printInfo(msg)
    setColor(colors.lightBlue)
    print("[i] " .. msg)
    setColor(colors.white)
end

local function printWarn(msg)
    setColor(colors.orange)
    print("[!] " .. msg)
    setColor(colors.white)
end

-- ===========================================
-- DETECTION
-- ===========================================

local function detectMachine()
    if turtle then
        return "turtle"
    elseif pocket then
        return "pocket"
    else
        local hasWirelessModem = false
        local hasMonitor = peripheral.find("monitor") ~= nil
        
        for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
            if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
                local m = peripheral.wrap(side)
                if m.isWireless and m.isWireless() then
                    hasWirelessModem = true
                end
            end
        end
        
        if hasMonitor then
            return "server"
        elseif hasWirelessModem then
            return "gps_or_server"
        else
            return "computer"
        end
    end
end

local function isInstalled(machineType)
    if machineType == "turtle" then
        return fs.exists("builder.lua")
    elseif machineType == "server" then
        return fs.exists("server.lua")
    elseif machineType == "gps" then
        return fs.exists("startup.lua")
    end
    return false
end

-- ===========================================
-- TELECHARGEMENT
-- ===========================================

local function download(remotePath, localPath)
    local url = BASE_URL .. remotePath
    
    if fs.exists(localPath) then
        fs.delete(localPath)
    end
    
    local dir = fs.getDir(localPath)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(localPath, "w")
        if file then
            file.write(content)
            file.close()
            return true
        end
    end
    return false
end

-- ===========================================
-- FICHIERS PAR TYPE
-- ===========================================

local machineFiles = {
    turtle = {
        {remote = "turtle/nbt.lua", local_ = "nbt.lua"},
        {remote = "turtle/movement.lua", local_ = "movement.lua"},
        {remote = "turtle/builder.lua", local_ = "builder.lua"},
    },
    server = {
        {remote = "computer/ui.lua", local_ = "ui.lua"},
        {remote = "computer/server.lua", local_ = "server.lua"},
    },
    gps = {
        {remote = "turtle/gps_host.lua", local_ = "startup.lua"},
    }
}

-- ===========================================
-- INSTALLATION TURTLE
-- ===========================================

local function installTurtle(isUpdate)
    local action = isUpdate and "Mise a jour" or "Installation"
    printInfo(action .. " TURTLE")
    print("")
    
    local success = true
    for _, file in ipairs(machineFiles.turtle) do
        io.write("  " .. file.local_ .. "... ")
        if download(file.remote, file.local_) then
            printOK("OK")
        else
            printErr("ECHEC")
            success = false
        end
    end
    
    print("")
    if success then
        printOK(action .. " terminee!")
        print("")
        setColor(colors.yellow)
        print("Commande: builder")
        setColor(colors.white)
    else
        printErr(action .. " incomplete!")
    end
    return success
end

-- ===========================================
-- INSTALLATION SERVEUR
-- ===========================================

local function installServer(isUpdate)
    local action = isUpdate and "Mise a jour" or "Installation"
    printInfo(action .. " SERVEUR")
    print("")
    
    local success = true
    for _, file in ipairs(machineFiles.server) do
        io.write("  " .. file.local_ .. "... ")
        if download(file.remote, file.local_) then
            printOK("OK")
        else
            printErr("ECHEC")
            success = false
        end
    end
    
    if not fs.exists("schematics") then
        fs.makeDir("schematics")
    end
    
    if not isUpdate then
        io.write("  exemple.json... ")
        if download("computer/schematics/exemple_maison.json", "schematics/exemple_maison.json") then
            printOK("OK")
        else
            printWarn("ignore")
        end
    end
    
    print("")
    if success then
        printOK(action .. " terminee!")
        print("")
        setColor(colors.yellow)
        print("Commande: server")
        setColor(colors.white)
    else
        printErr(action .. " incomplete!")
    end
    return success
end

-- ===========================================
-- INSTALLATION GPS
-- ===========================================

local function installGPS(isUpdate)
    local action = isUpdate and "Mise a jour" or "Installation"
    printInfo(action .. " GPS HOST")
    print("")
    
    setColor(colors.yellow)
    print("Coordonnees de CE computer:")
    print("(F3 dans Minecraft)")
    setColor(colors.white)
    print("")
    
    -- Charge les anciennes coordonnees si update
    local oldX, oldY, oldZ = 0, 255, 0
    if isUpdate and fs.exists("startup.lua") then
        local f = fs.open("startup.lua", "r")
        if f then
            local content = f.readAll()
            f.close()
            oldX = tonumber(content:match("local X = (%-?%d+)")) or 0
            oldY = tonumber(content:match("local Y = (%-?%d+)")) or 255
            oldZ = tonumber(content:match("local Z = (%-?%d+)")) or 0
        end
    end
    
    io.write("X [" .. oldX .. "]: ")
    local inputX = read()
    local x = tonumber(inputX)
    if not x or inputX == "" then x = oldX end
    
    io.write("Y [" .. oldY .. "]: ")
    local inputY = read()
    local y = tonumber(inputY)
    if not y or inputY == "" then y = oldY end
    
    io.write("Z [" .. oldZ .. "]: ")
    local inputZ = read()
    local z = tonumber(inputZ)
    if not z or inputZ == "" then z = oldZ end
    
    print("")
    
    io.write("Telechargement... ")
    local url = BASE_URL .. "turtle/gps_host.lua"
    local response = http.get(url)
    
    if response then
        local content = response.readAll()
        response.close()
        
        content = content:gsub("local X = 0", "local X = " .. x)
        content = content:gsub("local Y = 255", "local Y = " .. y)
        content = content:gsub("local Z = 0", "local Z = " .. z)
        
        local file = fs.open("startup.lua", "w")
        if file then
            file.write(content)
            file.close()
            printOK("OK")
        else
            printErr("Ecriture impossible")
            return false
        end
    else
        printErr("Telechargement echoue")
        return false
    end
    
    print("")
    printOK(action .. " terminee!")
    print("")
    setColor(colors.lime)
    print("Position: " .. x .. ", " .. y .. ", " .. z)
    setColor(colors.white)
    print("")
    setColor(colors.yellow)
    print("IMPORTANT pour eviter 'ambiguous':")
    print("  - 4 hosts minimum")
    print("  - 1 host DOIT etre plus haut (+10 Y)")
    print("  - Espacement min 6 blocs")
    setColor(colors.white)
    print("")
    print("Tapez 'reboot' pour demarrer")
    
    return true
end

-- ===========================================
-- MENU
-- ===========================================

local function showMenu(detected)
    print("Que voulez-vous installer?")
    print("")
    setColor(colors.yellow)
    print("  1. Serveur (moniteur)")
    print("  2. GPS Host")
    print("  3. Annuler")
    setColor(colors.white)
    print("")
    io.write("Choix [1-3]: ")
    
    local choice = read()
    print("")
    
    if choice == "1" then
        return installServer(false)
    elseif choice == "2" then
        return installGPS(false)
    else
        printInfo("Annule")
        return false
    end
end

local function showUpdateMenu(machineType)
    print("Installation detectee!")
    print("")
    setColor(colors.yellow)
    print("  1. Mettre a jour")
    print("  2. Reinstaller")
    print("  3. Annuler")
    setColor(colors.white)
    print("")
    io.write("Choix [1-3]: ")
    
    local choice = read()
    print("")
    
    if choice == "1" or choice == "2" then
        local isUpdate = (choice == "1")
        if machineType == "turtle" then
            return installTurtle(isUpdate)
        elseif machineType == "server" then
            return installServer(isUpdate)
        elseif machineType == "gps" then
            return installGPS(isUpdate)
        end
    else
        printInfo("Annule")
        return false
    end
end

-- ===========================================
-- CONNEXION
-- ===========================================

local function checkInternet()
    local response = http.get("https://raw.githubusercontent.com")
    if response then
        response.close()
        return true
    end
    return false
end

-- ===========================================
-- MAIN
-- ===========================================

local function main()
    printHeader()
    
    io.write("Connexion... ")
    if not checkInternet() then
        printErr("Pas d'internet!")
        print("")
        print("Activez HTTP dans ComputerCraft.")
        return
    end
    printOK("OK")
    print("")
    
    local machineType = detectMachine()
    local installed = isInstalled(machineType)
    
    if machineType == "turtle" then
        if installed then
            showUpdateMenu("turtle")
        else
            installTurtle(false)
        end
        
    elseif machineType == "server" then
        if installed then
            showUpdateMenu("server")
        else
            installServer(false)
        end
        
    elseif machineType == "gps_or_server" then
        -- Verifie si c'est un GPS existant
        if fs.exists("startup.lua") then
            local f = fs.open("startup.lua", "r")
            if f then
                local content = f.readAll()
                f.close()
                if content:find("GPS HOST") then
                    showUpdateMenu("gps")
                    return
                end
            end
        end
        
        printWarn("Type ambigu")
        print("")
        showMenu()
        
    elseif machineType == "pocket" then
        printErr("Pocket non supporte")
        
    else
        printWarn("Aucun peripherique")
        print("")
        showMenu()
    end
    
    print("")
end

main()
