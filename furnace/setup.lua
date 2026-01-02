-- ============================================
-- FURNACE MANAGER - SETUP / INSTALLER
-- https://github.com/chausette/computerCraft
-- ============================================

local VERSION = "2.1"
local GITHUB_BASE = "https://raw.githubusercontent.com/chausette/computerCraft/master/furnace/"

local FILES = {
    { name = "furnace.lua", dest = "furnace" },
    { name = "README.md", dest = "furnace_readme" },
}

local CONFIG_FILE = "furnace_config"

-- Couleurs
local function setColors(bg, fg)
    if term.isColor() then
        term.setBackgroundColor(bg)
        term.setTextColor(fg)
    end
end

local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

local function printCentered(text, y)
    local w, _ = term.getSize()
    local x = math.floor((w - #text) / 2) + 1
    if y then term.setCursorPos(x, y) else term.setCursorPos(x, select(2, term.getCursorPos())) end
    print(text)
end

local function printHeader()
    clear()
    setColors(colors.black, colors.yellow)
    print("============================================")
    printCentered("FURNACE MANAGER v" .. VERSION)
    printCentered("Setup & Installer")
    print("============================================")
    setColors(colors.black, colors.white)
    print("")
end

local function printMenu()
    print("Que voulez-vous faire ?")
    print("")
    setColors(colors.black, colors.lime)
    print("  1. Installer / Mettre a jour")
    setColors(colors.black, colors.cyan)
    print("  2. Configurer les peripheriques")
    setColors(colors.black, colors.orange)
    print("  3. Verifier l'installation")
    setColors(colors.black, colors.magenta)
    print("  4. Voir les peripheriques connectes")
    setColors(colors.black, colors.red)
    print("  5. Desinstaller")
    setColors(colors.black, colors.lightGray)
    print("  6. Quitter")
    setColors(colors.black, colors.white)
    print("")
    write("Choix [1-6]: ")
end

-- ============================================
-- FONCTIONS D'INSTALLATION
-- ============================================

local function downloadFile(url, dest)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(dest, "w")
        file.write(content)
        file.close()
        return true
    end
    return false
end

local function install()
    printHeader()
    setColors(colors.black, colors.lime)
    print("=== INSTALLATION / MISE A JOUR ===")
    setColors(colors.black, colors.white)
    print("")
    
    -- Verifier HTTP
    if not http then
        setColors(colors.black, colors.red)
        print("ERREUR: HTTP n'est pas active!")
        print("")
        print("Activez HTTP dans la config de ComputerCraft:")
        print("  computercraft.cfg -> http_enable = true")
        setColors(colors.black, colors.white)
        print("")
        print("Appuyez sur une touche...")
        os.pullEvent("key")
        return false
    end
    
    print("Telechargement depuis GitHub...")
    print("")
    
    local success = true
    for _, file in ipairs(FILES) do
        write("  " .. file.name .. " ... ")
        local url = GITHUB_BASE .. file.name
        if downloadFile(url, file.dest) then
            setColors(colors.black, colors.lime)
            print("OK")
        else
            setColors(colors.black, colors.red)
            print("ERREUR")
            success = false
        end
        setColors(colors.black, colors.white)
    end
    
    print("")
    
    if success then
        setColors(colors.black, colors.lime)
        print("Installation terminee avec succes!")
        print("")
        setColors(colors.black, colors.yellow)
        print("Commandes disponibles:")
        print("  furnace  - Lancer le gestionnaire")
        print("  setup    - Configuration et mise a jour")
    else
        setColors(colors.black, colors.red)
        print("Certains fichiers n'ont pas pu etre telecharges.")
        print("Verifiez votre connexion internet.")
    end
    
    setColors(colors.black, colors.white)
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
    return success
end

-- ============================================
-- FONCTIONS DE CONFIGURATION
-- ============================================

local function listPeripherals()
    local result = {
        chests = {},
        furnaces = {},
        blastFurnaces = {},
        smokers = {},
        monitors = {}
    }
    
    for _, name in ipairs(peripheral.getNames()) do
        local pType = peripheral.getType(name)
        
        -- Coffres
        if string.find(name, "chest") or string.find(name, "barrel") or
           string.find(pType, "chest") or string.find(pType, "barrel") or
           string.find(name, "shulker") then
            table.insert(result.chests, name)
        
        -- Blast Furnace
        elseif string.find(name, "blast") or string.find(pType, "blast") then
            table.insert(result.blastFurnaces, name)
        
        -- Smoker
        elseif string.find(name, "smoker") or string.find(pType, "smoker") then
            table.insert(result.smokers, name)
        
        -- Furnace normal
        elseif string.find(name, "furnace") or string.find(pType, "furnace") then
            table.insert(result.furnaces, name)
        
        -- Moniteur
        elseif pType == "monitor" or string.find(name, "monitor") then
            table.insert(result.monitors, name)
        end
    end
    
    return result
end

local function showPeripherals()
    printHeader()
    setColors(colors.black, colors.cyan)
    print("=== PERIPHERIQUES CONNECTES ===")
    setColors(colors.black, colors.white)
    print("")
    
    local found = listPeripherals()
    
    local function printList(title, list, color)
        setColors(colors.black, color)
        print(title .. " (" .. #list .. "):")
        setColors(colors.black, colors.white)
        if #list == 0 then
            print("  (aucun)")
        else
            for _, name in ipairs(list) do
                print("  - " .. name)
            end
        end
        print("")
    end
    
    printList("Coffres", found.chests, colors.orange)
    printList("Fours (Furnace)", found.furnaces, colors.red)
    printList("Hauts fourneaux (Blast)", found.blastFurnaces, colors.lightBlue)
    printList("Fumoirs (Smoker)", found.smokers, colors.brown)
    printList("Moniteurs", found.monitors, colors.lime)
    
    local totalFurnaces = #found.furnaces + #found.blastFurnaces + #found.smokers
    setColors(colors.black, colors.yellow)
    print("Total: " .. #found.chests .. " coffres, " .. totalFurnaces .. " fours")
    
    setColors(colors.black, colors.white)
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
end

local function selectFromList(list, prompt)
    print(prompt)
    for i, item in ipairs(list) do
        print("  " .. i .. ". " .. item)
    end
    print("")
    write("Choix (numero): ")
    local input = read()
    local choice = tonumber(input)
    if choice and choice >= 1 and choice <= #list then
        return list[choice]
    end
    return nil
end

local function removeFromList(list, item)
    local newList = {}
    for _, v in ipairs(list) do
        if v ~= item then
            table.insert(newList, v)
        end
    end
    return newList
end

local function configure()
    printHeader()
    setColors(colors.black, colors.cyan)
    print("=== CONFIGURATION ===")
    setColors(colors.black, colors.white)
    print("")
    
    local found = listPeripherals()
    local allFurnaces = {}
    
    -- Combiner tous les fours
    for _, f in ipairs(found.furnaces) do table.insert(allFurnaces, f) end
    for _, f in ipairs(found.blastFurnaces) do table.insert(allFurnaces, f) end
    for _, f in ipairs(found.smokers) do table.insert(allFurnaces, f) end
    
    -- Verifications
    if #found.chests < 3 then
        setColors(colors.black, colors.red)
        print("ERREUR: Il faut au moins 3 coffres!")
        print("")
        print("Requis:")
        print("  - 1 coffre d'entree (items a cuire)")
        print("  - 1 coffre de sortie (items cuits)")
        print("  - 1 coffre de carburant (charbon)")
        print("")
        print("Detectes: " .. #found.chests)
        setColors(colors.black, colors.white)
        print("")
        print("Appuyez sur une touche...")
        os.pullEvent("key")
        return false
    end
    
    if #allFurnaces < 1 then
        setColors(colors.black, colors.red)
        print("ERREUR: Aucun four detecte!")
        print("")
        print("Connectez au moins un four avec un wired modem")
        print("et activez le modem (clic droit).")
        setColors(colors.black, colors.white)
        print("")
        print("Appuyez sur une touche...")
        os.pullEvent("key")
        return false
    end
    
    print("Coffres detectes: " .. #found.chests)
    print("Fours detectes: " .. #allFurnaces)
    print("")
    
    -- Selection des coffres
    local chestList = {}
    for _, c in ipairs(found.chests) do table.insert(chestList, c) end
    
    setColors(colors.black, colors.orange)
    local inputChest = selectFromList(chestList, "Selectionnez le COFFRE D'ENTREE:")
    if not inputChest then
        print("Selection invalide!")
        os.pullEvent("key")
        return false
    end
    print("-> " .. inputChest)
    print("")
    chestList = removeFromList(chestList, inputChest)
    
    setColors(colors.black, colors.lime)
    local outputChest = selectFromList(chestList, "Selectionnez le COFFRE DE SORTIE:")
    if not outputChest then
        print("Selection invalide!")
        os.pullEvent("key")
        return false
    end
    print("-> " .. outputChest)
    print("")
    chestList = removeFromList(chestList, outputChest)
    
    setColors(colors.black, colors.yellow)
    local fuelChest = selectFromList(chestList, "Selectionnez le COFFRE DE CARBURANT:")
    if not fuelChest then
        print("Selection invalide!")
        os.pullEvent("key")
        return false
    end
    print("-> " .. fuelChest)
    print("")
    
    -- Moniteur
    local monitorName = nil
    setColors(colors.black, colors.white)
    if #found.monitors > 0 then
        if #found.monitors == 1 then
            monitorName = found.monitors[1]
            print("Moniteur auto-detecte: " .. monitorName)
        else
            monitorName = selectFromList(found.monitors, "Selectionnez le MONITEUR:")
        end
    else
        print("Aucun moniteur detecte (optionnel)")
    end
    print("")
    
    -- Options supplementaires
    setColors(colors.black, colors.cyan)
    print("=== OPTIONS ===")
    setColors(colors.black, colors.white)
    print("")
    
    write("Activer le routage intelligent? (O/n): ")
    local smartRouting = string.lower(read()) ~= "n"
    
    write("Activer le mode economie carburant? (O/n): ")
    local ecoMode = string.lower(read()) ~= "n"
    
    write("Niveau minimum de carburant par four [8]: ")
    local minFuelInput = read()
    local minFuel = tonumber(minFuelInput) or 8
    
    write("Intervalle de mise a jour en secondes [2]: ")
    local intervalInput = read()
    local interval = tonumber(intervalInput) or 2
    
    -- Sauvegarder
    local config = {
        version = VERSION,
        inputChest = inputChest,
        outputChest = outputChest,
        fuelChest = fuelChest,
        monitor = monitorName,
        furnaces = found.furnaces,
        blastFurnaces = found.blastFurnaces,
        smokers = found.smokers,
        smartRouting = smartRouting,
        ecoMode = ecoMode,
        minFuelLevel = minFuel,
        updateInterval = interval,
        stats = {
            totalCooked = 0,
            startTime = os.epoch("utc"),
            sessionCooked = 0
        }
    }
    
    local file = fs.open(CONFIG_FILE, "w")
    file.write(textutils.serialise(config))
    file.close()
    
    print("")
    setColors(colors.black, colors.lime)
    print("========================================")
    print("  Configuration sauvegardee!")
    print("========================================")
    setColors(colors.black, colors.white)
    print("")
    print("Coffre entree:  " .. inputChest)
    print("Coffre sortie:  " .. outputChest)
    print("Coffre fuel:    " .. fuelChest)
    print("Moniteur:       " .. (monitorName or "Aucun"))
    print("Routage smart:  " .. (smartRouting and "Oui" or "Non"))
    print("Mode eco:       " .. (ecoMode and "Oui" or "Non"))
    print("")
    setColors(colors.black, colors.yellow)
    print("Lancez 'furnace' pour demarrer!")
    setColors(colors.black, colors.white)
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
    return true
end

local function checkInstall()
    printHeader()
    setColors(colors.black, colors.orange)
    print("=== VERIFICATION ===")
    setColors(colors.black, colors.white)
    print("")
    
    local allOk = true
    
    -- Verifier les fichiers
    print("Fichiers:")
    for _, file in ipairs(FILES) do
        write("  " .. file.dest .. " ... ")
        if fs.exists(file.dest) then
            setColors(colors.black, colors.lime)
            print("OK")
        else
            setColors(colors.black, colors.red)
            print("MANQUANT")
            allOk = false
        end
        setColors(colors.black, colors.white)
    end
    
    -- Verifier la config
    print("")
    print("Configuration:")
    write("  " .. CONFIG_FILE .. " ... ")
    if fs.exists(CONFIG_FILE) then
        setColors(colors.black, colors.lime)
        print("OK")
        setColors(colors.black, colors.white)
        
        -- Lire et afficher la config
        local file = fs.open(CONFIG_FILE, "r")
        local config = textutils.unserialise(file.readAll())
        file.close()
        
        if config then
            print("")
            print("  Version config: " .. (config.version or "?"))
            print("  Input:  " .. (config.inputChest or "?"))
            print("  Output: " .. (config.outputChest or "?"))
            print("  Fuel:   " .. (config.fuelChest or "?"))
            
            local totalFurnaces = #(config.furnaces or {}) + 
                                  #(config.blastFurnaces or {}) + 
                                  #(config.smokers or {})
            print("  Fours:  " .. totalFurnaces)
        end
    else
        setColors(colors.black, colors.orange)
        print("NON CONFIGURE")
        allOk = false
    end
    setColors(colors.black, colors.white)
    
    -- Verifier HTTP
    print("")
    print("Systeme:")
    write("  HTTP ... ")
    if http then
        setColors(colors.black, colors.lime)
        print("OK")
    else
        setColors(colors.black, colors.red)
        print("DESACTIVE")
        allOk = false
    end
    setColors(colors.black, colors.white)
    
    write("  Couleurs ... ")
    if term.isColor() then
        setColors(colors.black, colors.lime)
        print("OK (Advanced)")
    else
        setColors(colors.black, colors.orange)
        print("Non (Basic)")
    end
    setColors(colors.black, colors.white)
    
    print("")
    if allOk then
        setColors(colors.black, colors.lime)
        print("Tout est OK! Vous pouvez lancer 'furnace'")
    else
        setColors(colors.black, colors.orange)
        print("Des elements sont manquants.")
        print("Utilisez l'option 1 pour installer.")
    end
    
    setColors(colors.black, colors.white)
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
end

local function uninstall()
    printHeader()
    setColors(colors.black, colors.red)
    print("=== DESINSTALLATION ===")
    setColors(colors.black, colors.white)
    print("")
    print("Cette action va supprimer:")
    print("  - furnace (programme principal)")
    print("  - furnace_readme")
    print("  - furnace_config (configuration)")
    print("")
    setColors(colors.black, colors.yellow)
    write("Confirmer? (oui/NON): ")
    setColors(colors.black, colors.white)
    
    local confirm = string.lower(read())
    if confirm == "oui" or confirm == "o" or confirm == "yes" then
        print("")
        print("Suppression...")
        
        for _, file in ipairs(FILES) do
            if fs.exists(file.dest) then
                fs.delete(file.dest)
                print("  Supprime: " .. file.dest)
            end
        end
        
        if fs.exists(CONFIG_FILE) then
            fs.delete(CONFIG_FILE)
            print("  Supprime: " .. CONFIG_FILE)
        end
        
        print("")
        setColors(colors.black, colors.lime)
        print("Desinstallation terminee.")
        print("Le fichier 'setup' a ete conserve.")
    else
        print("")
        print("Desinstallation annulee.")
    end
    
    setColors(colors.black, colors.white)
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
end

-- ============================================
-- BOUCLE PRINCIPALE
-- ============================================

-- Recuperer les arguments au niveau global
local tArgs = {...}

local function main()
    -- Si lance avec argument "install", installer directement
    if tArgs[1] == "install" or tArgs[1] == "update" then
        install()
        return
    end
    
    while true do
        printHeader()
        printMenu()
        
        local choice = read()
        
        if choice == "1" then
            install()
        elseif choice == "2" then
            configure()
        elseif choice == "3" then
            checkInstall()
        elseif choice == "4" then
            showPeripherals()
        elseif choice == "5" then
            uninstall()
        elseif choice == "6" then
            clear()
            print("Au revoir!")
            return
        end
    end
end

main()
