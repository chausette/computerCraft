-- RadioCraft - Main Program
-- Systeme radio complet pour ComputerCraft
-- Necessite: Advanced Peripherals, Moniteur, Speaker(s)

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG_PATH = "/radiocraft/config.dat"
local MUSIC_PATH = "/radiocraft/music"
local DISK_MUSIC_PATH = "/disk/songs"

-- ============================================
-- CHARGEMENT DES MODULES
-- ============================================

local basePath = fs.getDir(shell.getRunningProgram())
if basePath == "" then basePath = "radiocraft" end

local function loadModule(name)
    local path = "/" .. basePath .. "/lib/" .. name .. ".lua"
    if not fs.exists(path) then
        error("Module non trouve: " .. path)
    end
    return dofile(path)
end

print("RadioCraft v1.0")
print("Chargement des modules...")

local Speakers = loadModule("speakers")
local Player = loadModule("player")
local Ambiance = loadModule("ambiance")
local Composer = loadModule("composer")
local UI = loadModule("ui")

-- ============================================
-- DETECTION DES PERIPHERIQUES
-- ============================================

print("Detection des peripheriques...")

-- Trouve le moniteur
local monitor = nil
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "monitor" then
        monitor = peripheral.wrap(name)
        print("Moniteur trouve: " .. name)
        break
    end
end

if not monitor then
    print("ERREUR: Aucun moniteur trouve!")
    print("Connectez un moniteur et relancez le programme.")
    return
end

-- Configure le moniteur
monitor.setTextScale(0.5)
local mw, mh = monitor.getSize()
print("Taille moniteur: " .. mw .. "x" .. mh)

if mw < 29 or mh < 12 then
    print("ATTENTION: Moniteur trop petit!")
    print("Recommande: 3x2 minimum")
end

-- ============================================
-- INITIALISATION
-- ============================================

print("Initialisation...")

-- Initialise les speakers
local speakers = Speakers.new()
if speakers:count() == 0 then
    print("ATTENTION: Aucun speaker trouve!")
    print("Le programme fonctionnera sans son.")
end

-- Charge la config des speakers
speakers:loadConfig(CONFIG_PATH)

-- Initialise les modules
local player = Player.new(speakers)
local ambiance = Ambiance.new(speakers)
local composer = Composer.new(speakers)
local ui = UI.new(monitor)

-- Cree les dossiers si necessaire
if not fs.exists(MUSIC_PATH) then
    fs.makeDir(MUSIC_PATH)
end

-- ============================================
-- LISTE DES DISQUES
-- ============================================

local DISCS = {
    {id = "13", name = "13", author = "C418"},
    {id = "cat", name = "Cat", author = "C418"},
    {id = "blocks", name = "Blocks", author = "C418"},
    {id = "chirp", name = "Chirp", author = "C418"},
    {id = "far", name = "Far", author = "C418"},
    {id = "mall", name = "Mall", author = "C418"},
    {id = "mellohi", name = "Mellohi", author = "C418"},
    {id = "stal", name = "Stal", author = "C418"},
    {id = "strad", name = "Strad", author = "C418"},
    {id = "ward", name = "Ward", author = "C418"},
    {id = "11", name = "11", author = "C418"},
    {id = "wait", name = "Wait", author = "C418"},
    {id = "pigstep", name = "Pigstep", author = "Lena Raine"},
    {id = "otherside", name = "Otherside", author = "Lena Raine"},
    {id = "5", name = "5", author = "Samuel Aberg"},
    {id = "relic", name = "Relic", author = "Aaron Cherof"},
}

-- ============================================
-- GESTION DES FICHIERS RCM
-- ============================================

local function listRCMFiles()
    local files = {}
    
    -- Fichiers locaux
    if fs.exists(MUSIC_PATH) then
        for _, file in ipairs(fs.list(MUSIC_PATH)) do
            if string.match(file, "%.rcm$") then
                table.insert(files, {
                    name = file:gsub("%.rcm$", ""),
                    path = MUSIC_PATH .. "/" .. file,
                    source = "local"
                })
            end
        end
    end
    
    -- Fichiers sur disquette
    if fs.exists(DISK_MUSIC_PATH) then
        for _, file in ipairs(fs.list(DISK_MUSIC_PATH)) do
            if string.match(file, "%.rcm$") then
                table.insert(files, {
                    name = file:gsub("%.rcm$", ""),
                    path = DISK_MUSIC_PATH .. "/" .. file,
                    source = "disk"
                })
            end
        end
    end
    
    return files
end

-- ============================================
-- GESTIONNAIRE D'EVENEMENTS
-- ============================================

local function handleButton(buttonId)
    -- Tabs
    if buttonId == "tab_jukebox" then
        ui:setTab("jukebox")
    elseif buttonId == "tab_ambiance" then
        ui:setTab("ambiance")
    elseif buttonId == "tab_composer" then
        ui:setTab("composer")
    elseif buttonId == "tab_settings" then
        ui:setTab("settings")
    
    -- Controles de lecture
    elseif buttonId == "ctrl_play" then
        player:togglePause()
    elseif buttonId == "ctrl_stop" then
        player:stop()
    elseif buttonId == "ctrl_prev" then
        player:playPrevious()
    elseif buttonId == "ctrl_next" then
        player:playNext()
    elseif buttonId == "ctrl_shuffle" then
        player:toggleShuffle()
    elseif buttonId == "ctrl_repeat" then
        player:cycleRepeat()
    
    -- Disques
    elseif string.match(buttonId, "^disc_") then
        local discId = buttonId:gsub("disc_", "")
        player:playDisc(discId)
    
    -- Stations d'ambiance
    elseif string.match(buttonId, "^station_") then
        local stationId = buttonId:gsub("station_", "")
        ambiance:toggle(stationId)
    
    -- Composer
    elseif buttonId == "comp_new" then
        composer:reset()
    elseif buttonId == "comp_save" then
        -- Ouvre un dialogue simple
        composer:saveToDisk(composer:getComposition().name)
    elseif buttonId == "comp_load" then
        local songs = composer:listDiskSongs()
        if #songs > 0 then
            composer:loadFromDisk(songs[1])
        end
    elseif buttonId == "comp_add_track" then
        composer:addTrack("harp")
    elseif string.match(buttonId, "^track_") then
        local trackNum = tonumber(buttonId:gsub("track_", ""))
        composer.currentTrack = trackNum
    
    -- Settings
    elseif buttonId == "refresh_speakers" then
        speakers:discover()
    elseif buttonId == "test_sound" then
        speakers:playSound("minecraft:block.note_block.harp", 1, 1)
    end
end

-- ============================================
-- BOUCLE PRINCIPALE
-- ============================================

print("Demarrage de l'interface...")
print("Appuyez sur Q dans le terminal pour quitter")

local running = true
local lastUpdate = os.clock()
local tickInterval = 0.05 -- 20 ticks par seconde

-- Premier affichage
ui:draw(player, ambiance, composer, speakers)

while running do
    -- Attend un evenement avec timeout
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "monitor_touch" then
        -- Clic sur le moniteur
        local x, y = p2, p3
        local buttonId = ui:handleClick(x, y)
        
        if buttonId then
            handleButton(buttonId)
            ui:draw(player, ambiance, composer, speakers)
        end
    
    elseif event == "key" then
        -- Touche clavier
        local key = p1
        
        if key == keys.q then
            running = false
        elseif key == keys.space then
            player:togglePause()
            ui:draw(player, ambiance, composer, speakers)
        elseif key == keys.s then
            player:stop()
            ui:draw(player, ambiance, composer, speakers)
        elseif key == keys.r then
            speakers:discover()
            ui:draw(player, ambiance, composer, speakers)
        end
    
    elseif event == "disk" then
        -- Disquette inseree
        print("Disquette detectee!")
        ui:draw(player, ambiance, composer, speakers)
    
    elseif event == "disk_eject" then
        -- Disquette retiree
        print("Disquette retiree")
        ui:draw(player, ambiance, composer, speakers)
    
    elseif event == "timer" or event == "alarm" then
        -- Rien
    end
    
    -- Update periodique
    local now = os.clock()
    if now - lastUpdate >= tickInterval then
        player:update()
        ambiance:update()
        lastUpdate = now
        
        -- Rafraichit l'affichage si en lecture
        if player:isPlaying() or ambiance:getIsPlaying() then
            ui:draw(player, ambiance, composer, speakers)
        end
    end
end

-- ============================================
-- NETTOYAGE
-- ============================================

print("Arret de RadioCraft...")
player:stop()
ambiance:stop()
speakers:saveConfig(CONFIG_PATH)
monitor.clear()
print("Au revoir!")
