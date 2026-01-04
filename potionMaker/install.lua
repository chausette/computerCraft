-- ============================================
-- Potion Maker - Installateur
-- Par Chausette
-- https://github.com/chausette/computerCraft
-- ============================================

local GITHUB_RAW = "https://raw.githubusercontent.com/chausette/computerCraft/master/potionMaker/"

local files = {
    -- Core
    { path = "startup.lua", required = true },
    { path = "main.lua", required = true },
    { path = "wizard.lua", required = true },
    
    -- Modules
    { path = "modules/config.lua", required = true },
    { path = "modules/recipes.lua", required = true },
    { path = "modules/inventory.lua", required = true },
    { path = "modules/brewing.lua", required = true },
    { path = "modules/queue.lua", required = true },
    { path = "modules/ui.lua", required = true },
    { path = "modules/network.lua", required = true },
    { path = "modules/sound.lua", required = true },
    
    -- Data (default files)
    { path = "data/recipes.json", required = true },
    
    -- Pocket
    { path = "pocket/potion_remote.lua", required = true },
}

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
    centerText(2, "================================")
    centerText(3, "   POTION MAKER - INSTALLATEUR  ")
    centerText(4, "================================")
    setColors(colors.black, colors.white)
end

local function drawProgressBar(y, progress, total)
    local w, _ = term.getSize()
    local barWidth = w - 10
    local filled = math.floor((progress / total) * barWidth)
    
    term.setCursorPos(5, y)
    setColors(colors.black, colors.white)
    term.write("[")
    setColors(colors.green, colors.green)
    term.write(string.rep(" ", filled))
    setColors(colors.gray, colors.gray)
    term.write(string.rep(" ", barWidth - filled))
    setColors(colors.black, colors.white)
    term.write("]")
    
    term.setCursorPos(5, y + 1)
    term.write(string.format("%d/%d fichiers", progress, total))
end

local function downloadFile(remotePath, localPath)
    local url = GITHUB_RAW .. remotePath
    local response = http.get(url)
    
    if response then
        local content = response.readAll()
        response.close()
        
        -- Créer les dossiers si nécessaire
        local dir = localPath:match("(.+)/[^/]+$")
        if dir and not fs.exists(dir) then
            fs.makeDir(dir)
        end
        
        local file = fs.open(localPath, "w")
        file.write(content)
        file.close()
        return true
    end
    return false
end

local function install()
    drawHeader()
    
    term.setCursorPos(3, 6)
    setColors(colors.black, colors.yellow)
    print("Installation de Potion Maker...")
    print("")
    
    -- Créer les dossiers
    local dirs = { "modules", "data", "pocket" }
    for _, dir in ipairs(dirs) do
        if not fs.exists(dir) then
            fs.makeDir(dir)
        end
    end
    
    -- Télécharger les fichiers
    local success = 0
    local failed = {}
    
    for i, fileInfo in ipairs(files) do
        drawProgressBar(9, i, #files)
        
        term.setCursorPos(3, 12)
        term.clearLine()
        setColors(colors.black, colors.lightGray)
        term.write("Telechargement: " .. fileInfo.path)
        
        if downloadFile(fileInfo.path, fileInfo.path) then
            success = success + 1
        else
            if fileInfo.required then
                table.insert(failed, fileInfo.path)
            end
        end
        
        sleep(0.1)
    end
    
    -- Résultat
    term.setCursorPos(1, 14)
    
    if #failed > 0 then
        setColors(colors.black, colors.red)
        print("  ERREUR: Certains fichiers n'ont pas pu")
        print("  etre telecharges:")
        for _, f in ipairs(failed) do
            print("    - " .. f)
        end
        print("")
        setColors(colors.black, colors.yellow)
        print("  Verifiez votre connexion et reessayez.")
        return false
    else
        setColors(colors.black, colors.green)
        print("  Installation reussie!")
        print("")
        setColors(colors.black, colors.white)
        print("  " .. success .. " fichiers installes.")
        print("")
        setColors(colors.black, colors.cyan)
        print("  Lancement du wizard de configuration...")
        sleep(2)
        return true
    end
end

-- Point d'entrée
local ok = install()

if ok then
    shell.run("wizard.lua")
else
    setColors(colors.black, colors.white)
    print("")
    print("  Appuyez sur une touche pour quitter...")
    os.pullEvent("key")
end
