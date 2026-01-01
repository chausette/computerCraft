-- ============================================
-- INSTALL_TURTLE.lua
-- Script d'installation pour la Turtle
-- ============================================
-- Utilisation:
-- 1. pastebin get <CODE> install
-- 2. install
-- ============================================

print("=================================")
print("  INSTALLATION TURTLE BUILDER")
print("=================================")
print("")

-- URLs des fichiers (remplacer par vos codes pastebin)
local files = {
    {name = "nbt.lua", pastebin = "PASTE_NBT_CODE_HERE"},
    {name = "movement.lua", pastebin = "PASTE_MOVEMENT_CODE_HERE"},
    {name = "builder.lua", pastebin = "PASTE_BUILDER_CODE_HERE"},
}

-- Telecharge un fichier depuis pastebin
local function download(name, code)
    print("Telechargement de " .. name .. "...")
    
    if code == "PASTE_NBT_CODE_HERE" or 
       code == "PASTE_MOVEMENT_CODE_HERE" or
       code == "PASTE_BUILDER_CODE_HERE" then
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
    print("Pour demarrer: builder")
else
    print("Installation incomplete.")
    print("Verifiez les codes pastebin.")
end
