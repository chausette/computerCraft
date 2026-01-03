-- ============================================
-- MOB TOWER MANAGER v1.1 - Installer
-- Version 1.21 NeoForge
-- Telecharge et installe depuis GitHub
-- ============================================

local REPO = "chausette/computerCraft"
local BRANCH = "master"
local BASE_PATH = "mobTower"
local BASE_URL = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/" .. BASE_PATH

-- Liste des fichiers à télécharger
local FILES = {
    { path = "mobTower.lua", dest = "mobTower/mobTower.lua" },
    { path = "config.lua", dest = "mobTower/config.lua" },
    { path = "startup.lua", dest = "startup.lua" },
    { path = "lib/utils.lua", dest = "mobTower/lib/utils.lua" },
    { path = "lib/peripherals.lua", dest = "mobTower/lib/peripherals.lua" },
    { path = "lib/storage.lua", dest = "mobTower/lib/storage.lua" },
    { path = "lib/ui.lua", dest = "mobTower/lib/ui.lua" },
}

-- Couleurs
local function setColor(color)
    if term.isColor() then
        term.setTextColor(color)
    end
end

-- Afficher le header
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

-- Créer un dossier si nécessaire
local function ensureDir(path)
    if not fs.exists(path) then
        fs.makeDir(path)
    end
end

-- Télécharger un fichier
local function downloadFile(url, dest)
    local response = http.get(url)
    
    if response then
        local content = response.readAll()
        response.close()
        
        -- Créer le dossier parent si nécessaire
        local dir = fs.getDir(dest)
        if dir and dir ~= "" then
            ensureDir(dir)
        end
        
        -- Écrire le fichier
        local file = fs.open(dest, "w")
        if file then
            file.write(content)
            file.close()
            return true
        end
    end
    
    return false
end

-- Vérifier la connexion HTTP
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

-- Menu principal
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

-- Installation
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
    
    -- Info mods requis
    setColor(colors.cyan)
    print("Mods requis:")
    print("  - CC: Tweaked")
    print("  - Advanced Peripherals")
    setColor(colors.white)
    print("")
    
    -- Créer les dossiers
    print("Creation des dossiers...")
    ensureDir("mobTower")
    ensureDir("mobTower/lib")
    ensureDir("mobTower/data")
    
    -- Sauvegarder la config si mise à jour
    local savedConfig = nil
    if update and fs.exists("mobTower/config.lua") then
        print("Sauvegarde de la configuration...")
        local file = fs.open("mobTower/config.lua", "r")
        if file then
            savedConfig = file.readAll()
            file.close()
        end
    end
    
    -- Sauvegarder les stats si mise à jour
    local savedStats = nil
    if update and fs.exists("mobTower/data/stats.dat") then
        print("Sauvegarde des statistiques...")
        local file = fs.open("mobTower/data/stats.dat", "r")
        if file then
            savedStats = file.readAll()
            file.close()
        end
    end
    
    -- Télécharger les fichiers
    print("")
    print("Telechargement des fichiers...")
    print("")
    
    local success = true
    local downloaded = 0
    local failed = 0
    
    for _, fileInfo in ipairs(FILES) do
        local url = BASE_URL .. "/" .. fileInfo.path
        local dest = fileInfo.dest
        
        -- Ne pas écraser la config en mise à jour
        if update and dest == "mobTower/config.lua" and savedConfig then
            setColor(colors.yellow)
            print("  [SKIP] " .. dest .. " (config preservee)")
            downloaded = downloaded + 1
        else
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
        end
        setColor(colors.white)
    end
    
    -- Restaurer la config si mise à jour
    if update and savedConfig then
        local file = fs.open("mobTower/config.lua", "w")
        if file then
            file.write(savedConfig)
            file.close()
        end
    end
    
    -- Restaurer les stats si mise à jour
    if update and savedStats then
        local file = fs.open("mobTower/data/stats.dat", "w")
        if file then
            file.write(savedStats)
            file.close()
        end
    end
    
    -- Résumé
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
        print("  mobTower/mobTower.lua")
        setColor(colors.white)
        print("")
        print("Le programme demarrera automatiquement")
        print("au prochain redemarrage de l'ordinateur.")
        
        if not update then
            print("")
            setColor(colors.yellow)
            print("Le Setup Wizard se lancera au premier")
            print("demarrage pour configurer les peripheriques.")
            print("")
            print("Materiel necessaire:")
            print("  - 1x Player Detector")
            print("  - 1x Monitor 3x2")
            print("  - 1x Double coffre (collecteur)")
            print("  - 23x Barils (tri)")
            print("  - Wired modems + cables")
        end
    else
        setColor(colors.red)
        print("Installation incomplete!")
        print("")
        setColor(colors.white)
        print("Fichiers telecharges: " .. downloaded)
        print("Echecs: " .. failed)
        print("")
        print("Verifiez votre connexion et reessayez.")
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
    print("Cela supprimera tous les fichiers de")
    print("Mob Tower Manager, y compris:")
    print("  - La configuration")
    print("  - Les statistiques sauvegardees")
    print("")
    setColor(colors.yellow)
    print("Etes-vous sur? (o/n)")
    setColor(colors.white)
    
    local confirm = read()
    if confirm:lower() ~= "o" and confirm:lower() ~= "oui" then
        print("")
        print("Desinstallation annulee.")
        print("")
        print("Appuyez sur une touche...")
        os.pullEvent("key")
        return
    end
    
    print("")
    print("Suppression des fichiers...")
    
    -- Supprimer le dossier mobTower
    if fs.exists("mobTower") then
        fs.delete("mobTower")
        setColor(colors.lime)
        print("  [OK] mobTower/")
    end
    
    -- Supprimer le startup.lua (vérifier si c'est le nôtre)
    if fs.exists("startup.lua") then
        local file = fs.open("startup.lua", "r")
        if file then
            local content = file.readAll()
            file.close()
            
            if content:find("mobTower") then
                fs.delete("startup.lua")
                print("  [OK] startup.lua")
            else
                setColor(colors.yellow)
                print("  [SKIP] startup.lua (modifie)")
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

-- Point d'entrée principal
local function main()
    -- Vérifier HTTP
    if not checkHTTP() then
        return
    end
    
    while true do
        local choice = mainMenu()
        
        if choice == 1 then
            -- Nouvelle installation
            if fs.exists("mobTower") then
                header()
                setColor(colors.yellow)
                print("Une installation existe deja!")
                print("")
                print("Voulez-vous la remplacer? (o/n)")
                setColor(colors.white)
                
                local confirm = read()
                if confirm:lower() == "o" or confirm:lower() == "oui" then
                    fs.delete("mobTower")
                    install(false)
                end
            else
                install(false)
            end
            
        elseif choice == 2 then
            -- Mise à jour
            if not fs.exists("mobTower") then
                header()
                setColor(colors.red)
                print("Aucune installation trouvee!")
                print("")
                print("Utilisez l'option 1 pour installer.")
                setColor(colors.white)
                print("")
                print("Appuyez sur une touche...")
                os.pullEvent("key")
            else
                install(true)
            end
            
        elseif choice == 3 then
            -- Désinstaller
            uninstall()
            
        elseif choice == 4 then
            -- Quitter
            term.clear()
            term.setCursorPos(1, 1)
            print("Au revoir!")
            return
        end
    end
end

-- Lancer l'installer
main()
