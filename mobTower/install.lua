-- ============================================
-- MOB TOWER MANAGER v1.3 - Installer
-- Version 1.21 NeoForge
-- ============================================

-- CONFIGURATION - Modifie ces lignes avec ton repo GitHub
local GITHUB_USER = "chausette"
local GITHUB_REPO = "computerCraft"
local BRANCH = "master"

local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. BRANCH .. "/mobTower"

local FILES = {
    { url = "/mobTower.lua", dest = "/mobTower/mobTower.lua" },
    { url = "/startup.lua", dest = "/startup.lua" },
}

-- Couleurs
local function setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

-- Header
local function header()
    term.clear()
    term.setCursorPos(1, 1)
    setColor(colors.cyan)
    print("============================================")
    print("   MOB TOWER MANAGER v1.1 - Installer")
    print("   Version 1.21 NeoForge")
    print("============================================")
    setColor(colors.white)
    print("")
end

-- Créer dossier
local function ensureDir(path)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
end

-- Télécharger fichier
local function downloadFile(url, dest)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        local dir = fs.getDir(dest)
        if dir and dir ~= "" then
            ensureDir(dir)
        end
        local file = fs.open(dest, "w")
        if file then
            file.write(content)
            file.close()
            return true
        end
    end
    return false
end

-- Vérifier HTTP
local function checkHTTP()
    if not http then
        setColor(colors.red)
        print("ERREUR: HTTP n'est pas active!")
        print("")
        setColor(colors.yellow)
        print("Pour activer HTTP:")
        print("1. Ouvrez le fichier:")
        print("   config/computercraft-server.toml")
        print("2. Trouvez: http { enabled = false }")
        print("3. Changez en: http { enabled = true }")
        print("4. Redemarrez le serveur/jeu")
        setColor(colors.white)
        return false
    end
    return true
end

-- Menu principal
local function mainMenu()
    header()
    print("Que voulez-vous faire?")
    print("")
    setColor(colors.lime)
    print("  1. Installer / Mettre a jour")
    setColor(colors.red)
    print("  2. Desinstaller")
    setColor(colors.lightGray)
    print("  3. Quitter")
    setColor(colors.white)
    print("")
    write("Choix (1-3): ")
    return tonumber(read())
end

-- Installation
local function install()
    header()
    setColor(colors.lime)
    print("INSTALLATION")
    setColor(colors.white)
    print("")
    
    -- Info mods
    setColor(colors.cyan)
    print("Mods requis:")
    print("  - CC: Tweaked")
    print("  - Advanced Peripherals (optionnel)")
    setColor(colors.white)
    print("")
    
    -- Créer dossiers
    print("Creation des dossiers...")
    ensureDir("/mobTower")
    ensureDir("/mobTower/data")
    
    -- Télécharger
    print("")
    print("Telechargement...")
    print("")
    
    local success = true
    local downloaded = 0
    
    for _, fileInfo in ipairs(FILES) do
        local url = BASE_URL .. fileInfo.url
        local dest = fileInfo.dest
        
        write("  " .. dest .. " ... ")
        
        if downloadFile(url, dest) then
            setColor(colors.lime)
            print("OK")
            downloaded = downloaded + 1
        else
            setColor(colors.red)
            print("ECHEC")
            success = false
        end
        setColor(colors.white)
    end
    
    -- Résultat
    print("")
    print("============================================")
    
    if success then
        setColor(colors.lime)
        print("Installation terminee!")
        setColor(colors.white)
        print("")
        print("Pour demarrer maintenant:")
        setColor(colors.cyan)
        print("  /mobTower/mobTower.lua")
        setColor(colors.white)
        print("")
        print("Le programme demarrera automatiquement")
        print("au prochain reboot de l'ordinateur.")
        print("")
        setColor(colors.yellow)
        print("Le Setup Wizard vous guidera pour")
        print("configurer vos peripheriques.")
    else
        setColor(colors.red)
        print("Installation incomplete!")
        setColor(colors.white)
        print("Verifiez votre connexion internet.")
    end
    
    setColor(colors.white)
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
    
    return success
end

-- Désinstallation
local function uninstall()
    header()
    setColor(colors.red)
    print("DESINSTALLATION")
    setColor(colors.white)
    print("")
    print("Cela supprimera tous les fichiers")
    print("de Mob Tower Manager.")
    print("")
    setColor(colors.yellow)
    print("Confirmer? (o/n)")
    setColor(colors.white)
    
    local confirm = read()
    if confirm:lower() ~= "o" then
        print("Annule.")
        sleep(1)
        return
    end
    
    print("")
    print("Suppression...")
    
    if fs.exists("/mobTower") then
        fs.delete("/mobTower")
        setColor(colors.lime)
        print("  [OK] /mobTower/")
    end
    
    if fs.exists("/startup.lua") then
        local file = fs.open("/startup.lua", "r")
        if file then
            local content = file.readAll()
            file.close()
            if content:find("mobTower") then
                fs.delete("/startup.lua")
                print("  [OK] /startup.lua")
            end
        end
    end
    
    setColor(colors.white)
    print("")
    print("Desinstallation terminee.")
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
end

-- Main
local function main()
    if not checkHTTP() then
        print("")
        print("Appuyez sur une touche...")
        os.pullEvent("key")
        return
    end
    
    while true do
        local choice = mainMenu()
        
        if choice == 1 then
            install()
        elseif choice == 2 then
            uninstall()
        elseif choice == 3 then
            term.clear()
            term.setCursorPos(1, 1)
            print("Au revoir!")
            return
        end
    end
end

main()
