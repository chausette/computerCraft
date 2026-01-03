-- ============================================
-- MOB TOWER MANAGER v1.1 - Installer
-- Version 1.21 NeoForge
-- ============================================

local REPO = "chausette/computerCraft"
local BRANCH = "master"
local BASE_URL = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/mobTower"

local FILES = {
    { path = "/mobTower.lua", dest = "/mobTower/mobTower.lua" },
    { path = "/config.lua", dest = "/mobTower/config.lua" },
    { path = "/startup.lua", dest = "/startup.lua" },
    { path = "/lib/utils.lua", dest = "/mobTower/lib/utils.lua" },
    { path = "/lib/peripherals.lua", dest = "/mobTower/lib/peripherals.lua" },
    { path = "/lib/storage.lua", dest = "/mobTower/lib/storage.lua" },
    { path = "/lib/ui.lua", dest = "/mobTower/lib/ui.lua" },
}

local function setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

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

local function ensureDir(path)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
end

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

local function checkHTTP()
    if not http then
        setColor(colors.red)
        print("ERREUR: HTTP n'est pas active!")
        print("")
        setColor(colors.yellow)
        print("Pour activer HTTP:")
        print("1. Ouvrez computercraft-server.toml")
        print("2. Trouvez 'http_enable'")
        print("3. Mettez-le a true")
        print("4. Redemarrez le serveur")
        setColor(colors.white)
        return false
    end
    return true
end

local function mainMenu()
    header()
    
    print("Que voulez-vous faire?")
    print("")
    setColor(colors.lime)
    print("  1. Nouvelle installation")
    setColor(colors.yellow)
    print("  2. Mise a jour")
    setColor(colors.red)
    print("  3. Desinstaller")
    setColor(colors.lightGray)
    print("  4. Quitter")
    setColor(colors.white)
    print("")
    write("Choix (1-4): ")
    
    local choice = read()
    return tonumber(choice)
end

local function install(update)
    header()
    
    if update then
        setColor(colors.yellow)
        print("MISE A JOUR")
    else
        setColor(colors.lime)
        print("INSTALLATION")
    end
    setColor(colors.white)
    print("")
    
    setColor(colors.cyan)
    print("Mods requis:")
    print("  - CC: Tweaked")
    print("  - Advanced Peripherals")
    setColor(colors.white)
    print("")
    
    print("Creation des dossiers...")
    ensureDir("/mobTower")
    ensureDir("/mobTower/lib")
    ensureDir("/mobTower/data")
    
    -- Sauvegarder les données si mise à jour
    local savedData = nil
    if update and fs.exists("/mobTower/data/config.dat") then
        print("Sauvegarde de la configuration...")
        local file = fs.open("/mobTower/data/config.dat", "r")
        if file then
            savedData = file.readAll()
            file.close()
        end
    end
    
    local savedStats = nil
    if update and fs.exists("/mobTower/data/stats.dat") then
        print("Sauvegarde des statistiques...")
        local file = fs.open("/mobTower/data/stats.dat", "r")
        if file then
            savedStats = file.readAll()
            file.close()
        end
    end
    
    print("")
    print("Telechargement des fichiers...")
    print("")
    
    local success = true
    local downloaded = 0
    local failed = 0
    
    for _, fileInfo in ipairs(FILES) do
        local url = BASE_URL .. fileInfo.path
        local dest = fileInfo.dest
        
        write("  " .. dest .. " ... ")
        
        if downloadFile(url, dest) then
            setColor(colors.lime)
            print("OK")
            downloaded = downloaded + 1
        else
            setColor(colors.red)
            print("ECHEC")
            failed = failed + 1
            success = false
        end
        setColor(colors.white)
    end
    
    -- Restaurer les données
    if update and savedData then
        local file = fs.open("/mobTower/data/config.dat", "w")
        if file then
            file.write(savedData)
            file.close()
        end
    end
    
    if update and savedStats then
        local file = fs.open("/mobTower/data/stats.dat", "w")
        if file then
            file.write(savedStats)
            file.close()
        end
    end
    
    print("")
    print("============================================")
    if success then
        setColor(colors.lime)
        print("Installation terminee avec succes!")
        print("")
        setColor(colors.white)
        print("Fichiers installes: " .. downloaded)
        print("")
        print("Pour demarrer:")
        setColor(colors.cyan)
        print("  /mobTower/mobTower.lua")
        setColor(colors.white)
        print("")
        print("Le programme demarrera automatiquement")
        print("au prochain redemarrage.")
        
        if not update then
            print("")
            setColor(colors.yellow)
            print("Le Setup Wizard se lancera au premier")
            print("demarrage pour configurer les peripheriques.")
        end
    else
        setColor(colors.red)
        print("Installation incomplete!")
        setColor(colors.white)
        print("Fichiers telecharges: " .. downloaded)
        print("Echecs: " .. failed)
    end
    setColor(colors.white)
    
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
    
    return success
end

local function uninstall()
    header()
    
    setColor(colors.red)
    print("DESINSTALLATION")
    setColor(colors.white)
    print("")
    print("Cela supprimera tous les fichiers.")
    print("")
    setColor(colors.yellow)
    print("Etes-vous sur? (o/n)")
    setColor(colors.white)
    
    local confirm = read()
    if confirm:lower() ~= "o" then
        print("Annule.")
        print("")
        print("Appuyez sur une touche...")
        os.pullEvent("key")
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

local function main()
    if not checkHTTP() then
        return
    end
    
    while true do
        local choice = mainMenu()
        
        if choice == 1 then
            if fs.exists("/mobTower") then
                header()
                setColor(colors.yellow)
                print("Une installation existe deja!")
                print("La remplacer? (o/n)")
                setColor(colors.white)
                
                local confirm = read()
                if confirm:lower() == "o" then
                    fs.delete("/mobTower")
                    install(false)
                end
            else
                install(false)
            end
            
        elseif choice == 2 then
            if not fs.exists("/mobTower") then
                header()
                setColor(colors.red)
                print("Aucune installation trouvee!")
                setColor(colors.white)
                print("")
                print("Appuyez sur une touche...")
                os.pullEvent("key")
            else
                install(true)
            end
            
        elseif choice == 3 then
            uninstall()
            
        elseif choice == 4 then
            term.clear()
            term.setCursorPos(1, 1)
            print("Au revoir!")
            return
        end
    end
end

main()
