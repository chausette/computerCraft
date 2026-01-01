-- ============================================
-- GPS HOST - ComputerCraft
-- ============================================
-- IMPORTANT: Pour eviter "ambiguous position"
--
-- Vous avez besoin de 4 GPS hosts minimum.
-- AU MOINS 1 doit etre a une hauteur Y differente!
--
-- Exemple de configuration correcte:
--   Host 1: X=100, Y=200, Z=100
--   Host 2: X=112, Y=200, Z=100
--   Host 3: X=100, Y=200, Z=112
--   Host 4: X=106, Y=210, Z=106  <- PLUS HAUT!
--
-- Espacement minimum: 6 blocs entre chaque host
-- ============================================

-- MODIFIEZ CES COORDONNEES (F3 dans Minecraft)
local X = 0
local Y = 255
local Z = 0

-- ============================================
-- NE PAS MODIFIER CI-DESSOUS
-- ============================================

-- Trouve le modem wireless
local modemSide = nil
for _, side in ipairs({"top", "bottom", "left", "right", "front", "back"}) do
    if peripheral.isPresent(side) and peripheral.getType(side) == "modem" then
        local m = peripheral.wrap(side)
        if m.isWireless and m.isWireless() then
            modemSide = side
            break
        end
    end
end

if not modemSide then
    print("=============================")
    print("ERREUR: Wireless Modem requis")
    print("=============================")
    print("")
    print("Attachez un Wireless Modem ou")
    print("un Ender Modem a ce computer.")
    return
end

-- Affichage
term.clear()
term.setCursorPos(1, 1)

print("=============================")
print("      GPS HOST ACTIF")
print("=============================")
print("")
print("Position:")
print("  X = " .. X)
print("  Y = " .. Y)
print("  Z = " .. Z)
print("")
print("Modem: " .. modemSide)
print("")
print("-----------------------------")
print("RAPPEL: 4 hosts necessaires")
print("1 host doit etre plus haut!")
print("-----------------------------")
print("")

-- Lance le GPS
shell.run("gps", "host", X, Y, Z)
