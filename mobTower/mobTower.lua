-- ============================================
-- MOB TOWER MANAGER v1.3
-- Version 1.21 NeoForge - TOUT EN UN
-- Avec wizard navigable et coffre overflow
-- ============================================

-- ============================================
-- UTILS
-- ============================================

local utils = {}

utils.SIDES = {"top", "bottom", "left", "right", "front", "back"}

utils.RARE_ITEMS = {
    ["minecraft:zombie_head"] = true,
    ["minecraft:skeleton_skull"] = true,
    ["minecraft:creeper_head"] = true,
    ["minecraft:wither_skeleton_skull"] = true,
    ["minecraft:music_disc_13"] = true,
    ["minecraft:music_disc_cat"] = true,
    ["minecraft:music_disc_blocks"] = true,
    ["minecraft:music_disc_chirp"] = true,
    ["minecraft:music_disc_far"] = true,
    ["minecraft:music_disc_mall"] = true,
    ["minecraft:music_disc_mellohi"] = true,
    ["minecraft:music_disc_stal"] = true,
    ["minecraft:music_disc_strad"] = true,
    ["minecraft:music_disc_ward"] = true,
    ["minecraft:music_disc_11"] = true,
    ["minecraft:music_disc_wait"] = true,
    ["minecraft:trident"] = true,
    ["minecraft:totem_of_undying"] = true,
    ["minecraft:enchanted_golden_apple"] = true,
    ["minecraft:nether_star"] = true,
}

function utils.isRareItem(itemName, nbt)
    if utils.RARE_ITEMS[itemName] then return true end
    if nbt and (nbt.Enchantments or nbt.StoredEnchantments) then return true end
    return false
end

-- Liste étendue des items à trier
utils.SORTABLE_ITEMS = {
    -- Drops de mobs
    { id = "minecraft:rotten_flesh", name = "Rotten Flesh" },
    { id = "minecraft:bone", name = "Bone" },
    { id = "minecraft:arrow", name = "Arrow" },
    { id = "minecraft:gunpowder", name = "Gunpowder" },
    { id = "minecraft:ender_pearl", name = "Ender Pearl" },
    { id = "minecraft:string", name = "String" },
    { id = "minecraft:spider_eye", name = "Spider Eye" },
    { id = "minecraft:slime_ball", name = "Slime Ball" },
    { id = "minecraft:phantom_membrane", name = "Phantom Membrane" },
    { id = "minecraft:blaze_rod", name = "Blaze Rod" },
    { id = "minecraft:ghast_tear", name = "Ghast Tear" },
    { id = "minecraft:magma_cream", name = "Magma Cream" },
    
    -- Drops Witch
    { id = "minecraft:redstone", name = "Redstone" },
    { id = "minecraft:glowstone_dust", name = "Glowstone" },
    { id = "minecraft:sugar", name = "Sugar" },
    { id = "minecraft:glass_bottle", name = "Glass Bottle" },
    { id = "minecraft:stick", name = "Stick" },
    
    -- Drops Zombie
    { id = "minecraft:iron_ingot", name = "Iron Ingot" },
    { id = "minecraft:carrot", name = "Carrot" },
    { id = "minecraft:potato", name = "Potato" },
    
    -- Arcs
    { id = "minecraft:bow", name = "Bow" },
    { id = "minecraft:crossbow", name = "Crossbow" },
    
    -- Potions (patterns)
    { id = "potion", name = "Potions (toutes)", pattern = true },
    { id = "splash_potion", name = "Potions Splash", pattern = true },
    { id = "lingering_potion", name = "Potions Lingering", pattern = true },
    
    -- Armures (patterns)
    { id = "_helmet", name = "Casques (tous)", pattern = true },
    { id = "_chestplate", name = "Plastrons (tous)", pattern = true },
    { id = "_leggings", name = "Jambieres (tous)", pattern = true },
    { id = "_boots", name = "Bottes (tous)", pattern = true },
    
    -- Outils (patterns)
    { id = "_sword", name = "Epees (toutes)", pattern = true },
    { id = "_pickaxe", name = "Pioches (toutes)", pattern = true },
    { id = "_axe", name = "Haches (toutes)", pattern = true },
    { id = "_shovel", name = "Pelles (toutes)", pattern = true },
    { id = "_hoe", name = "Houes (toutes)", pattern = true },
    
    -- Items rares
    { id = "_head", name = "Tetes de mob", pattern = true },
    { id = "_skull", name = "Cranes", pattern = true },
    { id = "music_disc", name = "Disques", pattern = true },
}

function utils.formatNumber(n)
    if n == nil then return "0" end
    local formatted = tostring(math.floor(n))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    return formatted
end

function utils.formatTime(seconds)
    if seconds == nil then seconds = 0 end
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%02d:%02d:%02d", hours, mins, secs)
end

function utils.formatTimestamp(timestamp)
    if timestamp == nil then return "--:--" end
    local date = os.date("*t", timestamp)
    if date then
        return string.format("%02d:%02d", date.hour, date.min)
    end
    return "--:--"
end

function utils.saveTable(filename, tbl)
    local file = fs.open(filename, "w")
    if file then
        file.write(textutils.serialize(tbl))
        file.close()
        return true
    end
    return false
end

function utils.loadTable(filename)
    if fs.exists(filename) then
        local file = fs.open(filename, "r")
        if file then
            local data = file.readAll()
            file.close()
            local success, result = pcall(textutils.unserialize, data)
            if success and result then return result end
        end
    end
    return nil
end

function utils.getShortName(itemId)
    if itemId == nil then return "Unknown" end
    local name = itemId:gsub("minecraft:", "")
    name = name:gsub("_", " ")
    return name
end

function utils.truncate(text, maxLen)
    if #text <= maxLen then return text end
    return string.sub(text, 1, maxLen - 2) .. ".."
end

function utils.ensureDir(path)
    if not fs.exists(path) then fs.makeDir(path) end
end

-- ============================================
-- MENU NAVIGABLE (pour le wizard)
-- ============================================

local function navigableMenu(title, options, allowNone)
    local selected = 1
    local scroll = 0
    local maxVisible = 10
    local totalOptions = #options
    
    -- Ajouter option "Aucun" si permis
    if allowNone then
        table.insert(options, 1, { name = "[ Aucun / Passer ]", value = nil })
        totalOptions = #options
    end
    
    while true do
        term.clear()
        term.setCursorPos(1, 1)
        
        -- Titre
        term.setTextColor(colors.cyan)
        print(title)
        print(string.rep("-", #title))
        term.setTextColor(colors.white)
        print("")
        
        -- Instructions
        term.setTextColor(colors.lightGray)
        print("Fleches: naviguer | Entree: selectionner")
        print("")
        term.setTextColor(colors.white)
        
        -- Afficher les options visibles
        local startIdx = scroll + 1
        local endIdx = math.min(scroll + maxVisible, totalOptions)
        
        -- Indicateur scroll haut
        if scroll > 0 then
            term.setTextColor(colors.gray)
            print("  [...] " .. scroll .. " de plus en haut")
            term.setTextColor(colors.white)
        end
        
        for i = startIdx, endIdx do
            local opt = options[i]
            local prefix = (i == selected) and "> " or "  "
            local displayName = opt.name or opt
            
            if type(displayName) == "table" then
                displayName = displayName.name or tostring(displayName)
            end
            
            -- Tronquer si trop long
            if #displayName > 45 then
                displayName = string.sub(displayName, 1, 42) .. "..."
            end
            
            if i == selected then
                term.setTextColor(colors.lime)
                print(prefix .. displayName)
                term.setTextColor(colors.white)
            else
                print(prefix .. displayName)
            end
        end
        
        -- Indicateur scroll bas
        if endIdx < totalOptions then
            term.setTextColor(colors.gray)
            print("  [...] " .. (totalOptions - endIdx) .. " de plus en bas")
            term.setTextColor(colors.white)
        end
        
        -- Afficher info sélection
        print("")
        term.setTextColor(colors.yellow)
        print("Selection: " .. selected .. "/" .. totalOptions)
        term.setTextColor(colors.white)
        
        -- Attendre input
        local event, key = os.pullEvent("key")
        
        if key == keys.up then
            selected = selected - 1
            if selected < 1 then selected = totalOptions end
            -- Ajuster scroll
            if selected < scroll + 1 then
                scroll = selected - 1
            end
            if selected > scroll + maxVisible then
                scroll = selected - maxVisible
            end
        elseif key == keys.down then
            selected = selected + 1
            if selected > totalOptions then selected = 1 end
            -- Ajuster scroll
            if selected > scroll + maxVisible then
                scroll = selected - maxVisible
            end
            if selected < scroll + 1 then
                scroll = selected - 1
            end
        elseif key == keys.pageUp then
            selected = selected - maxVisible
            if selected < 1 then selected = 1 end
            scroll = math.max(0, selected - 1)
        elseif key == keys.pageDown then
            selected = selected + maxVisible
            if selected > totalOptions then selected = totalOptions end
            scroll = math.max(0, math.min(selected - maxVisible, totalOptions - maxVisible))
        elseif key == keys.home then
            selected = 1
            scroll = 0
        elseif key == keys["end"] then
            selected = totalOptions
            scroll = math.max(0, totalOptions - maxVisible)
        elseif key == keys.enter then
            local opt = options[selected]
            if allowNone and selected == 1 then
                return nil, nil
            end
            if type(opt) == "table" then
                return opt.value or opt.name or opt, selected
            end
            return opt, selected
        end
    end
end

-- Menu pour sélectionner un inventaire
local function selectInventory(title, inventories, allowNone)
    local options = {}
    for i, inv in ipairs(inventories) do
        table.insert(options, {
            name = inv.name .. " (" .. inv.size .. " slots)",
            value = inv.name,
            index = i
        })
    end
    
    local result, idx = navigableMenu(title, options, allowNone)
    return result, idx
end

-- ============================================
-- PERIPHERALS
-- ============================================

local peripherals = {}
local pCache = { playerDetector = nil, monitor = nil }
local redstoneConfig = { side = "back", inverted = false }

function peripherals.init(config)
    if config.peripherals.playerDetector then
        pCache.playerDetector = peripheral.wrap(config.peripherals.playerDetector)
    end
    if config.peripherals.monitor then
        pCache.monitor = peripheral.wrap(config.peripherals.monitor)
        if pCache.monitor then pCache.monitor.setTextScale(0.5) end
    end
    if config.redstone then
        redstoneConfig.side = config.redstone.side or "back"
        redstoneConfig.inverted = config.redstone.inverted or false
    end
    return { playerDetector = pCache.playerDetector ~= nil, monitor = pCache.monitor ~= nil }
end

function peripherals.listAll()
    local all = peripheral.getNames()
    local result = { playerDetectors = {}, monitors = {}, inventories = {}, other = {} }
    
    for _, name in ipairs(all) do
        local pType = peripheral.getType(name)
        if pType == "playerDetector" or pType == "player_detector" then
            table.insert(result.playerDetectors, { name = name, type = pType })
        elseif pType == "monitor" then
            table.insert(result.monitors, { name = name, type = pType })
        elseif pType and (string.find(pType, "chest") or string.find(pType, "barrel") or string.find(pType, "shulker")) then
            local inv = peripheral.wrap(name)
            if inv and inv.size then
                local ok, size = pcall(function() return inv.size() end)
                if ok then
                    table.insert(result.inventories, { name = name, type = pType, size = size })
                end
            end
        else
            table.insert(result.other, { name = name, type = pType })
        end
    end
    
    -- Trier les inventaires par nom
    table.sort(result.inventories, function(a, b) return a.name < b.name end)
    
    return result
end

function peripherals.isPlayerPresent(playerName, range)
    if not pCache.playerDetector then return false end
    range = range or 16
    local ok, players = pcall(function() return pCache.playerDetector.getPlayersInRange(range) end)
    if not ok or not players then return false end
    for _, player in ipairs(players) do
        if player == playerName then return true end
    end
    return false
end

function peripherals.getInventoryContents(invName)
    local inv = peripheral.wrap(invName)
    if not inv then return nil end
    local ok, items = pcall(function() return inv.list() end)
    if not ok then return nil end
    return items
end

function peripherals.transferItems(fromInv, fromSlot, toInv, count)
    local source = peripheral.wrap(fromInv)
    if not source then return 0 end
    local ok, transferred = pcall(function() return source.pushItems(toInv, fromSlot, count) end)
    if not ok then return 0 end
    return transferred or 0
end

function peripherals.getFillPercent(invName)
    local inv = peripheral.wrap(invName)
    if not inv then return 0 end
    local ok, size = pcall(function() return inv.size() end)
    if not ok or size == 0 then return 0 end
    local items = peripherals.getInventoryContents(invName)
    if not items then return 0 end
    local used = 0
    for _ in pairs(items) do used = used + 1 end
    return math.floor((used / size) * 100)
end

function peripherals.setSpawnOff()
    redstone.setOutput(redstoneConfig.side, not redstoneConfig.inverted)
end

function peripherals.setSpawnOn()
    redstone.setOutput(redstoneConfig.side, redstoneConfig.inverted)
end

function peripherals.toggleSpawn(currentState)
    if currentState then
        peripherals.setSpawnOff()
        return true, false
    else
        peripherals.setSpawnOn()
        return true, true
    end
end

function peripherals.getMonitor() return pCache.monitor end
function peripherals.getMonitorSize()
    if not pCache.monitor then return 0, 0 end
    return pCache.monitor.getSize()
end

-- ============================================
-- STORAGE
-- ============================================

local storage = {}
local sortingRules = {}
local collectorChest = nil
local overflowChest = nil  -- NOUVEAU: coffre pour items non triés
local stats = {
    session = { startTime = 0, mobsKilled = 0, itemsCollected = 0, raresFound = 0 },
    total = { mobsKilled = 0, itemsCollected = 0, raresFound = 0, totalTime = 0 },
    hourly = {},
    rareItems = {}
}
local DATA_FILE = "/mobTower/data/stats.dat"

local MOB_ESTIMATES = {
    ["minecraft:rotten_flesh"] = 1.0,
    ["minecraft:bone"] = 0.5,
    ["minecraft:arrow"] = 0.25,
    ["minecraft:gunpowder"] = 0.75,
    ["minecraft:ender_pearl"] = 1.0,
    ["minecraft:string"] = 0.5,
    ["minecraft:spider_eye"] = 0.33,
    ["minecraft:slime_ball"] = 1.0,
    ["minecraft:blaze_rod"] = 1.0,
    ["minecraft:ghast_tear"] = 1.0,
    ["minecraft:phantom_membrane"] = 0.5,
}

function storage.init(config)
    collectorChest = config.storage.collectorChest
    overflowChest = config.storage.overflowChest  -- NOUVEAU
    sortingRules = config.storage.sortingRules or {}
    storage.loadStats()
    stats.session.startTime = os.epoch("utc") / 1000
    stats.session.mobsKilled = 0
    stats.session.itemsCollected = 0
    stats.session.raresFound = 0
end

function storage.loadStats()
    local loaded = utils.loadTable(DATA_FILE)
    if loaded then
        stats.total = loaded.total or stats.total
        stats.hourly = loaded.hourly or {}
        stats.rareItems = loaded.rareItems or {}
    end
end

function storage.saveStats()
    utils.saveTable(DATA_FILE, { total = stats.total, hourly = stats.hourly, rareItems = stats.rareItems })
end

function storage.getStats() return stats end

function storage.getSessionTime()
    if stats.session.startTime == 0 then return 0 end
    return (os.epoch("utc") / 1000) - stats.session.startTime
end

function storage.resetSession()
    stats.total.totalTime = stats.total.totalTime + storage.getSessionTime()
    stats.session.startTime = os.epoch("utc") / 1000
    stats.session.mobsKilled = 0
    stats.session.itemsCollected = 0
    stats.session.raresFound = 0
    storage.saveStats()
end

function storage.getHourlyData(hours)
    hours = hours or 12
    local data = {}
    local now = os.epoch("utc") / 1000
    for i = hours - 1, 0, -1 do
        local timestamp = now - (i * 3600)
        local hourKey = os.date("%Y-%m-%d-%H", timestamp)
        local hourData = stats.hourly[hourKey]
        table.insert(data, {
            hour = os.date("%H:00", timestamp),
            mobs = hourData and hourData.mobs or 0,
            items = hourData and hourData.items or 0
        })
    end
    return data
end

function storage.addKill(count)
    count = count or 1
    stats.session.mobsKilled = stats.session.mobsKilled + count
    stats.total.mobsKilled = stats.total.mobsKilled + count
    local currentHour = os.date("%Y-%m-%d-%H")
    if not stats.hourly[currentHour] then stats.hourly[currentHour] = { mobs = 0, items = 0 } end
    stats.hourly[currentHour].mobs = stats.hourly[currentHour].mobs + count
end

function storage.addItems(count)
    count = count or 1
    stats.session.itemsCollected = stats.session.itemsCollected + count
    stats.total.itemsCollected = stats.total.itemsCollected + count
    local currentHour = os.date("%Y-%m-%d-%H")
    if not stats.hourly[currentHour] then stats.hourly[currentHour] = { mobs = 0, items = 0 } end
    stats.hourly[currentHour].items = stats.hourly[currentHour].items + count
end

function storage.addRareItem(itemName, count)
    count = count or 1
    stats.session.raresFound = stats.session.raresFound + count
    stats.total.raresFound = stats.total.raresFound + count
    table.insert(stats.rareItems, 1, { name = itemName, count = count, time = os.epoch("utc") / 1000 })
    while #stats.rareItems > 50 do table.remove(stats.rareItems) end
end

function storage.getRecentRares(count)
    count = count or 5
    local result = {}
    for i = 1, math.min(count, #stats.rareItems) do
        table.insert(result, stats.rareItems[i])
    end
    return result
end

function storage.findDestination(itemName)
    for _, rule in ipairs(sortingRules) do
        if rule.pattern then
            if string.find(itemName, rule.itemId) then return rule.barrel end
        else
            if itemName == rule.itemId then return rule.barrel end
        end
    end
    -- NOUVEAU: retourner le coffre overflow si configuré
    return overflowChest
end

function storage.sortSlot(slot, item)
    if not collectorChest then return false end
    local destination = storage.findDestination(item.name)
    if not destination then return false end
    
    local transferred = peripherals.transferItems(collectorChest, slot, destination, item.count)
    if transferred > 0 then
        storage.addItems(transferred)
        local estimate = MOB_ESTIMATES[item.name]
        if estimate then storage.addKill(math.floor(transferred * estimate + 0.5)) end
        if utils.isRareItem(item.name, item.nbt) then
            storage.addRareItem(item.name, transferred)
            return true, "rare", transferred
        end
        return true, "sorted", transferred
    end
    return false
end

function storage.sortAll()
    if not collectorChest then return { sorted = 0, failed = 0, rares = {} } end
    local contents = peripherals.getInventoryContents(collectorChest)
    if not contents then return { sorted = 0, failed = 0, rares = {} } end
    
    local result = { sorted = 0, failed = 0, rares = {} }
    for slot, item in pairs(contents) do
        local success, status, count = storage.sortSlot(slot, item)
        if success then
            result.sorted = result.sorted + (count or item.count)
            if status == "rare" then
                table.insert(result.rares, { name = item.name, count = count or item.count })
            end
        else
            result.failed = result.failed + 1
        end
    end
    return result
end

function storage.getStorageStatus()
    local status = { total = { capacity = 0, used = 0, percent = 0 }, barrels = {}, warnings = {} }
    
    -- Vérifier les barils de tri
    for _, rule in ipairs(sortingRules) do
        local percent = peripherals.getFillPercent(rule.barrel)
        status.total.capacity = status.total.capacity + 100
        status.total.used = status.total.used + percent
        if percent >= 100 then
            table.insert(status.warnings, { level = "critical", item = utils.getShortName(rule.itemId), percent = percent })
        elseif percent >= 80 then
            table.insert(status.warnings, { level = "warning", item = utils.getShortName(rule.itemId), percent = percent })
        end
    end
    
    -- Vérifier le coffre overflow
    if overflowChest then
        local percent = peripherals.getFillPercent(overflowChest)
        status.total.capacity = status.total.capacity + 100
        status.total.used = status.total.used + percent
        if percent >= 100 then
            table.insert(status.warnings, { level = "critical", item = "Overflow", percent = percent })
        elseif percent >= 80 then
            table.insert(status.warnings, { level = "warning", item = "Overflow", percent = percent })
        end
    end
    
    if status.total.capacity > 0 then
        status.total.percent = math.floor(status.total.used / status.total.capacity * 100)
    end
    return status
end

-- ============================================
-- UI avec BOUTONS TACTILES
-- ============================================

local ui = {}
local monitor = nil
local monitorName = nil
local width, height = 0, 0
local alertState = { active = false, message = "", startTime = 0, duration = 3 }
local buttons = {}

local theme = {
    bg = colors.black, header = colors.blue, headerText = colors.white,
    text = colors.white, textDim = colors.lightGray, accent = colors.cyan,
    success = colors.lime, warning = colors.orange, danger = colors.red,
    rare = colors.yellow, border = colors.gray, graphBar = colors.lime, graphBg = colors.gray,
    buttonBg = colors.gray, buttonText = colors.white, buttonActive = colors.lime
}

function ui.init(mon, name)
    monitor = mon
    monitorName = name
    if monitor then
        monitor.setTextScale(0.5)
        width, height = monitor.getSize()
        monitor.setBackgroundColor(theme.bg)
        monitor.clear()
    end
    return width, height
end

function ui.clear()
    if not monitor then return end
    monitor.setBackgroundColor(theme.bg)
    monitor.clear()
    buttons = {}
end

function ui.writeLine(x, y, text, fg, bg)
    if not monitor then return end
    monitor.setCursorPos(x, y)
    monitor.setTextColor(fg or theme.text)
    monitor.setBackgroundColor(bg or theme.bg)
    monitor.write(text)
end

function ui.drawLine(y, char, fg)
    if not monitor then return end
    monitor.setCursorPos(1, y)
    monitor.setTextColor(fg or theme.border)
    monitor.setBackgroundColor(theme.bg)
    monitor.write(string.rep(char or "-", width))
end

function ui.drawProgressBar(x, y, w, percent, fg, bg)
    if not monitor then return end
    fg = fg or theme.graphBar
    bg = bg or theme.graphBg
    local filled = math.floor((percent / 100) * w)
    if filled > w then filled = w end
    if filled < 0 then filled = 0 end
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(fg)
    monitor.write(string.rep(" ", filled))
    monitor.setBackgroundColor(bg)
    monitor.write(string.rep(" ", w - filled))
    monitor.setBackgroundColor(theme.bg)
end

function ui.drawBarGraph(x, y, w, h, data, maxValue)
    if not monitor or not data or #data == 0 then return end
    if not maxValue then
        maxValue = 1
        for _, v in ipairs(data) do if v > maxValue then maxValue = v end end
    end
    local barWidth = math.floor(w / #data)
    if barWidth < 1 then barWidth = 1 end
    for i, value in ipairs(data) do
        local barHeight = math.floor((value / maxValue) * h)
        if barHeight > h then barHeight = h end
        local barX = x + (i - 1) * barWidth
        for j = 0, h - 1 do
            monitor.setCursorPos(barX, y + h - 1 - j)
            if j < barHeight then
                monitor.setBackgroundColor(theme.graphBar)
            else
                monitor.setBackgroundColor(theme.graphBg)
            end
            monitor.write(string.rep(" ", barWidth - 1))
        end
    end
    monitor.setBackgroundColor(theme.bg)
end

function ui.drawButton(x, y, w, h, text, id, active)
    if not monitor then return end
    local bgColor = active and theme.buttonActive or theme.buttonBg
    local fgColor = active and theme.bg or theme.buttonText
    for dy = 0, h - 1 do
        monitor.setCursorPos(x, y + dy)
        monitor.setBackgroundColor(bgColor)
        monitor.write(string.rep(" ", w))
    end
    local textX = x + math.floor((w - #text) / 2)
    local textY = y + math.floor(h / 2)
    monitor.setCursorPos(textX, textY)
    monitor.setTextColor(fgColor)
    monitor.setBackgroundColor(bgColor)
    monitor.write(text)
    table.insert(buttons, { id = id, x1 = x, y1 = y, x2 = x + w - 1, y2 = y + h - 1 })
    monitor.setBackgroundColor(theme.bg)
end

function ui.checkButtonClick(clickX, clickY)
    for _, btn in ipairs(buttons) do
        if clickX >= btn.x1 and clickX <= btn.x2 and clickY >= btn.y1 and clickY <= btn.y2 then
            return btn.id
        end
    end
    return nil
end

function ui.drawHeader(title, spawnOn, sessionTime)
    if not monitor then return end
    monitor.setTextColor(theme.headerText)
    monitor.setBackgroundColor(theme.header)
    monitor.setCursorPos(1, 1)
    monitor.write(string.rep(" ", width))
    monitor.setCursorPos(2, 1)
    monitor.write("# " .. title)
    
    local btnText = spawnOn and " ON " or " OFF"
    local btnX = math.floor(width / 2) - 3
    ui.drawButton(btnX, 1, 6, 1, btnText, "spawn", spawnOn)
    
    local timeText = utils.formatTime(sessionTime)
    monitor.setCursorPos(width - #timeText - 1, 1)
    monitor.setTextColor(theme.headerText)
    monitor.setBackgroundColor(theme.header)
    monitor.write(timeText)
    monitor.setBackgroundColor(theme.bg)
end

function ui.drawStats(x, y, stats, playerPresent)
    if not monitor then return end
    ui.writeLine(x, y, "STATISTIQUES", theme.accent)
    ui.writeLine(x + 13, y, playerPresent and "*" or ".", playerPresent and theme.success or theme.textDim)
    y = y + 2
    ui.writeLine(x, y, "Mobs session:", theme.textDim)
    ui.writeLine(x + 14, y, "~" .. utils.formatNumber(stats.session.mobsKilled), theme.success)
    y = y + 1
    ui.writeLine(x, y, "Mobs total:", theme.textDim)
    ui.writeLine(x + 14, y, "~" .. utils.formatNumber(stats.total.mobsKilled), theme.text)
    y = y + 2
    ui.writeLine(x, y, "Items session:", theme.textDim)
    ui.writeLine(x + 14, y, utils.formatNumber(stats.session.itemsCollected), theme.success)
    y = y + 1
    ui.writeLine(x, y, "Items total:", theme.textDim)
    ui.writeLine(x + 14, y, utils.formatNumber(stats.total.itemsCollected), theme.text)
    y = y + 2
    ui.writeLine(x, y, "Rares:", theme.textDim)
    ui.writeLine(x + 14, y, utils.formatNumber(stats.session.raresFound), theme.rare)
end

function ui.drawGraph(x, y, w, h, hourlyData)
    if not monitor then return end
    ui.writeLine(x, y, "PRODUCTION /HEURE", theme.accent)
    y = y + 2
    if not hourlyData or #hourlyData == 0 then
        ui.writeLine(x, y + 2, "Pas de donnees", theme.textDim)
        return
    end
    local values = {}
    local maxVal = 1
    for _, data in ipairs(hourlyData) do
        table.insert(values, data.mobs)
        if data.mobs > maxVal then maxVal = data.mobs end
    end
    ui.writeLine(x, y, "Max: ~" .. utils.formatNumber(maxVal) .. "/h", theme.textDim)
    y = y + 1
    ui.drawBarGraph(x, y, w, h - 3, values, maxVal)
    y = y + h - 2
    ui.writeLine(x, y, "-" .. #hourlyData .. "h", theme.textDim)
    ui.writeLine(x + w - 4, y, "now", theme.textDim)
end

function ui.drawStorage(x, y, storageStatus)
    if not monitor then return end
    ui.writeLine(x, y, "STOCKAGE", theme.accent)
    y = y + 2
    local percent = storageStatus.total.percent
    local barColor = theme.graphBar
    if percent >= 90 then barColor = theme.danger
    elseif percent >= 75 then barColor = theme.warning end
    ui.drawProgressBar(x, y, 18, percent, barColor)
    ui.writeLine(x + 19, y, percent .. "%", theme.text)
    y = y + 2
    local warningCount = 0
    for _, warning in ipairs(storageStatus.warnings) do
        if warningCount >= 3 then break end
        local icon = warning.level == "critical" and "!" or ">"
        local color = warning.level == "critical" and theme.danger or theme.warning
        ui.writeLine(x, y, icon .. " " .. utils.truncate(warning.item, 12) .. ": " .. warning.percent .. "%", color)
        y = y + 1
        warningCount = warningCount + 1
    end
    if warningCount == 0 then ui.writeLine(x, y, "Tout va bien", theme.success) end
end

function ui.drawRareItems(x, y, rareItems)
    if not monitor then return end
    ui.writeLine(x, y, "* ITEMS RARES", theme.rare)
    y = y + 2
    if not rareItems or #rareItems == 0 then
        ui.writeLine(x, y, "Aucun pour l'instant", theme.textDim)
        return
    end
    for i, item in ipairs(rareItems) do
        if i > 4 then break end
        ui.writeLine(x, y, "> ", theme.rare)
        ui.writeLine(x + 2, y, utils.truncate(utils.getShortName(item.name), 14), theme.text)
        ui.writeLine(x + 18, y, utils.formatTimestamp(item.time), theme.textDim)
        y = y + 1
    end
end

function ui.drawFooter(y)
    if not monitor then return end
    ui.drawLine(y, "-", theme.border)
    y = y + 1
    local btnWidth = 10
    local spacing = 2
    local startX = 2
    ui.drawButton(startX, y, btnWidth, 1, "CONFIG", "config", false)
    ui.drawButton(startX + btnWidth + spacing, y, btnWidth, 1, "RESET", "reset", false)
    ui.drawButton(startX + (btnWidth + spacing) * 2, y, btnWidth, 1, "QUITTER", "quit", false)
end

function ui.drawMainScreen(data)
    if not monitor then return end
    ui.clear()
    ui.drawHeader("MOB TOWER v1.3", data.spawnOn, data.sessionTime)
    ui.drawLine(2)
    local leftCol = 2
    local rightCol = math.floor(width / 2) + 2
    local colWidth = math.floor(width / 2) - 3
    ui.drawStats(leftCol, 4, data.stats, data.playerPresent)
    ui.drawGraph(rightCol, 4, colWidth, 8, data.hourlyData)
    local midLine = 13
    ui.drawLine(midLine)
    ui.drawStorage(leftCol, midLine + 2, data.storageStatus)
    ui.drawRareItems(rightCol, midLine + 2, data.rareItems)
    ui.drawFooter(height - 1)
    if alertState.active then ui.drawAlert() end
end

function ui.showAlert(message, duration)
    alertState.active = true
    alertState.message = message
    alertState.startTime = os.epoch("utc") / 1000
    alertState.duration = duration or 3
end

function ui.updateAlert()
    if not alertState.active then return false end
    local elapsed = (os.epoch("utc") / 1000) - alertState.startTime
    if elapsed >= alertState.duration then alertState.active = false return false end
    return true
end

function ui.drawAlert()
    if not monitor or not alertState.active then return end
    local msg = alertState.message
    local msgWidth = #msg + 4
    local x = math.floor((width - msgWidth) / 2)
    local y = math.floor(height / 2)
    local elapsed = (os.epoch("utc") / 1000) - alertState.startTime
    local flash = math.floor(elapsed * 4) % 2 == 0
    local bgColor = flash and theme.rare or theme.danger
    monitor.setTextColor(theme.bg)
    monitor.setBackgroundColor(bgColor)
    for dy = -1, 1 do
        monitor.setCursorPos(x, y + dy)
        monitor.write(string.rep(" ", msgWidth))
    end
    monitor.setCursorPos(x + 2, y)
    monitor.write(msg)
    monitor.setBackgroundColor(theme.bg)
end

-- ============================================
-- CONFIGURATION
-- ============================================

local config = {
    version = "1.3",
    player = { name = "MikeChausette", detectionRange = 16 },
    peripherals = { playerDetector = nil, monitor = nil },
    redstone = { side = "back", inverted = false },
    storage = { collectorChest = nil, overflowChest = nil, sortingRules = {} },
    display = { refreshRate = 1, graphHours = 12, rareItemsCount = 5, alertDuration = 5 },
    sorting = { interval = 5, enabled = true },
    setupComplete = false
}

local CONFIG_FILE = "/mobTower/data/config.dat"

-- ============================================
-- SETUP WIZARD AMELIORE
-- ============================================

local function setupWizard()
    term.clear()
    term.setCursorPos(1, 1)
    
    term.setTextColor(colors.cyan)
    print("============================================")
    print("   MOB TOWER MANAGER v1.3 - Setup Wizard")
    print("============================================")
    term.setTextColor(colors.white)
    print("")
    print("Navigation: Fleches haut/bas, Entree")
    print("PageUp/PageDown pour aller plus vite")
    print("")
    print("Appuyez sur une touche pour commencer...")
    os.pullEvent("key")
    
    -- Nom du joueur
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.cyan)
    print("[1/8] Pseudo Minecraft")
    term.setTextColor(colors.white)
    print("")
    write("Ton pseudo [" .. config.player.name .. "]: ")
    local playerName = read()
    if playerName and #playerName > 0 then config.player.name = playerName end
    
    -- Scan
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.cyan)
    print("[2/8] Scan des peripheriques...")
    term.setTextColor(colors.white)
    sleep(0.5)
    local allPeripherals = peripherals.listAll()
    print("")
    print("Trouves:")
    print("  - " .. #allPeripherals.playerDetectors .. " Player Detector(s)")
    print("  - " .. #allPeripherals.monitors .. " Moniteur(s)")
    print("  - " .. #allPeripherals.inventories .. " Inventaire(s)")
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
    
    -- Player Detector
    if #allPeripherals.playerDetectors > 0 then
        local options = {}
        for _, det in ipairs(allPeripherals.playerDetectors) do
            table.insert(options, { name = det.name, value = det.name })
        end
        local result = navigableMenu("[3/8] Choisir le Player Detector", options, true)
        config.peripherals.playerDetector = result
    else
        term.clear()
        term.setCursorPos(1, 1)
        term.setTextColor(colors.yellow)
        print("[3/8] Aucun Player Detector trouve")
        term.setTextColor(colors.white)
        print("(Optionnel - continue sans)")
        sleep(1)
    end
    
    -- Monitor
    if #allPeripherals.monitors == 0 then
        term.clear()
        term.setTextColor(colors.red)
        print("ERREUR: Aucun moniteur trouve!")
        term.setTextColor(colors.white)
        return false
    end
    local monOptions = {}
    for _, mon in ipairs(allPeripherals.monitors) do
        table.insert(monOptions, { name = mon.name, value = mon.name })
    end
    local monResult = navigableMenu("[4/8] Choisir le Moniteur", monOptions, false)
    if not monResult then return false end
    config.peripherals.monitor = monResult
    
    -- Redstone
    local sideOptions = {}
    for _, side in ipairs(utils.SIDES) do
        table.insert(sideOptions, { name = side, value = side })
    end
    local sideResult = navigableMenu("[5/8] Cote redstone (lampes)", sideOptions, true)
    if sideResult then
        config.redstone.side = sideResult
        term.clear()
        term.setCursorPos(1, 1)
        term.setTextColor(colors.cyan)
        print("Inverser le signal redstone?")
        term.setTextColor(colors.white)
        print("")
        print("Normal: signal OFF = lampes eteintes = spawn ON")
        print("Inverse: signal ON = lampes eteintes = spawn ON")
        print("")
        print("(o)ui / (n)on")
        local inv = read()
        config.redstone.inverted = (inv:lower() == "o")
    else
        config.redstone.side = nil
    end
    
    -- Coffre collecteur
    if #allPeripherals.inventories == 0 then
        term.clear()
        term.setTextColor(colors.red)
        print("ERREUR: Aucun inventaire trouve!")
        term.setTextColor(colors.white)
        return false
    end
    
    local collectorResult = selectInventory("[6/8] Coffre COLLECTEUR (entree des items)", allPeripherals.inventories, false)
    if not collectorResult then return false end
    config.storage.collectorChest = collectorResult
    
    -- Retirer le collecteur de la liste
    local remainingInv = {}
    for _, inv in ipairs(allPeripherals.inventories) do
        if inv.name ~= config.storage.collectorChest then
            table.insert(remainingInv, inv)
        end
    end
    
    -- Coffre overflow (NOUVEAU)
    local overflowResult = selectInventory("[7/8] Coffre OVERFLOW (items non tries)", remainingInv, true)
    config.storage.overflowChest = overflowResult
    
    -- Retirer l'overflow de la liste
    if overflowResult then
        local temp = {}
        for _, inv in ipairs(remainingInv) do
            if inv.name ~= overflowResult then
                table.insert(temp, inv)
            end
        end
        remainingInv = temp
    end
    
    -- Attribution des barils
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.cyan)
    print("[8/8] Attribution des barils de tri")
    term.setTextColor(colors.white)
    print("")
    print("Pour chaque item, choisissez un baril.")
    print("Les items non configures iront dans")
    if config.storage.overflowChest then
        print("le coffre overflow: " .. config.storage.overflowChest)
    else
        print("AUCUN coffre (resteront dans collecteur)")
    end
    print("")
    print("Barils disponibles: " .. #remainingInv)
    print("")
    print("Appuyez sur une touche...")
    os.pullEvent("key")
    
    config.storage.sortingRules = {}
    
    for _, item in ipairs(utils.SORTABLE_ITEMS) do
        if #remainingInv == 0 then
            term.clear()
            term.setTextColor(colors.yellow)
            print("Plus de barils disponibles!")
            term.setTextColor(colors.white)
            sleep(1)
            break
        end
        
        local barrelResult, idx = selectInventory(
            "Baril pour: " .. item.name .. " (" .. #remainingInv .. " dispo)",
            remainingInv,
            true
        )
        
        if barrelResult then
            table.insert(config.storage.sortingRules, {
                itemId = item.id,
                barrel = barrelResult,
                pattern = item.pattern or false
            })
            -- Retirer le baril utilisé
            table.remove(remainingInv, idx - 1)  -- -1 car on a ajouté "Aucun" en position 1
        end
    end
    
    -- Sauvegarde
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.lime)
    print("============================================")
    print("   Configuration terminee!")
    print("============================================")
    term.setTextColor(colors.white)
    print("")
    print("Resume:")
    print("  Joueur: " .. config.player.name)
    print("  Player Detector: " .. (config.peripherals.playerDetector or "Non"))
    print("  Moniteur: " .. config.peripherals.monitor)
    print("  Redstone: " .. (config.redstone.side or "Non"))
    print("  Collecteur: " .. config.storage.collectorChest)
    print("  Overflow: " .. (config.storage.overflowChest or "Non"))
    print("  Regles de tri: " .. #config.storage.sortingRules)
    print("")
    
    config.setupComplete = true
    utils.ensureDir("/mobTower/data")
    utils.saveTable(CONFIG_FILE, config)
    
    term.setTextColor(colors.yellow)
    print("CONSEIL: Touchez le moniteur pour")
    print("interagir avec les boutons!")
    term.setTextColor(colors.white)
    print("")
    print("Appuyez sur une touche pour demarrer...")
    os.pullEvent("key")
    
    return true
end

-- ============================================
-- PROGRAMME PRINCIPAL
-- ============================================

local running = true
local spawnOn = true
local lastSortTime = 0
local lastSaveTime = 0

local function loadConfig()
    if fs.exists(CONFIG_FILE) then
        local loaded = utils.loadTable(CONFIG_FILE)
        if loaded and loaded.setupComplete then
            config = loaded
            return true
        end
    end
    return false
end

local function initialize()
    utils.ensureDir("/mobTower/data")
    
    if not loadConfig() or not config.setupComplete then
        if not setupWizard() then return false end
    end
    
    local status = peripherals.init(config)
    if not status.monitor then
        print("Erreur: Moniteur non connecte!")
        return false
    end
    
    ui.init(peripherals.getMonitor(), config.peripherals.monitor)
    storage.init(config)
    
    spawnOn = true
    if config.redstone.side then
        peripherals.setSpawnOn()
    end
    
    return true
end

local function updateDisplay()
    local sts = storage.getStats()
    local playerPresent = peripherals.isPlayerPresent(config.player.name, config.player.detectionRange)
    
    ui.drawMainScreen({
        spawnOn = spawnOn,
        sessionTime = storage.getSessionTime(),
        playerPresent = playerPresent,
        stats = { session = sts.session, total = sts.total },
        hourlyData = storage.getHourlyData(config.display.graphHours),
        storageStatus = storage.getStorageStatus(),
        rareItems = storage.getRecentRares(config.display.rareItemsCount)
    })
end

local function handleMonitorTouch(x, y)
    local buttonId = ui.checkButtonClick(x, y)
    
    if buttonId == "spawn" then
        if config.redstone.side then
            local _, newState = peripherals.toggleSpawn(spawnOn)
            spawnOn = newState
        end
    elseif buttonId == "config" then
        config.setupComplete = false
        utils.saveTable(CONFIG_FILE, config)
        os.reboot()
    elseif buttonId == "reset" then
        storage.resetSession()
        ui.showAlert("Stats reset!", 2)
    elseif buttonId == "quit" then
        running = false
    end
end

local function sortItems()
    if not config.sorting.enabled then return end
    local now = os.epoch("utc") / 1000
    if now - lastSortTime < config.sorting.interval then return end
    lastSortTime = now
    
    local result = storage.sortAll()
    for _, rare in ipairs(result.rares) do
        ui.showAlert("RARE: " .. utils.getShortName(rare.name), config.display.alertDuration)
    end
end

local function autoSave()
    local now = os.epoch("utc") / 1000
    if now - lastSaveTime < 60 then return end
    lastSaveTime = now
    storage.saveStats()
end

local function mainLoop()
    while running do
        sortItems()
        updateDisplay()
        ui.updateAlert()
        autoSave()
        
        local timer = os.startTimer(config.display.refreshRate)
        
        while true do
            local event, p1, p2, p3 = os.pullEvent()
            
            if event == "timer" and p1 == timer then
                break
            elseif event == "monitor_touch" then
                if p1 == config.peripherals.monitor then
                    os.cancelTimer(timer)
                    handleMonitorTouch(p2, p3)
                    break
                end
            elseif event == "key" then
                os.cancelTimer(timer)
                if p1 == keys.q then
                    running = false
                elseif p1 == keys.s then
                    if config.redstone.side then
                        local _, newState = peripherals.toggleSpawn(spawnOn)
                        spawnOn = newState
                    end
                elseif p1 == keys.r then
                    storage.resetSession()
                    ui.showAlert("Stats reset!", 2)
                elseif p1 == keys.c then
                    config.setupComplete = false
                    utils.saveTable(CONFIG_FILE, config)
                    os.reboot()
                end
                break
            end
        end
    end
end

-- ============================================
-- DÉMARRAGE
-- ============================================

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.cyan)
print("Mob Tower Manager v1.3")
term.setTextColor(colors.white)
print("Chargement...")

if not initialize() then
    print("Echec!")
    return
end

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("Mob Tower Manager v1.3 actif!")
term.setTextColor(colors.white)
print("")
print(">>> TOUCHEZ LE MONITEUR <<<")
print("pour interagir avec l'interface")
print("")
print("Boutons:")
print("  - ON/OFF : Toggle lampes")
print("  - CONFIG : Reconfigurer")
print("  - RESET  : Reset stats")
print("  - QUITTER: Arreter")

pcall(mainLoop)
storage.saveStats()
print("")
print("Arrete.")
