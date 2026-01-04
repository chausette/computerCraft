-- ============================================
-- Potion Maker - Remote (Pocket Computer)
-- Controle a distance du systeme de potions
-- ============================================

-- Configuration
local PROTOCOL = "potion_network"
local CHANNEL = 500
local SERVER_ID = nil

-- État
local currentScreen = "main"
local potions = {}
local queueInfo = {}
local stockInfo = {}
local selectedPotion = nil
local selectedVariant = "normal"
local selectedForm = "normal"
local selectedQuantity = 3
local scrollOffset = 0

-- Couleurs
local theme = {
    bg = colors.black,
    header = colors.cyan,
    text = colors.white,
    textDim = colors.lightGray,
    success = colors.green,
    warning = colors.orange,
    error = colors.red,
    button = colors.gray,
    buttonActive = colors.blue
}

-- Boutons pour les clics
local buttons = {}

-- Utilitaires
local function setColors(bg, fg)
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
end

local function clear()
    setColors(theme.bg, theme.text)
    term.clear()
    term.setCursorPos(1, 1)
end

local function centerText(y, text, fg, bg)
    local w, _ = term.getSize()
    local x = math.floor((w - #text) / 2) + 1
    term.setCursorPos(x, y)
    setColors(bg or theme.bg, fg or theme.text)
    print(text)
end

local function drawButton(x, y, text, active, action)
    local bg = active and theme.buttonActive or theme.button
    setColors(bg, theme.text)
    term.setCursorPos(x, y)
    term.write(" " .. text .. " ")
    table.insert(buttons, {
        x1 = x, y1 = y,
        x2 = x + #text + 1, y2 = y,
        action = action or text
    })
end

-- Communication réseau
local function sendRequest(data)
    if not SERVER_ID then
        return { success = false, error = "Serveur non connecte" }
    end
    
    rednet.send(SERVER_ID, data, PROTOCOL)
    
    local senderId, response = rednet.receive(PROTOCOL, 5)
    
    if senderId == SERVER_ID and response then
        return response
    end
    
    return { success = false, error = "Timeout" }
end

local function findServer()
    rednet.broadcast({ action = "ping" }, PROTOCOL)
    
    local senderId, response = rednet.receive(PROTOCOL, 3)
    
    if senderId and response and response.success then
        SERVER_ID = senderId
        return true
    end
    
    return false
end

-- Écrans
local function drawHeader(title)
    clear()
    buttons = {}
    
    local w, _ = term.getSize()
    setColors(theme.header, theme.bg)
    term.setCursorPos(1, 1)
    term.clearLine()
    term.write(" " .. title)
    
    -- Bouton retour
    if currentScreen ~= "main" then
        term.setCursorPos(w - 3, 1)
        term.write(" < ")
        table.insert(buttons, {
            x1 = w - 3, y1 = 1, x2 = w, y2 = 1,
            action = "back"
        })
    end
    
    setColors(theme.bg, theme.text)
end

local function drawMainScreen()
    drawHeader("POTION REMOTE")
    
    local w, h = term.getSize()
    local btnY = 4
    
    -- Boutons principaux
    centerText(btnY, "[ Status ]", theme.text, theme.button)
    table.insert(buttons, { x1 = 1, y1 = btnY, x2 = w, y2 = btnY, action = "status" })
    
    btnY = btnY + 2
    centerText(btnY, "[ Commander ]", theme.text, theme.button)
    table.insert(buttons, { x1 = 1, y1 = btnY, x2 = w, y2 = btnY, action = "order" })
    
    btnY = btnY + 2
    centerText(btnY, "[ File d'attente ]", theme.text, theme.button)
    table.insert(buttons, { x1 = 1, y1 = btnY, x2 = w, y2 = btnY, action = "queue" })
    
    btnY = btnY + 2
    centerText(btnY, "[ Stock ]", theme.text, theme.button)
    table.insert(buttons, { x1 = 1, y1 = btnY, x2 = w, y2 = btnY, action = "stock" })
    
    -- Statut connexion
    term.setCursorPos(1, h)
    if SERVER_ID then
        setColors(theme.bg, theme.success)
        term.write("Connecte (ID:" .. SERVER_ID .. ")")
    else
        setColors(theme.bg, theme.error)
        term.write("Deconnecte")
    end
end

local function drawStatusScreen()
    drawHeader("STATUS")
    
    local response = sendRequest({ action = "getStatus" })
    
    if not response.success then
        term.setCursorPos(2, 4)
        setColors(theme.bg, theme.error)
        term.write("Erreur: " .. (response.error or "inconnu"))
        return
    end
    
    local data = response.data
    
    -- Alambics
    term.setCursorPos(2, 3)
    setColors(theme.bg, theme.header)
    term.write("ALAMBICS")
    
    for i, stand in ipairs(data.brewing_stands) do
        term.setCursorPos(2, 3 + i)
        setColors(theme.bg, theme.text)
        term.write(i .. ": ")
        
        if stand.status == "idle" then
            setColors(theme.bg, theme.success)
            term.write("Pret")
        elseif stand.status == "brewing" then
            setColors(theme.bg, theme.warning)
            term.write("Brassage " .. stand.progress .. "%")
        else
            setColors(theme.bg, theme.textDim)
            term.write(stand.status)
        end
    end
    
    -- File d'attente
    local qY = 3 + #data.brewing_stands + 2
    term.setCursorPos(2, qY)
    setColors(theme.bg, theme.header)
    term.write("FILE D'ATTENTE")
    
    term.setCursorPos(2, qY + 1)
    setColors(theme.bg, theme.text)
    term.write("En attente: " .. data.queue.pending)
    
    term.setCursorPos(2, qY + 2)
    term.write("En cours: " .. data.queue.processing)
end

local function drawOrderScreen()
    drawHeader("COMMANDER")
    
    -- Charger la liste des potions si nécessaire
    if #potions == 0 then
        local response = sendRequest({ action = "getPotions" })
        if response.success then
            potions = response.data.potions
        end
    end
    
    local w, h = term.getSize()
    
    -- Liste des potions
    term.setCursorPos(1, 3)
    setColors(theme.bg, theme.header)
    term.write(" Potion:")
    
    local listHeight = 5
    for i = 1, listHeight do
        local idx = i + scrollOffset
        if idx <= #potions then
            local potion = potions[idx]
            local y = 3 + i
            local selected = selectedPotion == potion.key
            
            term.setCursorPos(1, y)
            setColors(selected and theme.buttonActive or theme.bg, theme.text)
            term.clearLine()
            term.write(" " .. potion.name:sub(1, w - 2))
            
            table.insert(buttons, {
                x1 = 1, y1 = y, x2 = w, y2 = y,
                action = "selectPotion",
                potion = potion.key
            })
        end
    end
    
    -- Options
    local optY = 10
    
    -- Variant
    term.setCursorPos(1, optY)
    setColors(theme.bg, theme.textDim)
    term.write(" Type: ")
    
    local variants = { {"N", "normal"}, {"P+", "extended"}, {"II", "amplified"} }
    local vx = 8
    for _, v in ipairs(variants) do
        local active = selectedVariant == v[2]
        setColors(active and theme.buttonActive or theme.button, theme.text)
        term.write(" " .. v[1] .. " ")
        table.insert(buttons, {
            x1 = vx, y1 = optY, x2 = vx + #v[1] + 1, y2 = optY,
            action = "selectVariant",
            variant = v[2]
        })
        vx = vx + #v[1] + 3
    end
    
    -- Forme
    optY = optY + 1
    term.setCursorPos(1, optY)
    setColors(theme.bg, theme.textDim)
    term.write(" Forme: ")
    
    local forms = { {"Norm", "normal"}, {"Spl", "splash"}, {"Ling", "lingering"} }
    vx = 8
    for _, f in ipairs(forms) do
        local active = selectedForm == f[2]
        setColors(active and theme.buttonActive or theme.button, theme.text)
        term.write(" " .. f[1] .. " ")
        table.insert(buttons, {
            x1 = vx, y1 = optY, x2 = vx + #f[1] + 1, y2 = optY,
            action = "selectForm",
            form = f[2]
        })
        vx = vx + #f[1] + 3
    end
    
    -- Quantité
    optY = optY + 1
    term.setCursorPos(1, optY)
    setColors(theme.bg, theme.textDim)
    term.write(" Qte: ")
    
    drawButton(7, optY, "-", false, "qtyDown")
    term.setCursorPos(11, optY)
    setColors(theme.bg, theme.text)
    term.write(tostring(selectedQuantity))
    drawButton(14, optY, "+", false, "qtyUp")
    
    -- Bouton commander
    optY = optY + 2
    term.setCursorPos(1, optY)
    if selectedPotion then
        setColors(theme.success, theme.bg)
        centerText(optY, "[ COMMANDER ]", theme.bg, theme.success)
        table.insert(buttons, {
            x1 = 1, y1 = optY, x2 = w, y2 = optY,
            action = "placeOrder"
        })
    end
end

local function drawQueueScreen()
    drawHeader("FILE D'ATTENTE")
    
    local response = sendRequest({ action = "getQueue" })
    
    if not response.success then
        term.setCursorPos(2, 4)
        setColors(theme.bg, theme.error)
        term.write("Erreur: " .. (response.error or "inconnu"))
        return
    end
    
    local data = response.data
    local y = 3
    
    -- En cours
    if #data.processing > 0 then
        term.setCursorPos(1, y)
        setColors(theme.bg, theme.warning)
        term.write(" EN COURS:")
        y = y + 1
        
        for _, cmd in ipairs(data.processing) do
            term.setCursorPos(1, y)
            setColors(theme.bg, theme.text)
            term.write(" " .. cmd.potionName:sub(1, 20) .. " x" .. cmd.quantity)
            y = y + 1
        end
        y = y + 1
    end
    
    -- En attente
    if #data.pending > 0 then
        term.setCursorPos(1, y)
        setColors(theme.bg, theme.header)
        term.write(" EN ATTENTE:")
        y = y + 1
        
        for i, cmd in ipairs(data.pending) do
            if y < 17 then
                term.setCursorPos(1, y)
                setColors(theme.bg, theme.textDim)
                term.write(" " .. i .. ". " .. cmd.potionName:sub(1, 18) .. " x" .. cmd.quantity)
                y = y + 1
            end
        end
    else
        term.setCursorPos(1, y)
        setColors(theme.bg, theme.textDim)
        term.write(" Aucune commande en attente")
    end
end

local function drawStockScreen()
    drawHeader("STOCK")
    
    local response = sendRequest({ action = "getStock" })
    
    if not response.success then
        term.setCursorPos(2, 4)
        setColors(theme.bg, theme.error)
        term.write("Erreur: " .. (response.error or "inconnu"))
        return
    end
    
    local data = response.data
    local threshold = data.low_stock_threshold or 5
    local y = 3
    local w, _ = term.getSize()
    
    -- Fioles d'eau
    term.setCursorPos(1, y)
    setColors(theme.bg, theme.text)
    term.write(" Fioles d'eau")
    term.setCursorPos(w - 5, y)
    setColors(theme.bg, data.water_bottles < threshold and theme.error or theme.success)
    term.write("x" .. data.water_bottles)
    y = y + 2
    
    -- Ingrédients importants
    term.setCursorPos(1, y)
    setColors(theme.bg, theme.header)
    term.write(" INGREDIENTS")
    y = y + 1
    
    local important = {
        "minecraft:nether_wart",
        "minecraft:blaze_powder",
        "minecraft:redstone",
        "minecraft:glowstone_dust",
        "minecraft:gunpowder"
    }
    
    for _, item in ipairs(important) do
        if y < 18 then
            local count = data.ingredients[item] or 0
            local name = item:gsub("minecraft:", ""):gsub("_", " ")
            
            term.setCursorPos(1, y)
            setColors(theme.bg, theme.text)
            term.write(" " .. name:sub(1, 15))
            
            term.setCursorPos(w - 5, y)
            setColors(theme.bg, count < threshold and theme.warning or theme.textDim)
            term.write("x" .. count)
            
            y = y + 1
        end
    end
end

-- Gestion des clics
local function handleClick(x, y)
    for _, btn in ipairs(buttons) do
        if x >= btn.x1 and x <= btn.x2 and y >= btn.y1 and y <= btn.y2 then
            return handleAction(btn)
        end
    end
    return false
end

function handleAction(btn)
    local action = btn.action
    
    if action == "back" then
        currentScreen = "main"
        return true
        
    elseif action == "status" then
        currentScreen = "status"
        return true
        
    elseif action == "order" then
        currentScreen = "order"
        return true
        
    elseif action == "queue" then
        currentScreen = "queue"
        return true
        
    elseif action == "stock" then
        currentScreen = "stock"
        return true
        
    elseif action == "selectPotion" then
        selectedPotion = btn.potion
        return true
        
    elseif action == "selectVariant" then
        selectedVariant = btn.variant
        return true
        
    elseif action == "selectForm" then
        selectedForm = btn.form
        return true
        
    elseif action == "qtyUp" then
        selectedQuantity = math.min(selectedQuantity + 3, 64)
        return true
        
    elseif action == "qtyDown" then
        selectedQuantity = math.max(selectedQuantity - 3, 3)
        return true
        
    elseif action == "placeOrder" then
        if selectedPotion then
            local response = sendRequest({
                action = "order",
                potion = selectedPotion,
                variant = selectedVariant,
                form = selectedForm,
                quantity = selectedQuantity
            })
            
            if response.success then
                -- Afficher confirmation
                clear()
                centerText(5, "Commande envoyee!", theme.success)
                centerText(7, response.data.potionName, theme.text)
                centerText(8, "x" .. response.data.quantity, theme.text)
                centerText(10, "Position: " .. response.data.position, theme.textDim)
                sleep(2)
            else
                clear()
                centerText(5, "ERREUR", theme.error)
                centerText(7, response.error or "Erreur inconnue", theme.text)
                sleep(2)
            end
        end
        return true
    end
    
    return false
end

-- Écran de connexion
local function connectScreen()
    clear()
    centerText(3, "POTION REMOTE", theme.header)
    centerText(5, "Connexion...", theme.text)
    
    -- Ouvrir le modem
    local modem = peripheral.find("modem")
    if not modem then
        centerText(7, "Pas de modem!", theme.error)
        centerText(9, "Equipez un modem sans fil")
        return false
    end
    
    rednet.open(peripheral.getName(modem))
    
    -- Chercher le serveur
    for i = 1, 5 do
        centerText(7, "Tentative " .. i .. "/5", theme.textDim)
        
        if findServer() then
            centerText(9, "Connecte!", theme.success)
            sleep(1)
            return true
        end
        
        sleep(1)
    end
    
    centerText(9, "Serveur non trouve", theme.error)
    centerText(11, "Verifiez que le serveur")
    centerText(12, "est en marche.")
    
    return false
end

-- Dessiner l'écran actuel
local function draw()
    if currentScreen == "main" then
        drawMainScreen()
    elseif currentScreen == "status" then
        drawStatusScreen()
    elseif currentScreen == "order" then
        drawOrderScreen()
    elseif currentScreen == "queue" then
        drawQueueScreen()
    elseif currentScreen == "stock" then
        drawStockScreen()
    end
end

-- Boucle principale
local function main()
    if not connectScreen() then
        sleep(3)
        return
    end
    
    while true do
        draw()
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "mouse_click" or event == "monitor_touch" then
            handleClick(p2, p3)
            
        elseif event == "mouse_scroll" then
            if currentScreen == "order" then
                scrollOffset = math.max(0, scrollOffset + p1)
                scrollOffset = math.min(#potions - 5, scrollOffset)
            end
            
        elseif event == "key" then
            if p1 == keys.q then
                break
            elseif p1 == keys.backspace then
                if currentScreen ~= "main" then
                    currentScreen = "main"
                end
            elseif p1 == keys.r then
                -- Rafraîchir
                if currentScreen == "order" then
                    potions = {}
                end
            end
        end
    end
    
    rednet.close()
    clear()
    print("Au revoir!")
end

main()
