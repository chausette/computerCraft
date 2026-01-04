-- ============================================
-- Potion Maker - Module UI
-- Interface moniteur 3x2
-- Version corrigée - sans clignotement
-- ============================================

local UI = {}

local Recipes = require("modules.recipes")
local Queue = require("modules.queue")
local Brewing = require("modules.brewing")
local Inventory = require("modules.inventory")

-- Références
local monitor = nil
local config = nil
local recipes = nil

-- État de l'UI
local currentScreen = "dashboard"
local selectedPotion = nil
local selectedVariant = "normal"
local selectedForm = "normal"
local selectedQuantity = 3
local scrollOffset = 0
local potionList = {}
local lowStockAlerts = {}
local lastScreen = nil

-- Couleurs du thème
local theme = {
    bg = colors.black,
    header = colors.cyan,
    text = colors.white,
    textDim = colors.lightGray,
    success = colors.green,
    warning = colors.orange,
    error = colors.red,
    button = colors.gray,
    buttonActive = colors.blue,
    highlight = colors.yellow
}

-- Dimensions du moniteur
local width, height = 0, 0

-- Boutons pour les clics
local buttons = {}

-- Initialiser l'UI
function UI.init(cfg, mon, rec)
    config = cfg
    monitor = mon
    recipes = rec
    potionList = Recipes.getPotionList(recipes)
    
    if monitor then
        monitor.setTextScale(0.5)
        width, height = monitor.getSize()
    end
    
    return monitor ~= nil
end

-- Utilitaires d'affichage
local function setColors(bg, fg)
    if monitor then
        monitor.setBackgroundColor(bg)
        monitor.setTextColor(fg)
    end
end

local function clear()
    if monitor then
        setColors(theme.bg, theme.text)
        monitor.clear()
    end
end

local function setCursor(x, y)
    if monitor then
        monitor.setCursorPos(x, y)
    end
end

local function write(text)
    if monitor then
        monitor.write(text)
    end
end

local function centerText(y, text, fg, bg)
    if not monitor then return end
    local x = math.floor((width - #text) / 2) + 1
    setCursor(x, y)
    setColors(bg or theme.bg, fg or theme.text)
    write(text)
end

local function fillLine(y, bg)
    if not monitor then return end
    setColors(bg, theme.text)
    setCursor(1, y)
    write(string.rep(" ", width))
end

local function clearLine(y)
    if not monitor then return end
    setCursor(1, y)
    setColors(theme.bg, theme.text)
    write(string.rep(" ", width))
end

-- Dessiner l'en-tête (SANS HEURE)
local function drawHeader()
    fillLine(1, theme.header)
    setCursor(2, 1)
    setColors(theme.header, theme.bg)
    write("POTION MAKER")
end

-- Dessiner la barre de navigation
local function drawNav()
    local y = 2
    fillLine(y, colors.gray)
    
    local navItems = {
        { text = "Accueil", screen = "dashboard" },
        { text = "Cmd", screen = "order" },
        { text = "Potions", screen = "potions" },
        { text = "Stock", screen = "stock" }
    }
    
    local x = 1
    for _, item in ipairs(navItems) do
        local active = currentScreen == item.screen
        local bg = active and theme.buttonActive or colors.gray
        setColors(bg, theme.text)
        setCursor(x, y)
        write(" " .. item.text .. " ")
        table.insert(buttons, {
            x1 = x, y1 = y,
            x2 = x + #item.text + 1, y2 = y,
            action = "nav",
            screen = item.screen
        })
        x = x + #item.text + 2
    end
end

-- Écran Dashboard
local function drawDashboard()
    -- Section Alambics
    setCursor(2, 4)
    setColors(theme.bg, theme.header)
    write("ALAMBICS")
    
    local stands = Brewing.getStatus()
    for i, stand in ipairs(stands) do
        local y = 5 + (i - 1)
        clearLine(y)
        setCursor(2, y)
        setColors(theme.bg, theme.text)
        write("#" .. i .. ": ")
        
        if stand.status == "idle" then
            setColors(theme.bg, theme.success)
            write("Pret")
        elseif stand.status == "brewing" then
            setColors(theme.bg, theme.warning)
            write("Brassage " .. stand.progress .. "%")
        else
            setColors(theme.bg, theme.textDim)
            write("Attente")
        end
    end
    
    -- Section File d'attente
    local queueY = 8
    setCursor(2, queueY)
    setColors(theme.bg, theme.header)
    write("FILE D'ATTENTE")
    
    local counts = Queue.count()
    clearLine(queueY + 1)
    setCursor(2, queueY + 1)
    setColors(theme.bg, theme.text)
    write("Attente: ")
    setColors(theme.bg, counts.pending > 0 and theme.warning or theme.success)
    write(tostring(counts.pending))
    
    setColors(theme.bg, theme.text)
    write("  En cours: ")
    setColors(theme.bg, counts.processing > 0 and theme.highlight or theme.textDim)
    write(tostring(counts.processing))
    
    -- Commandes en attente (liste)
    local pending = Queue.getPending()
    local listY = queueY + 3
    
    for i = 1, math.min(4, #pending) do
        local cmd = pending[i]
        clearLine(listY + i - 1)
        setCursor(2, listY + i - 1)
        setColors(theme.bg, theme.textDim)
        local name = Recipes.getFullPotionName(recipes, cmd.potion, cmd.variant, cmd.form)
        write(i .. ". " .. name:sub(1, 22) .. " x" .. cmd.quantity)
    end
    
    -- Section Alertes stock bas
    if #lowStockAlerts > 0 then
        local alertY = height - 4
        clearLine(alertY)
        setCursor(2, alertY)
        setColors(theme.bg, theme.error)
        write("! STOCK BAS !")
        
        for i, alert in ipairs(lowStockAlerts) do
            if i > 2 then break end
            clearLine(alertY + i)
            setCursor(2, alertY + i)
            setColors(theme.bg, theme.warning)
            write(alert.name:sub(1, 20) .. ": " .. alert.count)
        end
    end
end

-- Écran de commande
local function drawOrderScreen()
    -- Liste des potions
    setCursor(2, 4)
    setColors(theme.bg, theme.header)
    write("POTION")
    
    local listHeight = math.min(8, height - 12)
    
    for i = 1, listHeight do
        local idx = i + scrollOffset
        local y = 4 + i
        clearLine(y)
        
        if idx <= #potionList then
            local potion = potionList[idx]
            local selected = selectedPotion == potion.key
            
            setCursor(1, y)
            if selected then
                setColors(theme.buttonActive, theme.text)
                write(string.rep(" ", math.floor(width / 2)))
                setCursor(1, y)
            else
                setColors(theme.bg, theme.text)
            end
            
            write(" " .. potion.name:sub(1, math.floor(width / 2) - 2))
            
            table.insert(buttons, {
                x1 = 1, y1 = y, x2 = math.floor(width / 2), y2 = y,
                action = "selectPotion",
                potion = potion.key
            })
        end
    end
    
    -- Options à droite
    local optX = math.floor(width / 2) + 2
    
    -- Variant
    local varY = 4
    setCursor(optX, varY)
    setColors(theme.bg, theme.header)
    write("TYPE")
    
    local variants = {
        { key = "normal", label = "Normal" },
        { key = "extended", label = "Duree+" },
        { key = "amplified", label = "Force II" }
    }
    
    for i, v in ipairs(variants) do
        local y = varY + i
        local active = selectedVariant == v.key
        clearLine(y)
        setCursor(optX, y)
        setColors(active and theme.buttonActive or theme.button, theme.text)
        write(" " .. v.label .. " ")
        table.insert(buttons, {
            x1 = optX, y1 = y, x2 = optX + #v.label + 2, y2 = y,
            action = "selectVariant",
            variant = v.key
        })
    end
    
    -- Forme
    local formY = varY + 5
    setCursor(optX, formY)
    setColors(theme.bg, theme.header)
    write("FORME")
    
    local forms = {
        { key = "normal", label = "Normal" },
        { key = "splash", label = "Splash" },
        { key = "lingering", label = "Persist" }
    }
    
    for i, f in ipairs(forms) do
        local y = formY + i
        local active = selectedForm == f.key
        clearLine(y)
        setCursor(optX, y)
        setColors(active and theme.buttonActive or theme.button, theme.text)
        write(" " .. f.label .. " ")
        table.insert(buttons, {
            x1 = optX, y1 = y, x2 = optX + #f.label + 2, y2 = y,
            action = "selectForm",
            form = f.key
        })
    end
    
    -- Quantité
    local qtyY = formY + 5
    clearLine(qtyY)
    setCursor(optX, qtyY)
    setColors(theme.bg, theme.text)
    write("Qte: ")
    
    setColors(theme.button, theme.text)
    write(" - ")
    table.insert(buttons, {
        x1 = optX + 5, y1 = qtyY, x2 = optX + 7, y2 = qtyY,
        action = "quantityDown"
    })
    
    setColors(theme.bg, theme.highlight)
    write(" " .. selectedQuantity .. " ")
    
    setColors(theme.button, theme.text)
    write(" + ")
    table.insert(buttons, {
        x1 = optX + 12, y1 = qtyY, x2 = optX + 14, y2 = qtyY,
        action = "quantityUp"
    })
    
    -- Bouton Commander
    local cmdY = height - 2
    clearLine(cmdY)
    if selectedPotion then
        setCursor(optX, cmdY)
        setColors(theme.success, theme.bg)
        write(" COMMANDER ")
        table.insert(buttons, {
            x1 = optX, y1 = cmdY, x2 = optX + 11, y2 = cmdY,
            action = "placeOrder"
        })
    end
end

-- Écran des potions en stock (CORRIGÉ)
local function drawPotionsScreen()
    setCursor(2, 4)
    setColors(theme.bg, theme.header)
    write("POTIONS EN STOCK")
    
    local stock = Inventory.getPotionsStock()
    local y = 5
    local potionIndex = 0
    
    for displayName, info in pairs(stock) do
        potionIndex = potionIndex + 1
        if y < height - 2 then
            clearLine(y)
            setCursor(2, y)
            setColors(theme.bg, theme.text)
            
            -- Afficher le nom
            write(displayName:sub(1, width - 15))
            
            -- Afficher la quantité
            setCursor(width - 10, y)
            local lowStock = info.count < (config.alerts.low_stock_threshold or 5)
            setColors(theme.bg, lowStock and theme.warning or theme.success)
            write("x" .. info.count)
            
            -- Bouton distribuer
            setCursor(width - 4, y)
            setColors(theme.button, theme.text)
            write(" > ")
            table.insert(buttons, {
                x1 = width - 4, y1 = y, x2 = width, y2 = y,
                action = "distribute",
                displayName = displayName,
                count = 1
            })
            
            y = y + 1
        end
    end
    
    if potionIndex == 0 then
        clearLine(6)
        setCursor(2, 6)
        setColors(theme.bg, theme.textDim)
        write("Aucune potion en stock")
    end
    
    -- Instructions en bas
    clearLine(height - 1)
    setCursor(2, height - 1)
    setColors(theme.bg, theme.textDim)
    write("Appuyez > pour distribuer")
end

-- Écran du stock d'ingrédients
local function drawStockScreen()
    setCursor(2, 4)
    setColors(theme.bg, theme.header)
    write("STOCK")
    
    local threshold = config.alerts.low_stock_threshold or 5
    local y = 5
    
    -- Fioles d'eau
    clearLine(y)
    setCursor(2, y)
    setColors(theme.bg, theme.text)
    write("Fioles d'eau")
    local waterCount = Inventory.countWaterBottles()
    setCursor(width - 8, y)
    setColors(theme.bg, waterCount < threshold and theme.error or theme.success)
    write("x" .. waterCount)
    y = y + 1
    
    -- Ingrédients
    local stock = Inventory.getIngredientsStock()
    
    -- Ingrédients importants en premier
    local important = {
        "minecraft:nether_wart",
        "minecraft:blaze_powder",
        "minecraft:redstone",
        "minecraft:glowstone_dust",
        "minecraft:gunpowder",
        "minecraft:dragon_breath"
    }
    
    for _, itemId in ipairs(important) do
        if y < height - 1 then
            local count = stock[itemId] or 0
            if count > 0 or itemId == "minecraft:nether_wart" or itemId == "minecraft:blaze_powder" then
                clearLine(y)
                setCursor(2, y)
                setColors(theme.bg, theme.text)
                
                local name = itemId:gsub("minecraft:", ""):gsub("_", " ")
                write(name:sub(1, width - 10))
                
                setCursor(width - 8, y)
                setColors(theme.bg, count < threshold and theme.warning or theme.textDim)
                write("x" .. count)
                
                y = y + 1
            end
            stock[itemId] = nil -- Retirer de la liste
        end
    end
    
    -- Autres ingrédients
    for itemId, count in pairs(stock) do
        if y < height - 1 then
            clearLine(y)
            setCursor(2, y)
            setColors(theme.bg, theme.textDim)
            
            local name = itemId:gsub("minecraft:", ""):gsub("_", " ")
            write(name:sub(1, width - 10))
            
            setCursor(width - 8, y)
            write("x" .. count)
            
            y = y + 1
        end
    end
end

-- Vérifier les stocks bas
function UI.checkLowStock()
    lowStockAlerts = {}
    local threshold = config.alerts.low_stock_threshold or 5
    
    -- Vérifier les fioles d'eau
    local waterCount = Inventory.countWaterBottles()
    if waterCount < threshold then
        table.insert(lowStockAlerts, { name = "Fioles d'eau", count = waterCount })
    end
    
    -- Vérifier les ingrédients importants
    local stock = Inventory.getIngredientsStock()
    local importantIngredients = {
        { id = "minecraft:nether_wart", name = "Nether Wart" },
        { id = "minecraft:blaze_powder", name = "Blaze Powder" },
        { id = "minecraft:redstone", name = "Redstone" },
        { id = "minecraft:glowstone_dust", name = "Glowstone" },
        { id = "minecraft:gunpowder", name = "Gunpowder" }
    }
    
    for _, item in ipairs(importantIngredients) do
        local count = stock[item.id] or 0
        if count < threshold then
            table.insert(lowStockAlerts, { name = item.name, count = count })
        end
    end
    
    return lowStockAlerts
end

-- Dessiner l'écran actuel
function UI.draw()
    if not monitor then return end
    
    -- Ne clear que si on change d'écran
    if currentScreen ~= lastScreen then
        clear()
        lastScreen = currentScreen
    end
    
    buttons = {}
    
    drawHeader()
    drawNav()
    
    if currentScreen == "dashboard" then
        drawDashboard()
    elseif currentScreen == "order" then
        drawOrderScreen()
    elseif currentScreen == "potions" then
        drawPotionsScreen()
    elseif currentScreen == "stock" then
        drawStockScreen()
    end
end

-- Gérer les clics
function UI.handleClick(x, y)
    for _, btn in ipairs(buttons) do
        if x >= btn.x1 and x <= btn.x2 and y >= btn.y1 and y <= btn.y2 then
            return UI.handleAction(btn)
        end
    end
    return nil
end

-- Gérer les actions (CORRIGÉ)
function UI.handleAction(btn)
    local action = btn.action
    
    if action == "nav" then
        currentScreen = btn.screen
        scrollOffset = 0
        return { type = "navigate", screen = btn.screen }
        
    elseif action == "selectPotion" then
        selectedPotion = btn.potion
        return { type = "selectPotion", potion = btn.potion }
        
    elseif action == "selectVariant" then
        selectedVariant = btn.variant
        return { type = "selectVariant", variant = btn.variant }
        
    elseif action == "selectForm" then
        selectedForm = btn.form
        return { type = "selectForm", form = btn.form }
        
    elseif action == "quantityUp" then
        selectedQuantity = math.min(selectedQuantity + 3, 64)
        return { type = "quantityChange", quantity = selectedQuantity }
        
    elseif action == "quantityDown" then
        selectedQuantity = math.max(selectedQuantity - 3, 3)
        return { type = "quantityChange", quantity = selectedQuantity }
        
    elseif action == "placeOrder" then
        if selectedPotion then
            return {
                type = "order",
                potion = selectedPotion,
                variant = selectedVariant,
                form = selectedForm,
                quantity = selectedQuantity
            }
        end
        
    elseif action == "distribute" then
        -- CORRECTION: retourner le displayName directement
        return {
            type = "distribute",
            displayName = btn.displayName,
            count = btn.count or 1
        }
    end
    
    return nil
end

-- Scroll
function UI.scroll(direction)
    if currentScreen == "order" then
        if direction == "up" then
            scrollOffset = math.max(0, scrollOffset - 1)
        else
            scrollOffset = math.min(math.max(0, #potionList - 5), scrollOffset + 1)
        end
    end
end

-- Obtenir l'écran actuel
function UI.getCurrentScreen()
    return currentScreen
end

-- Changer d'écran
function UI.setScreen(screen)
    currentScreen = screen
    scrollOffset = 0
end

-- Forcer un refresh complet
function UI.forceRefresh()
    lastScreen = nil
end

-- Obtenir les alertes
function UI.getAlerts()
    return lowStockAlerts
end

return UI
