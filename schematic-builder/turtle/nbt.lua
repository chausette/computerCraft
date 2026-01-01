-- ============================================
-- NBT.lua - Parser NBT pour ComputerCraft
-- Supporte les fichiers .schematic (decompresses)
-- et le format JSON alternatif
-- ============================================

local nbt = {}

-- ============================================
-- UTILITAIRES
-- ============================================

-- Lit un nombre big-endian depuis une chaine
local function readByte(data, pos)
    return string.byte(data, pos), pos + 1
end

local function readShort(data, pos)
    local b1, b2 = string.byte(data, pos, pos + 1)
    local val = b1 * 256 + b2
    if val >= 32768 then val = val - 65536 end
    return val, pos + 2
end

local function readInt(data, pos)
    local b1, b2, b3, b4 = string.byte(data, pos, pos + 3)
    local val = b1 * 16777216 + b2 * 65536 + b3 * 256 + b4
    if val >= 2147483648 then val = val - 4294967296 end
    return val, pos + 4
end

local function readLong(data, pos)
    -- Lua 5.1 n'a pas de support 64-bit natif, on simplifie
    local high, pos = readInt(data, pos)
    local low, pos = readInt(data, pos)
    return low, pos  -- On ignore la partie haute pour simplifier
end

local function readFloat(data, pos)
    local b1, b2, b3, b4 = string.byte(data, pos, pos + 3)
    -- Conversion IEEE 754 simplifiee
    local sign = (b1 >= 128) and -1 or 1
    local exp = ((b1 % 128) * 2) + math.floor(b2 / 128)
    local mantissa = ((b2 % 128) * 65536) + (b3 * 256) + b4
    if exp == 0 then
        return 0, pos + 4
    end
    return sign * math.ldexp(1 + mantissa / 8388608, exp - 127), pos + 4
end

local function readDouble(data, pos)
    -- Simplifie: on lit 8 bytes et on retourne 0
    -- Pour un vrai parsing, il faudrait plus de code
    return 0, pos + 8
end

local function readString(data, pos)
    local len, pos = readShort(data, pos)
    if len <= 0 then
        return "", pos
    end
    local str = string.sub(data, pos, pos + len - 1)
    return str, pos + len
end

-- ============================================
-- PARSER NBT
-- ============================================

local tagParsers = {}

-- TAG_End (0)
tagParsers[0] = function(data, pos)
    return nil, pos
end

-- TAG_Byte (1)
tagParsers[1] = function(data, pos)
    local val, pos = readByte(data, pos)
    if val >= 128 then val = val - 256 end
    return val, pos
end

-- TAG_Short (2)
tagParsers[2] = function(data, pos)
    return readShort(data, pos)
end

-- TAG_Int (3)
tagParsers[3] = function(data, pos)
    return readInt(data, pos)
end

-- TAG_Long (4)
tagParsers[4] = function(data, pos)
    return readLong(data, pos)
end

-- TAG_Float (5)
tagParsers[5] = function(data, pos)
    return readFloat(data, pos)
end

-- TAG_Double (6)
tagParsers[6] = function(data, pos)
    return readDouble(data, pos)
end

-- TAG_Byte_Array (7)
tagParsers[7] = function(data, pos)
    local len, pos = readInt(data, pos)
    local arr = {}
    for i = 1, len do
        local val
        val, pos = readByte(data, pos)
        arr[i] = val
    end
    return arr, pos
end

-- TAG_String (8)
tagParsers[8] = function(data, pos)
    return readString(data, pos)
end

-- TAG_List (9)
tagParsers[9] = function(data, pos)
    local tagType, pos = readByte(data, pos)
    local len, pos = readInt(data, pos)
    local arr = {}
    for i = 1, len do
        local val
        val, pos = tagParsers[tagType](data, pos)
        arr[i] = val
    end
    return arr, pos
end

-- TAG_Compound (10)
tagParsers[10] = function(data, pos)
    local compound = {}
    while true do
        local tagType, newPos = readByte(data, pos)
        pos = newPos
        if tagType == 0 then
            break
        end
        local name
        name, pos = readString(data, pos)
        local value
        value, pos = tagParsers[tagType](data, pos)
        compound[name] = value
    end
    return compound, pos
end

-- TAG_Int_Array (11)
tagParsers[11] = function(data, pos)
    local len, pos = readInt(data, pos)
    local arr = {}
    for i = 1, len do
        local val
        val, pos = readInt(data, pos)
        arr[i] = val
    end
    return arr, pos
end

-- TAG_Long_Array (12)
tagParsers[12] = function(data, pos)
    local len, pos = readInt(data, pos)
    local arr = {}
    for i = 1, len do
        local val
        val, pos = readLong(data, pos)
        arr[i] = val
    end
    return arr, pos
end

-- Parse un fichier NBT complet
function nbt.parseNBT(data)
    local pos = 1
    local tagType, newPos = readByte(data, pos)
    pos = newPos
    
    if tagType ~= 10 then
        return nil, "Le fichier doit commencer par un TAG_Compound"
    end
    
    local name
    name, pos = readString(data, pos)
    
    local value
    value, pos = tagParsers[10](data, pos)
    
    return {name = name, value = value}, nil
end

-- ============================================
-- PARSER SCHEMATIC
-- ============================================

-- Mapping des block IDs classiques (Minecraft 1.12 et avant)
local classicBlockNames = {
    [0] = "minecraft:air",
    [1] = "minecraft:stone",
    [2] = "minecraft:grass_block",
    [3] = "minecraft:dirt",
    [4] = "minecraft:cobblestone",
    [5] = "minecraft:oak_planks",
    [6] = "minecraft:oak_sapling",
    [7] = "minecraft:bedrock",
    [8] = "minecraft:water",
    [9] = "minecraft:water",
    [10] = "minecraft:lava",
    [11] = "minecraft:lava",
    [12] = "minecraft:sand",
    [13] = "minecraft:gravel",
    [14] = "minecraft:gold_ore",
    [15] = "minecraft:iron_ore",
    [16] = "minecraft:coal_ore",
    [17] = "minecraft:oak_log",
    [18] = "minecraft:oak_leaves",
    [19] = "minecraft:sponge",
    [20] = "minecraft:glass",
    [21] = "minecraft:lapis_ore",
    [22] = "minecraft:lapis_block",
    [23] = "minecraft:dispenser",
    [24] = "minecraft:sandstone",
    [25] = "minecraft:note_block",
    [35] = "minecraft:white_wool",
    [41] = "minecraft:gold_block",
    [42] = "minecraft:iron_block",
    [43] = "minecraft:smooth_stone_slab",
    [44] = "minecraft:stone_slab",
    [45] = "minecraft:bricks",
    [46] = "minecraft:tnt",
    [47] = "minecraft:bookshelf",
    [48] = "minecraft:mossy_cobblestone",
    [49] = "minecraft:obsidian",
    [50] = "minecraft:torch",
    [53] = "minecraft:oak_stairs",
    [54] = "minecraft:chest",
    [56] = "minecraft:diamond_ore",
    [57] = "minecraft:diamond_block",
    [58] = "minecraft:crafting_table",
    [61] = "minecraft:furnace",
    [62] = "minecraft:furnace",
    [64] = "minecraft:oak_door",
    [65] = "minecraft:ladder",
    [66] = "minecraft:rail",
    [67] = "minecraft:cobblestone_stairs",
    [73] = "minecraft:redstone_ore",
    [79] = "minecraft:ice",
    [80] = "minecraft:snow_block",
    [81] = "minecraft:cactus",
    [82] = "minecraft:clay",
    [85] = "minecraft:oak_fence",
    [86] = "minecraft:pumpkin",
    [87] = "minecraft:netherrack",
    [88] = "minecraft:soul_sand",
    [89] = "minecraft:glowstone",
    [98] = "minecraft:stone_bricks",
    [112] = "minecraft:nether_bricks",
    [121] = "minecraft:end_stone",
    [133] = "minecraft:emerald_block",
    [152] = "minecraft:redstone_block",
    [155] = "minecraft:quartz_block",
    [159] = "minecraft:white_terracotta",
    [172] = "minecraft:terracotta",
}

-- Obtient le nom du bloc a partir de l'ID
function nbt.getBlockName(blockId)
    return classicBlockNames[blockId] or ("minecraft:unknown_" .. blockId)
end

-- Parse un fichier .schematic
function nbt.parseSchematic(filepath)
    local file = fs.open(filepath, "rb")
    if not file then
        return nil, "Impossible d'ouvrir le fichier: " .. filepath
    end
    
    -- Lire tout le fichier
    local data = ""
    while true do
        local byte = file.read()
        if byte == nil then break end
        data = data .. string.char(byte)
    end
    file.close()
    
    -- Verifier si c'est compresse (GZIP magic number: 1f 8b)
    if #data >= 2 then
        local b1, b2 = string.byte(data, 1, 2)
        if b1 == 0x1f and b2 == 0x8b then
            return nil, "Le fichier est compresse (GZIP). Decompresse-le d'abord avec 7-zip ou gunzip."
        end
    end
    
    -- Parser le NBT
    local result, err = nbt.parseNBT(data)
    if not result then
        return nil, "Erreur de parsing NBT: " .. (err or "inconnue")
    end
    
    local schematic = result.value
    
    -- Extraire les donnees du schematic
    local parsed = {
        width = schematic.Width or 0,
        height = schematic.Height or 0,
        length = schematic.Length or 0,
        blocks = schematic.Blocks or {},
        data = schematic.Data or {},
        palette = {}
    }
    
    -- Construire la palette des blocs utilises
    local usedBlocks = {}
    for _, blockId in ipairs(parsed.blocks) do
        if blockId ~= 0 then
            usedBlocks[blockId] = true
        end
    end
    
    for blockId, _ in pairs(usedBlocks) do
        parsed.palette[blockId] = nbt.getBlockName(blockId)
    end
    
    return parsed, nil
end

-- ============================================
-- PARSER JSON ALTERNATIF
-- ============================================

function nbt.parseJSON(filepath)
    local file = fs.open(filepath, "r")
    if not file then
        return nil, "Impossible d'ouvrir le fichier: " .. filepath
    end
    
    local content = file.readAll()
    file.close()
    
    local data = textutils.unserializeJSON(content)
    if not data then
        return nil, "Erreur de parsing JSON"
    end
    
    -- Convertir le format JSON en format interne
    local parsed = {
        width = data.width or 0,
        height = data.height or 0,
        length = data.length or 0,
        blocks = {},
        data = {},
        palette = data.palette or {}
    }
    
    -- Convertir le tableau 3D en tableau 1D
    if data.blocks then
        local index = 1
        for y = 1, parsed.height do
            for z = 1, parsed.length do
                for x = 1, parsed.width do
                    local layer = data.blocks[y]
                    local row = layer and layer[z]
                    local block = row and row[x]
                    parsed.blocks[index] = block or 0
                    parsed.data[index] = 0
                    index = index + 1
                end
            end
        end
    end
    
    return parsed, nil
end

-- ============================================
-- FONCTION PRINCIPALE
-- ============================================

-- Detecte le format et parse le fichier
function nbt.loadSchematic(filepath)
    if not fs.exists(filepath) then
        return nil, "Fichier non trouve: " .. filepath
    end
    
    -- Detecter l'extension
    local ext = string.lower(filepath:match("%.([^%.]+)$") or "")
    
    if ext == "json" then
        return nbt.parseJSON(filepath)
    else
        return nbt.parseSchematic(filepath)
    end
end

-- Obtient le bloc a une position donnee
function nbt.getBlock(schematic, x, y, z)
    if x < 0 or x >= schematic.width then return 0 end
    if y < 0 or y >= schematic.height then return 0 end
    if z < 0 or z >= schematic.length then return 0 end
    
    local index = (y * schematic.length + z) * schematic.width + x + 1
    return schematic.blocks[index] or 0
end

-- Obtient les metadata a une position donnee
function nbt.getData(schematic, x, y, z)
    if x < 0 or x >= schematic.width then return 0 end
    if y < 0 or y >= schematic.height then return 0 end
    if z < 0 or z >= schematic.length then return 0 end
    
    local index = (y * schematic.length + z) * schematic.width + x + 1
    return schematic.data[index] or 0
end

-- Compte les blocs par type
function nbt.countBlocks(schematic)
    local counts = {}
    for _, blockId in ipairs(schematic.blocks) do
        if blockId ~= 0 then
            counts[blockId] = (counts[blockId] or 0) + 1
        end
    end
    return counts
end

-- Genere une liste de materiaux necessaires
function nbt.getMaterialList(schematic)
    local counts = nbt.countBlocks(schematic)
    local list = {}
    for blockId, count in pairs(counts) do
        table.insert(list, {
            id = blockId,
            name = schematic.palette[blockId] or nbt.getBlockName(blockId),
            count = count
        })
    end
    table.sort(list, function(a, b) return a.count > b.count end)
    return list
end

return nbt
