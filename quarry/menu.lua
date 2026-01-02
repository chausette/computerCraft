-- ============================================
-- MENU.lua - Menu principal Turtle
-- Choix entre Quarry et Fill
-- ============================================

local VERSION = "1.0"

local function clear()
    term.clear()
    term.setCursorPos(1, 1)
end

local function color(c)
    if term.isColor() then
        term.setTextColor(c)
    end
end

local function printHeader()
    clear()
    color(colors.yellow)
    print("================================")
    print("   TURTLE TOOLS v" .. VERSION)
    print("================================")
    color(colors.white)
    print("")
end

local function printMenu()
    printHeader()
    
    color(colors.cyan)
    print("Programmes disponibles:")
    color(colors.white)
    print("")
    
    print("  1. QUARRY - Miner une zone")
    print("     Creuse entre 2 coordonnees")
    print("")
    
    print("  2. FILL - Remplir une zone")
    print("     Rebouche avec dirt/cobble")
    print("")
    
    print("  3. Quitter")
    print("")
    
    color(colors.lightGray)
    print("--------------------------------")
    print("Fuel actuel: " .. turtle.getFuelLevel())
    print("--------------------------------")
    color(colors.white)
    print("")
end

local function main()
    while true do
        printMenu()
        
        io.write("Choix [1-3]: ")
        local input = read()
        
        if input == "1" then
            if fs.exists("quarry.lua") then
                shell.run("quarry")
            else
                color(colors.red)
                print("quarry.lua non trouve!")
                print("Reinstallez avec l'installer")
                color(colors.white)
                sleep(2)
            end
            
        elseif input == "2" then
            if fs.exists("fill.lua") then
                shell.run("fill")
            else
                color(colors.red)
                print("fill.lua non trouve!")
                print("Reinstallez avec l'installer")
                color(colors.white)
                sleep(2)
            end
            
        elseif input == "3" then
            clear()
            print("Au revoir!")
            return
            
        else
            color(colors.red)
            print("Choix invalide!")
            color(colors.white)
            sleep(1)
        end
    end
end

main()
