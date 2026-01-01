-- ============================================
-- INSTALL_SERVER.lua
-- Script d'installation pour l'Advanced Computer
-- ============================================
-- Utilisation:
-- 1. pastebin get <CODE> install
-- 2. install
-- ============================================

print("=================================")
print("  INSTALLATION SERVER BUILDER")
print("=================================")
print("")

-- URLs des fichiers (remplacer par vos codes pastebin)
local files = {
    {name = "ui.lua", pastebin = "PASTE_UI_CODE_HERE"},
    {name = "server.lua", pastebin = "PASTE_SERVER_CODE_HERE"},
}

-- Telecharge un fichier depuis pastebin
local function download(name, code)
    print("Telechargement de " .. name .. "...")
    
    if code == "PASTE_UI_CODE_HERE" or 
       code == "PASTE_SERVER_CODE_HERE" then
        print("  ERREUR: Code pastebin non configure!")
        print("  Editez ce script et ajoutez vos codes.")
        return false
    end
    
    local url = "https://pastebin.com/raw/" .. code
    local response = http.get(url)
    
    if response then
        local content = response.readAll()
        response.close()
        
        local file = fs.open(name, "w")
        file.write(content)
        file.close()
        
        print("  OK!")
        return true
    else
        print("  ERREUR: Impossible de telecharger!")
        return false
    end
end

-- Cree le dossier schematics
if not fs.exists("schematics") then
    fs.makeDir("schematics")
    print("Dossier schematics cree")
end

-- Installation
local success = true
for _, file in ipairs(files) do
    if not download(file.name, file.pastebin) then
        success = false
    end
end

print("")

if success then
    print("Installation terminee!")
    print("")
    print("Pour demarrer: server")
    print("")
    print("N'oubliez pas de placer vos")
    print("schematics dans le dossier")
    print("'schematics/'")
else
    print("Installation incomplete.")
    print("Verifiez les codes pastebin.")
end
