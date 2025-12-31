-- ============================================
-- INTERFACE MONITEUR
-- Affichage graphique élégant
-- ============================================

local ui = {}
local config = require("config")

ui.monitor = nil
ui.width = 0
ui.height = 0
ui.currentPage = "main"
ui.scrollOffset = 0
ui.buttons = {}  -- Stocke les boutons cliquables
ui.selectedChest = nil  -- Coffre sélectionné pour action

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
        -- Cherche un moniteur
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
end

function ui.setColor(fg, bg)
    if fg then ui.monitor.setTextColor(fg) end
    if bg then ui.monitor.setBackgroundColor(bg) end
end

function ui.write(x, y, text, fg, bg)
    ui.monitor.setCursorPos(x, y)
    ui.setColor(fg or ui.theme.text, bg or ui.theme.background)
    ui.monitor.write(text)
end

function ui.writeCentered(y, text, fg, bg)
    local x = math.floor((ui.width - #text) / 2) + 1
    ui.write(x, y, text, fg, bg)
end

function ui.fillLine(y, char, fg, bg)
    ui.setColor(fg, bg)
    ui.monitor.setCursorPos(1, y)
    ui.monitor.write(string.rep(char or " ", ui.width))
end

function ui.drawBox(x, y, w, h, bg, borderColor)
    ui.setColor(nil, bg or ui.theme.background)
    for i = 0, h - 1 do
        ui.monitor.setCursorPos(x, y + i)
        ui.monitor.write(string.rep(" ", w))
    end
    
    if borderColor then
        ui.setColor(borderColor)
        -- Coins et bords
        ui.write(x, y, "+" .. string.rep("-", w - 2) .. "+", borderColor, bg)
        ui.write(x, y + h - 1, "+" .. string.rep("-", w - 2) .. "+", borderColor, bg)
        for i = 1, h - 2 do
            ui.write(x, y + i, "|", borderColor, bg)
            ui.write(x + w - 1, y + i, "|", borderColor, bg)
        end
    end
end

-- === COMPOSANTS UI ===

-- En-tête avec titre
function ui.drawHeader(title, subtitle)
    ui.fillLine(1, " ", ui.theme.headerText, ui.theme.headerBg)
    ui.fillLine(2, " ", ui.theme.headerText, ui.theme.headerBg)
    
    ui.writeCentered(1, title, ui.theme.headerText, ui.theme.headerBg)
    
    if subtitle then
        ui.writeCentered(2, subtitle, ui.theme.textDim, ui.theme.headerBg)
    end
    
    -- Ligne de séparation
    ui.fillLine(3, "-", ui.theme.border, ui.theme.background)
end

-- Barre de progression
function ui.drawProgressBar(x, y, width, value, maxValue, color)
    local fillWidth = math.floor((value / maxValue) * (width - 2))
    local percent = math.floor((value / maxValue) * 100)
    
    ui.write(x, y, "[", ui.theme.border)
    
    ui.setColor(color or ui.theme.success, ui.theme.background)
    ui.monitor.write(string.rep("=", fillWidth))
    
    ui.setColor(ui.theme.textDim)
    ui.monitor.write(string.rep("-", width - 2 - fillWidth))
    
    ui.setColor(ui.theme.border)
    ui.monitor.write("]")
    
    ui.write(x + width + 1, y, percent .. "%", ui.theme.textDim)
end

-- Carte de statistique
function ui.drawStatCard(x, y, title, value, icon, color)
    local cardWidth = 12
    
    ui.drawBox(x, y, cardWidth, 4, ui.theme.background, ui.theme.border)
    
    ui.write(x + 1, y + 1, icon or "□", color or ui.theme.accent)
    ui.write(x + 3, y + 1, title, ui.theme.textDim)
    ui.write(x + 1, y + 2, tostring(value), ui.theme.text)
end

-- Liste d'items
function ui.drawItemList(x, y, items, maxItems, showCategory)
    local displayed = 0
    
    for i, item in ipairs(items) do
        if displayed >= maxItems then break end
        
        local line = y + displayed
        local name = item.displayName or item.name
        
        -- Tronque le nom si nécessaire
        local maxNameLen = ui.width - x - 12
        if #name > maxNameLen then
            name = name:sub(1, maxNameLen - 2) .. ".."
        end
        
        -- Couleur selon le stock
        local nameColor = ui.theme.text
        if item.count == 0 then
            nameColor = ui.theme.error
        elseif item.count < 10 then
            nameColor = ui.theme.warning
        end
        
        ui.write(x, line, name, nameColor)
        
        -- Quantité alignée à droite
        local countStr = tostring(item.count)
        ui.write(ui.width - #countStr, line, countStr, ui.theme.accent)
        
        displayed = displayed + 1
    end
    
    return displayed
end

-- Section de catégorie
function ui.drawCategorySection(y, category, items, maxItems)
    -- En-tête de catégorie
    ui.fillLine(y, " ", ui.theme.headerText, category.color or ui.theme.categoryBg)
    ui.write(2, y, " " .. category.name .. " ", ui.theme.headerText, category.color)
    
    local itemCount = #items
    local countStr = "(" .. itemCount .. ")"
    ui.write(ui.width - #countStr, y, countStr, ui.theme.textDim, category.color)
    
    -- Items
    local displayed = 0
    for i, item in ipairs(items) do
        if displayed >= maxItems then break end
        
        local line = y + 1 + displayed
        local name = item.displayName
        
        -- Tronque
        local maxLen = ui.width - 10
        if #name > maxLen then
            name = name:sub(1, maxLen - 2) .. ".."
        end
        
        ui.write(3, line, name, ui.theme.text)
        ui.write(ui.width - #tostring(item.count), line, tostring(item.count), ui.theme.accent)
        
        displayed = displayed + 1
    end
    
    return displayed + 1
end

-- Alerte
function ui.drawAlert(y, message, alertType)
    local color = ui.theme.warning
    local icon = "!"
    
    if alertType == "error" then
        color = ui.theme.error
        icon = "X"
    elseif alertType == "success" then
        color = ui.theme.success
        icon = "✓"
    elseif alertType == "info" then
        color = ui.theme.accent
        icon = "i"
    end
    
    ui.write(2, y, "[" .. icon .. "]", color)
    ui.write(6, y, message, ui.theme.text)
end

-- === PAGES D'AFFICHAGE ===

-- Page principale avec statistiques
function ui.drawMainPage(storage, stats)
    ui.clear()
    ui.drawHeader("SYSTEME DE STOCKAGE", os.date("%H:%M:%S"))
    
    local y = 5
    
    -- Statistiques générales
    ui.write(2, y, "STATISTIQUES", ui.theme.accent)
    y = y + 2
    
    ui.write(2, y, "Items totaux:", ui.theme.textDim)
    ui.write(18, y, tostring(stats.totalItems), ui.theme.text)
    y = y + 1
    
    ui.write(2, y, "Types uniques:", ui.theme.textDim)
    ui.write(18, y, tostring(stats.uniqueItems), ui.theme.text)
    y = y + 1
    
    ui.write(2, y, "Slots utilises:", ui.theme.textDim)
    ui.write(18, y, stats.usedSlots .. "/" .. stats.totalSlots, ui.theme.text)
    y = y + 2
    
    -- Barre de capacité
    ui.write(2, y, "Capacite:", ui.theme.textDim)
    y = y + 1
    local fillColor = ui.theme.success
    local fillPercent = stats.usedSlots / math.max(stats.totalSlots, 1)
    if fillPercent > 0.9 then
        fillColor = ui.theme.error
    elseif fillPercent > 0.7 then
        fillColor = ui.theme.warning
    end
    ui.drawProgressBar(2, y, ui.width - 10, stats.usedSlots, math.max(stats.totalSlots, 1), fillColor)
    
    y = y + 3
    
    -- Alertes
    local alerts = storage.checkAlerts()
    if #alerts > 0 then
        ui.write(2, y, "ALERTES STOCK", ui.theme.warning)
        y = y + 1
        ui.fillLine(y, "-", ui.theme.border)
        y = y + 1
        
        for _, alert in ipairs(alerts) do
            ui.write(2, y, alert.displayName, ui.theme.warning)
            ui.write(ui.width - 10, y, alert.current .. "/" .. alert.minimum, ui.theme.error)
            y = y + 1
            if y > ui.height - 2 then break end
        end
    end
    
    -- Pied de page
    ui.fillLine(ui.height, " ", ui.theme.textDim, ui.theme.headerBg)
    local timestamp = "Maj: " .. os.date("%H:%M:%S")
    ui.write(ui.width - #timestamp, ui.height, timestamp, ui.theme.textDim, ui.theme.headerBg)
end

-- Page inventaire par catégorie
function ui.drawInventoryPage(byCategory, pageNum)
    ui.clear()
    ui.drawHeader("INVENTAIRE", "Page " .. pageNum)
    
    local y = 4
    local categoriesPerPage = 3
    local itemsPerCategory = 4
    
    -- Calcule les catégories à afficher
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
    
    for i = startIdx, endIdx do
        local cat = categories[i]
        if cat and y < ui.height - 2 then
            local lines = ui.drawCategorySection(y, cat, cat.items, itemsPerCategory)
            y = y + lines + 2
        end
    end
    
    -- Navigation
    local totalPages = math.ceil(#categories / categoriesPerPage)
    ui.fillLine(ui.height, " ", ui.theme.textDim, ui.theme.headerBg)
    ui.writeCentered(ui.height, "< Page " .. pageNum .. "/" .. totalPages .. " >", 
                     ui.theme.textDim, ui.theme.headerBg)
    
    return totalPages
end

-- Page favoris
function ui.drawFavoritesPage(favorites)
    ui.clear()
    ui.drawHeader("FAVORIS", #favorites .. " items")
    
    local y = 4
    
    if #favorites == 0 then
        ui.writeCentered(y + 2, "Aucun favori configure", ui.theme.textDim)
        return
    end
    
    for i, fav in ipairs(favorites) do
        if y > ui.height - 2 then break end
        
        local name = fav.displayName
        local maxLen = ui.width - 12
        if #name > maxLen then
            name = name:sub(1, maxLen - 2) .. ".."
        end
        
        local color = ui.theme.text
        local star = "*"
        if not fav.inStock then
            color = ui.theme.error
            star = "!"
        elseif fav.count < 10 then
            color = ui.theme.warning
        end
        
        ui.write(2, y, star, ui.theme.accent)
        ui.write(4, y, name, color)
        ui.write(ui.width - #tostring(fav.count), y, tostring(fav.count), ui.theme.accent)
        
        y = y + 1
    end
end

-- Page de recherche / résultats
function ui.drawSearchResults(query, results)
    ui.clear()
    ui.drawHeader("RECHERCHE", '"' .. query .. '"')
    
    local y = 4
    
    ui.write(2, y, #results .. " resultats trouves", ui.theme.textDim)
    y = y + 2
    
    if #results == 0 then
        ui.writeCentered(y + 2, "Aucun item trouve", ui.theme.textDim)
        return
    end
    
    for i, item in ipairs(results) do
        if y > ui.height - 2 then break end
        
        local name = item.displayName
        local maxLen = ui.width - 15
        if #name > maxLen then
            name = name:sub(1, maxLen - 2) .. ".."
        end
        
        ui.write(2, y, name, ui.theme.text)
        ui.write(ui.width - 10, y, item.category:sub(1, 8), ui.theme.textDim)
        ui.write(ui.width - #tostring(item.count), y, tostring(item.count), ui.theme.accent)
        
        y = y + 1
    end
end

-- Écran de chargement
function ui.drawLoading(message)
    ui.clear()
    ui.drawHeader("SYSTEME DE STOCKAGE")
    ui.writeCentered(math.floor(ui.height / 2), message or "Chargement...", ui.theme.accent)
    
    -- Animation simple
    local frames = {"|", "/", "-", "\\"}
    local frameIndex = math.floor(os.clock() * 4) % 4 + 1
    local frame = frames[frameIndex] or "|"
    ui.writeCentered(math.floor(ui.height / 2) + 2, "[ " .. frame .. " ]", ui.theme.textDim)
end

-- Écran d'erreur
function ui.drawError(message)
    ui.clear()
    ui.drawHeader("ERREUR", nil)
    ui.writeCentered(math.floor(ui.height / 2), message, ui.theme.error)
end

-- === SYSTEME DE BOUTONS ===

-- Réinitialise les boutons
function ui.clearButtons()
    ui.buttons = {}
end

-- Ajoute un bouton
function ui.addButton(x, y, w, h, text, action, data)
    table.insert(ui.buttons, {
        x = x, y = y, w = w, h = h,
        text = text,
        action = action,
        data = data
    })
end

-- Dessine un bouton
function ui.drawButton(x, y, w, text, fg, bg)
    local padding = math.floor((w - #text) / 2)
    ui.setColor(fg or ui.theme.text, bg or ui.theme.accent)
    ui.monitor.setCursorPos(x, y)
    ui.monitor.write(string.rep(" ", w))
    ui.monitor.setCursorPos(x + padding, y)
    ui.monitor.write(text)
    ui.setColor(ui.theme.text, ui.theme.background)
end

-- Vérifie si un clic touche un bouton
function ui.checkClick(clickX, clickY)
    for _, btn in ipairs(ui.buttons) do
        if clickX >= btn.x and clickX < btn.x + btn.w and
           clickY >= btn.y and clickY < btn.y + btn.h then
            return btn.action, btn.data
        end
    end
    return nil, nil
end

-- === PAGE DE GESTION DES COFFRES ===

function ui.drawChestManagementPage(connectedChests, storageChests)
    ui.clear()
    ui.clearButtons()
    ui.drawHeader("GESTION COFFRES", "Touchez pour gerer")
    
    local y = 4
    
    -- Boutons de navigation
    ui.drawButton(2, y, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, y, 10, 1, "RETOUR", "goto_main", nil)
    
    y = y + 2
    
    -- Section: Coffres de stockage actifs
    ui.write(2, y, "COFFRES ACTIFS:", ui.theme.accent)
    y = y + 1
    
    local activeCount = 0
    for _, sc in ipairs(storageChests) do
        if y > ui.height - 4 then break end
        activeCount = activeCount + 1
        
        local name = sc.name
        if #name > ui.width - 15 then
            name = ".." .. name:sub(-(ui.width - 17))
        end
        
        ui.write(2, y, name, ui.theme.text)
        
        -- Bouton supprimer
        local btnX = ui.width - 5
        ui.drawButton(btnX, y, 5, " X ", ui.theme.text, ui.theme.error)
        ui.addButton(btnX, y, 5, 1, "X", "remove_chest", sc.name)
        
        y = y + 1
    end
    
    if activeCount == 0 then
        ui.write(2, y, "(aucun)", ui.theme.textDim)
        y = y + 1
    end
    
    y = y + 1
    
    -- Section: Coffres disponibles (non utilisés)
    ui.write(2, y, "COFFRES DISPONIBLES:", ui.theme.success)
    y = y + 1
    
    local availableCount = 0
    for _, chest in ipairs(connectedChests) do
        if not chest.isUsed and y > ui.height - 2 then break end
        if not chest.isUsed then
            availableCount = availableCount + 1
            
            local name = chest.name
            if #name > ui.width - 15 then
                name = ".." .. name:sub(-(ui.width - 17))
            end
            
            ui.write(2, y, name, ui.theme.textDim)
            
            -- Bouton ajouter
            local btnX = ui.width - 5
            ui.drawButton(btnX, y, 5, " + ", ui.theme.text, ui.theme.success)
            ui.addButton(btnX, y, 5, 1, "+", "add_chest", chest.name)
            
            y = y + 1
        end
    end
    
    if availableCount == 0 then
        ui.write(2, y, "(aucun)", ui.theme.textDim)
    end
    
    -- Pied de page
    ui.fillLine(ui.height, " ", ui.theme.textDim, ui.theme.headerBg)
    ui.write(2, ui.height, "Touchez + ou X", ui.theme.textDim, ui.theme.headerBg)
end

-- === MISE A JOUR PAGE PRINCIPALE AVEC BOUTONS ===

-- Page principale avec statistiques et boutons de navigation
function ui.drawMainPageWithButtons(storage, stats)
    ui.clear()
    ui.clearButtons()
    ui.drawHeader("SYSTEME DE STOCKAGE", os.date("%H:%M:%S"))
    
    local y = 5
    
    -- Statistiques générales
    ui.write(2, y, "STATISTIQUES", ui.theme.accent)
    y = y + 2
    
    ui.write(2, y, "Items totaux:", ui.theme.textDim)
    ui.write(18, y, tostring(stats.totalItems), ui.theme.text)
    y = y + 1
    
    ui.write(2, y, "Types uniques:", ui.theme.textDim)
    ui.write(18, y, tostring(stats.uniqueItems), ui.theme.text)
    y = y + 1
    
    ui.write(2, y, "Slots utilises:", ui.theme.textDim)
    ui.write(18, y, stats.usedSlots .. "/" .. stats.totalSlots, ui.theme.text)
    y = y + 2
    
    -- Barre de capacité
    ui.write(2, y, "Capacite:", ui.theme.textDim)
    y = y + 1
    local fillColor = ui.theme.success
    local fillPercent = stats.usedSlots / math.max(stats.totalSlots, 1)
    if fillPercent > 0.9 then
        fillColor = ui.theme.error
    elseif fillPercent > 0.7 then
        fillColor = ui.theme.warning
    end
    ui.drawProgressBar(2, y, math.min(ui.width - 10, 30), stats.usedSlots, math.max(stats.totalSlots, 1), fillColor)
    
    y = y + 3
    
    -- Alertes
    local alerts = storage.checkAlerts()
    if #alerts > 0 then
        ui.write(2, y, "ALERTES STOCK", ui.theme.warning)
        y = y + 1
        ui.fillLine(y, "-", ui.theme.border)
        y = y + 1
        
        for _, alert in ipairs(alerts) do
            ui.write(2, y, alert.displayName, ui.theme.warning)
            ui.write(ui.width - 10, y, alert.current .. "/" .. alert.minimum, ui.theme.error)
            y = y + 1
            if y > ui.height - 5 then break end
        end
    end
    
    -- Boutons de navigation en bas
    local btnY = ui.height - 2
    local btnWidth = math.floor((ui.width - 4) / 4)
    
    -- Bouton Inventaire
    ui.drawButton(2, btnY, btnWidth, "INVENT", ui.theme.text, ui.theme.accent)
    ui.addButton(2, btnY, btnWidth, 1, "INVENT", "goto_inventory", nil)
    
    -- Bouton Favoris
    ui.drawButton(2 + btnWidth + 1, btnY, btnWidth, "FAVORIS", ui.theme.text, ui.theme.accent)
    ui.addButton(2 + btnWidth + 1, btnY, btnWidth, 1, "FAVORIS", "goto_favorites", nil)
    
    -- Bouton Coffres
    ui.drawButton(2 + (btnWidth + 1) * 2, btnY, btnWidth, "COFFRES", ui.theme.text, ui.theme.success)
    ui.addButton(2 + (btnWidth + 1) * 2, btnY, btnWidth, 1, "COFFRES", "goto_chests", nil)
    
    -- Bouton Tri
    ui.drawButton(2 + (btnWidth + 1) * 3, btnY, btnWidth, "TRIER", ui.theme.text, ui.theme.warning)
    ui.addButton(2 + (btnWidth + 1) * 3, btnY, btnWidth, 1, "TRIER", "sort_input", nil)
    
    -- Pied de page
    ui.fillLine(ui.height, " ", ui.theme.textDim, ui.theme.headerBg)
    local timestamp = "Maj: " .. os.date("%H:%M:%S")
    ui.write(ui.width - #timestamp, ui.height, timestamp, ui.theme.textDim, ui.theme.headerBg)
end

-- Page inventaire avec bouton retour
function ui.drawInventoryPageWithButtons(byCategory, pageNum)
    ui.clear()
    ui.clearButtons()
    ui.drawHeader("INVENTAIRE", "Page " .. pageNum)
    
    -- Bouton retour
    ui.drawButton(2, 4, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, 4, 10, 1, "RETOUR", "goto_main", nil)
    
    local y = 6
    local categoriesPerPage = 2
    local itemsPerCategory = 4
    
    -- Calcule les catégories à afficher
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
    
    for i = startIdx, endIdx do
        local cat = categories[i]
        if cat and y < ui.height - 4 then
            local lines = ui.drawCategorySection(y, cat, cat.items, itemsPerCategory)
            y = y + lines + 2
        end
    end
    
    -- Navigation
    local totalPages = math.ceil(#categories / categoriesPerPage)
    local btnY = ui.height - 2
    
    if pageNum > 1 then
        ui.drawButton(2, btnY, 8, "< PREC", ui.theme.text, ui.theme.accent)
        ui.addButton(2, btnY, 8, 1, "PREC", "prev_page", nil)
    end
    
    if pageNum < totalPages then
        ui.drawButton(ui.width - 9, btnY, 8, "SUIV >", ui.theme.text, ui.theme.accent)
        ui.addButton(ui.width - 9, btnY, 8, 1, "SUIV", "next_page", nil)
    end
    
    ui.fillLine(ui.height, " ", ui.theme.textDim, ui.theme.headerBg)
    ui.writeCentered(ui.height, "Page " .. pageNum .. "/" .. totalPages, 
                     ui.theme.textDim, ui.theme.headerBg)
    
    return totalPages
end

-- Page favoris avec bouton retour
function ui.drawFavoritesPageWithButtons(favorites)
    ui.clear()
    ui.clearButtons()
    ui.drawHeader("FAVORIS", #favorites .. " items")
    
    -- Bouton retour
    ui.drawButton(2, 4, 10, "< RETOUR", ui.theme.text, ui.theme.border)
    ui.addButton(2, 4, 10, 1, "RETOUR", "goto_main", nil)
    
    local y = 6
    
    if #favorites == 0 then
        ui.writeCentered(y + 2, "Aucun favori configure", ui.theme.textDim)
        ui.writeCentered(y + 4, "Ajoutez via le Pocket", ui.theme.textDim)
        return
    end
    
    for i, fav in ipairs(favorites) do
        if y > ui.height - 2 then break end
        
        local name = fav.displayName
        local maxLen = ui.width - 12
        if #name > maxLen then
            name = name:sub(1, maxLen - 2) .. ".."
        end
        
        local color = ui.theme.text
        local star = "*"
        if not fav.inStock then
            color = ui.theme.error
            star = "!"
        elseif fav.count < 10 then
            color = ui.theme.warning
        end
        
        ui.write(2, y, star, ui.theme.accent)
        ui.write(4, y, name, color)
        ui.write(ui.width - #tostring(fav.count), y, tostring(fav.count), ui.theme.accent)
        
        y = y + 1
    end
end

return ui
