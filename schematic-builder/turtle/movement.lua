-- ============================================
-- MOVEMENT.lua - Gestion des deplacements GPS
-- Pour Mining Turtle avec Wireless Modem
-- ============================================

local movement = {}

-- ============================================
-- VARIABLES D'ETAT
-- ============================================

-- Position actuelle
movement.x = 0
movement.y = 0
movement.z = 0

-- Direction (0=nord/-z, 1=est/+x, 2=sud/+z, 3=ouest/-x)
movement.facing = 0

-- Noms des directions
local directionNames = {"nord", "est", "sud", "ouest"}
local directionVectors = {
    {x = 0, z = -1},  -- Nord
    {x = 1, z = 0},   -- Est
    {x = 0, z = 1},   -- Sud
    {x = -1, z = 0}   -- Ouest
}

-- ============================================
-- GPS
-- ============================================

-- Localise la turtle via GPS
function movement.locate()
    local x, y, z = gps.locate(5)
    if x then
        movement.x = math.floor(x)
        movement.y = math.floor(y)
        movement.z = math.floor(z)
        return true
    end
    return false
end

-- Determine la direction en se deplacant
function movement.calibrate()
    if not movement.locate() then
        return false, "GPS non disponible"
    end
    
    local startX, startZ = movement.x, movement.z
    
    -- Essaie d'avancer
    if turtle.forward() then
        if movement.locate() then
            local dx = movement.x - startX
            local dz = movement.z - startZ
            
            if dz == -1 then movement.facing = 0      -- Nord
            elseif dx == 1 then movement.facing = 1   -- Est
            elseif dz == 1 then movement.facing = 2   -- Sud
            elseif dx == -1 then movement.facing = 3  -- Ouest
            end
            
            -- Retourne a la position initiale
            turtle.back()
            movement.x = startX
            movement.z = startZ
            return true
        end
    end
    
    -- Si impossible d'avancer, essaie de tourner et reessayer
    for i = 1, 4 do
        turtle.turnRight()
        if turtle.forward() then
            if movement.locate() then
                local dx = movement.x - startX
                local dz = movement.z - startZ
                
                if dz == -1 then movement.facing = 0
                elseif dx == 1 then movement.facing = 1
                elseif dz == 1 then movement.facing = 2
                elseif dx == -1 then movement.facing = 3
                end
                
                turtle.back()
                movement.x = startX
                movement.z = startZ
                return true
            end
            turtle.back()
        end
    end
    
    return false, "Impossible de calibrer la direction"
end

-- ============================================
-- MOUVEMENTS DE BASE
-- ============================================

-- Avance d'un bloc
function movement.forward()
    if turtle.forward() then
        local vec = directionVectors[movement.facing + 1]
        movement.x = movement.x + vec.x
        movement.z = movement.z + vec.z
        return true
    end
    return false
end

-- Recule d'un bloc
function movement.back()
    if turtle.back() then
        local vec = directionVectors[movement.facing + 1]
        movement.x = movement.x - vec.x
        movement.z = movement.z - vec.z
        return true
    end
    return false
end

-- Monte d'un bloc
function movement.up()
    if turtle.up() then
        movement.y = movement.y + 1
        return true
    end
    return false
end

-- Descend d'un bloc
function movement.down()
    if turtle.down() then
        movement.y = movement.y - 1
        return true
    end
    return false
end

-- Tourne a droite
function movement.turnRight()
    turtle.turnRight()
    movement.facing = (movement.facing + 1) % 4
end

-- Tourne a gauche
function movement.turnLeft()
    turtle.turnLeft()
    movement.facing = (movement.facing - 1) % 4
end

-- ============================================
-- MOUVEMENTS AVANCES
-- ============================================

-- Tourne vers une direction specifique
function movement.face(direction)
    while movement.facing ~= direction do
        movement.turnRight()
    end
end

-- Tourne vers le nord
function movement.faceNorth() movement.face(0) end
function movement.faceEast() movement.face(1) end
function movement.faceSouth() movement.face(2) end
function movement.faceWest() movement.face(3) end

-- Se deplace vers une position cible
function movement.goTo(targetX, targetY, targetZ, digBlocks)
    digBlocks = digBlocks or false
    
    -- D'abord, monter/descendre au bon niveau Y
    while movement.y < targetY do
        if not movement.up() then
            if digBlocks then
                turtle.digUp()
                if not movement.up() then
                    return false, "Bloque en montant"
                end
            else
                return false, "Bloque en montant"
            end
        end
    end
    
    while movement.y > targetY do
        if not movement.down() then
            if digBlocks then
                turtle.digDown()
                if not movement.down() then
                    return false, "Bloque en descendant"
                end
            else
                return false, "Bloque en descendant"
            end
        end
    end
    
    -- Ensuite, se deplacer en X
    if movement.x < targetX then
        movement.faceEast()
        while movement.x < targetX do
            if not movement.forward() then
                if digBlocks then
                    turtle.dig()
                    if not movement.forward() then
                        return false, "Bloque en X+"
                    end
                else
                    return false, "Bloque en X+"
                end
            end
        end
    elseif movement.x > targetX then
        movement.faceWest()
        while movement.x > targetX do
            if not movement.forward() then
                if digBlocks then
                    turtle.dig()
                    if not movement.forward() then
                        return false, "Bloque en X-"
                    end
                else
                    return false, "Bloque en X-"
                end
            end
        end
    end
    
    -- Enfin, se deplacer en Z
    if movement.z < targetZ then
        movement.faceSouth()
        while movement.z < targetZ do
            if not movement.forward() then
                if digBlocks then
                    turtle.dig()
                    if not movement.forward() then
                        return false, "Bloque en Z+"
                    end
                else
                    return false, "Bloque en Z+"
                end
            end
        end
    elseif movement.z > targetZ then
        movement.faceNorth()
        while movement.z > targetZ do
            if not movement.forward() then
                if digBlocks then
                    turtle.dig()
                    if not movement.forward() then
                        return false, "Bloque en Z-"
                    end
                else
                    return false, "Bloque en Z-"
                end
            end
        end
    end
    
    return true
end

-- ============================================
-- FUEL
-- ============================================

-- Niveau de fuel actuel
function movement.getFuel()
    return turtle.getFuelLevel()
end

-- Fuel maximum
function movement.getMaxFuel()
    return turtle.getFuelLimit()
end

-- Refuel depuis le slot selectionne
function movement.refuel(count)
    return turtle.refuel(count)
end

-- Refuel automatique depuis tous les slots
function movement.refuelAll()
    local totalRefueled = 0
    for slot = 1, 16 do
        turtle.select(slot)
        local count = turtle.getItemCount()
        if count > 0 then
            local before = turtle.getFuelLevel()
            turtle.refuel()
            totalRefueled = totalRefueled + (turtle.getFuelLevel() - before)
        end
    end
    turtle.select(1)
    return totalRefueled
end

-- ============================================
-- UTILITAIRES
-- ============================================

-- Obtient la position actuelle
function movement.getPos()
    return movement.x, movement.y, movement.z
end

-- Obtient la direction actuelle
function movement.getFacing()
    return movement.facing
end

-- Obtient le nom de la direction
function movement.getFacingName()
    return directionNames[movement.facing + 1]
end

-- Definit la position manuellement
function movement.setPos(x, y, z)
    movement.x = x
    movement.y = y
    movement.z = z
end

-- Definit la direction manuellement
function movement.setFacing(facing)
    movement.facing = facing % 4
end

-- Distance jusqu'a une position
function movement.distanceTo(x, y, z)
    return math.abs(x - movement.x) + math.abs(y - movement.y) + math.abs(z - movement.z)
end

-- Sauvegarde la position dans un fichier
function movement.savePosition(filepath)
    filepath = filepath or "position.txt"
    local file = fs.open(filepath, "w")
    if file then
        file.writeLine(movement.x)
        file.writeLine(movement.y)
        file.writeLine(movement.z)
        file.writeLine(movement.facing)
        file.close()
        return true
    end
    return false
end

-- Charge la position depuis un fichier
function movement.loadPosition(filepath)
    filepath = filepath or "position.txt"
    if fs.exists(filepath) then
        local file = fs.open(filepath, "r")
        if file then
            movement.x = tonumber(file.readLine()) or 0
            movement.y = tonumber(file.readLine()) or 0
            movement.z = tonumber(file.readLine()) or 0
            movement.facing = tonumber(file.readLine()) or 0
            file.close()
            return true
        end
    end
    return false
end

-- Convertit une direction texte en numero
function movement.directionToNumber(dir)
    dir = string.lower(dir)
    if dir == "nord" or dir == "north" or dir == "n" then return 0
    elseif dir == "est" or dir == "east" or dir == "e" then return 1
    elseif dir == "sud" or dir == "south" or dir == "s" then return 2
    elseif dir == "ouest" or dir == "west" or dir == "o" or dir == "w" then return 3
    end
    return 0
end

return movement
