-- ============================================
-- MOB TOWER MANAGER - UI Library
-- Interface graphique moniteur
-- ============================================

local utils = require("mobTower.lib.utils")

local ui = {}

-- Références
local monitor = nil
local width = 0
local height = 0

-- État de l'alerte
local alertState = {
    active = false,
    message = "",
    startTime = 0,
    duration = 3
}

-- Couleurs du thème
local theme = {
    bg = colors.black,
    header = colors.blue,
    headerText = colors.white,
    text = colors.white,
    textDim = colors.lightGray,
    accent = colors.cyan,
    success = colors.lime,
    warning = colors.orange,
    danger = colors.red,
    rare = colors.yellow,
    border = colors.gray,
    graphBar = colors.lime,
    graphBg = colors.gray
}

-- ============================================
-- INITIALISATION
-- ============================================

function ui.init(mon)
    monitor = mon
    if monitor then
        monitor.setTextScale(0.5)
        width, height = monitor.getSize()
        monitor.setBackgroundColor(theme.bg)
        monitor.clear()
        utils.log("UI initialisé: " .. width .. "x" .. height)
    end
    return width, height
end

function ui.getSize()
    return width, height
end

-- ============================================
-- FONCTIONS DE DESSIN DE BASE
-- ============================================

function ui.clear()
    if not monitor then return end
    monitor.setBackgroundColor(theme.bg)
    monitor.clear()
end

function ui.setCursor(x, y)
    if not monitor then return end
    monitor.setCursorPos(x, y)
end

function ui.setColors(fg, bg)
    if not monitor then return end
    if fg then monitor.setTextColor(fg) end
    if bg then monitor.setBackgroundColor(bg) end
end

function ui.write(text)
    if not monitor then return end
    monitor.write(text)
end

function ui.writeLine(x, y, text, fg, bg)
    if not monitor then return end
    ui.setCursor(x, y)
    ui.setColors(fg or theme.text, bg or theme.bg)
    ui.write(text)
end

function ui.writeCenter(y, text, fg, bg)
    local x = math.floor((width - #text) / 2) + 1
    ui.writeLine(x, y, text, fg, bg)
end

-- Dessiner une ligne horizontale
function ui.drawLine(y, char, fg)
    if not monitor then return end
    char = char or "\140"
    ui.setColors(fg or theme.border, theme.bg)
    ui.setCursor(1, y)
    ui.write(string.rep(char, width))
end

-- Dessiner un rectangle
function ui.drawBox(x, y, w, h, title, fg)
    if not monitor then return end
    fg = fg or theme.border
    
    -- Coins et bordures
    local topLeft = "\151"
    local topRight = "\148"
    local bottomLeft = "\138"
    local bottomRight = "\133"
    local horizontal = "\140"
    local vertical = "\149"
    
    ui.setColors(fg, theme.bg)
    
    -- Haut
    ui.setCursor(x, y)
    ui.write(topLeft .. string.rep(horizontal, w - 2) .. topRight)
    
    -- Côtés
    for i = 1, h - 2 do
        ui.setCursor(x, y + i)
        ui.write(vertical)
        ui.setCursor(x + w - 1, y + i)
        ui.write(vertical)
    end
    
    -- Bas
    ui.setCursor(x, y + h - 1)
    ui.write(bottomLeft .. string.rep(horizontal, w - 2) .. bottomRight)
    
    -- Titre
    if title then
        ui.setCursor(x + 2, y)
        ui.setColors(theme.accent, theme.bg)
        ui.write(" " .. title .. " ")
    end
end

-- ============================================
-- COMPOSANTS D'INTERFACE
-- ============================================

-- Barre de progression
function ui.drawProgressBar(x, y, w, percent, fg, bg)
    if not monitor then return end
    fg = fg or theme.graphBar
    bg = bg or theme.graphBg
    
    local filled = math.floor((percent / 100) * w)
    if filled > w then filled = w end
    if filled < 0 then filled = 0 end
    
    ui.setCursor(x, y)
    ui.setColors(theme.text, fg)
    ui.write(string.rep(" ", filled))
    ui.setColors(theme.text, bg)
    ui.write(string.rep(" ", w - filled))
    
    -- Reset background
    ui.setColors(theme.text, theme.bg)
end

-- Graphique en barres ASCII
function ui.drawBarGraph(x, y, w, h, data, maxValue)
    if not monitor then return end
    if not data or #data == 0 then return end
    
    -- Trouver la valeur max si non fournie
    if not maxValue then
        maxValue = 1
        for _, v in ipairs(data) do
            if v > maxValue then maxValue = v end
        end
    end
    
    -- Largeur de chaque barre
    local barWidth = math.floor(w / #data)
    if barWidth < 1 then barWidth = 1 end
    
    -- Dessiner les barres
    for i, value in ipairs(data) do
        local barHeight = math.floor((value / maxValue) * h)
        if barHeight > h then barHeight = h end
        
        local barX = x + (i - 1) * barWidth
        
        -- Dessiner la barre de bas en haut
        for j = 0, h - 1 do
            ui.setCursor(barX, y + h - 1 - j)
            if j < barHeight then
                ui.setColors(theme.graphBar, theme.graphBar)
            else
                ui.setColors(theme.graphBg, theme.graphBg)
            end
            ui.write(string.rep(" ", barWidth - 1))
        end
    end
    
    ui.setColors(theme.text, theme.bg)
end

-- ============================================
-- ÉCRAN PRINCIPAL
-- ============================================

function ui.drawHeader(title, spawnOn, sessionTime)
    if not monitor then return end
    
    -- Barre d'en-tête
    ui.setColors(theme.headerText, theme.header)
    ui.setCursor(1, 1)
    ui.write(string.rep(" ", width))
    
    -- Titre
    ui.setCursor(2, 1)
    ui.write("\4 " .. title)
    
    -- État spawn
    local spawnText = spawnOn and "[ON ]" or "[OFF]"
    local spawnColor = spawnOn and theme.success or theme.danger
    ui.setCursor(math.floor(width / 2) - 2, 1)
    ui.setColors(spawnColor, theme.header)
    ui.write(spawnText)
    
    -- Temps session
    local timeText = "\2 " .. utils.formatTime(sessionTime)
    ui.setCursor(width - #timeText, 1)
    ui.setColors(theme.headerText, theme.header)
    ui.write(timeText)
    
    ui.setColors(theme.text, theme.bg)
end

function ui.drawStats(x, y, stats, playerPresent)
    if not monitor then return end
    
    -- Titre section
    ui.writeLine(x, y, "STATS EN DIRECT", theme.accent)
    
    -- Indicateur joueur
    local playerIcon = playerPresent and "\7" or "\21"
    local playerColor = playerPresent and theme.success or theme.danger
    ui.writeLine(x + 16, y, playerIcon, playerColor)
    
    y = y + 2
    
    -- Mobs en attente
    ui.writeLine(x, y, "Mobs attente:", theme.textDim)
    ui.writeLine(x + 14, y, utils.formatNumber(stats.mobsWaiting), theme.text)
    y = y + 1
    
    -- Tués session
    ui.writeLine(x, y, "Tues session:", theme.textDim)
    ui.writeLine(x + 14, y, utils.formatNumber(stats.session.mobsKilled), theme.success)
    y = y + 1
    
    -- Tués total
    ui.writeLine(x, y, "Tues total:", theme.textDim)
    ui.writeLine(x + 14, y, utils.formatNumber(stats.total.mobsKilled), theme.text)
    y = y + 2
    
    -- Items session
    ui.writeLine(x, y, "Items session:", theme.textDim)
    ui.writeLine(x + 14, y, utils.formatNumber(stats.session.itemsCollected), theme.success)
    y = y + 1
    
    -- Items total
    ui.writeLine(x, y, "Items total:", theme.textDim)
    ui.writeLine(x + 14, y, utils.formatNumber(stats.total.itemsCollected), theme.text)
end

function ui.drawGraph(x, y, w, h, hourlyData)
    if not monitor then return end
    
    -- Titre
    ui.writeLine(x, y, "PRODUCTION /HEURE", theme.accent)
    y = y + 2
    
    if not hourlyData or #hourlyData == 0 then
        ui.writeLine(x, y + 2, "Pas de donnees", theme.textDim)
        return
    end
    
    -- Extraire les valeurs de mobs
    local values = {}
    local maxVal = 1
    for _, data in ipairs(hourlyData) do
        table.insert(values, data.mobs)
        if data.mobs > maxVal then maxVal = data.mobs end
    end
    
    -- Afficher max
    ui.writeLine(x, y, "Max: " .. utils.formatNumber(maxVal) .. "/h", theme.textDim)
    y = y + 1
    
    -- Dessiner le graphique
    ui.drawBarGraph(x, y, w, h - 3, values, maxVal)
    
    -- Légende temps
    y = y + h - 2
    ui.writeLine(x, y, "-" .. #hourlyData .. "h", theme.textDim)
    ui.writeLine(x + w - 4, y, "now", theme.textDim)
end

function ui.drawStorage(x, y, storageStatus)
    if not monitor then return end
    
    -- Titre
    ui.writeLine(x, y, "STOCKAGE", theme.accent)
    y = y + 2
    
    -- Barre globale
    local percent = storageStatus.total.percent
    local barColor = theme.graphBar
    if percent >= 90 then
        barColor = theme.danger
    elseif percent >= 75 then
        barColor = theme.warning
    end
    
    ui.drawProgressBar(x, y, 18, percent, barColor)
    ui.writeLine(x + 19, y, percent .. "%", theme.text)
    y = y + 2
    
    -- Warnings
    local warningCount = 0
    for _, warning in ipairs(storageStatus.warnings) do
        if warningCount >= 2 then break end
        
        local icon = warning.level == "critical" and "\7" or "!"
        local color = warning.level == "critical" and theme.danger or theme.warning
        
        local text = icon .. " " .. utils.truncate(warning.item, 12) .. ": " .. warning.percent .. "%"
        ui.writeLine(x, y, text, color)
        y = y + 1
        warningCount = warningCount + 1
    end
    
    if warningCount == 0 then
        ui.writeLine(x, y, "Tout va bien", theme.success)
    end
end

function ui.drawRareItems(x, y, rareItems)
    if not monitor then return end
    
    -- Titre avec étoile
    ui.writeLine(x, y, "\4 ITEMS RARES", theme.rare)
    y = y + 2
    
    if not rareItems or #rareItems == 0 then
        ui.writeLine(x, y, "Aucun pour l'instant", theme.textDim)
        return
    end
    
    for i, item in ipairs(rareItems) do
        if i > 5 then break end
        
        local name = utils.truncate(utils.getShortName(item.name), 16)
        local time = utils.formatTimestamp(item.time)
        
        ui.writeLine(x, y, "\7 ", theme.rare)
        ui.writeLine(x + 2, y, name, theme.text)
        ui.writeLine(x + 20, y, time, theme.textDim)
        y = y + 1
    end
end

function ui.drawFooter(y)
    if not monitor then return end
    
    ui.drawLine(y, "\140", theme.border)
    y = y + 1
    
    ui.writeLine(2, y, "[S] Spawn", theme.accent)
    ui.writeLine(14, y, "[C] Config", theme.accent)
    ui.writeLine(27, y, "[R] Reset", theme.accent)
    ui.writeLine(39, y, "[Q] Quitter", theme.accent)
end

-- ============================================
-- ÉCRAN PRINCIPAL COMPLET
-- ============================================

function ui.drawMainScreen(data)
    if not monitor then return end
    
    ui.clear()
    
    -- En-tête
    ui.drawHeader("MOB TOWER v1.0", data.spawnOn, data.sessionTime)
    
    -- Ligne de séparation
    ui.drawLine(2)
    
    -- Calculer les positions
    local leftCol = 2
    local rightCol = math.floor(width / 2) + 2
    local colWidth = math.floor(width / 2) - 3
    
    -- Stats (colonne gauche, haut)
    ui.drawStats(leftCol, 4, data.stats, data.playerPresent)
    
    -- Graphique (colonne droite, haut)
    ui.drawGraph(rightCol, 4, colWidth, 8, data.hourlyData)
    
    -- Ligne de séparation
    local midLine = 13
    ui.drawLine(midLine)
    
    -- Stockage (colonne gauche, bas)
    ui.drawStorage(leftCol, midLine + 2, data.storageStatus)
    
    -- Items rares (colonne droite, bas)
    ui.drawRareItems(rightCol, midLine + 2, data.rareItems)
    
    -- Footer
    ui.drawFooter(height - 1)
    
    -- Alerte si active
    if alertState.active then
        ui.drawAlert()
    end
end

-- ============================================
-- ALERTES
-- ============================================

function ui.showAlert(message, duration)
    alertState.active = true
    alertState.message = message
    alertState.startTime = os.epoch("utc") / 1000
    alertState.duration = duration or 3
end

function ui.updateAlert()
    if not alertState.active then return false end
    
    local elapsed = (os.epoch("utc") / 1000) - alertState.startTime
    if elapsed >= alertState.duration then
        alertState.active = false
        return false
    end
    
    return true
end

function ui.drawAlert()
    if not monitor or not alertState.active then return end
    
    local msg = alertState.message
    local msgWidth = #msg + 4
    local x = math.floor((width - msgWidth) / 2)
    local y = math.floor(height / 2)
    
    -- Flash effect (alternance de couleurs)
    local elapsed = (os.epoch("utc") / 1000) - alertState.startTime
    local flash = math.floor(elapsed * 4) % 2 == 0
    
    local bgColor = flash and theme.rare or theme.danger
    local fgColor = theme.bg
    
    -- Dessiner le fond
    ui.setColors(fgColor, bgColor)
    for dy = -1, 1 do
        ui.setCursor(x, y + dy)
        ui.write(string.rep(" ", msgWidth))
    end
    
    -- Message
    ui.setCursor(x + 2, y)
    ui.write(msg)
    
    ui.setColors(theme.text, theme.bg)
end

function ui.isAlertActive()
    return alertState.active
end

-- ============================================
-- ÉCRANS SECONDAIRES
-- ============================================

-- Menu de sélection
function ui.drawMenu(title, options, selected)
    if not monitor then return end
    
    ui.clear()
    ui.drawHeader(title, nil, 0)
    ui.drawLine(2)
    
    local y = 4
    for i, option in ipairs(options) do
        local prefix = (i == selected) and "> " or "  "
        local color = (i == selected) and theme.accent or theme.text
        ui.writeLine(4, y, prefix .. option, color)
        y = y + 1
    end
    
    ui.drawLine(height - 2)
    ui.writeLine(2, height - 1, "[Fleches] Naviguer  [Entree] Selectionner", theme.textDim)
end

-- Écran de confirmation
function ui.drawConfirm(title, message)
    if not monitor then return end
    
    ui.clear()
    ui.drawHeader(title, nil, 0)
    
    ui.writeCenter(math.floor(height / 2) - 1, message, theme.warning)
    ui.writeCenter(math.floor(height / 2) + 1, "[O] Oui  [N] Non", theme.accent)
end

-- Message simple
function ui.showMessage(title, message, duration)
    if not monitor then return end
    
    ui.clear()
    ui.drawHeader(title, nil, 0)
    ui.writeCenter(math.floor(height / 2), message, theme.text)
    
    if duration then
        sleep(duration)
    end
end

return ui
