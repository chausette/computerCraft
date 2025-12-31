-- ============================================
-- CLIENT POCKET ADVANCED - STOCKAGE
-- Recherche temps reel + navigation fleches
-- ============================================

local PROTOCOL = "storage_system"
local SERVER_ID = "storage_server"

local serverId = nil
local running = true
local allItems = {}  -- Cache de tous les items

-- === COULEURS ===
local colors_bg = colors.black
local colors_header = colors.blue
local colors_text = colors.white
local colors_dim = colors.lightGray
local colors_accent = colors.cyan
local colors_success = colors.lime
local colors_warning = colors.yellow
local colors_error = colors.red
local colors_selected = colors.blue

-- === FONCTIONS RESEAU ===

local function initNetwork()
    local modemSide = nil
    for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
        if peripheral.getType(side) == "modem" then
            modemSide = side
            break
        end
    end
    
    if not modemSide then
        return false, "Aucun modem trouve"
    end
    
    rednet.open(modemSide)
    serverId = rednet.lookup(PROTOCOL, SERVER_ID)
    
    if not serverId then
        return false, "Serveur non trouve"
    end
    
    return true, nil
end

local function sendRequest(request)
    if not serverId then
        return nil, "Non connecte"
    end
    
    rednet.send(serverId, request, PROTOCOL)
    local sender, response = rednet.receive(PROTOCOL, 5)
    
    if sender == serverId then
        return response, nil
    end
    
    return nil, "Timeout"
end

-- === FONCTIONS D'AFFICHAGE ===

local w, h = term.getSize()

local function clearScreen()
    term.setBackgroundColor(colors_bg)
    term.clear()
    term.setCursorPos(1, 1)
end

local function drawHeader(title)
    term.setBackgroundColor(colors_header)
    term.setTextColor(colors_text)
    term.setCursorPos(1, 1)
    term.write(string.rep(" ", w))
    local padding = math.floor((w - #title) / 2)
    term.setCursorPos(padding + 1, 1)
    term.write(title)
    term.setBackgroundColor(colors_bg)
end

local function drawFooter(text)
    term.setCursorPos(1, h)
    term.setBackgroundColor(colors_header)
    term.setTextColor(colors_dim)
    term.write(string.rep(" ", w))
    term.setCursorPos(1, h)
    term.write(text:sub(1, w))
    term.setBackgroundColor(colors_bg)
    term.setTextColor(colors_text)
end

local function writeAt(x, y, text, fg, bg)
    term.setCursorPos(x, y)
    if fg then term.setTextColor(fg) end
    if bg then term.setBackgroundColor(bg) end
    term.write(text)
    term.setBackgroundColor(colors_bg)
    term.setTextColor(colors_text)
end

-- === CHARGEMENT INVENTAIRE ===

local function loadAllItems()
    local response, err = sendRequest({type = "get_inventory"})
    if response and response.success then
        allItems = {}
        for name, data in pairs(response.data) do
            table.insert(allItems, {
                name = data.name,
                displayName = data.displayName,
                count = data.count,
                category = data.category
            })
        end
        table.sort(allItems, function(a, b)
            return a.displayName < b.displayName
        end)
        return true
    end
    return false
end

-- === FILTRAGE ===

local function filterItems(query)
    if query == "" then
        return allItems
    end
    
    local results = {}
    local lowerQuery = query:lower()
    
    for _, item in ipairs(allItems) do
        if item.displayName:lower():find(lowerQuery, 1, true) or
           item.name:lower():find(lowerQuery, 1, true) then
            table.insert(results, item)
        end
    end
    
    return results
end

-- === INTERFACE RECHERCHE TEMPS REEL ===

local function searchInterface()
    loadAllItems()
    
    local query = ""
    local selectedIdx = 1
    local scrollOffset = 0
    local filteredItems = allItems
    local maxVisible = h - 5  -- Lignes visibles
    
    local function redraw()
        clearScreen()
        drawHeader("RECHERCHE")
        
        -- Barre de recherche
        writeAt(1, 2, ">", colors_accent)
        writeAt(3, 2, query, colors_text)
        writeAt(3 + #query, 2, "_", colors_dim)
        
        -- Ligne de separation
        writeAt(1, 3, string.rep("-", w), colors_dim)
        
        -- Liste des resultats
        local startY = 4
        
        if #filteredItems == 0 then
            writeAt(2, startY, "Aucun resultat", colors_dim)
        else
            for i = 1, maxVisible do
                local idx = scrollOffset + i
                local item = filteredItems[idx]
                
                if item then
                    local y = startY + i - 1
                    local isSelected = (idx == selectedIdx)
                    
                    -- Fond de selection
                    if isSelected then
                        term.setCursorPos(1, y)
                        term.setBackgroundColor(colors_selected)
                        term.write(string.rep(" ", w))
                    end
                    
                    -- Nom de l'item
                    local name = item.displayName
                    local maxLen = w - 8
                    if #name > maxLen then
                        name = name:sub(1, maxLen - 2) .. ".."
                    end
                    
                    local nameColor = colors_text
                    if item.count == 0 then
                        nameColor = colors_error
                    elseif item.count < 10 then
                        nameColor = colors_warning
                    end
                    
                    writeAt(2, y, name, nameColor, isSelected and colors_selected or colors_bg)
                    
                    -- Quantite
                    local countStr = tostring(item.count)
                    writeAt(w - #countStr, y, countStr, colors_accent, isSelected and colors_selected or colors_bg)
                    
                    term.setBackgroundColor(colors_bg)
                end
            end
        end
        
        -- Info en bas
        local info = #filteredItems .. " items"
        if #filteredItems > 0 then
            info = selectedIdx .. "/" .. #filteredItems
        end
        drawFooter("^v:Nav Enter:Ok Esc:Retour " .. info)
        
        -- Curseur sur la recherche
        term.setCursorPos(3 + #query, 2)
    end
    
    redraw()
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "char" then
            -- Ajout caractere
            query = query .. p1
            filteredItems = filterItems(query)
            selectedIdx = 1
            scrollOffset = 0
            redraw()
            
        elseif event == "key" then
            local key = p1
            
            if key == keys.backspace then
                -- Effacer caractere
                if #query > 0 then
                    query = query:sub(1, -2)
                    filteredItems = filterItems(query)
                    selectedIdx = 1
                    scrollOffset = 0
                end
                redraw()
                
            elseif key == keys.up then
                -- Monter dans la liste
                if selectedIdx > 1 then
                    selectedIdx = selectedIdx - 1
                    if selectedIdx <= scrollOffset then
                        scrollOffset = scrollOffset - 1
                    end
                end
                redraw()
                
            elseif key == keys.down then
                -- Descendre dans la liste
                if selectedIdx < #filteredItems then
                    selectedIdx = selectedIdx + 1
                    if selectedIdx > scrollOffset + maxVisible then
                        scrollOffset = scrollOffset + 1
                    end
                end
                redraw()
                
            elseif key == keys.enter then
                -- Selectionner l'item
                if #filteredItems > 0 and filteredItems[selectedIdx] then
                    return filteredItems[selectedIdx]
                end
                
            elseif key == keys.escape or key == keys.tab then
                -- Retour
                return nil
                
            elseif key == keys.pageUp then
                -- Page haut
                selectedIdx = math.max(1, selectedIdx - maxVisible)
                scrollOffset = math.max(0, selectedIdx - 1)
                redraw()
                
            elseif key == keys.pageDown then
                -- Page bas
                selectedIdx = math.min(#filteredItems, selectedIdx + maxVisible)
                scrollOffset = math.max(0, selectedIdx - maxVisible)
                redraw()
            end
        end
    end
end

-- === INTERFACE ACTION ITEM ===

local function itemActionInterface(item)
    local selectedOption = 1
    local options = {
        {text = "Commander", action = "retrieve"},
        {text = "Ajouter aux favoris", action = "add_fav"},
        {text = "Retirer des favoris", action = "rem_fav"},
        {text = "Retour", action = "back"}
    }
    
    local function redraw()
        clearScreen()
        drawHeader(item.displayName:sub(1, w))
        
        writeAt(2, 3, "Stock: " .. item.count, item.count > 0 and colors_success or colors_error)
        writeAt(2, 4, "Cat: " .. (item.category or "?"), colors_dim)
        
        writeAt(1, 6, string.rep("-", w), colors_dim)
        
        for i, opt in ipairs(options) do
            local y = 7 + i
            local isSelected = (i == selectedOption)
            
            if isSelected then
                term.setCursorPos(1, y)
                term.setBackgroundColor(colors_selected)
                term.write(string.rep(" ", w))
                writeAt(2, y, "> " .. opt.text, colors_text, colors_selected)
            else
                writeAt(2, y, "  " .. opt.text, colors_dim)
            end
        end
        
        term.setBackgroundColor(colors_bg)
        drawFooter("^v:Nav Enter:Ok Esc:Retour")
    end
    
    redraw()
    
    while true do
        local event, key = os.pullEvent("key")
        
        if key == keys.up then
            selectedOption = selectedOption > 1 and selectedOption - 1 or #options
            redraw()
        elseif key == keys.down then
            selectedOption = selectedOption < #options and selectedOption + 1 or 1
            redraw()
        elseif key == keys.enter then
            return options[selectedOption].action
        elseif key == keys.escape or key == keys.tab then
            return "back"
        end
    end
end

-- === INTERFACE QUANTITE ===

local function quantityInterface(item, maxQty)
    local qty = 1
    maxQty = math.min(maxQty, item.count, 64)
    
    if maxQty <= 0 then
        return 0
    end
    
    local function redraw()
        clearScreen()
        drawHeader("COMMANDER")
        
        writeAt(2, 3, item.displayName, colors_text)
        writeAt(2, 4, "Stock: " .. item.count, colors_dim)
        
        writeAt(2, 6, "Quantite:", colors_text)
        
        -- Affichage quantite avec fleches
        local qtyStr = "< " .. string.format("%3d", qty) .. " >"
        writeAt(math.floor((w - #qtyStr) / 2), 8, qtyStr, colors_accent)
        
        -- Raccourcis
        writeAt(2, 10, "1=1  2=16  3=32  4=64", colors_dim)
        
        drawFooter("<>:Qte Enter:Ok Esc:Annuler")
    end
    
    redraw()
    
    while true do
        local event, key = os.pullEvent("key")
        
        if key == keys.left then
            qty = math.max(1, qty - 1)
            redraw()
        elseif key == keys.right then
            qty = math.min(maxQty, qty + 1)
            redraw()
        elseif key == keys.up then
            qty = math.min(maxQty, qty + 10)
            redraw()
        elseif key == keys.down then
            qty = math.max(1, qty - 10)
            redraw()
        elseif key == keys.one then
            qty = 1
            redraw()
        elseif key == keys.two then
            qty = math.min(maxQty, 16)
            redraw()
        elseif key == keys.three then
            qty = math.min(maxQty, 32)
            redraw()
        elseif key == keys.four then
            qty = math.min(maxQty, 64)
            redraw()
        elseif key == keys.enter then
            return qty
        elseif key == keys.escape or key == keys.tab then
            return 0
        end
    end
end

-- === INTERFACE MESSAGE ===

local function showMessage(title, message, isError)
    clearScreen()
    drawHeader(title)
    
    local color = isError and colors_error or colors_success
    writeAt(2, math.floor(h/2), message, color)
    
    drawFooter("Appuyez sur une touche...")
    os.pullEvent("key")
end

-- === ACTIONS ===

local function doRetrieve(item)
    if item.count <= 0 then
        showMessage("ERREUR", "Stock vide!", true)
        return
    end
    
    local qty = quantityInterface(item, item.count)
    
    if qty > 0 then
        clearScreen()
        drawHeader("ENVOI...")
        writeAt(2, math.floor(h/2), "Transfert en cours...", colors_dim)
        
        local response, err = sendRequest({
            type = "retrieve_item",
            itemName = item.name,
            count = qty
        })
        
        if response and response.success then
            showMessage("OK", response.data .. " items envoyes!", false)
            -- Recharger l'inventaire
            loadAllItems()
        else
            showMessage("ERREUR", err or (response and response.error) or "Echec", true)
        end
    end
end

local function doAddFavorite(item)
    local response = sendRequest({
        type = "add_favorite",
        itemName = item.name
    })
    
    if response and response.success then
        showMessage("OK", "Ajoute aux favoris!", false)
    else
        showMessage("ERREUR", response and response.error or "Echec", true)
    end
end

local function doRemoveFavorite(item)
    local response = sendRequest({
        type = "remove_favorite",
        itemName = item.name
    })
    
    if response and response.success then
        showMessage("OK", "Retire des favoris!", false)
    else
        showMessage("ERREUR", response and response.error or "Echec", true)
    end
end

-- === MENU FAVORIS ===

local function favoritesInterface()
    local response = sendRequest({type = "get_favorites"})
    if not response or not response.success then
        showMessage("ERREUR", "Impossible de charger", true)
        return
    end
    
    local favorites = response.data
    if #favorites == 0 then
        showMessage("FAVORIS", "Aucun favori configure", true)
        return
    end
    
    local selectedIdx = 1
    local scrollOffset = 0
    local maxVisible = h - 4
    
    local function redraw()
        clearScreen()
        drawHeader("FAVORIS")
        
        for i = 1, maxVisible do
            local idx = scrollOffset + i
            local fav = favorites[idx]
            
            if fav then
                local y = 2 + i
                local isSelected = (idx == selectedIdx)
                
                if isSelected then
                    term.setCursorPos(1, y)
                    term.setBackgroundColor(colors_selected)
                    term.write(string.rep(" ", w))
                end
                
                local name = fav.displayName
                if #name > w - 10 then
                    name = name:sub(1, w - 13) .. ".."
                end
                
                local nameColor = colors_text
                if not fav.inStock or fav.count == 0 then
                    nameColor = colors_error
                elseif fav.count < 10 then
                    nameColor = colors_warning
                end
                
                writeAt(2, y, name, nameColor, isSelected and colors_selected or colors_bg)
                writeAt(w - #tostring(fav.count), y, tostring(fav.count), colors_accent, isSelected and colors_selected or colors_bg)
            end
        end
        
        term.setBackgroundColor(colors_bg)
        drawFooter("^v:Nav Enter:Cmd Esc:Retour")
    end
    
    redraw()
    
    while true do
        local event, key = os.pullEvent("key")
        
        if key == keys.up then
            if selectedIdx > 1 then
                selectedIdx = selectedIdx - 1
                if selectedIdx <= scrollOffset then
                    scrollOffset = scrollOffset - 1
                end
            end
            redraw()
        elseif key == keys.down then
            if selectedIdx < #favorites then
                selectedIdx = selectedIdx + 1
                if selectedIdx > scrollOffset + maxVisible then
                    scrollOffset = scrollOffset + 1
                end
            end
            redraw()
        elseif key == keys.enter then
            local fav = favorites[selectedIdx]
            if fav and fav.inStock and fav.count > 0 then
                doRetrieve(fav)
                -- Recharger les favoris
                response = sendRequest({type = "get_favorites"})
                if response and response.success then
                    favorites = response.data
                end
                redraw()
            elseif fav then
                showMessage("ERREUR", "Stock vide!", true)
                redraw()
            end
        elseif key == keys.escape or key == keys.tab then
            return
        end
    end
end

-- === MENU CATEGORIES ===

local function categoriesInterface()
    local response = sendRequest({type = "get_by_category"})
    if not response or not response.success then
        showMessage("ERREUR", "Impossible de charger", true)
        return
    end
    
    local categories = {}
    for name, data in pairs(response.data) do
        if data.items and #data.items > 0 then
            table.insert(categories, {name = name, items = data.items, count = #data.items})
        end
    end
    table.sort(categories, function(a, b) return a.name < b.name end)
    
    if #categories == 0 then
        showMessage("CATEGORIES", "Aucun item en stock", true)
        return
    end
    
    local selectedIdx = 1
    
    local function redrawCats()
        clearScreen()
        drawHeader("CATEGORIES")
        
        for i, cat in ipairs(categories) do
            local y = 2 + i
            if y > h - 2 then break end
            
            local isSelected = (i == selectedIdx)
            
            if isSelected then
                term.setCursorPos(1, y)
                term.setBackgroundColor(colors_selected)
                term.write(string.rep(" ", w))
            end
            
            local name = cat.name
            if #name > w - 8 then name = name:sub(1, w - 11) .. ".." end
            
            writeAt(2, y, name, colors_text, isSelected and colors_selected or colors_bg)
            writeAt(w - #tostring(cat.count) - 1, y, "(" .. cat.count .. ")", colors_dim, isSelected and colors_selected or colors_bg)
        end
        
        term.setBackgroundColor(colors_bg)
        drawFooter("^v:Nav Enter:Voir Esc:Retour")
    end
    
    redrawCats()
    
    while true do
        local event, key = os.pullEvent("key")
        
        if key == keys.up then
            selectedIdx = selectedIdx > 1 and selectedIdx - 1 or #categories
            redrawCats()
        elseif key == keys.down then
            selectedIdx = selectedIdx < #categories and selectedIdx + 1 or 1
            redrawCats()
        elseif key == keys.enter then
            -- Afficher les items de la categorie
            local cat = categories[selectedIdx]
            if cat then
                allItems = cat.items
                local item = searchInterface()
                if item then
                    local action = itemActionInterface(item)
                    if action == "retrieve" then
                        doRetrieve(item)
                    elseif action == "add_fav" then
                        doAddFavorite(item)
                    elseif action == "rem_fav" then
                        doRemoveFavorite(item)
                    end
                end
                loadAllItems()  -- Recharger tout
            end
            redrawCats()
        elseif key == keys.escape or key == keys.tab then
            return
        end
    end
end

-- === MENU STATS ===

local function statsInterface()
    clearScreen()
    drawHeader("STATISTIQUES")
    writeAt(2, 3, "Chargement...", colors_dim)
    
    local response = sendRequest({type = "get_stats"})
    
    if not response or not response.success then
        showMessage("ERREUR", "Impossible de charger", true)
        return
    end
    
    local stats = response.data
    
    clearScreen()
    drawHeader("STATISTIQUES")
    
    local y = 3
    writeAt(2, y, "Items totaux:", colors_dim)
    writeAt(w - #tostring(stats.totalItems), y, tostring(stats.totalItems), colors_text)
    y = y + 1
    
    writeAt(2, y, "Types:", colors_dim)
    writeAt(w - #tostring(stats.uniqueItems), y, tostring(stats.uniqueItems), colors_text)
    y = y + 1
    
    writeAt(2, y, "Slots:", colors_dim)
    local slotsStr = stats.usedSlots .. "/" .. stats.totalSlots
    writeAt(w - #slotsStr, y, slotsStr, colors_text)
    y = y + 1
    
    local percent = math.floor((stats.usedSlots / math.max(stats.totalSlots, 1)) * 100)
    writeAt(2, y, "Utilisation:", colors_dim)
    local percentColor = colors_success
    if percent > 90 then percentColor = colors_error
    elseif percent > 70 then percentColor = colors_warning end
    writeAt(w - #tostring(percent) - 1, y, percent .. "%", percentColor)
    y = y + 2
    
    -- Alertes
    local alertResponse = sendRequest({type = "get_alerts"})
    if alertResponse and alertResponse.success and #alertResponse.data > 0 then
        writeAt(2, y, "ALERTES:", colors_warning)
        y = y + 1
        for i, alert in ipairs(alertResponse.data) do
            if y > h - 2 then break end
            local name = alert.displayName
            if #name > w - 10 then name = name:sub(1, w - 13) .. ".." end
            writeAt(2, y, "! " .. name, colors_error)
            y = y + 1
        end
    end
    
    drawFooter("Appuyez sur une touche...")
    os.pullEvent("key")
end

-- === VIDER ENTREE ===

local function emptyInputInterface()
    clearScreen()
    drawHeader("TRI")
    writeAt(2, math.floor(h/2), "Tri en cours...", colors_dim)
    
    local response = sendRequest({type = "empty_input"})
    
    if response then
        local msg = response.data .. " items tries"
        showMessage("OK", msg, false)
    else
        showMessage("ERREUR", "Echec du tri", true)
    end
end

-- === MENU PRINCIPAL ===

local function mainMenu()
    local options = {
        {text = "Rechercher", icon = "[R]"},
        {text = "Favoris", icon = "[F]"},
        {text = "Categories", icon = "[C]"},
        {text = "Statistiques", icon = "[S]"},
        {text = "Trier entree", icon = "[T]"},
        {text = "Quitter", icon = "[Q]"}
    }
    
    local selectedIdx = 1
    
    local function redraw()
        clearScreen()
        drawHeader("STOCKAGE")
        
        for i, opt in ipairs(options) do
            local y = 2 + i * 2
            local isSelected = (i == selectedIdx)
            
            if isSelected then
                term.setCursorPos(1, y)
                term.setBackgroundColor(colors_selected)
                term.write(string.rep(" ", w))
            end
            
            writeAt(3, y, opt.text, colors_text, isSelected and colors_selected or colors_bg)
        end
        
        term.setBackgroundColor(colors_bg)
        drawFooter("^v:Nav Enter:Ok")
    end
    
    redraw()
    
    while running do
        local event, key = os.pullEvent("key")
        
        if key == keys.up then
            selectedIdx = selectedIdx > 1 and selectedIdx - 1 or #options
            redraw()
        elseif key == keys.down then
            selectedIdx = selectedIdx < #options and selectedIdx + 1 or 1
            redraw()
        elseif key == keys.enter then
            if selectedIdx == 1 then
                -- Recherche
                loadAllItems()
                local item = searchInterface()
                if item then
                    local action = itemActionInterface(item)
                    if action == "retrieve" then
                        doRetrieve(item)
                    elseif action == "add_fav" then
                        doAddFavorite(item)
                    elseif action == "rem_fav" then
                        doRemoveFavorite(item)
                    end
                end
                redraw()
            elseif selectedIdx == 2 then
                favoritesInterface()
                redraw()
            elseif selectedIdx == 3 then
                categoriesInterface()
                redraw()
            elseif selectedIdx == 4 then
                statsInterface()
                redraw()
            elseif selectedIdx == 5 then
                emptyInputInterface()
                redraw()
            elseif selectedIdx == 6 then
                running = false
            end
        elseif key == keys.escape then
            running = false
        end
    end
end

-- === PROGRAMME PRINCIPAL ===

local function main()
    clearScreen()
    writeAt(2, math.floor(h/2), "Connexion...", colors_dim)
    
    local ok, err = initNetwork()
    
    if not ok then
        clearScreen()
        drawHeader("ERREUR")
        writeAt(2, 4, err, colors_error)
        writeAt(2, 6, "Verifiez:", colors_dim)
        writeAt(2, 7, "- Modem connecte", colors_dim)
        writeAt(2, 8, "- Serveur demarre", colors_dim)
        drawFooter("Appuyez sur une touche...")
        os.pullEvent("key")
        return
    end
    
    -- Precharger l'inventaire
    writeAt(2, math.floor(h/2) + 1, "Chargement inventaire...", colors_dim)
    loadAllItems()
    
    mainMenu()
    
    clearScreen()
    writeAt(2, math.floor(h/2), "Deconnecte.", colors_dim)
    sleep(0.5)
end

main()
