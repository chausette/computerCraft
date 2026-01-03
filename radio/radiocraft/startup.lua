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

-- Variable globale pour la liste des fichiers RCM
local rcmFiles = listRCMFiles()

-- ============================================
-- GESTIONNAIRE D'EVENEMENTS
-- ============================================

-- Variable pour le dialogue de zone
local zoneDialog = nil

local function handleButton(buttonId, touchX, touchData)
    -- Tabs
    if buttonId == "tab_jukebox" then
        ui:setTab("jukebox")
    elseif buttonId == "tab_ambiance" then
        ui:setTab("ambiance")
    elseif buttonId == "tab_composer" then
        ui:setTab("composer")
    elseif buttonId == "tab_settings" then
        ui:setTab("settings")
    
    -- Sous-onglets Jukebox
    elseif buttonId == "subtab_discs" then
        ui.jukeboxSubTab = "discs"
    elseif buttonId == "subtab_rcm" then
        ui.jukeboxSubTab = "rcm"
        rcmFiles = listRCMFiles()  -- Rafraichit la liste
    
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
    
    -- Volume master (footer)
    elseif buttonId == "vol_up" then
        speakers:setMasterVolume(speakers.masterVolume + 0.1)
    elseif buttonId == "vol_down" then
        speakers:setMasterVolume(speakers.masterVolume - 0.1)
    elseif buttonId == "master_volume" and touchX and touchData then
        local newVol = touchX / touchData.width
        speakers:setMasterVolume(newVol)
    
    -- Volume master (settings)
    elseif buttonId == "master_vol_up" then
        speakers:setMasterVolume(speakers.masterVolume + 0.1)
    elseif buttonId == "master_vol_down" then
        speakers:setMasterVolume(speakers.masterVolume - 0.1)
    elseif buttonId == "settings_master_vol" and touchX and touchData then
        local newVol = touchX / touchData.width
        speakers:setMasterVolume(newVol)
    
    -- Volume des zones
    elseif string.match(buttonId, "^zone_vol_up_") then
        local zoneName = buttonId:gsub("zone_vol_up_", "")
        local currentVol = speakers.zoneVolumes[zoneName] or 1
        speakers:setZoneVolume(zoneName, currentVol + 0.1)
    elseif string.match(buttonId, "^zone_vol_down_") then
        local zoneName = buttonId:gsub("zone_vol_down_", "")
        local currentVol = speakers.zoneVolumes[zoneName] or 1
        speakers:setZoneVolume(zoneName, currentVol - 0.1)
    elseif string.match(buttonId, "^zone_vol_") and touchX and touchData then
        local zoneName = buttonId:gsub("zone_vol_", "")
        local newVol = touchX / touchData.width
        speakers:setZoneVolume(zoneName, newVol)
    
    -- Assignment de zone pour un speaker
    elseif string.match(buttonId, "^speaker_zone_") then
        local speakerName = buttonId:gsub("speaker_zone_", "")
        local speakerList = speakers:list()
        for _, spk in ipairs(speakerList) do
            if spk.name == speakerName then
                zoneDialog = {
                    speakerName = spk.name,
                    currentZone = spk.zone
                }
                break
            end
        end
    
    -- Disques
    elseif string.match(buttonId, "^disc_") then
        local discId = buttonId:gsub("disc_", "")
        player:playDisc(discId)
        print("[RadioCraft] Lecture disque: " .. discId)
    
    -- Fichiers RCM
    elseif string.match(buttonId, "^rcm_") then
        local idx = tonumber(buttonId:gsub("rcm_", ""))
        if idx and rcmFiles[idx] then
            local rcm = rcmFiles[idx]
            local ok, err = player:playRCM(rcm.path)
            if ok then
                print("[RadioCraft] Lecture: " .. rcm.name)
            else
                print("[RadioCraft] Erreur: " .. tostring(err))
            end
        end
    
    -- Stations d'ambiance
    elseif string.match(buttonId, "^station_") then
        local stationId = buttonId:gsub("station_", "")
        ambiance:toggle(stationId)
        print("[RadioCraft] Ambiance: " .. stationId)
    
    -- Composer
    elseif buttonId == "comp_new" then
        composer:reset()
    elseif buttonId == "comp_save" then
        local ok = composer:saveToDisk(composer:getComposition().name)
        if ok then
            print("[RadioCraft] Composition sauvegardee!")
        end
    elseif buttonId == "comp_load" then
        local songs = composer:listDiskSongs()
        if #songs > 0 then
            composer:loadFromDisk(songs[1])
            print("[RadioCraft] Composition chargee: " .. songs[1])
        end
    elseif buttonId == "comp_add_track" then
        composer:addTrack("harp")
    elseif string.match(buttonId, "^track_") then
        local trackNum = tonumber(buttonId:gsub("track_", ""))
        composer.currentTrack = trackNum
    
    -- Settings
    elseif buttonId == "refresh_speakers" then
        local count = speakers:discover()
        print("[RadioCraft] " .. count .. " speaker(s) detecte(s)")
    elseif buttonId == "test_sound" then
        print("[RadioCraft] Test sonore...")
        speakers:playSound("minecraft:block.note_block.harp", 1, 1)
        sleep(0.3)
        speakers:playNote("harp", 1, 12)
        sleep(0.3)
        speakers:playNote("harp", 1, 16)
        sleep(0.3)
        speakers:playNote("harp", 1, 19)
    elseif buttonId == "save_config" then
        speakers:saveConfig(CONFIG_PATH)
        print("[RadioCraft] Configuration sauvegardee!")
    end
end

-- Dialogue pour changer la zone d'un speaker
local function handleZoneDialog()
    if not zoneDialog then return end
    
    term.clear()
    term.setCursorPos(1, 1)
    print("=== Assigner une zone ===")
    print("")
    print("Speaker: " .. zoneDialog.speakerName)
    print("Zone actuelle: " .. (zoneDialog.currentZone or "default"))
    print("")
    print("Entrez le nom de la nouvelle zone")
    print("(ex: salon, cave, cuisine...)")
    print("ou appuyez sur Entree pour annuler:")
    print("")
    write("> ")
    
    local newZone = read()
    
    if newZone and newZone ~= "" then
        speakers:setZone(zoneDialog.speakerName, newZone)
        print("Zone changee: " .. newZone)
    else
        print("Annule")
    end
    
    sleep(1)
    zoneDialog = nil
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
ui:draw(player, ambiance, composer, speakers, rcmFiles)

while running do
    -- Gere le dialogue de zone si actif
    if zoneDialog then
        handleZoneDialog()
        ui:draw(player, ambiance, composer, speakers, rcmFiles)
    end
    
    -- Attend un evenement avec timeout
    local event, p1, p2, p3 = os.pullEvent()
    
    if event == "monitor_touch" then
        -- Clic sur le moniteur
        local x, y = p2, p3
        local buttonId, touchX, touchData = ui:handleClick(x, y)
        
        if buttonId then
            handleButton(buttonId, touchX, touchData)
            ui:draw(player, ambiance, composer, speakers, rcmFiles)
        end
    
    elseif event == "key" then
        -- Touche clavier
        local key = p1
        
        if key == keys.q then
            running = false
        elseif key == keys.space then
            player:togglePause()
            ui:draw(player, ambiance, composer, speakers, rcmFiles)
        elseif key == keys.s then
            player:stop()
            ui:draw(player, ambiance, composer, speakers, rcmFiles)
        elseif key == keys.r then
            speakers:discover()
            ui:draw(player, ambiance, composer, speakers, rcmFiles)
        elseif key == keys.t then
            -- Test sonore avec T
            print("[RadioCraft] Test sonore...")
            speakers:playNote("harp", 1, 12)
        elseif key == keys.up then
            speakers:setMasterVolume(speakers.masterVolume + 0.1)
            ui:draw(player, ambiance, composer, speakers, rcmFiles)
        elseif key == keys.down then
            speakers:setMasterVolume(speakers.masterVolume - 0.1)
            ui:draw(player, ambiance, composer, speakers, rcmFiles)
        end
    
    elseif event == "disk" then
        -- Disquette inseree
        print("[RadioCraft] Disquette detectee!")
        rcmFiles = listRCMFiles()  -- Rafraichit la liste
        ui:draw(player, ambiance, composer, speakers, rcmFiles)
    
    elseif event == "disk_eject" then
        -- Disquette retiree
        print("[RadioCraft] Disquette retiree")
        rcmFiles = listRCMFiles()  -- Rafraichit la liste
        ui:draw(player, ambiance, composer, speakers, rcmFiles)
    
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
            ui:draw(player, ambiance, composer, speakers, rcmFiles)
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
