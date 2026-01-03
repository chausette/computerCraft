-- RadioCraft Installer / Updater
-- Installe ou met a jour RadioCraft depuis GitHub
-- Usage: pastebin run XXXXX [install|update|uninstall]

local REPO = "chausette/computerCraft"
local BRANCH = "master"
local BASE_PATH = "radio/"
local BASE_URL = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/" .. BASE_PATH
local INSTALL_PATH = "/radiocraft"
local VERSION_FILE = INSTALL_PATH .. "/.version"

-- Liste des fichiers a telecharger
local FILES = {
    -- Programme principal
    {remote = "radiocraft/startup.lua", local_path = "/radiocraft/startup.lua"},
    {remote = "radiocraft/diagnostic.lua", local_path = "/radiocraft/diagnostic.lua"},
    
    -- Bibliotheques
    {remote = "radiocraft/lib/speakers.lua", local_path = "/radiocraft/lib/speakers.lua"},
    {remote = "radiocraft/lib/player.lua", local_path = "/radiocraft/lib/player.lua"},
    {remote = "radiocraft/lib/ambiance.lua", local_path = "/radiocraft/lib/ambiance.lua"},
    {remote = "radiocraft/lib/composer.lua", local_path = "/radiocraft/lib/composer.lua"},
    {remote = "radiocraft/lib/ui.lua", local_path = "/radiocraft/lib/ui.lua"},
    
    -- Musiques exemples
    {remote = "radiocraft/music/demo.rcm", local_path = "/radiocraft/music/demo.rcm"},
    {remote = "radiocraft/music/epic_adventure.rcm", local_path = "/radiocraft/music/epic_adventure.rcm"},
}

-- Dossiers a creer
local DIRS = {
    "/radiocraft",
    "/radiocraft/lib",
    "/radiocraft/music",
    "/radiocraft/stations",
}

-- Couleurs
local function setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

-- Affiche le header
local function header()
    term.clear()
    term.setCursorPos(1, 1)
    setColor(colors.cyan)
    print("========================================")
    print("       RadioCraft Installer v1.1")
    print("========================================")
    setColor(colors.white)
    print("")
end

-- Affiche un message de succes
local function success(msg)
    setColor(colors.lime)
    print("[OK] " .. msg)
    setColor(colors.white)
end

-- Affiche un message d'erreur
local function err(msg)
    setColor(colors.red)
    print("[ERREUR] " .. msg)
    setColor(colors.white)
end

-- Affiche un message d'info
local function info(msg)
    setColor(colors.yellow)
    print("[INFO] " .. msg)
    setColor(colors.white)
end

-- Affiche la progression
local function progress(current, total, filename)
    local pct = math.floor((current / total) * 100)
    local bar = string.rep("=", math.floor(pct / 5)) .. string.rep(" ", 20 - math.floor(pct / 5))
    term.clearLine()
    term.setCursorPos(1, select(2, term.getCursorPos()))
    setColor(colors.lightBlue)
    write("[" .. bar .. "] " .. pct .. "% ")
    setColor(colors.gray)
    write(filename)
    setColor(colors.white)
end

-- Verifie la connexion HTTP
local function checkHTTP()
    if not http then
        err("HTTP API non disponible!")
        print("Activez l'API HTTP dans la config:")
        print("  computercraft.cfg -> http.enabled = true")
        return false
    end
    return true
end

-- Telecharge un fichier
local function downloadFile(url, path)
    local response = http.get(url)
    if not response then
        return false, "Impossible de telecharger"
    end
    
    local content = response.readAll()
    response.close()
    
    if not content or content == "" then
        return false, "Fichier vide"
    end
    
    -- Verifie si c'est une erreur 404
    if string.find(content, "404") and string.find(content, "Not Found") then
        return false, "Fichier non trouve (404)"
    end
    
    -- Cree le dossier parent si necessaire
    local dir = fs.getDir(path)
    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
    
    local file = fs.open(path, "w")
    if not file then
        return false, "Impossible d'ecrire"
    end
    
    file.write(content)
    file.close()
    
    return true
end

-- Cree les dossiers
local function createDirs()
    for _, dir in ipairs(DIRS) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end
    end
end

-- Telecharge tous les fichiers
local function downloadAll()
    local total = #FILES
    local errors = {}
    
    print("")
    
    for i, file in ipairs(FILES) do
        local url = BASE_URL .. file.remote
        progress(i, total, fs.getName(file.local_path))
        
        local ok, error = downloadFile(url, file.local_path)
        if not ok then
            table.insert(errors, {file = file.local_path, error = error})
        end
        
        sleep(0.1) -- Petit delai pour eviter le rate limiting
    end
    
    print("")
    print("")
    
    return errors
end

-- Sauvegarde la version
local function saveVersion()
    local file = fs.open(VERSION_FILE, "w")
    if file then
        file.write(os.date("%Y-%m-%d %H:%M:%S"))
        file.close()
    end
end

-- Lit la version installee
local function getInstalledVersion()
    if not fs.exists(VERSION_FILE) then
        return nil
    end
    
    local file = fs.open(VERSION_FILE, "r")
    if file then
        local version = file.readAll()
        file.close()
        return version
    end
    return nil
end

-- Installation
local function install()
    header()
    
    if not checkHTTP() then
        return false
    end
    
    if fs.exists(INSTALL_PATH .. "/startup.lua") then
        setColor(colors.orange)
        print("RadioCraft est deja installe!")
        print("Utilisez 'update' pour mettre a jour.")
        print("")
        setColor(colors.white)
        write("Reinstaller? (o/n): ")
        local answer = read()
        if answer:lower() ~= "o" and answer:lower() ~= "oui" then
            print("Installation annulee.")
            return false
        end
    end
    
    info("Creation des dossiers...")
    createDirs()
    success("Dossiers crees")
    
    info("Telechargement des fichiers...")
    local errors = downloadAll()
    
    if #errors == 0 then
        saveVersion()
        success("Installation terminee!")
        print("")
        setColor(colors.lime)
        print("Pour lancer RadioCraft:")
        setColor(colors.white)
        print("  cd /radiocraft")
        print("  startup")
        print("")
        print("Ou ajoutez au demarrage:")
        print("  edit /startup.lua")
        print("  -> shell.run('/radiocraft/startup.lua')")
    else
        err("Installation terminee avec " .. #errors .. " erreur(s):")
        for _, e in ipairs(errors) do
            print("  - " .. e.file .. ": " .. e.error)
        end
    end
    
    return #errors == 0
end

-- Mise a jour
local function update()
    header()
    
    if not checkHTTP() then
        return false
    end
    
    local installed = getInstalledVersion()
    if not installed then
        info("RadioCraft n'est pas installe.")
        print("Lancement de l'installation...")
        sleep(1)
        return install()
    end
    
    print("Version installee: " .. installed)
    print("")
    info("Telechargement des mises a jour...")
    
    createDirs()
    local errors = downloadAll()
    
    if #errors == 0 then
        saveVersion()
        success("Mise a jour terminee!")
        print("")
        print("Redemarrez RadioCraft pour appliquer")
        print("les changements.")
    else
        err("Mise a jour terminee avec " .. #errors .. " erreur(s):")
        for _, e in ipairs(errors) do
            print("  - " .. e.file .. ": " .. e.error)
        end
    end
    
    return #errors == 0
end

-- Desinstallation
local function uninstall()
    header()
    
    if not fs.exists(INSTALL_PATH) then
        err("RadioCraft n'est pas installe.")
        return false
    end
    
    setColor(colors.orange)
    print("ATTENTION: Cela supprimera RadioCraft")
    print("et toutes vos compositions locales!")
    print("")
    setColor(colors.white)
    write("Confirmer la suppression? (oui/non): ")
    local answer = read()
    
    if answer:lower() ~= "oui" then
        print("Desinstallation annulee.")
        return false
    end
    
    info("Suppression en cours...")
    fs.delete(INSTALL_PATH)
    success("RadioCraft a ete desinstalle.")
    
    return true
end

-- Affiche le statut
local function status()
    header()
    
    local installed = getInstalledVersion()
    
    if installed then
        setColor(colors.lime)
        print("RadioCraft est installe")
        setColor(colors.white)
        print("  Version: " .. installed)
        print("  Chemin: " .. INSTALL_PATH)
        print("")
        
        -- Compte les fichiers
        local musicCount = 0
        if fs.exists(INSTALL_PATH .. "/music") then
            for _, f in ipairs(fs.list(INSTALL_PATH .. "/music")) do
                if string.match(f, "%.rcm$") then
                    musicCount = musicCount + 1
                end
            end
        end
        print("  Musiques: " .. musicCount .. " fichier(s) .rcm")
    else
        setColor(colors.red)
        print("RadioCraft n'est pas installe")
        setColor(colors.white)
    end
end

-- Affiche l'aide
local function showHelp()
    header()
    print("Usage: installer [commande]")
    print("")
    print("Commandes:")
    print("  install   - Installe RadioCraft")
    print("  update    - Met a jour RadioCraft")
    print("  uninstall - Supprime RadioCraft")
    print("  status    - Affiche le statut")
    print("  help      - Affiche cette aide")
    print("")
    print("Sans argument: menu interactif")
end

-- Menu interactif
local function menu()
    while true do
        header()
        
        local installed = fs.exists(INSTALL_PATH .. "/startup.lua")
        
        if installed then
            setColor(colors.lime)
            print("  [Installe]")
        else
            setColor(colors.red)
            print("  [Non installe]")
        end
        setColor(colors.white)
        print("")
        
        print("1. Installer / Reinstaller")
        print("2. Mettre a jour")
        print("3. Desinstaller")
        print("4. Statut")
        print("5. Quitter")
        print("")
        write("Choix: ")
        
        local choice = read()
        
        if choice == "1" then
            install()
            print("")
            print("Appuyez sur une touche...")
            os.pullEvent("key")
        elseif choice == "2" then
            update()
            print("")
            print("Appuyez sur une touche...")
            os.pullEvent("key")
        elseif choice == "3" then
            uninstall()
            print("")
            print("Appuyez sur une touche...")
            os.pullEvent("key")
        elseif choice == "4" then
            status()
            print("")
            print("Appuyez sur une touche...")
            os.pullEvent("key")
        elseif choice == "5" then
            term.clear()
            term.setCursorPos(1, 1)
            return
        end
    end
end

-- Point d'entree
local args = {...}
local command = args[1]

if command == "install" then
    install()
elseif command == "update" then
    update()
elseif command == "uninstall" then
    uninstall()
elseif command == "status" then
    status()
elseif command == "help" or command == "-h" or command == "--help" then
    showHelp()
elseif command then
    err("Commande inconnue: " .. command)
    showHelp()
else
    menu()
end
