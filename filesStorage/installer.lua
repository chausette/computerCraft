-- ============================================
-- INSTALLATEUR DU SYSTEME DE STOCKAGE
-- Executez: pastebin run XXXXXX
-- ou copiez ce fichier et executez-le
-- ============================================

local GITHUB_BASE = "https://raw.githubusercontent.com/votre-repo/storage-system/main/"

-- Fichiers à télécharger pour le SERVEUR
local SERVER_FILES = {
    "config.lua",
    "storage.lua",
    "network.lua",
    "ui_monitor.lua",
    "startup.lua"
}

-- Fichiers pour le POCKET
local POCKET_FILES = {
    "pocket_client.lua"
}

local function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

local function printCentered(text)
    local w = term.getSize()
    local x = math.floor((w - #text) / 2) + 1
    term.setCursorPos(x, select(2, term.getCursorPos()))
    print(text)
end

local function printHeader()
    clearScreen()
    print(string.rep("=", 40))
    printCentered("INSTALLATION STOCKAGE")
    print(string.rep("=", 40))
    print("")
end

local function downloadFile(url, path)
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(path, "w")
        file.write(content)
        file.close()
        return true
    end
    return false
end

local function installServer()
    printHeader()
    print("Installation SERVEUR")
    print("")
    
    -- Crée le dossier de données
    if not fs.exists("storage_data") then
        fs.makeDir("storage_data")
    end
    
    print("Telechargement des fichiers...")
    print("")
    
    local success = true
    for _, filename in ipairs(SERVER_FILES) do
        term.write("  " .. filename .. "... ")
        
        -- Simule le téléchargement (à adapter selon votre méthode)
        -- local ok = downloadFile(GITHUB_BASE .. filename, filename)
        
        -- Pour l'instant, vérifie si le fichier existe
        if fs.exists(filename) then
            print("OK")
        else
            print("MANQUANT")
            success = false
        end
    end
    
    print("")
    
    if success then
        print("Installation terminee!")
        print("")
        print("Configuration requise:")
        print("1. Editez 'config.lua'")
        print("2. Definissez les noms de vos coffres")
        print("3. Redemarrez l'ordinateur")
    else
        print("Certains fichiers manquent!")
        print("Copiez-les manuellement.")
    end
end

local function installPocket()
    printHeader()
    print("Installation POCKET")
    print("")
    
    term.write("  pocket_client.lua... ")
    
    if fs.exists("pocket_client.lua") then
        -- Renomme en startup pour lancement auto
        if fs.exists("startup.lua") then
            fs.delete("startup.lua")
        end
        fs.copy("pocket_client.lua", "startup.lua")
        print("OK")
        print("")
        print("Installation terminee!")
        print("Redemarrez le pocket.")
    else
        print("MANQUANT")
        print("")
        print("Copiez le fichier manuellement.")
    end
end

local function configWizard()
    printHeader()
    print("ASSISTANT DE CONFIGURATION")
    print("")
    
    -- Liste les périphériques
    print("Peripheriques detectes:")
    print("")
    
    local peripherals = peripheral.getNames()
    local chests = {}
    local modems = {}
    local monitors = {}
    
    for _, name in ipairs(peripherals) do
        local pType = peripheral.getType(name)
        
        if pType:find("chest") or pType:find("barrel") then
            table.insert(chests, name)
            print("  [COFFRE] " .. name)
        elseif pType == "modem" then
            table.insert(modems, name)
            print("  [MODEM] " .. name)
        elseif pType == "monitor" then
            table.insert(monitors, name)
            print("  [MONITEUR] " .. name)
        end
    end
    
    print("")
    
    if #chests < 3 then
        print("ATTENTION: Minimum 3 coffres requis")
        print("(entree, sortie, stockage)")
    end
    
    if #modems == 0 then
        print("ATTENTION: Aucun modem detecte")
    end
    
    print("")
    print("Modifiez config.lua avec ces noms.")
    print("")
    print("Exemple de configuration:")
    print("  INPUT_CHEST = \"" .. (chests[1] or "minecraft:chest_0") .. "\"")
    print("  OUTPUT_CHEST = \"" .. (chests[2] or "minecraft:chest_1") .. "\"")
    
    if #monitors > 0 then
        print("  MONITOR_NAME = \"" .. monitors[1] .. "\"")
    end
end

-- Menu principal
local function main()
    while true do
        printHeader()
        
        print("Que voulez-vous installer?")
        print("")
        print("[1] Serveur (ordinateur principal)")
        print("[2] Client Pocket")
        print("[3] Assistant configuration")
        print("[4] Verifier l'installation")
        print("[0] Quitter")
        print("")
        
        term.write("> ")
        local choice = read()
        
        if choice == "1" then
            installServer()
            print("")
            print("Appuyez sur une touche...")
            os.pullEvent("key")
        elseif choice == "2" then
            installPocket()
            print("")
            print("Appuyez sur une touche...")
            os.pullEvent("key")
        elseif choice == "3" then
            configWizard()
            print("")
            print("Appuyez sur une touche...")
            os.pullEvent("key")
        elseif choice == "4" then
            printHeader()
            print("Verification des fichiers...")
            print("")
            
            local files = {"config.lua", "storage.lua", "network.lua", "ui_monitor.lua", "startup.lua"}
            local allOk = true
            
            for _, f in ipairs(files) do
                term.write("  " .. f .. ": ")
                if fs.exists(f) then
                    print("OK")
                else
                    print("MANQUANT")
                    allOk = false
                end
            end
            
            print("")
            if allOk then
                print("Tous les fichiers sont presents!")
            else
                print("Des fichiers manquent.")
            end
            
            print("")
            print("Appuyez sur une touche...")
            os.pullEvent("key")
        elseif choice == "0" then
            clearScreen()
            print("Installation terminee.")
            return
        end
    end
end

main()
