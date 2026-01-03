-- ============================================
-- Installateur MineColonies Dashboard Pro
-- Execute: wget run https://raw.githubusercontent.com/chausette/computerCraft/master/mycolony/install.lua
-- ============================================

local repo = "https://raw.githubusercontent.com/chausette/computerCraft/master/mycolony/"

print("=================================")
print(" MineColonies Dashboard Pro v4")
print(" Installateur")
print("=================================")
print("")

-- Telecharger le fichier principal
print("[1/2] Telechargement du dashboard...")
local ok, err = pcall(function()
    shell.run("wget", repo .. "colony_pro_v4.lua", "colony_pro_v4.lua")
end)

if not ok then
    print("ERREUR: " .. tostring(err))
    print("Verifiez votre connexion HTTP.")
    return
end

print("[2/2] Installation terminee!")
print("")
print("=================================")
print(" Pour lancer le dashboard:")
print(" > colony_pro_v4")
print("=================================")
print("")
print("Materiel requis:")
print(" - Moniteur 3x2 (Advanced)")
print(" - Colony Integrator")
print(" - Speaker (optionnel)")
print(" - Disk Drive (optionnel)")
