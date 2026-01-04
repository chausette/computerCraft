-- ============================================
-- Potion Maker - Wizard de Configuration
-- ============================================

local Config = require("modules.config")

-- Variables
local config = {
    peripherals = {
        monitor = nil,
        speaker = nil,
        brewing_stands = {},
        chests = {
            input = nil,
            water_bottles = nil,
            ingredients = nil,
            potions = nil,
            output = nil
        }
    },
    network = {
        protocol = "potion_network",
        channel = 500
    },
    alerts = {
        low_stock_threshold = 5
    },
    version = "1.0.0"
}

local peripheralsList = {}
local step = 1
local totalSteps = 9

-- Couleurs
local function setColors(bg, fg)
    if term.isColor() then
        term.setBackgroundColor(bg)
        term.setTextColor(fg)
    end
end

local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

local function centerText(y, text, fg, bg)
    local w, _ = term.getSize()
    local x = math.floor((w - #text) / 2) + 1
    term.setCursorPos(x, y)
    if fg then setColors(bg or colors.black, fg) end
    print(text)
end

local function drawHeader()
    clear()
    setColors(colors.black, colors.cyan)
    centerText(1, "================================")
    centerText(2, "  POTION MAKER - CONFIGURATION  ")
    centerText(3, "================================")
    
    -- Progress bar
    local w, _ = term.getSize()
    local barWidth = w - 4
    local filled = math.floor((step / totalSteps) * barWidth)
    
    term.setCursorPos(2, 4)
    setColors(colors.black, colors.white)
    term.write("[")
    setColors(colors.green, colors.green)
    term.write(string.rep(" ", filled))
    setColors(colors.gray, colors.gray)
    term.write(string.rep(" ", barWidth - filled))
    setColors(colors.black, colors.white)
    term.write("]")
    
    term.setCursorPos(2, 5)
    setColors(colors.black, colors.lightGray)
    print("Etape " .. step .. "/" .. totalSteps)
    
    setColors(colors.black, colors.white)
end

local function prompt(message)
    print("")
    setColors(colors.black, colors.yellow)
    term.write("> " .. message .. " ")
    setColors(colors.black, colors.white)
    return read()
end

local function promptYN(message, default)
    print("")
    setColors(colors.black, colors.yellow)
    local defText = default and "[O/n]" or "[o/N]"
    term.write("> " .. message .. " " .. defText .. " ")
    setColors(colors.black, colors.white)
    local input = read():lower()
    if input == "" then return default end
    return input == "o" or input == "oui" or input == "y" or input == "yes"
end

local function scanPeripherals()
    peripheralsList = {}
    local names = peripheral.getNames()
    
    for _, name in ipairs(names) do
        local pType = peripheral.getType(name)
        table.insert(peripheralsList, {
            name = name,
            type = pType
        })
    end
    
    return peripheralsList
end

local function filterPeripherals(filterType)
    local filtered = {}
    for _, p in ipairs(peripheralsList) do
        if p.type == filterType or (filterType == "chest" and p.type:find("inventory")) then
            table.insert(filtered, p)
        end
    end
    return filtered
end

local function selectPeripheral(list, title, allowMultiple)
    if #list == 0 then
        setColors(colors.black, colors.red)
        print("  Aucun peripherique de ce type trouve!")
        print("  Verifiez vos connexions wired modem.")
        return nil
    end
    
    print("")
    setColors(colors.black, colors.white)
    print("  " .. title)
    print("")
    
    for i, p in ipairs(list) do
        setColors(colors.black, colors.lightGray)
        print("  " .. i .. ". " .. p.name)
    end
    
    print("")
    
    if allowMultiple then
        setColors(colors.black, colors.yellow)
        term.write("> Entrez les numeros (ex: 1,2): ")
        setColors(colors.black, colors.white)
        local input = read()
        
        local selected = {}
        for num in input:gmatch("%d+") do
            local idx = tonumber(num)
            if idx and list[idx] then
                table.insert(selected, list[idx].name)
            end
        end
        return selected
    else
        setColors(colors.black, colors.yellow)
        term.write("> Entrez le numero: ")
        setColors(colors.black, colors.white)
        local input = tonumber(read())
        
        if input and list[input] then
            return list[input].name
        end
        return nil
    end
end

-- Étapes du wizard
local function stepWelcome()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  Bienvenue dans l'assistant de")
    print("  configuration de Potion Maker!")
    print("")
    print("  Ce wizard va vous guider pour")
    print("  configurer vos peripheriques.")
    print("")
    setColors(colors.black, colors.lightGray)
    print("  Assurez-vous que tous vos")
    print("  peripheriques sont connectes")
    print("  via wired modem.")
    print("")
    
    setColors(colors.black, colors.cyan)
    print("  Appuyez sur ENTREE pour commencer...")
    read()
    
    step = step + 1
end

local function stepScanPeripherals()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  Scan des peripheriques...")
    print("")
    
    scanPeripherals()
    
    setColors(colors.black, colors.green)
    print("  " .. #peripheralsList .. " peripherique(s) trouve(s):")
    print("")
    
    -- Compter par type
    local counts = {}
    for _, p in ipairs(peripheralsList) do
        counts[p.type] = (counts[p.type] or 0) + 1
    end
    
    setColors(colors.black, colors.lightGray)
    for pType, count in pairs(counts) do
        print("    - " .. pType .. ": " .. count)
    end
    
    print("")
    setColors(colors.black, colors.cyan)
    print("  Appuyez sur ENTREE pour continuer...")
    read()
    
    step = step + 1
end

local function stepMonitor()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  MONITEUR (3x2)")
    
    local monitors = filterPeripherals("monitor")
    local selected = selectPeripheral(monitors, "Selectionnez le moniteur principal:")
    
    if selected then
        config.peripherals.monitor = selected
        setColors(colors.black, colors.green)
        print("")
        print("  Moniteur configure: " .. selected)
        sleep(1)
        step = step + 1
    else
        setColors(colors.black, colors.red)
        print("  Selection invalide, reessayez.")
        sleep(1)
    end
end

local function stepSpeaker()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  SPEAKER")
    
    local speakers = filterPeripherals("speaker")
    local selected = selectPeripheral(speakers, "Selectionnez le speaker:")
    
    if selected then
        config.peripherals.speaker = selected
        setColors(colors.black, colors.green)
        print("")
        print("  Speaker configure: " .. selected)
        sleep(1)
        step = step + 1
    else
        if promptYN("Continuer sans speaker?", false) then
            config.peripherals.speaker = nil
            step = step + 1
        end
    end
end

local function stepBrewingStands()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  ALAMBICS (2)")
    
    -- Chercher les brewing stands
    local brewingStands = {}
    for _, p in ipairs(peripheralsList) do
        if p.type == "minecraft:brewing_stand" or p.type:find("brewing") then
            table.insert(brewingStands, p)
        end
    end
    
    local selected = selectPeripheral(brewingStands, "Selectionnez les 2 alambics:", true)
    
    if selected and #selected >= 1 then
        config.peripherals.brewing_stands = selected
        setColors(colors.black, colors.green)
        print("")
        print("  " .. #selected .. " alambic(s) configure(s)")
        sleep(1)
        step = step + 1
    else
        setColors(colors.black, colors.red)
        print("  Selectionnez au moins 1 alambic.")
        sleep(1)
    end
end

local function stepChestInput()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  COFFRE INPUT")
    print("  (depot ingredients/potions/fioles)")
    
    local chests = filterPeripherals("chest")
    -- Aussi chercher les inventaires génériques
    for _, p in ipairs(peripheralsList) do
        if p.type:find("inventory") or p.type:find("chest") or p.type:find("barrel") then
            local found = false
            for _, c in ipairs(chests) do
                if c.name == p.name then found = true break end
            end
            if not found then table.insert(chests, p) end
        end
    end
    
    local selected = selectPeripheral(chests, "Selectionnez le coffre INPUT:")
    
    if selected then
        config.peripherals.chests.input = selected
        setColors(colors.black, colors.green)
        print("")
        print("  Coffre INPUT: " .. selected)
        sleep(1)
        step = step + 1
    else
        setColors(colors.black, colors.red)
        print("  Selection invalide.")
        sleep(1)
    end
end

local function stepChestWater()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  COFFRE FIOLES D'EAU")
    
    local chests = filterPeripherals("chest")
    for _, p in ipairs(peripheralsList) do
        if p.type:find("inventory") or p.type:find("chest") or p.type:find("barrel") then
            local found = false
            for _, c in ipairs(chests) do
                if c.name == p.name then found = true break end
            end
            if not found then table.insert(chests, p) end
        end
    end
    
    -- Filtrer les coffres déjà utilisés
    local available = {}
    for _, c in ipairs(chests) do
        if c.name ~= config.peripherals.chests.input then
            table.insert(available, c)
        end
    end
    
    local selected = selectPeripheral(available, "Selectionnez le coffre FIOLES D'EAU:")
    
    if selected then
        config.peripherals.chests.water_bottles = selected
        setColors(colors.black, colors.green)
        print("")
        print("  Coffre Fioles: " .. selected)
        sleep(1)
        step = step + 1
    else
        setColors(colors.black, colors.red)
        print("  Selection invalide.")
        sleep(1)
    end
end

local function stepChestIngredients()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  COFFRE INGREDIENTS")
    
    local chests = filterPeripherals("chest")
    for _, p in ipairs(peripheralsList) do
        if p.type:find("inventory") or p.type:find("chest") or p.type:find("barrel") then
            local found = false
            for _, c in ipairs(chests) do
                if c.name == p.name then found = true break end
            end
            if not found then table.insert(chests, p) end
        end
    end
    
    -- Filtrer les coffres déjà utilisés
    local available = {}
    local used = {
        config.peripherals.chests.input,
        config.peripherals.chests.water_bottles
    }
    for _, c in ipairs(chests) do
        local isUsed = false
        for _, u in ipairs(used) do
            if c.name == u then isUsed = true break end
        end
        if not isUsed then table.insert(available, c) end
    end
    
    local selected = selectPeripheral(available, "Selectionnez le coffre INGREDIENTS:")
    
    if selected then
        config.peripherals.chests.ingredients = selected
        setColors(colors.black, colors.green)
        print("")
        print("  Coffre Ingredients: " .. selected)
        sleep(1)
        step = step + 1
    else
        setColors(colors.black, colors.red)
        print("  Selection invalide.")
        sleep(1)
    end
end

local function stepChestPotions()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  COFFRE STOCKAGE POTIONS")
    
    local chests = filterPeripherals("chest")
    for _, p in ipairs(peripheralsList) do
        if p.type:find("inventory") or p.type:find("chest") or p.type:find("barrel") then
            local found = false
            for _, c in ipairs(chests) do
                if c.name == p.name then found = true break end
            end
            if not found then table.insert(chests, p) end
        end
    end
    
    -- Filtrer les coffres déjà utilisés
    local available = {}
    local used = {
        config.peripherals.chests.input,
        config.peripherals.chests.water_bottles,
        config.peripherals.chests.ingredients
    }
    for _, c in ipairs(chests) do
        local isUsed = false
        for _, u in ipairs(used) do
            if c.name == u then isUsed = true break end
        end
        if not isUsed then table.insert(available, c) end
    end
    
    local selected = selectPeripheral(available, "Selectionnez le coffre POTIONS:")
    
    if selected then
        config.peripherals.chests.potions = selected
        setColors(colors.black, colors.green)
        print("")
        print("  Coffre Potions: " .. selected)
        sleep(1)
        step = step + 1
    else
        setColors(colors.black, colors.red)
        print("  Selection invalide.")
        sleep(1)
    end
end

local function stepChestOutput()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.white)
    print("  COFFRE OUTPUT")
    print("  (distribution des potions)")
    
    local chests = filterPeripherals("chest")
    for _, p in ipairs(peripheralsList) do
        if p.type:find("inventory") or p.type:find("chest") or p.type:find("barrel") then
            local found = false
            for _, c in ipairs(chests) do
                if c.name == p.name then found = true break end
            end
            if not found then table.insert(chests, p) end
        end
    end
    
    -- Filtrer les coffres déjà utilisés
    local available = {}
    local used = {
        config.peripherals.chests.input,
        config.peripherals.chests.water_bottles,
        config.peripherals.chests.ingredients,
        config.peripherals.chests.potions
    }
    for _, c in ipairs(chests) do
        local isUsed = false
        for _, u in ipairs(used) do
            if c.name == u then isUsed = true break end
        end
        if not isUsed then table.insert(available, c) end
    end
    
    local selected = selectPeripheral(available, "Selectionnez le coffre OUTPUT:")
    
    if selected then
        config.peripherals.chests.output = selected
        setColors(colors.black, colors.green)
        print("")
        print("  Coffre Output: " .. selected)
        sleep(1)
        step = step + 1
    else
        setColors(colors.black, colors.red)
        print("  Selection invalide.")
        sleep(1)
    end
end

local function stepFinish()
    drawHeader()
    
    term.setCursorPos(2, 7)
    setColors(colors.black, colors.green)
    print("  CONFIGURATION TERMINEE!")
    print("")
    setColors(colors.black, colors.white)
    print("  Resume:")
    setColors(colors.black, colors.lightGray)
    print("  - Moniteur: " .. (config.peripherals.monitor or "Non"))
    print("  - Speaker: " .. (config.peripherals.speaker or "Non"))
    print("  - Alambics: " .. #config.peripherals.brewing_stands)
    print("  - Coffre Input: " .. (config.peripherals.chests.input or "Non"))
    print("  - Coffre Eau: " .. (config.peripherals.chests.water_bottles or "Non"))
    print("  - Coffre Ingr.: " .. (config.peripherals.chests.ingredients or "Non"))
    print("  - Coffre Potions: " .. (config.peripherals.chests.potions or "Non"))
    print("  - Coffre Output: " .. (config.peripherals.chests.output or "Non"))
    
    print("")
    
    -- Sauvegarder la configuration
    Config.save(config)
    
    setColors(colors.black, colors.green)
    print("  Configuration sauvegardee!")
    print("")
    setColors(colors.black, colors.cyan)
    
    if promptYN("Demarrer Potion Maker maintenant?", true) then
        shell.run("main.lua")
    else
        print("")
        print("  Tapez 'main' pour demarrer.")
    end
end

-- Main wizard loop
local steps = {
    stepWelcome,
    stepScanPeripherals,
    stepMonitor,
    stepSpeaker,
    stepBrewingStands,
    stepChestInput,
    stepChestWater,
    stepChestIngredients,
    stepChestPotions,
    stepChestOutput,
    stepFinish
}

totalSteps = #steps - 1 -- -1 car welcome ne compte pas vraiment

while step <= #steps do
    steps[step]()
end
