-- ============================================
-- GPS HOST - startup.lua
-- Place sur chaque Advanced Computer GPS
-- ============================================
-- MODIFIE CES COORDONNEES selon la position
-- REELLE de ce computer dans le monde !
-- ============================================

local X = 0      -- Coordonnée X de ce computer
local Y = 255    -- Coordonnée Y de ce computer  
local Z = 0      -- Coordonnée Z de ce computer

-- ============================================
-- NE PAS MODIFIER EN DESSOUS
-- ============================================

-- Cherche le modem wireless
local modem = nil
for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
        local m = peripheral.wrap(side)
        if m.isWireless() then
            modem = side
            break
        end
    end
end

if not modem then
    print("ERREUR: Aucun modem wireless trouve!")
    print("Attache un Wireless Modem a ce computer.")
    return
end

print("=================================")
print("   GPS HOST - ComputerCraft")
print("=================================")
print("")
print("Position configuree:")
print("  X = " .. X)
print("  Y = " .. Y)
print("  Z = " .. Z)
print("")
print("Modem: " .. modem)
print("")
print("Demarrage du service GPS...")
print("")

-- Lance le host GPS
shell.run("gps", "host", X, Y, Z)
