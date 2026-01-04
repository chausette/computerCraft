-- ============================================
-- Potion Maker - Startup
-- Demarrage automatique du systeme
-- ============================================

-- Vérifier si la configuration existe
if not fs.exists("data/config.json") then
    print("Configuration non trouvee.")
    print("Lancement du wizard...")
    sleep(1)
    shell.run("wizard.lua")
else
    -- Démarrer le programme principal
    shell.run("main.lua")
end
