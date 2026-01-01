-- ============================================
-- INSTALLER.lua - Installateur Universel
-- Schematic Builder pour ComputerCraft
-- ============================================
-- Installation:
-- pastebin run <CODE>
-- ou
-- wget run https://raw.githubusercontent.com/VOTRE_USER/VOTRE_REPO/main/installer.lua
-- ============================================

-- ===========================================
-- CONFIGURATION - MODIFIEZ CES VALEURS
-- ===========================================

local GITHUB_USER = "chausette"
local GITHUB_REPO = "schematic-builder"
local GITHUB_BRANCH = "master"

-- ===========================================
-- NE PAS MODIFIER EN DESSOUS
-- ===========================================

local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/"

-- Couleurs
local function setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

-- Affichage
local function printHeader()
    term.clear()
    term.setCursorPos(1, 1)
    setColor(colors.yellow)
    print("========================================")
    print("   SCHEMATIC BUILDER - INSTALLATEUR")
    print("========================================")
    setColor(colors.white)
    print("")
end

local function printSuccess(msg)
    setColor(colors.lime)
    print("[OK] " .. msg)
    setColor(colors.white)
end

local function printError(msg)
    setColor(colors.red)
    print("[ERREUR] " .. msg)
    setColor(colors.white)
end

local function printInfo(msg)
    setColor(colors.lightBlue)
    print("[INFO] " .. msg)
    setColor(colors.white)
end

local function printWarning(msg)
    setColor(colors.orange)
    print("[ATTENTION] " .. msg)
    setColor(colors.white)
end

-- Detection du type de machine
local function detectMachine()
    if turtle then
        return "turtle"
    elseif pocket then
        return "pocket"
    else
        -- Verifie si c'est un GPS host potentiel
        local hasWirelessModem = false
        for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
            if peripheral.isPresent(side) then
                local pType = peripheral.getType(side)
                if pType == "modem" then
                    local m = peripheral.wrap(side)
                    if m.isWireless and m.isWireless() then
                        hasWirelessModem = true
                    end
                end
            end
        end
        
        -- Verifie si un moniteur est connecte
        local hasMonitor = peripheral.find("monitor") ~= nil
        
        if hasMonitor then
            return "server"
        elseif hasWirelessModem then
            return "gps_or_server"
        else
            return "computer"
        end
    end
end

-- Telecharge un fichier depuis GitHub
local function downloadFile(remotePath, localPath)
    local url = BASE_URL .. remotePath
    
    -- Supprime le fichier existant
    if fs.exists(localPath) then
        fs.delete(localPath)
    end
    
    -- Cree les dossiers parents si necessaire
    local dir = fs.getDir(localPath)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    -- Telecharge
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

-- Fichiers pour chaque type de machine
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

-- Installation pour Turtle
local function installTurtle()
    printInfo("Installation pour TURTLE detectee")
    print("")
    
    local success = true
    for _, file in ipairs(machineFiles.turtle) do
        io.write("  Telechargement de " .. file.local_ .. "... ")
        if downloadFile(file.remote, file.local_) then
            printSuccess("OK")
        else
            printError("ECHEC")
            success = false
        end
    end
    
    print("")
    
    if success then
        printSuccess("Installation terminee!")
        print("")
        setColor(colors.yellow)
        print("Pour demarrer: builder")
        print("")
        print("Assurez-vous que:")
        print("  - Le reseau GPS est en place")
        print("  - Un wireless modem est attache")
        setColor(colors.white)
    else
        printError("Installation incomplete!")
    end
    
    return success
end

-- Installation pour Server
local function installServer()
    printInfo("Installation pour SERVEUR detectee")
    print("")
    
    local success = true
    for _, file in ipairs(machineFiles.server) do
        io.write("  Telechargement de " .. file.local_ .. "... ")
        if downloadFile(file.remote, file.local_) then
            printSuccess("OK")
        else
            printError("ECHEC")
            success = false
        end
    end
    
    -- Cree le dossier schematics
    if not fs.exists("schematics") then
        fs.makeDir("schematics")
        printInfo("Dossier 'schematics' cree")
    end
    
    -- Telecharge l'exemple
    io.write("  Telechargement exemple... ")
    if downloadFile("computer/schematics/exemple_maison.json", "schematics/exemple_maison.json") then
        printSuccess("OK")
    else
        printWarning("Optionnel - ignore")
    end
    
    print("")
    
    if success then
        printSuccess("Installation terminee!")
        print("")
        setColor(colors.yellow)
        print("Pour demarrer: server")
        print("")
        print("Assurez-vous que:")
        print("  - Un moniteur 3x2 est connecte")
        print("  - Un wireless modem est attache")
        setColor(colors.white)
    else
        printError("Installation incomplete!")
    end
    
    return success
end

-- Installation pour GPS Host
local function installGPS()
    printInfo("Installation pour GPS HOST")
    print("")
    
    -- Demande les coordonnees
    setColor(colors.yellow)
    print("Entrez les coordonnees de CE computer:")
    print("(Utilisez F3 dans Minecraft pour les voir)")
    print("")
    setColor(colors.white)
    
    io.write("Coordonnee X: ")
    local x = tonumber(read()) or 0
    
    io.write("Coordonnee Y: ")
    local y = tonumber(read()) or 0
    
    io.write("Coordonnee Z: ")
    local z = tonumber(read()) or 0
    
    print("")
    
    -- Telecharge et modifie le fichier
    io.write("Telechargement de gps_host.lua... ")
    local url = BASE_URL .. "turtle/gps_host.lua"
    local response = http.get(url)
    
    if response then
        local content = response.readAll()
        response.close()
        
        -- Remplace les coordonnees
        content = content:gsub("local X = 0", "local X = " .. x)
        content = content:gsub("local Y = 255", "local Y = " .. y)
        content = content:gsub("local Z = 0", "local Z = " .. z)
        
        -- Sauvegarde en tant que startup.lua
        local file = fs.open("startup.lua", "w")
        if file then
            file.write(content)
            file.close()
            printSuccess("OK")
        else
            printError("Impossible d'ecrire le fichier")
            return false
        end
    else
        printError("Echec du telechargement")
        return false
    end
    
    print("")
    printSuccess("Installation terminee!")
    print("")
    setColor(colors.yellow)
    print("Position configuree: " .. x .. ", " .. y .. ", " .. z)
    print("")
    print("Le GPS demarrera automatiquement")
    print("au prochain redemarrage.")
    print("")
    print("Pour demarrer maintenant: reboot")
    setColor(colors.white)
    
    return true
end

-- Menu de selection pour les cas ambigus
local function showMenu()
    print("Que voulez-vous installer?")
    print("")
    setColor(colors.yellow)
    print("  1. Serveur (avec moniteur)")
    print("  2. GPS Host")
    print("  3. Annuler")
    setColor(colors.white)
    print("")
    io.write("Choix [1-3]: ")
    
    local choice = read()
    print("")
    
    if choice == "1" then
        return installServer()
    elseif choice == "2" then
        return installGPS()
    else
        printInfo("Installation annulee")
        return false
    end
end

-- Verifie la connexion internet
local function checkInternet()
    local response = http.get("https://raw.githubusercontent.com")
    if response then
        response.close()
        return true
    end
    return false
end

-- Programme principal
local function main()
    printHeader()
    
    -- Verifie la configuration
    if GITHUB_USER == "VOTRE_USERNAME" then
        printError("Configuration requise!")
        print("")
        print("Editez ce fichier et modifiez:")
        setColor(colors.yellow)
        print("  GITHUB_USER = \"votre_username\"")
        print("  GITHUB_REPO = \"votre_repo\"")
        setColor(colors.white)
        print("")
        return
    end
    
    -- Verifie la connexion
    printInfo("Verification de la connexion...")
    if not checkInternet() then
        printError("Pas de connexion internet!")
        print("")
        print("Verifiez que HTTP est active dans")
        print("la configuration de ComputerCraft.")
        return
    end
    printSuccess("Connexion OK")
    print("")
    
    -- Detecte le type de machine
    local machineType = detectMachine()
    
    if machineType == "turtle" then
        installTurtle()
    elseif machineType == "server" then
        installServer()
    elseif machineType == "gps_or_server" then
        -- Cas ambigu - demande a l'utilisateur
        printWarning("Type de machine ambigu")
        print("")
        showMenu()
    elseif machineType == "pocket" then
        printError("Les Pocket Computers ne sont pas supportes")
    else
        -- Computer sans peripheriques detectes
        printWarning("Aucun peripherique detecte")
        print("")
        showMenu()
    end
    
    print("")
end

-- Lance le programme
main()
