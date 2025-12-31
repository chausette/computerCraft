-- ============================================
-- INTERFACE MONITEUR
-- Affichage graphique élégant avec tactile
-- ============================================

local ui = {}
local config = require("config")

ui.monitor = nil
ui.width = 0
ui.height = 0
ui.currentPage = "main"
ui.buttons = {}
ui.scrollOffset = 0
ui.maxScroll = 0
ui.selectedItem = nil

-- === COULEURS DU THEME ===
ui.theme = {
    background = colors.black,
    headerBg = colors.blue,
    headerText = colors.white,
    text = colors.white,
    textDim = colors.lightGray,
    accent = colors.cyan,
    success = colors.lime,
    warning = colors.yellow,
    error = colors.red,
    border = colors.gray,
    highlight = colors.lightBlue,
    categoryBg = colors.gray
}

-- === INITIALISATION ===

function ui.init(monitorName)
    ui.monitor = peripheral.wrap(monitorName or config.MONITOR_NAME)
    
    if not ui.monitor then
        for _, name in ipairs(peripheral.getNames()) do
            if peripheral.getType(name) == "monitor" then
                ui.monitor = peripheral.wrap(name)
                break
            end
        end
    end
    
    if ui.monitor then
        ui.monitor.setTextScale(config.display.monitor_scale)
        ui.width, ui.height = ui.monitor.getSize()
        ui.clear()
        return true
    end
    
    return false
end

-- === FONCTIONS DE DESSIN DE BASE ===

function ui.clear()
    ui.monitor.setBackgroundColor(ui.theme.background)
    ui.monitor.clear()
    ui.buttons = {}
end

function ui.setColor(fg, bg)
    if fg then ui.monitor.setTextColor(fg) end
    if bg then ui.monitor.setBackgroundColor(bg) end
end

function ui.write(x, y, text, fg, bg)
    if y < 1 or y > ui.height then return end
    ui.monitor.setCursorPos(x, y)
    ui.setColor(fg or ui.theme.text, bg or ui.theme.background)
    ui.monitor.write(text)
end

function ui.writeCentered(y, text, fg, bg)
    local x = math.floor((ui.width - #text) / 2) + 1
    ui.write(x, y, text, fg, bg)
end

function ui.fillLine(y, char, fg, bg)
    if y < 1 or y > ui.height then return end
    ui.setColor(fg, bg)
    ui.monitor.setCursorPos(1, y)
    ui.monitor.write(string.rep(char or " ", ui.width))
end

-- === SYSTEME DE BOUTONS ===

function ui.clearButtons()
    ui.buttons = {}
end

function ui.addButton(x, y, w, h, text, action, data)
    table.insert(ui.buttons, {
        x = x, y = y, w = w, h = h,
        text = text, action = action, data = data
    })
end

function ui.drawButton(x, y, w, text, fg, bg)
    if y < 1 or y > ui.height then return end
    local padding = math.floor((w - #text) / 2)
    ui.setColor(fg or ui.theme.text, bg or ui.theme.accent)
    ui.monitor.setCursorPos(x, y)
    ui.monitor.write(string.rep(" ", w))
    ui.monitor.setCursorPos(x + padding, y)
    ui.monitor.write(text)
    ui.setColor(ui.theme.text, ui.theme.background)
end

function ui.checkClick(clickX, clickY)
    for _, btn in ipairs(ui.buttons) do
        if clickX >= btn.x and clickX < btn.x + btn.w and
           clickY >= btn.y and clickY < btn.y + btn.h then
            return btn.action, btn.data
        end
    end
    return nil, nil
end

-- === COMPOSANTS UI ===

function ui.drawHeader(title, subtitle)
    ui.fillLine(1, " ", ui.theme.headerText, ui.theme.headerBg)
    ui.fillLine(2, " ", ui.theme.headerText, ui.theme.headerBg)
    ui.writeCentered(1, title, ui.theme.headerText, ui.theme.headerBg)
    if subtitle then
        ui.writeCentered(2, subtitle, ui.theme.textDim, ui.theme.headerBg)
    end
    ui.fillLine(3, "-", ui.theme.border, ui.theme.background)
end

function ui.drawProgressBar(x, y, width, value, maxValue, color)
    if y < 1 or y > ui.height then return end
    local fillWidth = math.floor((value / math.max(maxValue, 1)) * (width - 2))
    local percent = math.floor((value / math.max(maxValue, 1)) * 100)
    
    ui.write(x, y, "[", ui.theme.border)
    ui.setColor(color or ui.theme.success, ui.theme.background)
    ui.monitor.write(string.rep("=", fillWidth))
    ui.setColor(ui.theme.textDim)
    ui.monitor.write(string.rep("-", width - 2 - fillWidth))
    ui.setColor(ui.theme.border)
    ui.monitor.write("]")
    ui.write(x + width + 1, y, percent .. "%", ui.theme.textDim)
end

-- Boutons de navigation haut/bas
function ui.drawScrollButtons(y, canScrollUp, canScrollDown)
    local btnWidth = 6
    
    if canScrollUp then
        ui.drawButton(2, y, btnWidth, " UP ", ui.theme.text, ui.theme.accent)
        ui.addButton(2, y, btnWidth, 1, "UP", "scroll_up", nil)
    else
        ui.drawButton(2, y, btnWidth, " UP ", ui.theme.textDim, ui.theme.border)
    end
    
    if canScrollDown then
        ui.drawButton(ui.width - btnWidth, y, btnWidth, " DOWN ", ui.theme.text, ui.theme.accent)
        ui.addButton(ui.width - btnWidth, y, btnWidth, 1, "DOWN", "scroll_down", nil)
    else
        ui.drawButton(ui.width - btnWidth, y, btnWidth, " DOWN ", ui.theme.textDim, ui.theme.border)
    end
end

-- === PAGE PRINCIPALE ===

function ui.drawMainPage(storage, stats)
    ui.clear()
    ui.drawHeader("SYSTEME DE STOCKAGE", os.date("%H:%M:%S"))
    
    local y = 5
    
    ui.write(2, y, "STATISTIQUES", ui.theme.accent)
    y = y + 2
    
    ui.write(2, y, "Items totaux:", ui.theme.textDim)
    ui.write(18, y, tostring(stats.totalItems), ui.theme.text)
    y = y + 1
    
    ui.write(2, y, "Types uniques:", ui.theme.textDim)
    ui.write(18, y, tostring(stats.uniqueItems), ui.theme.text)
    y = y + 1
    
    ui.write(2, y, "Slots:", ui.theme.textDim)
    ui.write(18, y, stats.usedSlots .. "/" .. stats.totalSlots, ui.theme.text)
    y = y + 2
    
    -- Barre de capacité
    local fillColor = ui.theme.success
    local fillPercent = stats.usedSlots / math.max(stats.totalSlots, 1)
    if fillPercent > 0.9 then fillColor = ui.theme.error
    elseif fillPercent > 0.7 then fillColor = ui.theme.warning end
    ui.drawProgressBar(2, y, math.min(ui.width - 10, 30), stats.usedSlots, math.max(stats.totalSlots, 1), fillColor)
    
    y = y + 3
    
    -- Alertes (seulement si > 0)
    local alerts = storage.checkAlerts()
    if #alerts > 0 then
        ui.write(2, y, "ALERTES STOCK", ui.theme.warning)
        y = y + 1
        for i, alert in ipairs(alerts) do
            if y > ui.height - 5 then break end
            local name = alert.displayName
            if #name > ui.width - 15 then name = name:sub(1, ui.width - 18) .. ".." end
            ui.write(2, y, "! " .. name, ui.theme.warning)
            y = y + 1
        end
    end
    
    -- Boutons de navigation
    local btnY = ui.height - 2
    local btnW = math.floor((ui.width - 6) / 5)
    
    ui.drawButton(2, btnY, btnW, "INVENT", ui.theme.text, ui.theme.accent)
    ui.addButton(2, btnY, btnW, 1, "INVENT", "goto_inventory", nil)
    
    ui.drawButton(3 + btnW, btnY, btnW, "FAVOR", ui.theme.text, ui.theme.accent)
    ui.addButton(3 + btnW, btnY, btnW, 1, "FAVOR", "goto_favorites", nil)
    
    ui.drawButton(4 + btnW*2, btnY, btnW, "COFFR", ui.theme.text, ui.theme.success)
    ui.addButton(4 + btnW*2, btnY, btnW, 1, "COFFR", "goto_chests", nil)
    
    ui.drawButton(5 + btnW*3, btnY, btnW, "CATEG", ui.theme.text, ui.theme.warning)
    ui.addButton(5 + btnW*3, btnY, btnW, 1, "CATEG", "goto_categories", nil)
    
    ui.drawButton(6 + btnW*4, btnY, btnW, "ALERT", ui.theme.text, ui.theme.error)
    ui.addButton(6 + btnW*4, btnY, btnW, 1, "ALERT", "goto_alerts", nil)
    
    -- Bouton trier
    ui.drawButton(2, btnY - 2, ui.width - 2, "TRIER COFFRE ENTREE", ui.theme.text, ui.theme.border)
    ui.addButton(2, btnY - 2, ui.width - 2, 1, "TRIER", "sort_input", nil)
end

-- === PAGE GESTION DES COFFRES ===

function ui.drawChestsPage(connectedChests, storageChests, scrollOffset)
    ui.clear()
    ui.drawHeader("GESTION COFFRES", "Touchez + ou X")
    
    local y = 4
    
    -- Bouton retour
    ui.drawButton(2, y, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, y, 10, 1, "RETOUR", "goto_main", nil)
    
    y = y + 2
    
    -- Construire la liste complète
    local allItems = {}
    
    -- D'abord les coffres actifs
    for _, sc in ipairs(storageChests) do
        table.insert(allItems, {type = "active", name = sc.name})
    end
    
    -- Puis les coffres disponibles
    for _, chest in ipairs(connectedChests) do
        if not chest.isUsed then
            table.insert(allItems, {type = "available", name = chest.name, size = chest.size})
        end
    end
    
    -- Calcul du scroll
    local visibleLines = ui.height - y - 4
    local maxOffset = math.max(0, #allItems - visibleLines)
    scrollOffset = math.min(scrollOffset, maxOffset)
    ui.maxScroll = maxOffset
    
    -- Titres
    local activeCount = #storageChests
    local availCount = #allItems - activeCount
    
    ui.write(2, y, "ACTIFS: " .. activeCount .. " | DISPO: " .. availCount, ui.theme.accent)
    y = y + 1
    ui.fillLine(y, "-", ui.theme.border)
    y = y + 1
    
    -- Afficher les items avec scroll
    local startIdx = scrollOffset + 1
    local endIdx = math.min(startIdx + visibleLines - 1, #allItems)
    
    for i = startIdx, endIdx do
        local item = allItems[i]
        if item and y < ui.height - 3 then
            local name = item.name
            local maxLen = ui.width - 12
            if #name > maxLen then
                name = ".." .. name:sub(-(maxLen - 2))
            end
            
            if item.type == "active" then
                ui.write(2, y, name, ui.theme.text)
                local btnX = ui.width - 4
                ui.drawButton(btnX, y, 4, " X ", ui.theme.text, ui.theme.error)
                ui.addButton(btnX, y, 4, 1, "X", "remove_chest", item.name)
            else
                ui.write(2, y, name, ui.theme.textDim)
                local btnX = ui.width - 4
                ui.drawButton(btnX, y, 4, " + ", ui.theme.text, ui.theme.success)
                ui.addButton(btnX, y, 4, 1, "+", "add_chest", item.name)
            end
            
            y = y + 1
        end
    end
    
    -- Boutons de navigation
    local navY = ui.height - 2
    local canUp = scrollOffset > 0
    local canDown = scrollOffset < maxOffset
    ui.drawScrollButtons(navY, canUp, canDown)
    
    -- Info scroll
    if #allItems > 0 then
        local info = (scrollOffset + 1) .. "-" .. math.min(endIdx, #allItems) .. "/" .. #allItems
        ui.writeCentered(navY, info, ui.theme.textDim)
    end
    
    return scrollOffset
end

-- === PAGE GESTION DES CATEGORIES ===

function ui.drawCategoriesPage(categories, inventory, scrollOffset)
    ui.clear()
    ui.drawHeader("GESTION CATEGORIES", "Modifier les items")
    
    local y = 4
    
    -- Bouton retour
    ui.drawButton(2, y, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, y, 10, 1, "RETOUR", "goto_main", nil)
    
    -- Bouton ajouter catégorie
    ui.drawButton(ui.width - 12, y, 12, "+ CATEGORIE", ui.theme.text, ui.theme.success)
    ui.addButton(ui.width - 12, y, 12, 1, "ADD_CAT", "add_category", nil)
    
    y = y + 2
    
    -- Liste des catégories avec leurs items
    local allItems = {}
    
    for _, cat in ipairs(categories) do
        table.insert(allItems, {type = "category", name = cat.name, color = cat.color})
        
        for itemName, itemData in pairs(inventory) do
            if itemData.category == cat.name then
                table.insert(allItems, {
                    type = "item",
                    name = itemData.name,
                    displayName = itemData.displayName,
                    category = cat.name,
                    count = itemData.count
                })
            end
        end
    end
    
    -- Calcul du scroll
    local visibleLines = ui.height - y - 3
    local maxOffset = math.max(0, #allItems - visibleLines)
    scrollOffset = math.min(scrollOffset, maxOffset)
    ui.maxScroll = maxOffset
    
    -- Afficher avec scroll
    local startIdx = scrollOffset + 1
    local endIdx = math.min(startIdx + visibleLines - 1, #allItems)
    
    for i = startIdx, endIdx do
        local item = allItems[i]
        if item and y < ui.height - 2 then
            if item.type == "category" then
                ui.fillLine(y, " ", ui.theme.text, item.color or ui.theme.categoryBg)
                ui.write(2, y, " " .. item.name .. " ", ui.theme.text, item.color)
            else
                local name = item.displayName or item.name
                local maxLen = ui.width - 10
                if #name > maxLen then name = name:sub(1, maxLen - 2) .. ".." end
                
                ui.write(3, y, name, ui.theme.textDim)
                
                ui.drawButton(ui.width - 5, y, 5, "[>]", ui.theme.text, ui.theme.accent)
                ui.addButton(ui.width - 5, y, 5, 1, "CHANGE", "change_category", {name = item.name, displayName = item.displayName})
            end
            y = y + 1
        end
    end
    
    -- Navigation
    local navY = ui.height - 2
    ui.drawScrollButtons(navY, scrollOffset > 0, scrollOffset < maxOffset)
    
    return scrollOffset
end

-- === PAGE SELECTION CATEGORIE ===

function ui.drawCategorySelectPage(categories, itemName, itemDisplayName)
    ui.clear()
    ui.drawHeader("CHANGER CATEGORIE", itemDisplayName or itemName)
    
    local y = 4
    
    ui.drawButton(2, y, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, y, 10, 1, "RETOUR", "goto_categories", nil)
    
    y = y + 2
    ui.write(2, y, "Choisir la categorie:", ui.theme.textDim)
    y = y + 2
    
    for i, cat in ipairs(categories) do
        if y < ui.height - 2 then
            ui.drawButton(2, y, ui.width - 4, cat.name, ui.theme.text, cat.color or ui.theme.accent)
            ui.addButton(2, y, ui.width - 4, 1, cat.name, "set_category", {item = itemName, category = cat.name})
            y = y + 2
        end
    end
end

-- === PAGE GESTION DES ALERTES ===

function ui.drawAlertsPage(inventory, stockAlerts, scrollOffset)
    ui.clear()
    ui.drawHeader("ALERTES STOCK", "Seuil 0 = desactive")
    
    local y = 4
    
    ui.drawButton(2, y, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, y, 10, 1, "RETOUR", "goto_main", nil)
    
    y = y + 2
    
    -- Liste tous les items
    local allItems = {}
    
    -- D'abord les items avec alerte active
    for itemName, minQty in pairs(stockAlerts) do
        if minQty > 0 then
            local itemData = inventory[itemName]
            table.insert(allItems, {
                name = itemName,
                displayName = itemData and itemData.displayName or itemName:gsub("^[^:]+:", ""),
                current = itemData and itemData.count or 0,
                threshold = minQty,
                hasAlert = true
            })
        end
    end
    
    -- Puis les items sans alerte
    for itemName, itemData in pairs(inventory) do
        local hasAlert = stockAlerts[itemName] and stockAlerts[itemName] > 0
        if not hasAlert then
            table.insert(allItems, {
                name = itemName,
                displayName = itemData.displayName,
                current = itemData.count,
                threshold = 0,
                hasAlert = false
            })
        end
    end
    
    -- Tri
    table.sort(allItems, function(a, b)
        if a.hasAlert and not b.hasAlert then return true end
        if not a.hasAlert and b.hasAlert then return false end
        return a.displayName < b.displayName
    end)
    
    -- Calcul du scroll
    local visibleLines = ui.height - y - 4
    local maxOffset = math.max(0, #allItems - visibleLines)
    scrollOffset = math.min(scrollOffset, maxOffset)
    ui.maxScroll = maxOffset
    
    -- En-tête
    ui.write(2, y, "Item", ui.theme.accent)
    ui.write(ui.width - 15, y, "Qte", ui.theme.accent)
    ui.write(ui.width - 8, y, "Seuil", ui.theme.accent)
    y = y + 1
    ui.fillLine(y, "-", ui.theme.border)
    y = y + 1
    
    local startIdx = scrollOffset + 1
    local endIdx = math.min(startIdx + visibleLines - 1, #allItems)
    
    for i = startIdx, endIdx do
        local item = allItems[i]
        if item and y < ui.height - 2 then
            local name = item.displayName
            local maxLen = ui.width - 22
            if #name > maxLen then name = name:sub(1, maxLen - 2) .. ".." end
            
            local color = ui.theme.text
            if item.hasAlert and item.current < item.threshold then
                color = ui.theme.error
            elseif item.hasAlert then
                color = ui.theme.warning
            end
            
            ui.write(2, y, name, color)
            ui.write(ui.width - 15, y, tostring(item.current), ui.theme.textDim)
            
            local threshStr = item.threshold > 0 and tostring(item.threshold) or "-"
            ui.write(ui.width - 8, y, threshStr, item.hasAlert and ui.theme.warning or ui.theme.textDim)
            
            ui.drawButton(ui.width - 3, y, 3, "[E]", ui.theme.text, ui.theme.accent)
            ui.addButton(ui.width - 3, y, 3, 1, "EDIT", "edit_alert", {name = item.name, displayName = item.displayName, current = item.current, threshold = item.threshold})
            
            y = y + 1
        end
    end
    
    local navY = ui.height - 2
    ui.drawScrollButtons(navY, scrollOffset > 0, scrollOffset < maxOffset)
    
    if #allItems > 0 then
        local info = (scrollOffset + 1) .. "-" .. math.min(endIdx, #allItems) .. "/" .. #allItems
        ui.writeCentered(navY, info, ui.theme.textDim)
    end
    
    return scrollOffset
end

-- === PAGE EDITION SEUIL ALERTE ===

function ui.drawAlertEditPage(itemName, itemDisplayName, currentStock, currentThreshold)
    ui.clear()
    ui.drawHeader("MODIFIER ALERTE", itemDisplayName or itemName)
    
    local y = 4
    
    ui.drawButton(2, y, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, y, 10, 1, "RETOUR", "goto_alerts", nil)
    
    y = y + 3
    
    ui.write(2, y, "Stock actuel: " .. currentStock, ui.theme.textDim)
    y = y + 1
    ui.write(2, y, "Seuil actuel: " .. (currentThreshold > 0 and currentThreshold or "OFF"), 
             currentThreshold > 0 and ui.theme.warning or ui.theme.textDim)
    y = y + 3
    
    ui.write(2, y, "Choisir le seuil:", ui.theme.text)
    y = y + 2
    
    local thresholds = {0, 16, 32, 64, 128, 256, 512}
    local btnWidth = math.floor((ui.width - 6) / 3)
    
    for i, thresh in ipairs(thresholds) do
        local row = math.floor((i - 1) / 3)
        local col = (i - 1) % 3
        local btnX = 2 + col * (btnWidth + 1)
        local btnY = y + row * 2
        
        local label = thresh == 0 and "OFF" or tostring(thresh)
        local bg = thresh == currentThreshold and ui.theme.success or ui.theme.accent
        if thresh == 0 then bg = ui.theme.border end
        
        ui.drawButton(btnX, btnY, btnWidth, label, ui.theme.text, bg)
        ui.addButton(btnX, btnY, btnWidth, 1, label, "set_alert", {item = itemName, threshold = thresh})
    end
end

-- === PAGE INVENTAIRE ===

function ui.drawInventoryPage(byCategory, pageNum)
    ui.clear()
    ui.drawHeader("INVENTAIRE", "Page " .. pageNum)
    
    ui.drawButton(2, 4, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, 4, 10, 1, "RETOUR", "goto_main", nil)
    
    local y = 6
    local categoriesPerPage = 2
    local itemsPerCategory = math.floor((ui.height - 10) / 2)
    
    local categories = {}
    for _, cat in ipairs(config.categories) do
        if byCategory[cat.name] and #byCategory[cat.name].items > 0 then
            table.insert(categories, {
                name = cat.name,
                color = cat.color,
                items = byCategory[cat.name].items
            })
        end
    end
    
    local startIdx = (pageNum - 1) * categoriesPerPage + 1
    local endIdx = math.min(startIdx + categoriesPerPage - 1, #categories)
    local totalPages = math.ceil(math.max(#categories, 1) / categoriesPerPage)
    
    for i = startIdx, endIdx do
        local cat = categories[i]
        if cat and y < ui.height - 4 then
            ui.fillLine(y, " ", ui.theme.text, cat.color or ui.theme.categoryBg)
            ui.write(2, y, " " .. cat.name .. " (" .. #cat.items .. ")", ui.theme.text, cat.color)
            y = y + 1
            
            for j = 1, math.min(itemsPerCategory, #cat.items) do
                local item = cat.items[j]
                local name = item.displayName
                if #name > ui.width - 10 then name = name:sub(1, ui.width - 13) .. ".." end
                ui.write(3, y, name, ui.theme.textDim)
                ui.write(ui.width - #tostring(item.count), y, tostring(item.count), ui.theme.accent)
                y = y + 1
            end
            y = y + 1
        end
    end
    
    local navY = ui.height - 2
    if pageNum > 1 then
        ui.drawButton(2, navY, 8, "< PREC", ui.theme.text, ui.theme.accent)
        ui.addButton(2, navY, 8, 1, "PREC", "prev_page", nil)
    end
    if pageNum < totalPages then
        ui.drawButton(ui.width - 9, navY, 8, "SUIV >", ui.theme.text, ui.theme.accent)
        ui.addButton(ui.width - 9, navY, 8, 1, "SUIV", "next_page", nil)
    end
    
    ui.writeCentered(ui.height, "Page " .. pageNum .. "/" .. totalPages, ui.theme.textDim)
    
    return totalPages
end

-- === PAGE FAVORIS ===

function ui.drawFavoritesPage(favorites)
    ui.clear()
    ui.drawHeader("FAVORIS", #favorites .. " items")
    
    ui.drawButton(2, 4, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, 4, 10, 1, "RETOUR", "goto_main", nil)
    
    local y = 6
    
    if #favorites == 0 then
        ui.writeCentered(y + 2, "Aucun favori", ui.theme.textDim)
        ui.writeCentered(y + 3, "Ajoutez via le Pocket", ui.theme.textDim)
        return
    end
    
    for i, fav in ipairs(favorites) do
        if y > ui.height - 2 then break end
        
        local name = fav.displayName
        if #name > ui.width - 12 then name = name:sub(1, ui.width - 15) .. ".." end
        
        local color = ui.theme.text
        if not fav.inStock then color = ui.theme.error
        elseif fav.count < 10 then color = ui.theme.warning end
        
        ui.write(2, y, fav.inStock and "*" or "!", ui.theme.accent)
        ui.write(4, y, name, color)
        ui.write(ui.width - #tostring(fav.count), y, tostring(fav.count), ui.theme.accent)
        y = y + 1
    end
end

-- === ECRAN DE CHARGEMENT ===

function ui.drawLoading(message)
    ui.clear()
    ui.drawHeader("SYSTEME DE STOCKAGE", nil)
    ui.writeCentered(math.floor(ui.height / 2), message or "Chargement...", ui.theme.accent)
    
    local frames = {"|", "/", "-", "\\"}
    local frameIndex = math.floor(os.clock() * 4) % 4 + 1
    local frame = frames[frameIndex] or "|"
    ui.writeCentered(math.floor(ui.height / 2) + 2, "[ " .. frame .. " ]", ui.theme.textDim)
end

return ui
