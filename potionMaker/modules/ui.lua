-- ============================================
-- Potion Maker - Module UI
-- Interface moniteur 3x2
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
local currentScreen = "dashboard"  -- dashboard, order, potions, settings
local selectedPotion = nil
local selectedVariant = "normal"
local selectedForm = "normal"
local selectedQuantity = 3
local scrollOffset = 0
local potionList = {}
local lowStockAlerts = {}

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

local function drawButton(x, y, text, active)
    if not monitor then return end
    local bg = active and theme.buttonActive or theme.button
    setColors(bg, theme.text)
    setCursor(x, y)
    write(" " .. text .. " ")
    return { x1 = x, y1 = y, x2 = x + #text + 1, y2 = y, action = text }
end

-- Dessiner l'en-tête
local function drawHeader()
    fillLine(1, theme.header)
    setCursor(2, 1)
    setColors(theme.header, theme.bg)
    write("POTION MAKER")
    
    -- Heure
    local time = textutils.formatTime(os.time(), true)
    setCursor(width - #time, 1)
    write(time)
end

-- Dessiner la barre de navigation
local buttons = {}

local function drawNav()
    buttons = {}
    local y = 2
    fillLine(y, colors.gray)
    
    local navItems = {
        { text = "Dashboard", screen = "dashboard" },
        { text = "Commander", screen = "order" },
        { text = "Potions", screen = "potions" },
        { text = "Stock", screen = "stock" }
    }
    
    local x = 2
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
        x = x + #item.text + 3
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
        setCursor(2, y)
        setColors(theme.bg, theme.text)
        write("Alambic " .. i .. ": ")
        
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
    setCursor(2, queueY + 1)
    setColors(theme.bg, theme.text)
    write("En attente: ")
    setColors(theme.bg, counts.pending > 0 and theme.warning or theme.success)
    write(tostring(counts.pending))
    
    setCursor(2, queueY + 2)
    setColors(theme.bg, theme.text)
    write("En cours: ")
    setColors(theme.bg, counts.processing > 0 and theme.highlight or theme.textDim)
    write(tostring(counts.processing))
    
    -- Commandes en attente (liste)
    local pending = Queue.getPending()
    local listY = queueY + 4
    
    for i = 1, math.min(3, #pending) do
        local cmd = pending[i]
        setCursor(2, listY + i - 1)
        setColors(theme.bg, theme.textDim)
        local name = Recipes.getFullPotionName(recipes, cmd.potion, cmd.variant, cmd.form)
        write(i .. ". " .. name:sub(1, 20) .. " x" .. cmd.quantity)
    end
    
    -- Section Alertes
    if #lowStockAlerts > 0 then
        local alertY = height - 3
        setCursor(2, alertY)
        setColors(theme.bg, theme.error)
        write("! STOCK BAS !")
        
        for i, alert in ipairs(lowStockAlerts) do
            if i > 2 then break end
            setCursor(2, alertY + i)
            setColors(theme.bg, theme.warning)
            write(alert.name:sub(1, 25) .. ": " .. alert.count)
        end
    end
end

-- Écran de commande
local function drawOrderScreen()
    -- Liste des potions
    setCursor(2, 4)
    setColors(theme.bg, theme.header)
    write("CHOISIR POTION")
    
    local listHeight = height - 10
    local visiblePotions = math.min(listHeight, #potionList)
    
    for i = 1, visiblePotions do
        local idx = i + scrollOffset
        if idx <= #potionList then
            local potion = potionList[idx]
            local y = 4 + i
            local selected = selectedPotion == potion.key
            
            if selected then
                fillLine(y, theme.buttonActive)
            end
            
            setCursor(2, y)
            setColors(selected and theme.buttonActive or theme.bg, theme.text)
            write(potion.name)
            
            table.insert(buttons, {
                x1 = 1, y1 = y, x2 = width / 2, y2 = y,
                action = "selectPotion",
                potion = potion.key
            })
        end
    end
    
    -- Options à droite
    local optX = math.floor(width / 2) + 2
    
    -- Variant
    setCursor(optX, 4)
    setColors(theme.bg, theme.header)
    write("TYPE")
    
    local variants = { "normal", "extended", "amplified" }
    local variantNames = { "Normal", "Prolonge+", "Renforce II" }
    
    for i, variant in ipairs(variants) do
        local y = 4 + i
        local active = selectedVariant == variant
        setCursor(optX, y)
        setColors(active and theme.buttonActive or theme.button, theme.text)
        write(" " .. variantNames[i] .. " ")
        table.insert(buttons, {
            x1 = optX, y1 = y, x2 = optX + 12, y2 = y,
            action = "selectVariant",
            variant = variant
        })
    end
    
    -- Forme
    setCursor(optX, 9)
    setColors(theme.bg, theme.header)
    write("FORME")
    
    local forms = { "normal", "splash", "lingering" }
    local formNames = { "Normal", "Splash", "Persistant" }
    
    for i, form in ipairs(forms) do
        local y = 9 + i
        local active = selectedForm == form
        setCursor(optX, y)
        setColors(active and theme.buttonActive or theme.button, theme.text)
        write(" " .. formNames[i] .. " ")
        table.insert(buttons, {
            x1 = optX, y1 = y, x2 = optX + 12, y2 = y,
            action = "selectForm",
            form = form
        })
    end
    
    -- Quantité
    setCursor(optX, 14)
    setColors(theme.bg, theme.header)
    write("QUANTITE: " .. selectedQuantity)
    
    setCursor(optX, 15)
    local btn = drawButton(optX, 15, "-", false)
    btn.action = "quantityDown"
    table.insert(buttons, btn)
    
    btn = drawButton(optX + 4, 15, "+", false)
    btn.action = "quantityUp"
    table.insert(buttons, btn)
    
    -- Bouton Commander
    local cmdY = height - 2
    setCursor(optX, cmdY)
    setColors(theme.success, theme.bg)
    write(" COMMANDER ")
    table.insert(buttons, {
        x1 = optX, y1 = cmdY, x2 = optX + 11, y2 = cmdY,
        action = "placeOrder"
    })
end

-- Écran des potions en stock
local function drawPotionsScreen()
    setCursor(2, 4)
    setColors(theme.bg, theme.header)
    write("POTIONS EN STOCK")
    
    local stock = Inventory.getPotionsStock()
    local y = 5
    
    for key, info in pairs(stock) do
        if y < height - 2 then
            setCursor(2, y)
            setColors(theme.bg, theme.text)
            
            local displayName = info.displayName or info.name
            displayName = displayName:gsub("minecraft:", "")
            
            write(displayName:sub(1, 30))
            
            setCursor(width - 8, y)
            setColors(theme.bg, info.count < config.alerts.low_stock_threshold and theme.warning or theme.success)
            write("x" .. info.count)
            
            -- Bouton distribuer
            local btnX = width - 4
            setColors(theme.button, theme.text)
            write(" > ")
            table.insert(buttons, {
                x1 = btnX, y1 = y, x2 = width, y2 = y,
                action = "distribute",
                item = info
            })
            
            y = y + 1
        end
    end
    
    if y == 5 then
        setCursor(2, 6)
        setColors(theme.bg, theme.textDim)
        write("Aucune potion en stock")
    end
end

-- Écran du stock d'ingrédients
local function drawStockScreen()
    setCursor(2, 4)
    setColors(theme.bg, theme.header)
    write("STOCK INGREDIENTS")
    
    local stock = Inventory.getIngredientsStock()
    local y = 5
    
    -- Fioles d'eau
    setCursor(2, y)
    setColors(theme.bg, theme.text)
    write("Fioles d'eau")
    local waterCount = Inventory.countWaterBottles()
    setCursor(width - 8, y)
    setColors(theme.bg, waterCount < config.alerts.low_stock_threshold and theme.error or theme.success)
    write("x" .. waterCount)
    y = y + 1
    
    -- Blaze powder (fuel)
    setCursor(2, y)
    setColors(theme.bg, theme.text)
    write("Blaze Powder")
    local blazeCount = stock["minecraft:blaze_powder"] or 0
    setCursor(width - 8, y)
    setColors(theme.bg, blazeCount < config.alerts.low_stock_threshold and theme.error or theme.success)
    write("x" .. blazeCount)
    y = y + 2
    
    -- Autres ingrédients
    for itemId, count in pairs(stock) do
        if y < height - 1 and itemId ~= "minecraft:blaze_powder" then
            setCursor(2, y)
            setColors(theme.bg, theme.text)
            
            local name = itemId:gsub("minecraft:", ""):gsub("_", " ")
            write(name:sub(1, 25))
            
            setCursor(width - 8, y)
            setColors(theme.bg, count < config.alerts.low_stock_threshold and theme.warning or theme.textDim)
            write("x" .. count)
            
            y = y + 1
        end
    end
end

-- Vérifier les stocks bas
function UI.checkLowStock()
    lowStockAlerts = {}
    
    -- Vérifier les fioles d'eau
    local waterCount = Inventory.countWaterBottles()
    if waterCount < config.alerts.low_stock_threshold then
        table.insert(lowStockAlerts, { name = "Fioles d'eau", count = waterCount })
    end
    
    -- Vérifier les ingrédients importants
    local stock = Inventory.getIngredientsStock()
    local importantIngredients = {
        "minecraft:nether_wart",
        "minecraft:blaze_powder",
        "minecraft:redstone",
        "minecraft:glowstone_dust",
        "minecraft:gunpowder"
    }
    
    for _, item in ipairs(importantIngredients) do
        local count = stock[item] or 0
        if count < config.alerts.low_stock_threshold then
            table.insert(lowStockAlerts, {
                name = item:gsub("minecraft:", ""):gsub("_", " "),
                count = count
            })
        end
    end
    
    return lowStockAlerts
end

-- Dessiner l'écran actuel
function UI.draw()
    if not monitor then return end
    
    clear()
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

-- Gérer les actions
function UI.handleAction(btn)
    if btn.action == "nav" then
        currentScreen = btn.screen
        scrollOffset = 0
        return { type = "navigate", screen = btn.screen }
        
    elseif btn.action == "selectPotion" then
        selectedPotion = btn.potion
        return { type = "selectPotion", potion = btn.potion }
        
    elseif btn.action == "selectVariant" then
        selectedVariant = btn.variant
        return { type = "selectVariant", variant = btn.variant }
        
    elseif btn.action == "selectForm" then
        selectedForm = btn.form
        return { type = "selectForm", form = btn.form }
        
    elseif btn.action == "quantityUp" then
        selectedQuantity = math.min(selectedQuantity + 3, 64)
        return { type = "quantityChange", quantity = selectedQuantity }
        
    elseif btn.action == "quantityDown" then
        selectedQuantity = math.max(selectedQuantity - 3, 3)
        return { type = "quantityChange", quantity = selectedQuantity }
        
    elseif btn.action == "placeOrder" then
        if selectedPotion then
            return {
                type = "order",
                potion = selectedPotion,
                variant = selectedVariant,
                form = selectedForm,
                quantity = selectedQuantity
            }
        end
        
    elseif btn.action == "distribute" then
        return {
            type = "distribute",
            item = btn.item
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
            scrollOffset = math.min(#potionList - 5, scrollOffset + 1)
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

-- Obtenir les alertes
function UI.getAlerts()
    return lowStockAlerts
end

return UI
