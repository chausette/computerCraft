-- ============================================
-- CLIENT POCKET ADVANCED - STOCKAGE
-- Avec systeme de panier multi-items
-- ============================================

local PROTOCOL = "storage_system"
local SERVER_ID = "storage_server"

local serverId = nil
local running = true
local allItems = {}
local cart = {}  -- Panier: {name, displayName, count, maxCount}

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
local colors_cart = colors.orange

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

local function sendRequest(request, timeout)
    if not serverId then
        return nil, "Non connecte"
    end
    
    timeout = timeout or 10
    
    rednet.send(serverId, request, PROTOCOL)
    local sender, response = rednet.receive(PROTOCOL, timeout)
    
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
    
    -- Afficher titre
    local displayTitle = title
    local cartCount = #cart
    if cartCount > 0 then
        displayTitle = title:sub(1, w - 5)
    end
    local padding = math.floor((w - #displayTitle) / 2)
    term.setCursorPos(padding + 1, 1)
    term.write(displayTitle)
    
    -- Indicateur panier
    if cartCount > 0 then
        term.setCursorPos(w - 3, 1)
        term.setTextColor(colors_cart)
        term.write("[" .. cartCount .. "]")
    end
    
    term.setBackgroundColor(colors_bg)
    term.setTextColor(colors_text)
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

-- === GESTION DU PANIER ===

local function getCartTotal()
    local total = 0
    for _, item in ipairs(cart) do
        total = total + item.count
    end
    return total
end

local function findInCart(itemName)
    for i, item in ipairs(cart) do
        if item.name == itemName then
            return i, item
        end
    end
    return nil, nil
end

local function addToCart(item, qty)
    local idx, existing = findInCart(item.name)
    
    if existing then
        -- Mettre a jour la quantite
        existing.count = math.min(existing.count + qty, existing.maxCount)
    else
        -- Ajouter au panier
        table.insert(cart, {
            name = item.name,
            displayName = item.displayName,
            count = qty,
            maxCount = item.count
        })
    end
end

local function removeFromCart(index)
    if cart[index] then
        table.remove(cart, index)
    end
end

local function clearCart()
    cart = {}
end

local function updateCartMaxCounts()
    -- Met a jour les quantites max apres un achat
    for i = #cart, 1, -1 do
        local cartItem = cart[i]
        local found = false
        for _, item in ipairs(allItems) do
            if item.name == cartItem.name then
                cartItem.maxCount = item.count
                if cartItem.count > cartItem.maxCount then
                    cartItem.count = cartItem.maxCount
                end
                found = true
                break
            end
        end
        if not found or cartItem.maxCount <= 0 then
            table.remove(cart, i)
        end
    end
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
        updateCartMaxCounts()
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

-- === INTERFACE MESSAGE ===

local function showMessage(title, message, isError)
    clearScreen()
    drawHeader(title)
    
    local color = isError and colors_error or colors_success
    
    local lines = {}
    local maxLen = w - 4
    while #message > 0 do
        table.insert(lines, message:sub(1, maxLen))
        message = message:sub(maxLen + 1)
    end
    
    local startY = math.floor(h/2) - math.floor(#lines/2)
    for i, line in ipairs(lines) do
        writeAt(2, startY + i - 1, line, color)
    end
    
    drawFooter("Appuyez sur une touche...")
    os.pullEvent("key")
end

-- === INTERFACE QUANTITE ===

local function quantityInterface(item, maxQty, forCart)
    local qty = 1
    maxQty = math.min(maxQty, item.count or item.maxCount, 64)
    
    if maxQty <= 0 then
        return 0
    end
    
    -- Si c'est pour le panier et l'item y est deja, proposer sa quantite actuelle
    local _, existing = findInCart(item.name)
    if forCart and existing then
        qty = existing.count
    end
    
    local function redraw()
        clearScreen()
        drawHeader(forCart and "AJOUTER AU PANIER" or "COMMANDER")
        
        local name = item.displayName
        if #name > w - 4 then name = name:sub(1, w - 7) .. ".." end
        writeAt(2, 3, name, colors_text)
        writeAt(2, 4, "Stock: " .. (item.count or item.maxCount), colors_dim)
        
        writeAt(2, 6, "Quantite:", colors_text)
        
        local qtyStr = "< " .. string.format("%3d", qty) .. " >"
        writeAt(math.floor((w - #qtyStr) / 2), 8, qtyStr, colors_accent)
        
        writeAt(2, 10, "1=1  2=16  3=32  4=64", colors_dim)
        
        drawFooter("<>:Qte Enter:Ok Bksp:Annul")
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
        elseif key == keys.backspace then
            return 0
        end
    end
end

-- === INTERFACE RECHERCHE ===

local function searchInterface()
    loadAllItems()
    
    local query = ""
    local selectedIdx = 1
    local scrollOffset = 0
    local filteredItems = allItems
    local maxVisible = h - 5
    
    local function redraw()
        clearScreen()
        drawHeader("RECHERCHE")
        
        writeAt(1, 2, ">", colors_accent)
        writeAt(3, 2, query, colors_text)
        writeAt(3 + #query, 2, "_", colors_dim)
        
        writeAt(1, 3, string.rep("-", w), colors_dim)
        
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
                    
                    if isSelected then
                        term.setCursorPos(1, y)
                        term.setBackgroundColor(colors_selected)
                        term.write(string.rep(" ", w))
                    end
                    
                    -- Verifier si dans le panier
                    local _, inCart = findInCart(item.name)
                    local prefix = inCart and "*" or " "
                    
                    local name = item.displayName
                    local maxLen = w - 9
                    if #name > maxLen then
                        name = name:sub(1, maxLen - 2) .. ".."
                    end
                    
                    local nameColor = colors_text
                    if item.count == 0 then
                        nameColor = colors_error
                    elseif item.count < 10 then
                        nameColor = colors_warning
                    end
                    
                    writeAt(1, y, prefix, colors_cart, isSelected and colors_selected or colors_bg)
                    writeAt(2, y, name, nameColor, isSelected and colors_selected or colors_bg)
                    
                    local countStr = tostring(item.count)
                    writeAt(w - #countStr, y, countStr, colors_accent, isSelected and colors_selected or colors_bg)
                    
                    term.setBackgroundColor(colors_bg)
                end
            end
        end
        
        local info = #filteredItems .. " items"
        if #filteredItems > 0 then
            info = selectedIdx .. "/" .. #filteredItems
        end
        drawFooter("^v:Nav Enter:Ok Bksp:Ret")
        
        term.setCursorPos(3 + #query, 2)
    end
    
    redraw()
    
    while true do
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "char" then
            query = query .. p1
            filteredItems = filterItems(query)
            selectedIdx = 1
            scrollOffset = 0
            redraw()
            
        elseif event == "key" then
            local key = p1
            
            if key == keys.backspace then
                if #query > 0 then
                    query = query:sub(1, -2)
                    filteredItems = filterItems(query)
                    selectedIdx = 1
                    scrollOffset = 0
                    redraw()
                else
                    return nil
                end
                
            elseif key == keys.up then
                if selectedIdx > 1 then
                    selectedIdx = selectedIdx - 1
                    if selectedIdx <= scrollOffset then
                        scrollOffset = scrollOffset - 1
                    end
                end
                redraw()
                
            elseif key == keys.down then
                if selectedIdx < #filteredItems then
                    selectedIdx = selectedIdx + 1
                    if selectedIdx > scrollOffset + maxVisible then
                        scrollOffset = scrollOffset + 1
                    end
                end
                redraw()
                
            elseif key == keys.enter then
                if #filteredItems > 0 and filteredItems[selectedIdx] then
                    return filteredItems[selectedIdx]
                end
                
            elseif key == keys.pageUp then
                selectedIdx = math.max(1, selectedIdx - maxVisible)
                scrollOffset = math.max(0, selectedIdx - 1)
                redraw()
                
            elseif key == keys.pageDown then
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
    local _, inCart = findInCart(item.name)
    
    local options = {
        {text = "Ajouter au panier", action = "add_cart"},
        {text = "Commander direct", action = "retrieve"},
        {text = "Ajouter aux favoris", action = "add_fav"},
        {text = "Retirer des favoris", action = "rem_fav"},
        {text = "Retour", action = "back"}
    }
    
    local function redraw()
        clearScreen()
        
        local title = item.displayName
        if #title > w then title = title:sub(1, w - 3) .. ".." end
        drawHeader(title)
        
        writeAt(2, 3, "Stock: " .. item.count, item.count > 0 and colors_success or colors_error)
        writeAt(2, 4, "Cat: " .. (item.category or "?"), colors_dim)
        
        if inCart then
            writeAt(2, 5, "Dans panier: " .. inCart.count, colors_cart)
        end
        
        writeAt(1, 6, string.rep("-", w), colors_dim)
        
        for i, opt in ipairs(options) do
            local y = 6 + i
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
        drawFooter("^v:Nav Enter:Ok Bksp:Retour")
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
        elseif key == keys.backspace then
            return "back"
        end
    end
end

-- === INTERFACE PANIER ===

local function cartInterface()
    if #cart == 0 then
        showMessage("PANIER", "Le panier est vide", false)
        return
    end
    
    local selectedIdx = 1
    local maxVisible = h - 6
    local scrollOffset = 0
    
    local function redraw()
        clearScreen()
        drawHeader("PANIER (" .. getCartTotal() .. " items)")
        
        writeAt(1, 2, string.rep("-", w), colors_dim)
        
        local startY = 3
        
        for i = 1, maxVisible do
            local idx = scrollOffset + i
            local item = cart[idx]
            
            if item then
                local y = startY + i - 1
                local isSelected = (idx == selectedIdx)
                
                if isSelected then
                    term.setCursorPos(1, y)
                    term.setBackgroundColor(colors_selected)
                    term.write(string.rep(" ", w))
                end
                
                local name = item.displayName
                local maxLen = w - 10
                if #name > maxLen then
                    name = name:sub(1, maxLen - 2) .. ".."
                end
                
                writeAt(2, y, name, colors_text, isSelected and colors_selected or colors_bg)
                
                local qtyStr = "x" .. item.count
                writeAt(w - #qtyStr - 1, y, qtyStr, colors_accent, isSelected and colors_selected or colors_bg)
                
                term.setBackgroundColor(colors_bg)
            end
        end
        
        -- Boutons en bas
        local btnY = h - 3
        writeAt(1, btnY, string.rep("-", w), colors_dim)
        
        writeAt(2, btnY + 1, "[Enter] COMMANDER TOUT", colors_success)
        writeAt(2, btnY + 2, "[Del] Suppr  [E] Qte  [C] Vider", colors_dim)
        
        drawFooter("^v:Nav Bksp:Retour")
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
            if selectedIdx < #cart then
                selectedIdx = selectedIdx + 1
                if selectedIdx > scrollOffset + maxVisible then
                    scrollOffset = scrollOffset + 1
                end
            end
            redraw()
            
        elseif key == keys.enter then
            -- Commander tout le panier
            return "order_all"
            
        elseif key == keys.delete or key == keys.x then
            -- Supprimer l'item selectionne
            removeFromCart(selectedIdx)
            if #cart == 0 then
                return "empty"
            end
            selectedIdx = math.min(selectedIdx, #cart)
            redraw()
            
        elseif key == keys.e then
            -- Modifier la quantite
            local item = cart[selectedIdx]
            if item then
                local newQty = quantityInterface(item, item.maxCount, false)
                if newQty > 0 then
                    item.count = newQty
                end
            end
            redraw()
            
        elseif key == keys.c then
            -- Vider le panier
            clearCart()
            return "empty"
            
        elseif key == keys.backspace then
            return "back"
        end
    end
end

-- === ACTIONS ===

local function doRetrieveSingle(item, qty)
    local response, err = sendRequest({
        type = "retrieve_item",
        itemName = item.name,
        count = qty
    }, 15)
    
    return response
end

local function doRetrieveCart()
    if #cart == 0 then
        return
    end
    
    local maxRetries = 3
    local totalOrdered = 0
    local failedItems = {}
    local pendingItems = {}
    
    -- Copier le panier dans pending
    for _, item in ipairs(cart) do
        table.insert(pendingItems, {
            name = item.name,
            displayName = item.displayName,
            count = item.count,
            ordered = 0
        })
    end
    
    -- Essayer jusqu'à maxRetries fois
    for attempt = 1, maxRetries do
        if #pendingItems == 0 then
            break
        end
        
        clearScreen()
        if attempt == 1 then
            drawHeader("COMMANDE EN COURS")
        else
            drawHeader("RETRY " .. attempt .. "/" .. maxRetries)
        end
        
        local stillFailed = {}
        
        for i, item in ipairs(pendingItems) do
            local y = 3 + i
            local name = item.displayName
            if #name > w - 12 then
                name = name:sub(1, w - 15) .. ".."
            end
            
            if y < h - 2 then
                writeAt(2, y, name, colors_dim)
                writeAt(w - 5, y, "...", colors_dim)
            end
            
            local remaining = item.count - item.ordered
            local response = doRetrieveSingle({name = item.name}, remaining)
            
            if response and response.success then
                local got = response.data or remaining
                item.ordered = item.ordered + got
                totalOrdered = totalOrdered + got
                
                if y < h - 2 then
                    writeAt(w - 5, y, " OK ", colors_success)
                end
            else
                -- Echec, on le garde pour retry
                table.insert(stillFailed, item)
                if y < h - 2 then
                    writeAt(w - 5, y, "FAIL", colors_error)
                end
            end
            
            sleep(0.3)
        end
        
        pendingItems = stillFailed
        
        -- Si encore des echecs et pas le dernier essai, attendre
        if #pendingItems > 0 and attempt < maxRetries then
            writeAt(2, h - 3, "Attente avant retry...", colors_warning)
            sleep(1)
        end
    end
    
    -- Les items encore en echec apres tous les retries
    for _, item in ipairs(pendingItems) do
        local remaining = item.count - item.ordered
        if remaining > 0 then
            table.insert(failedItems, {
                name = item.displayName,
                wanted = item.count,
                got = item.ordered
            })
        end
    end
    
    -- Vider le panier
    clearCart()
    loadAllItems()
    
    -- Afficher le resultat final
    clearScreen()
    
    if #failedItems == 0 then
        drawHeader("COMMANDE OK")
        writeAt(2, 4, "Tous les items envoyes!", colors_success)
        writeAt(2, 6, "Total: " .. totalOrdered .. " items", colors_accent)
        drawFooter("Appuyez sur une touche...")
        os.pullEvent("key")
    else
        drawHeader("COMMANDE PARTIELLE")
        
        writeAt(2, 3, "Envoyes: " .. totalOrdered .. " items", colors_success)
        writeAt(2, 4, "Echecs: " .. #failedItems .. " items", colors_error)
        
        writeAt(1, 6, string.rep("-", w), colors_dim)
        writeAt(2, 7, "ITEMS NON ENVOYES:", colors_error)
        
        local y = 8
        for i, fail in ipairs(failedItems) do
            if y > h - 2 then
                writeAt(2, y, "... et " .. (#failedItems - i + 1) .. " autres", colors_dim)
                break
            end
            
            local name = fail.name
            if #name > w - 12 then
                name = name:sub(1, w - 15) .. ".."
            end
            
            local status = fail.got .. "/" .. fail.wanted
            writeAt(2, y, name, colors_warning)
            writeAt(w - #status, y, status, colors_error)
            y = y + 1
        end
        
        drawFooter("Appuyez sur une touche...")
        os.pullEvent("key")
    end
end

local function doAddToCart(item)
    if item.count <= 0 then
        showMessage("ERREUR", "Stock vide!", true)
        return
    end
    
    local qty = quantityInterface(item, item.count, true)
    
    if qty > 0 then
        addToCart(item, qty)
        -- Pas de message, retour direct pour continuer a ajouter
    end
end

local function doRetrieveDirect(item)
    if item.count <= 0 then
        showMessage("ERREUR", "Stock vide!", true)
        return
    end
    
    local qty = quantityInterface(item, item.count, false)
    
    if qty > 0 then
        clearScreen()
        drawHeader("ENVOI...")
        writeAt(2, math.floor(h/2), "Transfert en cours...", colors_dim)
        
        local response, err = sendRequest({
            type = "retrieve_item",
            itemName = item.name,
            count = qty
        }, 15)
        
        if response then
            if response.success then
                showMessage("OK", (response.data or qty) .. " items envoyes!", false)
            else
                showMessage("ERREUR", response.error or "Echec", true)
            end
            loadAllItems()
        else
            showMessage("ATTENTION", "Timeout - verifiez le coffre", true)
            loadAllItems()
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
    elseif response then
        showMessage("INFO", response.error or "Deja en favoris", false)
    else
        showMessage("ERREUR", "Pas de reponse", true)
    end
end

local function doRemoveFavorite(item)
    local response = sendRequest({
        type = "remove_favorite",
        itemName = item.name
    })
    
    if response and response.success then
        showMessage("OK", "Retire des favoris!", false)
    elseif response then
        showMessage("INFO", response.error or "Non trouve", false)
    else
        showMessage("ERREUR", "Pas de reponse", true)
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
        showMessage("FAVORIS", "Aucun favori configure", false)
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
                
                -- Verifier si dans le panier
                local _, inCart = findInCart(fav.name)
                local prefix = inCart and "*" or " "
                
                local name = fav.displayName
                if #name > w - 11 then
                    name = name:sub(1, w - 14) .. ".."
                end
                
                local nameColor = colors_text
                if not fav.inStock or fav.count == 0 then
                    nameColor = colors_error
                elseif fav.count < 10 then
                    nameColor = colors_warning
                end
                
                writeAt(1, y, prefix, colors_cart, isSelected and colors_selected or colors_bg)
                writeAt(2, y, name, nameColor, isSelected and colors_selected or colors_bg)
                writeAt(w - #tostring(fav.count), y, tostring(fav.count), colors_accent, isSelected and colors_selected or colors_bg)
            end
        end
        
        term.setBackgroundColor(colors_bg)
        drawFooter("^v:Nav Enter:Panier Bksp:Ret")
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
                doAddToCart(fav)
                -- Rafraichir les favoris
                response = sendRequest({type = "get_favorites"})
                if response and response.success then
                    favorites = response.data
                end
                if #favorites == 0 then return end
                redraw()
            elseif fav then
                showMessage("INFO", "Stock vide!", false)
                redraw()
            end
        elseif key == keys.backspace then
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
        showMessage("CATEGORIES", "Aucun item en stock", false)
        return
    end
    
    local selectedIdx = 1
    local scrollOffset = 0
    local maxVisible = h - 4
    
    local function redrawCats()
        clearScreen()
        drawHeader("CATEGORIES")
        
        for i = 1, maxVisible do
            local idx = scrollOffset + i
            local cat = categories[idx]
            
            if cat then
                local y = 2 + i
                local isSelected = (idx == selectedIdx)
                
                if isSelected then
                    term.setCursorPos(1, y)
                    term.setBackgroundColor(colors_selected)
                    term.write(string.rep(" ", w))
                end
                
                local name = cat.name
                if #name > w - 8 then name = name:sub(1, w - 11) .. ".." end
                
                writeAt(2, y, name, colors_text, isSelected and colors_selected or colors_bg)
                writeAt(w - #tostring(cat.count) - 2, y, "(" .. cat.count .. ")", colors_dim, isSelected and colors_selected or colors_bg)
            end
        end
        
        term.setBackgroundColor(colors_bg)
        drawFooter("^v:Nav Enter:Voir Bksp:Ret")
    end
    
    redrawCats()
    
    while true do
        local event, key = os.pullEvent("key")
        
        if key == keys.up then
            if selectedIdx > 1 then
                selectedIdx = selectedIdx - 1
                if selectedIdx <= scrollOffset then
                    scrollOffset = scrollOffset - 1
                end
            end
            redrawCats()
        elseif key == keys.down then
            if selectedIdx < #categories then
                selectedIdx = selectedIdx + 1
                if selectedIdx > scrollOffset + maxVisible then
                    scrollOffset = scrollOffset + 1
                end
            end
            redrawCats()
        elseif key == keys.enter then
            local cat = categories[selectedIdx]
            if cat then
                allItems = cat.items
                local item = searchInterface()
                if item then
                    local action = itemActionInterface(item)
                    if action == "add_cart" then
                        doAddToCart(item)
                    elseif action == "retrieve" then
                        doRetrieveDirect(item)
                    elseif action == "add_fav" then
                        doAddFavorite(item)
                    elseif action == "rem_fav" then
                        doRemoveFavorite(item)
                    end
                end
                loadAllItems()
            end
            redrawCats()
        elseif key == keys.backspace then
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

-- === MENU GESTION COFFRES ===

local function chestDetailInterface(chest)
    local selectedOption = 1
    
    local function getOptions()
        local opts = {}
        
        if chest.isStorage then
            -- Coffre actif - options de modification
            if chest.category then
                table.insert(opts, {text = "Retirer filtre categorie", action = "clear_cat"})
            else
                table.insert(opts, {text = "Filtrer par categorie", action = "set_cat"})
            end
            
            if chest.itemLock then
                table.insert(opts, {text = "Retirer filtre item", action = "clear_item"})
            else
                table.insert(opts, {text = "Filtrer par item", action = "set_item"})
            end
            
            table.insert(opts, {text = "Retirer du stockage", action = "remove"})
        else
            -- Coffre disponible - ajouter
            table.insert(opts, {text = "Ajouter au stockage", action = "add"})
            table.insert(opts, {text = "Ajouter avec categorie", action = "add_cat"})
            table.insert(opts, {text = "Ajouter avec item", action = "add_item"})
        end
        
        table.insert(opts, {text = "Retour", action = "back"})
        return opts
    end
    
    local function redraw()
        local options = getOptions()
        clearScreen()
        
        local title = chest.name
        if #title > w then title = ".." .. title:sub(-(w-2)) end
        drawHeader(title)
        
        local y = 3
        writeAt(2, y, "Slots: " .. chest.used .. "/" .. chest.size, colors_dim)
        y = y + 1
        
        if chest.isSystem then
            writeAt(2, y, "COFFRE SYSTEME", colors_warning)
            y = y + 1
        elseif chest.isStorage then
            writeAt(2, y, "STOCKAGE ACTIF", colors_success)
            y = y + 1
            
            if chest.category then
                writeAt(2, y, "Cat: " .. chest.category, colors_accent)
                y = y + 1
            end
            if chest.itemLock then
                local itemName = storage.getDisplayName and storage.getDisplayName(chest.itemLock) or chest.itemLock:gsub("^[^:]+:", "")
                writeAt(2, y, "Item: " .. itemName, colors_cart)
                y = y + 1
            end
            if not chest.category and not chest.itemLock then
                writeAt(2, y, "Pas de restriction", colors_dim)
                y = y + 1
            end
        else
            writeAt(2, y, "DISPONIBLE", colors_dim)
            y = y + 1
        end
        
        writeAt(1, y + 1, string.rep("-", w), colors_dim)
        y = y + 2
        
        for i, opt in ipairs(options) do
            local isSelected = (i == selectedOption)
            
            if isSelected then
                term.setCursorPos(1, y)
                term.setBackgroundColor(colors_selected)
                term.write(string.rep(" ", w))
                writeAt(2, y, "> " .. opt.text, colors_text, colors_selected)
            else
                writeAt(2, y, "  " .. opt.text, colors_dim)
            end
            y = y + 1
        end
        
        term.setBackgroundColor(colors_bg)
        drawFooter("^v:Nav Enter:Ok Bksp:Ret")
    end
    
    redraw()
    
    while true do
        local event, key = os.pullEvent("key")
        local options = getOptions()
        
        if key == keys.up then
            selectedOption = selectedOption > 1 and selectedOption - 1 or #options
            redraw()
        elseif key == keys.down then
            selectedOption = selectedOption < #options and selectedOption + 1 or 1
            redraw()
        elseif key == keys.enter then
            return options[selectedOption].action
        elseif key == keys.backspace then
            return "back"
        end
    end
end

local function selectCategoryInterface()
    local response = sendRequest({type = "get_categories"})
    if not response or not response.success then
        showMessage("ERREUR", "Impossible de charger", true)
        return nil
    end
    
    local categories = response.data
    local selectedIdx = 1
    local scrollOffset = 0
    local maxVisible = h - 4
    
    local function redraw()
        clearScreen()
        drawHeader("CHOISIR CATEGORIE")
        
        for i = 1, maxVisible do
            local idx = scrollOffset + i
            local cat = categories[idx]
            
            if cat then
                local y = 2 + i
                local isSelected = (idx == selectedIdx)
                
                if isSelected then
                    term.setCursorPos(1, y)
                    term.setBackgroundColor(colors_selected)
                    term.write(string.rep(" ", w))
                end
                
                writeAt(2, y, cat.name, colors_text, isSelected and colors_selected or colors_bg)
            end
        end
        
        term.setBackgroundColor(colors_bg)
        drawFooter("^v:Nav Enter:Ok Bksp:Annul")
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
            if selectedIdx < #categories then
                selectedIdx = selectedIdx + 1
                if selectedIdx > scrollOffset + maxVisible then
                    scrollOffset = scrollOffset + 1
                end
            end
            redraw()
        elseif key == keys.enter then
            return categories[selectedIdx].name
        elseif key == keys.backspace then
            return nil
        end
    end
end

local function selectItemInterface()
    -- Utilise la recherche existante pour choisir un item
    loadAllItems()
    local item = searchInterface()
    if item then
        return item.name
    end
    return nil
end

local function chestsInterface()
    local selectedIdx = 1
    local scrollOffset = 0
    local maxVisible = h - 5
    local chests = {}
    
    local function loadChests()
        local response = sendRequest({type = "list_chests"})
        if response and response.success then
            chests = response.data
            -- Trier: système d'abord, puis actifs, puis disponibles
            table.sort(chests, function(a, b)
                if a.isSystem ~= b.isSystem then return a.isSystem end
                if a.isStorage ~= b.isStorage then return a.isStorage end
                return a.name < b.name
            end)
        end
    end
    
    loadChests()
    
    local function redraw()
        clearScreen()
        drawHeader("GESTION COFFRES")
        
        if #chests == 0 then
            writeAt(2, 4, "Aucun coffre trouve", colors_dim)
            drawFooter("Bksp:Retour")
            return
        end
        
        writeAt(1, 2, string.rep("-", w), colors_dim)
        
        local startY = 3
        
        for i = 1, maxVisible do
            local idx = scrollOffset + i
            local chest = chests[idx]
            
            if chest then
                local y = startY + i - 1
                local isSelected = (idx == selectedIdx)
                
                if isSelected then
                    term.setCursorPos(1, y)
                    term.setBackgroundColor(colors_selected)
                    term.write(string.rep(" ", w))
                end
                
                -- Icone de statut
                local icon = " "
                local iconColor = colors_dim
                if chest.isSystem then
                    icon = "S"
                    iconColor = colors_warning
                elseif chest.isStorage then
                    if chest.itemLock then
                        icon = "I"
                        iconColor = colors_cart
                    elseif chest.category then
                        icon = "C"
                        iconColor = colors_accent
                    else
                        icon = "*"
                        iconColor = colors_success
                    end
                end
                
                writeAt(1, y, icon, iconColor, isSelected and colors_selected or colors_bg)
                
                -- Nom du coffre (tronqué)
                local name = chest.name
                local maxLen = w - 8
                if #name > maxLen then
                    name = ".." .. name:sub(-(maxLen - 2))
                end
                
                writeAt(3, y, name, colors_text, isSelected and colors_selected or colors_bg)
                
                -- Slots
                local slotsStr = chest.used .. "/" .. chest.size
                writeAt(w - #slotsStr, y, slotsStr, colors_dim, isSelected and colors_selected or colors_bg)
            end
        end
        
        term.setBackgroundColor(colors_bg)
        
        -- Légende
        writeAt(1, h - 2, "S=Sys *=Actif C=Cat I=Item", colors_dim)
        
        local info = selectedIdx .. "/" .. #chests
        drawFooter("^v:Nav Enter:Detail Bksp:Ret")
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
            if selectedIdx < #chests then
                selectedIdx = selectedIdx + 1
                if selectedIdx > scrollOffset + maxVisible then
                    scrollOffset = scrollOffset + 1
                end
            end
            redraw()
        elseif key == keys.enter then
            local chest = chests[selectedIdx]
            if chest and not chest.isSystem then
                local action = chestDetailInterface(chest)
                
                if action == "add" then
                    sendRequest({type = "add_chest", chestName = chest.name})
                    showMessage("OK", "Coffre ajoute!", false)
                    
                elseif action == "add_cat" then
                    local cat = selectCategoryInterface()
                    if cat then
                        sendRequest({type = "add_chest", chestName = chest.name, category = cat})
                        showMessage("OK", "Coffre ajoute avec filtre!", false)
                    end
                    
                elseif action == "add_item" then
                    local itemName = selectItemInterface()
                    if itemName then
                        sendRequest({type = "add_chest", chestName = chest.name, itemLock = itemName})
                        showMessage("OK", "Coffre ajoute avec filtre!", false)
                    end
                    
                elseif action == "remove" then
                    sendRequest({type = "remove_chest", chestName = chest.name})
                    showMessage("OK", "Coffre retire!", false)
                    
                elseif action == "set_cat" then
                    local cat = selectCategoryInterface()
                    if cat then
                        sendRequest({type = "update_chest", chestName = chest.name, category = cat, itemLock = nil})
                        showMessage("OK", "Filtre applique!", false)
                    end
                    
                elseif action == "clear_cat" then
                    sendRequest({type = "update_chest", chestName = chest.name, category = nil, itemLock = chest.itemLock})
                    showMessage("OK", "Filtre retire!", false)
                    
                elseif action == "set_item" then
                    local itemName = selectItemInterface()
                    if itemName then
                        sendRequest({type = "update_chest", chestName = chest.name, category = nil, itemLock = itemName})
                        showMessage("OK", "Filtre applique!", false)
                    end
                    
                elseif action == "clear_item" then
                    sendRequest({type = "update_chest", chestName = chest.name, category = chest.category, itemLock = nil})
                    showMessage("OK", "Filtre retire!", false)
                end
                
                loadChests()
                selectedIdx = math.min(selectedIdx, #chests)
            elseif chest and chest.isSystem then
                showMessage("INFO", "Coffre systeme non modifiable", false)
            end
            redraw()
        elseif key == keys.backspace then
            return
        end
    end
end

-- === VIDER ENTREE ===

local function emptyInputInterface()
    clearScreen()
    drawHeader("TRI")
    writeAt(2, math.floor(h/2), "Tri en cours...", colors_dim)
    writeAt(2, math.floor(h/2) + 1, "Patientez...", colors_dim)
    
    local response, err = sendRequest({type = "empty_input"}, 20)
    
    if response then
        local count = response.data or 0
        local msg = count .. " items tries"
        showMessage("OK", msg, false)
    else
        showMessage("ATTENTION", "Timeout - verifiez le coffre", false)
    end
    
    loadAllItems()
end

-- === MENU PRINCIPAL ===

local function mainMenu()
    local function getOptions()
        local opts = {
            {text = "Rechercher"},
            {text = "Favoris"},
            {text = "Categories"},
            {text = "Gestion Coffres"},
            {text = "Statistiques"},
            {text = "Trier entree"},
            {text = "Quitter"}
        }
        
        -- Ajouter option panier si non vide
        if #cart > 0 then
            table.insert(opts, 1, {text = "PANIER (" .. getCartTotal() .. ")", isCart = true})
        end
        
        return opts
    end
    
    local selectedIdx = 1
    
    local function redraw()
        local options = getOptions()
        
        clearScreen()
        drawHeader("STOCKAGE")
        
        for i, opt in ipairs(options) do
            local y = 2 + i * 2
            if y > h - 2 then break end
            local isSelected = (i == selectedIdx)
            
            if isSelected then
                term.setCursorPos(1, y)
                term.setBackgroundColor(colors_selected)
                term.write(string.rep(" ", w))
                
                local textColor = opt.isCart and colors_cart or colors_text
                writeAt(3, y, "> " .. opt.text, textColor, colors_selected)
            else
                local textColor = opt.isCart and colors_cart or colors_dim
                writeAt(3, y, "  " .. opt.text, textColor)
            end
        end
        
        term.setBackgroundColor(colors_bg)
        drawFooter("^v:Nav Enter:Ok")
    end
    
    redraw()
    
    while running do
        local event, key = os.pullEvent("key")
        local options = getOptions()
        
        if key == keys.up then
            selectedIdx = selectedIdx > 1 and selectedIdx - 1 or #options
            redraw()
        elseif key == keys.down then
            selectedIdx = selectedIdx < #options and selectedIdx + 1 or 1
            redraw()
        elseif key == keys.enter then
            local opt = options[selectedIdx]
            
            if opt.isCart then
                -- Menu panier
                local result = cartInterface()
                if result == "order_all" then
                    doRetrieveCart()
                end
                redraw()
            elseif opt.text == "Rechercher" then
                loadAllItems()
                local item = searchInterface()
                if item then
                    local action = itemActionInterface(item)
                    if action == "add_cart" then
                        doAddToCart(item)
                    elseif action == "retrieve" then
                        doRetrieveDirect(item)
                    elseif action == "add_fav" then
                        doAddFavorite(item)
                    elseif action == "rem_fav" then
                        doRemoveFavorite(item)
                    end
                end
                redraw()
            elseif opt.text == "Favoris" then
                favoritesInterface()
                redraw()
            elseif opt.text == "Categories" then
                categoriesInterface()
                redraw()
            elseif opt.text == "Gestion Coffres" then
                chestsInterface()
                redraw()
            elseif opt.text == "Statistiques" then
                statsInterface()
                redraw()
            elseif opt.text == "Trier entree" then
                emptyInputInterface()
                redraw()
            elseif opt.text == "Quitter" then
                running = false
            end
        elseif key == keys.backspace then
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
    
    writeAt(2, math.floor(h/2) + 1, "Chargement...", colors_dim)
    loadAllItems()
    
    mainMenu()
    
    clearScreen()
    writeAt(2, math.floor(h/2), "Deconnecte.", colors_dim)
    sleep(0.5)
end

main()
