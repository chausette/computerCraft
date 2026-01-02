-- ============================================
-- INSTALLER - Turtle Tools
-- Installe quarry, fill, menu et monitor
-- ============================================
-- wget run https://raw.githubusercontent.com/chausette/computerCraft/master/quarry/installer.lua
-- ============================================

local GITHUB_USER = "chausette"
local GITHUB_REPO = "computerCraft"
local GITHUB_BRANCH = "master"

local BASE_URL = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/quarry/"

local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

local function color(c)
    if term.isColor() then
        term.setTextColor(c)
    end
end

local function download(file)
    local url = BASE_URL .. file
    
    if fs.exists(file) then
        fs.delete(file)
    end
    
    local response = http.get(url)
    if response then
        local content = response.readAll()
        response.close()
        
        local f = fs.open(file, "w")
        if f then
            f.write(content)
            f.close()
            return true
        end
    end
    return false
end

local function printHeader()
    clear()
    color(colors.yellow)
    print("================================")
    print("   TURTLE TOOLS INSTALLER")
    print("================================")
    color(colors.white)
    print("")
end

local function installTurtle()
    printHeader()
    
    color(colors.cyan)
    print("Installation Turtle...")
    color(colors.white)
    print("")
    
    local files = {"menu.lua", "quarry.lua", "fill.lua"}
    local success = true
    
    for _, file in ipairs(files) do
        io.write("  " .. file .. "... ")
        if download(file) then
            color(colors.lime)
            print("OK")
        else
            color(colors.red)
            print("ECHEC")
            success = false
        end
        color(colors.white)
    end
    
    print("")
    
    if success then
        color(colors.lime)
        print("Installation reussie!")
        color(colors.white)
        print("")
        print("Programmes installes:")
        print("  menu   - Menu principal")
        print("  quarry - Miner une zone")
        print("  fill   - Remplir une zone")
        print("")
        color(colors.yellow)
        print("Tapez 'menu' pour commencer")
    else
        color(colors.red)
        print("Installation incomplete!")
        print("Verifiez votre connexion")
    end
end

local function installPocket()
    printHeader()
    
    color(colors.cyan)
    print("Installation Pocket...")
    color(colors.white)
    print("")
    
    io.write("  monitor.lua... ")
    if download("monitor.lua") then
        color(colors.lime)
        print("OK")
        color(colors.white)
        print("")
        color(colors.lime)
        print("Installation reussie!")
        color(colors.white)
        print("")
        print("Programme installe:")
        print("  monitor - Surveiller turtle")
        print("")
        color(colors.yellow)
        print("Tapez 'monitor' pour lancer")
        print("")
        color(colors.lightGray)
        print("Canal: 400")
    else
        color(colors.red)
        print("ECHEC")
        print("")
        print("Installation echouee!")
        print("Verifiez votre connexion")
    end
end

local function installAll()
    printHeader()
    
    color(colors.cyan)
    print("Installation complete...")
    color(colors.white)
    print("")
    
    local files = {"menu.lua", "quarry.lua", "fill.lua", "monitor.lua"}
    local success = true
    
    for _, file in ipairs(files) do
        io.write("  " .. file .. "... ")
        if download(file) then
            color(colors.lime)
            print("OK")
        else
            color(colors.red)
            print("ECHEC")
            success = false
        end
        color(colors.white)
    end
    
    print("")
    
    if success then
        color(colors.lime)
        print("Installation reussie!")
    else
        color(colors.orange)
        print("Installation partielle")
    end
end

-- Main
local function main()
    printHeader()
    
    -- Detection du type de machine
    local isTurtle = turtle ~= nil
    local isPocket = pocket ~= nil
    local isComputer = not isTurtle and not isPocket
    
    color(colors.cyan)
    print("Type detecte:")
    color(colors.white)
    
    if isTurtle then
        print("  Mining Turtle")
        print("")
        color(colors.lightGray)
        print("Installation automatique des")
        print("programmes turtle...")
        print("")
        sleep(1)
        installTurtle()
        
    elseif isPocket then
        print("  Pocket Computer")
        print("")
        color(colors.lightGray)
        print("Installation automatique du")
        print("programme monitor...")
        print("")
        sleep(1)
        installPocket()
        
    else
        print("  Computer")
        print("")
        print("Que voulez-vous installer?")
        print("")
        print("  1. Programmes Turtle")
        print("     (quarry, fill, menu)")
        print("")
        print("  2. Programme Monitor")
        print("     (pour pocket)")
        print("")
        print("  3. Tout")
        print("")
        
        io.write("Choix [1-3]: ")
        local input = read()
        
        if input == "2" then
            installPocket()
        elseif input == "3" then
            installAll()
        else
            installTurtle()
        end
    end
end

main()
