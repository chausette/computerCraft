-- ============================================
-- UI.lua - Interface Moniteur 3x2
-- Pour Advanced Computer + Advanced Monitor
-- ============================================

local ui = {}

-- ============================================
-- CONFIGURATION
-- ============================================

local monitor = nil
local monW, monH = 0, 0

-- Couleurs du theme
local colors_bg = colors.black
local colors_header = colors.blue
local colors_button = colors.gray
local colors_buttonActive = colors.lime
local colors_text = colors.white
local colors_textDim = colors.lightGray
local colors_progress = colors.green
local colors_warning = colors.orange
local colors_error = colors.red

-- ============================================
-- INITIALISATION
-- ============================================

function ui.init()
    -- Cherche le moniteur
    monitor = peripheral.find("monitor")
    if not monitor then
        return false, "Moniteur non trouve"
    end
    
    monitor.setTextScale(0.5)
    monW, monH = monitor.getSize()
    
    return true
end

function ui.getMonitor()
    return monitor
end

function ui.getSize()
    return monW, monH
end

-- ============================================
-- PRIMITIVES
-- ============================================

function ui.clear()
    monitor.setBackgroundColor(colors_bg)
    monitor.clear()
end

function ui.setCursor(x, y)
    monitor.setCursorPos(x, y)
end

function ui.write(text)
    monitor.write(text)
end

function ui.setColors(fg, bg)
    if fg then monitor.setTextColor(fg) end
    if bg then monitor.setBackgroundColor(bg) end
end

-- Dessine un rectangle rempli
function ui.fillRect(x, y, w, h, color)
    monitor.setBackgroundColor(color)
    for i = 0, h - 1 do
        monitor.setCursorPos(x, y + i)
        monitor.write(string.rep(" ", w))
    end
end

-- Dessine un cadre
function ui.drawBox(x, y, w, h, color)
    monitor.setBackgroundColor(color)
    -- Haut
    monitor.setCursorPos(x, y)
    monitor.write(string.rep(" ", w))
    -- Bas
    monitor.setCursorPos(x, y + h - 1)
    monitor.write(string.rep(" ", w))
    -- Cotes
    for i = 1, h - 2 do
        monitor.setCursorPos(x, y + i)
        monitor.write(" ")
        monitor.setCursorPos(x + w - 1, y + i)
        monitor.write(" ")
    end
end

-- Centre un texte
function ui.centerText(y, text, fg, bg)
    local x = math.floor((monW - #text) / 2) + 1
    ui.setColors(fg, bg or colors_bg)
    monitor.setCursorPos(x, y)
    monitor.write(text)
end

-- Texte aligne a gauche avec padding
function ui.leftText(y, text, fg, bg, padding)
    padding = padding or 2
    ui.setColors(fg, bg or colors_bg)
    monitor.setCursorPos(padding, y)
    monitor.write(text)
end

-- Texte aligne a droite
function ui.rightText(y, text, fg, bg, padding)
    padding = padding or 2
    local x = monW - #text - padding + 1
    ui.setColors(fg, bg or colors_bg)
    monitor.setCursorPos(x, y)
    monitor.write(text)
end

-- ============================================
-- COMPOSANTS
-- ============================================

-- Dessine l'en-tete
function ui.drawHeader(title)
    ui.fillRect(1, 1, monW, 3, colors_header)
    ui.setColors(colors.white, colors_header)
    ui.centerText(2, title)
end

-- Dessine un bouton
function ui.drawButton(x, y, w, h, text, active)
    local bg = active and colors_buttonActive or colors_button
    local fg = active and colors.black or colors.white
    
    ui.fillRect(x, y, w, h, bg)
    ui.setColors(fg, bg)
    
    local textX = x + math.floor((w - #text) / 2)
    local textY = y + math.floor(h / 2)
    monitor.setCursorPos(textX, textY)
    monitor.write(text)
    
    return {x = x, y = y, w = w, h = h}
end

-- Dessine une barre de progression
function ui.drawProgressBar(x, y, w, progress, maxProgress)
    local pct = maxProgress > 0 and (progress / maxProgress) or 0
    local filled = math.floor(pct * (w - 2))
    
    ui.setColors(colors_textDim, colors_bg)
    monitor.setCursorPos(x, y)
    monitor.write("[")
    
    ui.setColors(colors_progress, colors_bg)
    monitor.write(string.rep("=", filled))
    
    ui.setColors(colors_textDim, colors_bg)
    monitor.write(string.rep("-", w - 2 - filled))
    monitor.write("]")
    
    -- Pourcentage
    local pctText = string.format(" %d%%", math.floor(pct * 100))
    ui.setColors(colors_text, colors_bg)
    monitor.write(pctText)
end

-- Dessine un champ de saisie
function ui.drawInput(x, y, w, label, value)
    ui.setColors(colors_textDim, colors_bg)
    monitor.setCursorPos(x, y)
    monitor.write(label .. ": ")
    
    ui.setColors(colors_text, colors.gray)
    local inputX = x + #label + 2
    local inputW = w - #label - 2
    monitor.setCursorPos(inputX, y)
    monitor.write(string.rep(" ", inputW))
    monitor.setCursorPos(inputX, y)
    
    local displayValue = tostring(value or "")
    if #displayValue > inputW then
        displayValue = string.sub(displayValue, 1, inputW - 2) .. ".."
    end
    monitor.write(displayValue)
    
    return {x = inputX, y = y, w = inputW, h = 1}
end

-- Dessine une liste de selection
function ui.drawList(x, y, w, h, items, selected)
    ui.fillRect(x, y, w, h, colors.gray)
    
    for i = 1, math.min(#items, h) do
        local item = items[i]
        local isSelected = (i == selected)
        
        if isSelected then
            ui.fillRect(x, y + i - 1, w, 1, colors.blue)
            ui.setColors(colors.white, colors.blue)
        else
            ui.setColors(colors.white, colors.gray)
        end
        
        monitor.setCursorPos(x + 1, y + i - 1)
        local text = tostring(item)
        if #text > w - 2 then
            text = string.sub(text, 1, w - 5) .. "..."
        end
        monitor.write(text)
    end
end

-- ============================================
-- ECRANS
-- ============================================

local buttons = {}

function ui.clearButtons()
    buttons = {}
end

function ui.addButton(name, x, y, w, h)
    buttons[name] = {x = x, y = y, w = w, h = h}
end

function ui.checkClick(clickX, clickY)
    for name, btn in pairs(buttons) do
        if clickX >= btn.x and clickX < btn.x + btn.w and
           clickY >= btn.y and clickY < btn.y + btn.h then
            return name
        end
    end
    return nil
end

-- Ecran principal / Menu
function ui.drawMainMenu(state)
    ui.clear()
    ui.clearButtons()
    
    ui.drawHeader("SCHEMATIC BUILDER v1.0")
    
    local btnW = math.floor(monW / 2) - 4
    local btnH = 3
    local startY = 6
    local spacing = 4
    
    -- Boutons gauche
    local btn = ui.drawButton(3, startY, btnW, btnH, "1. Charger Schematic", false)
    ui.addButton("load", btn.x, btn.y, btn.w, btn.h)
    
    btn = ui.drawButton(3, startY + spacing, btnW, btnH, "2. Config Coffres", false)
    ui.addButton("chests", btn.x, btn.y, btn.w, btn.h)
    
    btn = ui.drawButton(3, startY + spacing * 2, btnW, btnH, "3. Config Position", false)
    ui.addButton("position", btn.x, btn.y, btn.w, btn.h)
    
    -- Boutons droite
    local rightX = monW - btnW - 2
    
    btn = ui.drawButton(rightX, startY, btnW, btnH, "4. Materiaux", false)
    ui.addButton("materials", btn.x, btn.y, btn.w, btn.h)
    
    local buildText = state.building and "5. ARRETER" or "5. CONSTRUIRE"
    local buildActive = state.schematic ~= nil
    btn = ui.drawButton(rightX, startY + spacing, btnW, btnH, buildText, buildActive)
    ui.addButton("build", btn.x, btn.y, btn.w, btn.h)
    
    local pauseText = state.paused and "6. Reprendre" or "6. Pause"
    btn = ui.drawButton(rightX, startY + spacing * 2, btnW, btnH, pauseText, state.building)
    ui.addButton("pause", btn.x, btn.y, btn.w, btn.h)
    
    -- Zone statut
    local statusY = startY + spacing * 3 + 2
    ui.fillRect(1, statusY, monW, monH - statusY + 1, colors.gray)
    
    ui.setColors(colors.white, colors.gray)
    monitor.setCursorPos(3, statusY + 1)
    monitor.write("Status: ")
    
    local statusColor = colors.white
    if state.status == "building" then statusColor = colors.lime
    elseif state.status == "pause" then statusColor = colors.orange
    elseif state.status == "error" then statusColor = colors.red
    end
    ui.setColors(statusColor, colors.gray)
    monitor.write(state.status or "En attente")
    
    -- Progression
    if state.totalBlocks and state.totalBlocks > 0 then
        ui.setColors(colors.white, colors.gray)
        monitor.setCursorPos(3, statusY + 3)
        monitor.write(string.format("Couche: %d/%d", 
            state.layer or 0, 
            state.schematicHeight or 0))
        
        monitor.setCursorPos(3, statusY + 4)
        monitor.write(string.format("Blocs: %d/%d", 
            state.placedBlocks or 0, 
            state.totalBlocks or 0))
        
        ui.drawProgressBar(3, statusY + 6, monW - 12, 
            state.placedBlocks or 0, 
            state.totalBlocks or 0)
    end
    
    -- Infos turtle
    ui.setColors(colors.lightGray, colors.gray)
    monitor.setCursorPos(monW - 20, statusY + 1)
    monitor.write(string.format("Fuel: %d", state.fuel or 0))
    
    monitor.setCursorPos(monW - 20, statusY + 2)
    monitor.write(string.format("Pos: %d,%d,%d", 
        state.x or 0, state.y or 0, state.z or 0))
end

-- Ecran de configuration des coffres
function ui.drawChestConfig(config)
    ui.clear()
    ui.clearButtons()
    
    ui.drawHeader("CONFIGURATION COFFRES")
    
    local y = 6
    
    ui.leftText(y, "COFFRE FUEL:", colors.yellow)
    y = y + 2
    
    local fuelX = config.fuelChest and config.fuelChest.x or 0
    local fuelY = config.fuelChest and config.fuelChest.y or 0
    local fuelZ = config.fuelChest and config.fuelChest.z or 0
    
    ui.drawInput(4, y, 20, "X", fuelX)
    ui.addButton("fuel_x", 4, y, 20, 1)
    
    ui.drawInput(4, y + 2, 20, "Y", fuelY)
    ui.addButton("fuel_y", 4, y + 2, 20, 1)
    
    ui.drawInput(4, y + 4, 20, "Z", fuelZ)
    ui.addButton("fuel_z", 4, y + 4, 20, 1)
    
    y = y + 8
    ui.leftText(y, "COFFRE MATERIAUX:", colors.yellow)
    y = y + 2
    
    local matX = config.materialChest and config.materialChest.x or 0
    local matY = config.materialChest and config.materialChest.y or 0
    local matZ = config.materialChest and config.materialChest.z or 0
    
    ui.drawInput(4, y, 20, "X", matX)
    ui.addButton("mat_x", 4, y, 20, 1)
    
    ui.drawInput(4, y + 2, 20, "Y", matY)
    ui.addButton("mat_y", 4, y + 2, 20, 1)
    
    ui.drawInput(4, y + 4, 20, "Z", matZ)
    ui.addButton("mat_z", 4, y + 4, 20, 1)
    
    -- Boutons
    local btnY = monH - 4
    local btn = ui.drawButton(3, btnY, 15, 3, "< Retour", false)
    ui.addButton("back", btn.x, btn.y, btn.w, btn.h)
    
    btn = ui.drawButton(monW - 17, btnY, 15, 3, "Sauver >", true)
    ui.addButton("save", btn.x, btn.y, btn.w, btn.h)
end

-- Ecran de configuration position
function ui.drawPositionConfig(config)
    ui.clear()
    ui.clearButtons()
    
    ui.drawHeader("POSITION DE DEPART")
    
    local y = 6
    
    ui.leftText(y, "COORDONNEES:", colors.yellow)
    y = y + 2
    
    local startX = config.buildStart and config.buildStart.x or 0
    local startY = config.buildStart and config.buildStart.y or 0
    local startZ = config.buildStart and config.buildStart.z or 0
    
    ui.drawInput(4, y, 20, "X", startX)
    ui.addButton("start_x", 4, y, 20, 1)
    
    ui.drawInput(4, y + 2, 20, "Y", startY)
    ui.addButton("start_y", 4, y + 2, 20, 1)
    
    ui.drawInput(4, y + 4, 20, "Z", startZ)
    ui.addButton("start_z", 4, y + 4, 20, 1)
    
    y = y + 8
    ui.leftText(y, "DIRECTION:", colors.yellow)
    y = y + 2
    
    local directions = {"Nord", "Est", "Sud", "Ouest"}
    local btnW = 12
    local btnSpacing = 2
    
    for i, dir in ipairs(directions) do
        local active = (config.buildDirection == i - 1)
        local btnX = 4 + (i - 1) * (btnW + btnSpacing)
        local btn = ui.drawButton(btnX, y, btnW, 3, dir, active)
        ui.addButton("dir_" .. (i - 1), btn.x, btn.y, btn.w, btn.h)
    end
    
    -- Boutons
    local btnY = monH - 4
    local btn = ui.drawButton(3, btnY, 15, 3, "< Retour", false)
    ui.addButton("back", btn.x, btn.y, btn.w, btn.h)
    
    btn = ui.drawButton(monW - 17, btnY, 15, 3, "Sauver >", true)
    ui.addButton("save", btn.x, btn.y, btn.w, btn.h)
end

-- Ecran de chargement schematic
function ui.drawSchematicList(schematics, selected)
    ui.clear()
    ui.clearButtons()
    
    ui.drawHeader("CHARGER SCHEMATIC")
    
    local y = 5
    ui.leftText(y, "Fichiers disponibles:", colors.yellow)
    y = y + 2
    
    local listH = monH - y - 6
    ui.drawList(3, y, monW - 6, listH, schematics, selected)
    
    -- Zone cliquable pour chaque item
    for i = 1, math.min(#schematics, listH) do
        ui.addButton("item_" .. i, 3, y + i - 1, monW - 6, 1)
    end
    
    -- Boutons
    local btnY = monH - 4
    local btn = ui.drawButton(3, btnY, 15, 3, "< Retour", false)
    ui.addButton("back", btn.x, btn.y, btn.w, btn.h)
    
    btn = ui.drawButton(monW - 17, btnY, 15, 3, "Charger >", selected ~= nil)
    ui.addButton("load", btn.x, btn.y, btn.w, btn.h)
end

-- Ecran de configuration materiaux
function ui.drawMaterialConfig(materials, slotMapping)
    ui.clear()
    ui.clearButtons()
    
    ui.drawHeader("CONFIGURATION MATERIAUX")
    
    local y = 5
    ui.leftText(y, "Bloc -> Slot turtle (1-16):", colors.yellow)
    y = y + 2
    
    local col1 = 3
    local col2 = monW / 2 + 2
    local currentCol = col1
    local startY = y
    
    for i, mat in ipairs(materials or {}) do
        if i > 16 then break end
        
        local slot = slotMapping[mat.id] or i
        local text = string.format("%s", mat.name:gsub("minecraft:", ""))
        if #text > 18 then text = string.sub(text, 1, 15) .. "..." end
        
        ui.setColors(colors.white, colors_bg)
        monitor.setCursorPos(currentCol, y)
        monitor.write(text)
        
        local inputX = currentCol + 20
        ui.drawInput(inputX - 8, y, 10, "Slot", slot)
        ui.addButton("slot_" .. mat.id, inputX - 8, y, 10, 1)
        
        y = y + 2
        
        if i == 8 then
            currentCol = col2
            y = startY
        end
    end
    
    -- Boutons
    local btnY = monH - 4
    local btn = ui.drawButton(3, btnY, 15, 3, "< Retour", false)
    ui.addButton("back", btn.x, btn.y, btn.w, btn.h)
    
    btn = ui.drawButton(monW - 17, btnY, 15, 3, "Sauver >", true)
    ui.addButton("save", btn.x, btn.y, btn.w, btn.h)
end

-- Ecran vue 2D de la couche actuelle
function ui.drawLayerView(schematic, layer, turtleX, turtleZ)
    if not schematic then return end
    
    local startX = 3
    local startY = 5
    local maxW = monW - 6
    local maxH = monH - 10
    
    local scaleX = math.max(1, math.ceil(schematic.width / maxW))
    local scaleZ = math.max(1, math.ceil(schematic.length / maxH))
    local scale = math.max(scaleX, scaleZ)
    
    local displayW = math.floor(schematic.width / scale)
    local displayH = math.floor(schematic.length / scale)
    
    for dz = 0, displayH - 1 do
        for dx = 0, displayW - 1 do
            local x = dx * scale
            local z = dz * scale
            
            -- Moyenne des blocs dans cette zone
            local hasBlock = false
            for sx = 0, scale - 1 do
                for sz = 0, scale - 1 do
                    if schematic.getBlock then
                        local blockId = schematic.getBlock(x + sx, layer, z + sz)
                        if blockId and blockId ~= 0 then
                            hasBlock = true
                            break
                        end
                    end
                end
                if hasBlock then break end
            end
            
            monitor.setCursorPos(startX + dx, startY + dz)
            
            if turtleX and turtleZ and 
               x <= turtleX and turtleX < x + scale and
               z <= turtleZ and turtleZ < z + scale then
                ui.setColors(colors.red, colors_bg)
                monitor.write("T")
            elseif hasBlock then
                ui.setColors(colors.lime, colors_bg)
                monitor.write("#")
            else
                ui.setColors(colors.gray, colors_bg)
                monitor.write(".")
            end
        end
    end
end

-- Dialogue de saisie numerique
function ui.showNumberInput(title, currentValue)
    local value = tostring(currentValue or "")
    
    while true do
        ui.clear()
        ui.drawHeader(title)
        
        local y = math.floor(monH / 2) - 3
        
        -- Affiche la valeur actuelle
        ui.centerText(y, "Valeur: " .. value, colors.white)
        
        -- Clavier numerique
        local keys = {"1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "0", "C"}
        local keyW = 5
        local keyH = 3
        local startX = math.floor((monW - 3 * keyW - 4) / 2)
        local startY = y + 3
        
        ui.clearButtons()
        
        for i, key in ipairs(keys) do
            local row = math.floor((i - 1) / 3)
            local col = (i - 1) % 3
            local kx = startX + col * (keyW + 2)
            local ky = startY + row * (keyH + 1)
            
            local btn = ui.drawButton(kx, ky, keyW, keyH, key, false)
            ui.addButton("key_" .. key, btn.x, btn.y, btn.w, btn.h)
        end
        
        -- Boutons OK / Annuler
        local btnY = startY + 4 * (keyH + 1) + 1
        local btn = ui.drawButton(startX, btnY, 8, 3, "Annuler", false)
        ui.addButton("cancel", btn.x, btn.y, btn.w, btn.h)
        
        btn = ui.drawButton(startX + 12, btnY, 8, 3, "OK", true)
        ui.addButton("ok", btn.x, btn.y, btn.w, btn.h)
        
        -- Attend un clic
        local event, side, x, y = os.pullEvent("monitor_touch")
        local clicked = ui.checkClick(x, y)
        
        if clicked then
            if clicked == "ok" then
                return tonumber(value)
            elseif clicked == "cancel" then
                return nil
            elseif clicked == "key_C" then
                value = ""
            elseif clicked:match("^key_") then
                local key = clicked:sub(5)
                if key == "-" and #value == 0 then
                    value = "-"
                elseif key:match("%d") then
                    value = value .. key
                end
            end
        end
    end
end

return ui
