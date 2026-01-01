-- ============================================
-- UI.lua - Interface Moniteur Esthetique
-- Schematic Builder v1.2
-- ============================================

local ui = {}

local mon = nil
local W, H = 0, 0

-- Palette de couleurs
local C = {
    bg = colors.black,
    header = colors.blue,
    headerText = colors.white,
    btn = colors.gray,
    btnActive = colors.lime,
    btnText = colors.white,
    btnTextActive = colors.black,
    text = colors.white,
    textDim = colors.lightGray,
    accent = colors.cyan,
    success = colors.lime,
    warning = colors.orange,
    error = colors.red,
    border = colors.gray,
}

-- Boutons
local buttons = {}

-- ============================================
-- INIT
-- ============================================

function ui.init()
    mon = peripheral.find("monitor")
    if not mon then
        return false, "Moniteur non trouve"
    end
    
    mon.setTextScale(0.5)
    W, H = mon.getSize()
    
    return true
end

function ui.getSize()
    return W, H
end

function ui.getMonitor()
    return mon
end

-- ============================================
-- PRIMITIVES
-- ============================================

function ui.clear()
    mon.setBackgroundColor(C.bg)
    mon.clear()
    buttons = {}
end

function ui.setColor(fg, bg)
    if fg then mon.setTextColor(fg) end
    if bg then mon.setBackgroundColor(bg) end
end

function ui.write(x, y, text)
    mon.setCursorPos(x, y)
    mon.write(text)
end

function ui.fill(x, y, w, h, color)
    mon.setBackgroundColor(color)
    for i = 0, h - 1 do
        mon.setCursorPos(x, y + i)
        mon.write(string.rep(" ", w))
    end
end

function ui.center(y, text, fg, bg)
    local x = math.floor((W - #text) / 2) + 1
    ui.setColor(fg, bg or C.bg)
    ui.write(x, y, text)
end

function ui.box(x, y, w, h, title)
    ui.setColor(C.border, C.bg)
    
    ui.write(x, y, "+" .. string.rep("-", w - 2) .. "+")
    for i = 1, h - 2 do
        ui.write(x, y + i, "|")
        ui.write(x + w - 1, y + i, "|")
    end
    ui.write(x, y + h - 1, "+" .. string.rep("-", w - 2) .. "+")
    
    if title then
        ui.setColor(C.accent, C.bg)
        ui.write(x + 2, y, "[ " .. title .. " ]")
    end
end

-- ============================================
-- COMPOSANTS
-- ============================================

function ui.addButton(id, x, y, w, h)
    buttons[id] = {x = x, y = y, w = w, h = h}
end

function ui.checkClick(cx, cy)
    for id, b in pairs(buttons) do
        if cx >= b.x and cx < b.x + b.w and cy >= b.y and cy < b.y + b.h then
            return id
        end
    end
    return nil
end

function ui.button(x, y, w, text, active, id)
    local bg = active and C.btnActive or C.btn
    local fg = active and C.btnTextActive or C.btnText
    
    ui.fill(x, y, w, 1, bg)
    ui.setColor(fg, bg)
    
    local tx = x + math.floor((w - #text) / 2)
    ui.write(tx, y, text)
    
    if id then
        ui.addButton(id, x, y, w, 1)
    end
end

function ui.progress(x, y, w, current, max)
    local pct = max > 0 and (current / max) or 0
    local filled = math.floor(pct * (w - 2))
    
    ui.setColor(C.textDim, C.bg)
    ui.write(x, y, "[")
    
    ui.setColor(C.success, C.bg)
    mon.write(string.rep("=", filled))
    
    ui.setColor(C.textDim, C.bg)
    mon.write(string.rep("-", w - 2 - filled))
    mon.write("]")
    
    local pctText = string.format(" %d%%", math.floor(pct * 100))
    ui.setColor(C.text, C.bg)
    mon.write(pctText)
end

function ui.label(x, y, label, value, labelColor, valueColor)
    ui.setColor(labelColor or C.textDim, C.bg)
    ui.write(x, y, label .. ": ")
    ui.setColor(valueColor or C.text, C.bg)
    mon.write(tostring(value))
end

-- ============================================
-- HEADER
-- ============================================

function ui.header(title)
    ui.fill(1, 1, W, 1, C.header)
    ui.setColor(C.headerText, C.header)
    ui.center(1, title)
end

-- ============================================
-- ECRAN PRINCIPAL
-- ============================================

function ui.drawMain(state)
    ui.clear()
    ui.header("SCHEMATIC BUILDER")
    
    local midX = math.floor(W / 2)
    local btnW = midX - 3
    local y = 3
    
    -- Boutons gauche
    ui.button(2, y, btnW, "1. Charger", state.schematic ~= nil, "load")
    ui.button(midX + 1, y, btnW, "4. Materiaux", false, "materials")
    
    y = y + 2
    ui.button(2, y, btnW, "2. Coffres", false, "chests")
    
    local buildTxt = state.building and "STOP" or "5. BUILD"
    ui.button(midX + 1, y, btnW, buildTxt, state.schematic ~= nil, "build")
    
    y = y + 2
    ui.button(2, y, btnW, "3. Position", false, "position")
    
    local pauseTxt = state.paused and "REPRENDRE" or "6. Pause"
    ui.button(midX + 1, y, btnW, pauseTxt, state.building, "pause")
    
    -- Separateur
    y = y + 2
    ui.setColor(C.border, C.bg)
    ui.write(1, y, string.rep("-", W))
    
    -- Status
    y = y + 1
    ui.setColor(C.accent, C.bg)
    ui.write(2, y, "STATUS: ")
    
    local statusColor = C.text
    local status = state.status or "attente"
    if status == "building" or status == "pret" then statusColor = C.success
    elseif status == "pause" then statusColor = C.warning
    elseif status:find("err") or status == "deconnecte" then statusColor = C.error
    end
    ui.setColor(statusColor, C.bg)
    mon.write(status:sub(1, W - 12))
    
    -- Schematic info
    y = y + 1
    if state.schematicName then
        ui.setColor(C.textDim, C.bg)
        ui.write(2, y, "Fichier: ")
        ui.setColor(C.text, C.bg)
        mon.write(state.schematicName:sub(1, W - 12))
    end
    
    -- Progression
    y = y + 2
    if state.totalBlocks and state.totalBlocks > 0 then
        ui.label(2, y, "Couche", (state.layer or 0) .. "/" .. (state.schematicHeight or 0), C.textDim, C.accent)
        
        y = y + 1
        ui.label(2, y, "Blocs", (state.placedBlocks or 0) .. "/" .. (state.totalBlocks or 0), C.textDim, C.text)
        
        y = y + 1
        ui.progress(2, y, W - 8, state.placedBlocks or 0, state.totalBlocks or 0)
    end
    
    -- Infos turtle
    y = H - 1
    ui.setColor(C.textDim, C.bg)
    ui.write(2, y, "Fuel:")
    ui.setColor(state.fuel and state.fuel < 100 and C.error or C.text, C.bg)
    mon.write(tostring(state.fuel or 0))
    
    ui.setColor(C.textDim, C.bg)
    ui.write(midX, y, "Pos:")
    ui.setColor(C.text, C.bg)
    mon.write(string.format("%d,%d,%d", state.x or 0, state.y or 0, state.z or 0))
end

-- ============================================
-- ECRAN COFFRES
-- ============================================

function ui.drawChests(config)
    ui.clear()
    ui.header("CONFIGURATION COFFRES")
    
    local y = 3
    local fieldW = math.floor((W - 4) / 3)
    
    -- Coffre Fuel
    ui.box(1, y, W, 4, "COFFRE FUEL")
    y = y + 1
    
    local fx = config.fuelChest and config.fuelChest.x or 0
    local fy = config.fuelChest and config.fuelChest.y or 0
    local fz = config.fuelChest and config.fuelChest.z or 0
    
    ui.button(3, y + 1, fieldW, "X:" .. fx, false, "fx")
    ui.button(3 + fieldW + 1, y + 1, fieldW, "Y:" .. fy, false, "fy")
    ui.button(3 + (fieldW + 1) * 2, y + 1, fieldW, "Z:" .. fz, false, "fz")
    
    y = y + 5
    
    -- Coffre Materiaux
    ui.box(1, y, W, 4, "COFFRE MATERIAUX")
    y = y + 1
    
    local mx = config.materialChest and config.materialChest.x or 0
    local my = config.materialChest and config.materialChest.y or 0
    local mz = config.materialChest and config.materialChest.z or 0
    
    ui.button(3, y + 1, fieldW, "X:" .. mx, false, "mx")
    ui.button(3 + fieldW + 1, y + 1, fieldW, "Y:" .. my, false, "my")
    ui.button(3 + (fieldW + 1) * 2, y + 1, fieldW, "Z:" .. mz, false, "mz")
    
    -- Boutons bas
    local btnW = math.floor(W / 2) - 2
    ui.button(2, H - 1, btnW, "< Retour", false, "back")
    ui.button(W - btnW, H - 1, btnW, "Sauver >", true, "save")
end

-- ============================================
-- ECRAN POSITION
-- ============================================

function ui.drawPosition(config)
    ui.clear()
    ui.header("POSITION DE DEPART")
    
    local y = 3
    local fieldW = math.floor((W - 4) / 3)
    
    -- Coordonnees
    ui.box(1, y, W, 4, "COORDONNEES")
    y = y + 1
    
    local sx = config.buildStart and config.buildStart.x or 0
    local sy = config.buildStart and config.buildStart.y or 0
    local sz = config.buildStart and config.buildStart.z or 0
    
    ui.button(3, y + 1, fieldW, "X:" .. sx, false, "sx")
    ui.button(3 + fieldW + 1, y + 1, fieldW, "Y:" .. sy, false, "sy")
    ui.button(3 + (fieldW + 1) * 2, y + 1, fieldW, "Z:" .. sz, false, "sz")
    
    y = y + 5
    
    -- Direction
    ui.box(1, y, W, 4, "DIRECTION")
    y = y + 2
    
    local dirs = {"NORD", "EST", "SUD", "OUEST"}
    local dirW = math.floor((W - 4) / 4)
    
    for i, dir in ipairs(dirs) do
        local active = (config.buildDirection == i - 1)
        local x = 2 + (i - 1) * dirW
        ui.button(x, y, dirW - 1, dir, active, "dir" .. (i - 1))
    end
    
    -- Boutons bas
    local btnW = math.floor(W / 2) - 2
    ui.button(2, H - 1, btnW, "< Retour", false, "back")
    ui.button(W - btnW, H - 1, btnW, "Sauver >", true, "save")
end

-- ============================================
-- ECRAN SCHEMATICS
-- ============================================

function ui.drawSchematics(files, selected)
    ui.clear()
    ui.header("CHARGER SCHEMATIC")
    
    local y = 3
    local maxItems = H - 5
    
    if #files == 0 then
        ui.setColor(C.error, C.bg)
        ui.center(y + 2, "Aucun fichier dans schematics/")
        ui.setColor(C.textDim, C.bg)
        ui.center(y + 4, "Formats: .json ou .schematic")
    else
        for i = 1, math.min(#files, maxItems) do
            local isSelected = (i == selected)
            
            if isSelected then
                ui.fill(1, y, W, 1, C.btnActive)
                ui.setColor(C.btnTextActive, C.btnActive)
            else
                ui.setColor(C.text, C.bg)
            end
            
            local name = files[i]
            if #name > W - 6 then
                name = name:sub(1, W - 8) .. ".."
            end
            ui.write(3, y, i .. ". " .. name)
            ui.addButton("item" .. i, 1, y, W, 1)
            
            y = y + 1
        end
    end
    
    -- Boutons bas
    local btnW = math.floor(W / 2) - 2
    ui.button(2, H - 1, btnW, "< Retour", false, "back")
    ui.button(W - btnW, H - 1, btnW, "Charger", selected ~= nil, "loadfile")
end

-- ============================================
-- ECRAN MATERIAUX
-- ============================================

function ui.drawMaterials(materials, slots, page)
    ui.clear()
    
    page = page or 1
    local perPage = H - 4
    local totalPages = math.max(1, math.ceil(#materials / perPage))
    
    ui.header("MATERIAUX " .. page .. "/" .. totalPages)
    
    local y = 3
    local startIdx = (page - 1) * perPage + 1
    
    for i = startIdx, math.min(#materials, startIdx + perPage - 1) do
        local mat = materials[i]
        local slot = slots[mat.id] or i
        
        ui.setColor(C.text, C.bg)
        local name = mat.name:gsub("minecraft:", "")
        if #name > W - 12 then
            name = name:sub(1, W - 14) .. ".."
        end
        ui.write(2, y, name)
        
        ui.button(W - 8, y, 7, "S:" .. slot, false, "slot" .. mat.id)
        
        y = y + 1
    end
    
    -- Boutons bas
    local btnW = math.floor(W / 3) - 1
    ui.button(2, H - 1, btnW, "Retour", false, "back")
    
    if totalPages > 1 then
        ui.button(2 + btnW + 1, H - 1, btnW, "Page+", true, "nextpage")
    end
    
    ui.button(W - btnW - 1, H - 1, btnW, "Sauver", true, "save")
end

-- ============================================
-- CLAVIER NUMERIQUE COMPACT
-- ============================================

function ui.numberInput(title, current)
    local value = tostring(current or "")
    
    while true do
        ui.clear()
        ui.header(title:sub(1, W - 2))
        
        -- Valeur actuelle
        ui.setColor(C.success, C.bg)
        ui.center(3, "Valeur: " .. value)
        
        -- Clavier compact - 4 colonnes x 4 lignes
        local keys = {
            {"1", "2", "3", "-"},
            {"4", "5", "6", "0"},
            {"7", "8", "9", "C"},
        }
        
        local keyW = math.floor((W - 8) / 4)
        local startX = math.floor((W - (keyW * 4 + 3)) / 2) + 1
        local startY = 5
        
        for row, rowKeys in ipairs(keys) do
            for col, key in ipairs(rowKeys) do
                local x = startX + (col - 1) * (keyW + 1)
                local y = startY + (row - 1) * 2
                ui.button(x, y, keyW, key, false, "k" .. key)
            end
        end
        
        -- Boutons OK / Annuler
        local btnY = startY + 6
        local btnW = math.floor((W - 6) / 2)
        
        ui.button(2, btnY, btnW, "Annuler", false, "cancel")
        ui.button(W - btnW - 1, btnY, btnW, "OK", true, "ok")
        
        -- Attente clic
        local event, side, cx, cy = os.pullEvent("monitor_touch")
        local clicked = ui.checkClick(cx, cy)
        
        if clicked then
            if clicked == "ok" then
                return tonumber(value) or 0
            elseif clicked == "cancel" then
                return nil
            elseif clicked == "kC" then
                value = ""
            elseif clicked == "k-" then
                if #value == 0 then
                    value = "-"
                end
            elseif clicked == "k0" then
                if #value > 0 or value == "-" then
                    value = value .. "0"
                end
            elseif clicked:match("^k%d$") then
                value = value .. clicked:sub(2)
            end
        end
    end
end

return ui
