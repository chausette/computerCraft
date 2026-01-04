-- ============================================
-- Potion Maker - Programme Principal
-- Système automatique de brassage de potions
-- Version corrigée
-- ============================================

-- Charger les modules
local Config = require("modules.config")
local Recipes = require("modules.recipes")
local Inventory = require("modules.inventory")
local Brewing = require("modules.brewing")
local Queue = require("modules.queue")
local UI = require("modules.ui")
local Network = require("modules.network")
local Sound = require("modules.sound")

-- Variables globales
local config = nil
local recipes = nil
local monitor = nil
local running = true

-- Initialisation
local function init()
    term.clear()
    term.setCursorPos(1, 1)
    print("Potion Maker - Demarrage...")
    print("")
    
    -- Charger la configuration
    config = Config.load()
    if not config then
        print("ERREUR: Configuration non trouvee!")
        print("Lancez 'wizard' pour configurer le systeme.")
        return false
    end
    
    -- Valider la configuration
    local valid, errors = Config.validate(config)
    if not valid then
        print("ERREUR: Configuration invalide!")
        for _, err in ipairs(errors) do
            print("  - " .. err)
        end
        print("")
        print("Lancez 'wizard' pour reconfigurer.")
        return false
    end
    
    print("Configuration chargee.")
    
    -- Charger les recettes
    recipes = Recipes.load()
    print("Recettes chargees: " .. #Recipes.getPotionList(recipes) .. " potions")
    
    -- Initialiser les inventaires
    local invOk, invErr = Inventory.init(config)
    if not invOk then
        print("ERREUR Inventaire: " .. (invErr or "inconnu"))
        return false
    end
    print("Inventaires connectes.")
    
    -- Initialiser les alambics
    local brewOk, brewMsg = Brewing.init(config)
    if not brewOk then
        print("ERREUR Alambics: " .. (brewMsg or "inconnu"))
        return false
    end
    print("Alambics: " .. Brewing.getCount())
    
    -- Charger la file d'attente
    Queue.load()
    local counts = Queue.count()
    print("File d'attente: " .. counts.pending .. " en attente")
    
    -- Initialiser le moniteur
    if config.peripherals.monitor then
        monitor = peripheral.wrap(config.peripherals.monitor)
        if monitor then
            monitor.setTextScale(0.5)
            print("Moniteur connecte.")
        end
    end
    
    -- Initialiser l'UI
    UI.init(config, monitor, recipes)
    
    -- Initialiser le réseau
    if Network.init(config, recipes) then
        print("Reseau: " .. config.network.protocol .. " (canal " .. config.network.channel .. ")")
    else
        print("Reseau: Non disponible")
    end
    
    -- Initialiser le son
    if Sound.init(config) then
        print("Speaker connecte.")
        Sound.startup()
    end
    
    print("")
    print("Systeme pret!")
    sleep(1)
    
    return true
end

-- Traiter les commandes de la file
local function processQueue()
    while running do
        -- Obtenir la prochaine commande
        local command, index = Queue.getNext()
        
        if command then
            -- Trouver un alambic disponible
            local standIndex, stand = Brewing.findAvailableStand()
            
            if standIndex then
                -- Marquer comme en cours
                Queue.markProcessing(command.id)
                
                -- Notifier
                Sound.orderReceived()
                
                -- Calculer les étapes
                local steps, err = Recipes.calculateCraftSteps(
                    recipes,
                    command.potion,
                    command.variant,
                    command.form
                )
                
                if steps then
                    -- Exécuter la recette
                    local ok, result = Brewing.executeRecipe(
                        standIndex,
                        steps,
                        math.min(command.quantity, 3) -- Max 3 par batch
                    )
                    
                    if ok then
                        Queue.markCompleted(command.id, result)
                        Sound.potionComplete()
                        
                        -- Broadcast la notification
                        Network.broadcast({
                            type = "orderComplete",
                            orderId = command.id,
                            produced = result
                        })
                    else
                        Queue.markFailed(command.id, result)
                        Sound.error()
                        
                        Network.broadcast({
                            type = "orderFailed",
                            orderId = command.id,
                            error = result
                        })
                    end
                else
                    Queue.markFailed(command.id, err)
                    Sound.error()
                end
            end
        end
        
        sleep(2)
    end
end

-- Tri automatique du coffre input
local function autoSort()
    while running do
        local sorted = Inventory.sortInput(config)
        local total = sorted.water + sorted.ingredients + sorted.potions
        
        if total > 0 then
            -- Des items ont été triés
            UI.forceRefresh()
        end
        
        sleep(5) -- Vérifier toutes les 5 secondes
    end
end

-- Vérification des stocks bas
local function checkStock()
    while running do
        local alerts = UI.checkLowStock()
        
        if #alerts > 0 then
            Sound.lowStock()
            
            Network.broadcast({
                type = "lowStock",
                alerts = alerts
            })
        end
        
        sleep(60) -- Vérifier toutes les 60 secondes (moins fréquent)
    end
end

-- Mise à jour de l'interface (INTERVAL AUGMENTÉ)
local function updateUI()
    while running do
        UI.draw()
        sleep(1) -- 1 seconde au lieu de 0.5
    end
end

-- Gestion des événements moniteur (CORRIGÉ)
local function handleMonitorEvents()
    while running do
        local event, side, x, y = os.pullEvent()
        
        if event == "monitor_touch" then
            Sound.click()
            local action = UI.handleClick(x, y)
            
            if action then
                if action.type == "order" then
                    -- Passer une commande depuis le moniteur
                    local response = Network.placeOrder({
                        potion = action.potion,
                        variant = action.variant,
                        form = action.form,
                        quantity = action.quantity
                    }, "monitor")
                    
                    if response.success then
                        Sound.orderReceived()
                    else
                        Sound.error()
                    end
                    
                elseif action.type == "distribute" then
                    -- CORRECTION: Distribuer des potions avec displayName
                    local distributed = Inventory.distributePotion(
                        action.displayName,
                        action.count or 1
                    )
                    
                    if distributed > 0 then
                        Sound.notify()
                        UI.forceRefresh()
                    else
                        Sound.error()
                    end
                    
                elseif action.type == "navigate" then
                    UI.forceRefresh()
                end
            end
            
        elseif event == "mouse_scroll" then
            UI.scroll(y > 0 and "down" or "up")
            
        elseif event == "key" then
            if y == keys.q then
                running = false
            end
        end
    end
end

-- Gestion des événements réseau (pocket)
local function handleNetworkEvents()
    while running do
        local senderId, message = rednet.receive(config.network.protocol, 2)
        
        if senderId and message then
            local response = Network.handleRequest(senderId, message)
            Network.notify(senderId, response)
            
            -- Si c'est une commande, mettre à jour l'UI
            if message.action == "order" and response.success then
                Sound.orderReceived()
                UI.forceRefresh()
            end
        end
    end
end

-- Gestion des commandes clavier (terminal)
local function handleTerminal()
    while running do
        term.setCursorPos(1, 1)
        term.clearLine()
        term.write("Potion Maker | Q=Quitter R=Reconfig")
        
        local event, key = os.pullEvent("key")
        
        if key == keys.q then
            running = false
        elseif key == keys.r then
            running = false
            shell.run("wizard.lua")
        end
    end
end

-- Programme principal
local function main()
    if not init() then
        return
    end
    
    -- Exécuter toutes les tâches en parallèle
    parallel.waitForAny(
        processQueue,        -- Traitement de la file
        autoSort,            -- Tri automatique
        checkStock,          -- Vérification des stocks
        updateUI,            -- Mise à jour de l'interface
        handleMonitorEvents, -- Événements moniteur
        handleNetworkEvents, -- Événements réseau
        handleTerminal       -- Commandes terminal
    )
    
    -- Nettoyage
    Network.close()
    
    term.clear()
    term.setCursorPos(1, 1)
    print("Potion Maker arrete.")
end

-- Démarrer
main()
