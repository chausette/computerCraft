-- ============================================
-- MineColonies Dashboard Pro v4.0
-- Pour CC:Tweaked + Advanced Peripherals
-- Moniteur 3x2 Advanced Monitor (tactile)
-- ============================================

-- ============================================
-- CONFIGURATION
-- ============================================
local CONFIG = {
    refreshRate = 3,
    textScale = 0.5,
    alertSound = "minecraft:block.bell.use",
    alertSoundInterval = 2,  -- Secondes entre chaque son d'alerte
    exportPath = "/disk/materials.json",
    historyFile = "colony_history.dat",
    configFile = "colony_config.dat",
    maxHistoryPoints = 100,
    historyInterval = 60,
    itemsPerPage = 8,
    menuWidth = 12,
    maxCitizens = 100,  -- Max citoyens pour barre progression
    debugMode = false,  -- Active l'export des donnees brutes pour debug
}

-- ============================================
-- THEMES DE COULEURS
-- ============================================
local themes = {
    dark = {
        name = "Sombre",
        bg = colors.black,
        bgAlt = colors.gray,
        header = colors.blue,
        headerText = colors.white,
        menu = colors.gray,
        menuActive = colors.blue,
        menuText = colors.white,
        alert = colors.red,
        alertText = colors.white,
        card = colors.gray,
        cardTitle = colors.lightBlue,
        text = colors.white,
        textDim = colors.lightGray,
        textMuted = colors.gray,
        good = colors.lime,
        warning = colors.orange,
        danger = colors.red,
        button = colors.blue,
        buttonText = colors.white,
        popup = colors.gray,
        popupBorder = colors.lightGray,
        progress = colors.lime,
        progressBg = colors.gray,
        graphLine = colors.cyan,
    },
    light = {
        name = "Clair",
        bg = colors.white,
        bgAlt = colors.lightGray,
        header = colors.blue,
        headerText = colors.white,
        menu = colors.lightGray,
        menuActive = colors.blue,
        menuText = colors.black,
        alert = colors.red,
        alertText = colors.white,
        card = colors.lightGray,
        cardTitle = colors.blue,
        text = colors.black,
        textDim = colors.gray,
        textMuted = colors.lightGray,
        good = colors.green,
        warning = colors.orange,
        danger = colors.red,
        button = colors.blue,
        buttonText = colors.white,
        popup = colors.lightGray,
        popupBorder = colors.gray,
        progress = colors.green,
        progressBg = colors.white,
        graphLine = colors.blue,
    },
    minecolonies = {
        name = "MineColonies",
        bg = colors.black,
        bgAlt = colors.brown,
        header = colors.brown,
        headerText = colors.white,
        menu = colors.brown,
        menuActive = colors.orange,
        menuText = colors.white,
        alert = colors.red,
        alertText = colors.white,
        card = colors.brown,
        cardTitle = colors.yellow,
        text = colors.white,
        textDim = colors.lightGray,
        textMuted = colors.gray,
        good = colors.lime,
        warning = colors.yellow,
        danger = colors.red,
        button = colors.orange,
        buttonText = colors.white,
        popup = colors.brown,
        popupBorder = colors.orange,
        progress = colors.lime,
        progressBg = colors.gray,
        graphLine = colors.yellow,
    },
    ocean = {
        name = "Ocean",
        bg = colors.black,
        bgAlt = colors.blue,
        header = colors.cyan,
        headerText = colors.white,
        menu = colors.blue,
        menuActive = colors.cyan,
        menuText = colors.white,
        alert = colors.red,
        alertText = colors.white,
        card = colors.blue,
        cardTitle = colors.cyan,
        text = colors.white,
        textDim = colors.lightBlue,
        textMuted = colors.blue,
        good = colors.lime,
        warning = colors.yellow,
        danger = colors.red,
        button = colors.cyan,
        buttonText = colors.black,
        popup = colors.blue,
        popupBorder = colors.cyan,
        progress = colors.cyan,
        progressBg = colors.gray,
        graphLine = colors.lightBlue,
    },
    forest = {
        name = "Foret",
        bg = colors.black,
        bgAlt = colors.green,
        header = colors.green,
        headerText = colors.white,
        menu = colors.green,
        menuActive = colors.lime,
        menuText = colors.white,
        alert = colors.red,
        alertText = colors.white,
        card = colors.green,
        cardTitle = colors.lime,
        text = colors.white,
        textDim = colors.lightGray,
        textMuted = colors.gray,
        good = colors.lime,
        warning = colors.yellow,
        danger = colors.red,
        button = colors.lime,
        buttonText = colors.black,
        popup = colors.green,
        popupBorder = colors.lime,
        progress = colors.lime,
        progressBg = colors.gray,
        graphLine = colors.lime,
    },
    nether = {
        name = "Nether",
        bg = colors.black,
        bgAlt = colors.red,
        header = colors.red,
        headerText = colors.white,
        menu = colors.red,
        menuActive = colors.orange,
        menuText = colors.white,
        alert = colors.yellow,
        alertText = colors.black,
        card = colors.red,
        cardTitle = colors.orange,
        text = colors.white,
        textDim = colors.lightGray,
        textMuted = colors.gray,
        good = colors.lime,
        warning = colors.yellow,
        danger = colors.magenta,
        button = colors.orange,
        buttonText = colors.black,
        popup = colors.red,
        popupBorder = colors.orange,
        progress = colors.orange,
        progressBg = colors.gray,
        graphLine = colors.orange,
    },
}

-- Theme actif
local currentTheme = "dark"
local theme = themes.dark

-- ============================================
-- VARIABLES GLOBALES
-- ============================================
local mon = nil
local colony = nil
local speaker = nil
local disk = nil

local screenW, screenH = 0, 0
local contentX, contentW = 0, 0
local currentPage = "home"
local pageNumbers = {}
local showPopup = false
local popupData = nil
local selectedWorkOrder = nil

local lastAttackState = false
local alertBlink = false
local lastHistorySave = 0
local testAlertUntil = 0  -- Pour le test d'alerte temporaire
local lastAlertSound = 0  -- Pour jouer le son en boucle

-- Cache des donnees
local data = {
    name = "Colonie",
    happiness = 0,
    citizens = {},
    buildings = {},
    requests = {},
    workOrders = {},
    visitors = {},
    research = {},
    isActive = false,
    underAttack = false,
    location = {x=0, y=0, z=0},
}

-- Historique
local history = {
    happiness = {},
    citizens = {},
    requests = {},
    attacks = {},
    timestamps = {},
}

-- Pages disponibles
local pages = {
    {id = "home", name = "Accueil"},
    {id = "citizens", name = "Citoyens"},
    {id = "requests", name = "Requetes"},
    {id = "construction", name = "Chantiers"},
    {id = "buildings", name = "Batiments"},
    {id = "stats", name = "Statistiques"},
    {id = "settings", name = "Configuration"},
}

-- Traduction des metiers
local jobTranslations = {
    -- Format com.minecolonies.job.xxx
    ["com.minecolonies.job.deliveryman"] = "Livreur",
    ["com.minecolonies.job.miner"] = "Mineur",
    ["com.minecolonies.job.builder"] = "Batisseur",
    ["com.minecolonies.job.farmer"] = "Fermier",
    ["com.minecolonies.job.lumberjack"] = "Bucheron",
    ["com.minecolonies.job.fisherman"] = "Pecheur",
    ["com.minecolonies.job.baker"] = "Boulanger",
    ["com.minecolonies.job.cook"] = "Cuisinier",
    ["com.minecolonies.job.smelter"] = "Fondeur",
    ["com.minecolonies.job.stonemason"] = "Tailleur",
    ["com.minecolonies.job.crusher"] = "Broyeur",
    ["com.minecolonies.job.sifter"] = "Tamiseur",
    ["com.minecolonies.job.composter"] = "Composteur",
    ["com.minecolonies.job.florist"] = "Fleuriste",
    ["com.minecolonies.job.enchanter"] = "Enchanteur",
    ["com.minecolonies.job.researcher"] = "Chercheur",
    ["com.minecolonies.job.healer"] = "Soigneur",
    ["com.minecolonies.job.pupil"] = "Eleve",
    ["com.minecolonies.job.teacher"] = "Professeur",
    ["com.minecolonies.job.knight"] = "Chevalier",
    ["com.minecolonies.job.archer"] = "Archer",
    ["com.minecolonies.job.ranger"] = "Ranger",
    ["com.minecolonies.job.druid"] = "Druide",
    ["com.minecolonies.job.undertaker"] = "Croque-mort",
    ["com.minecolonies.job.planter"] = "Planteur",
    ["com.minecolonies.job.beekeeper"] = "Apiculteur",
    ["com.minecolonies.job.cowboy"] = "Eleveur",
    ["com.minecolonies.job.shepherd"] = "Berger",
    ["com.minecolonies.job.pigherder"] = "Porcher",
    ["com.minecolonies.job.chickenherder"] = "Aviculteur",
    ["com.minecolonies.job.rabbitherder"] = "Cuniculteur",
    ["com.minecolonies.job.sawmill"] = "Scieur",
    ["com.minecolonies.job.blacksmith"] = "Forgeron",
    ["com.minecolonies.job.stonesmeltery"] = "Fondeur Pierre",
    ["com.minecolonies.job.fletcher"] = "Empennage",
    ["com.minecolonies.job.dyer"] = "Teinturier",
    ["com.minecolonies.job.mechanic"] = "Mecanicien",
    ["com.minecolonies.job.concretemixer"] = "Betonniere",
    ["com.minecolonies.job.glassblower"] = "Verrier",
    ["com.minecolonies.job.alchemist"] = "Alchimiste",
    ["com.minecolonies.job.netherworker"] = "Nether",
    -- Noms simples (en minuscule)
    ["deliveryman"] = "Livreur",
    ["miner"] = "Mineur",
    ["builder"] = "Batisseur",
    ["farmer"] = "Fermier",
    ["lumberjack"] = "Bucheron",
    ["fisherman"] = "Pecheur",
    ["baker"] = "Boulanger",
    ["cook"] = "Cuisinier",
    ["smelter"] = "Fondeur",
    ["stonemason"] = "Tailleur",
    ["crusher"] = "Broyeur",
    ["sifter"] = "Tamiseur",
    ["composter"] = "Composteur",
    ["florist"] = "Fleuriste",
    ["enchanter"] = "Enchanteur",
    ["researcher"] = "Chercheur",
    ["healer"] = "Soigneur",
    ["pupil"] = "Eleve",
    ["teacher"] = "Professeur",
    ["knight"] = "Chevalier",
    ["archer"] = "Archer",
    ["ranger"] = "Ranger",
    ["druid"] = "Druide",
    ["undertaker"] = "Croque-mort",
    ["planter"] = "Planteur",
    ["beekeeper"] = "Apiculteur",
    ["cowboy"] = "Eleveur",
    ["shepherd"] = "Berger",
    ["swineherd"] = "Porcher",
    ["pigherder"] = "Porcher",
    ["chickenherder"] = "Aviculteur",
    ["chickenfarmer"] = "Aviculteur",
    ["rabbitherder"] = "Cuniculteur",
    ["sawmill"] = "Scieur",
    ["blacksmith"] = "Forgeron",
    ["stonesmeltery"] = "Fondeur Pierre",
    ["fletcher"] = "Empennage",
    ["dyer"] = "Teinturier",
    ["mechanic"] = "Mecanicien",
    ["concretemixer"] = "Betonniere",
    ["glassblower"] = "Verrier",
    ["alchemist"] = "Alchimiste",
    ["netherworker"] = "Nether",
    ["student"] = "Etudiant",
    ["guard"] = "Garde",
    ["forester"] = "Forestier",
    ["courier"] = "Coursier",
    ["waiter"] = "Serveur",
    ["assistant"] = "Assistant",
    ["tavern"] = "Tavernier",
    ["cowhand"] = "Vacher",
    -- Noms de batiments comme metiers
    ["townhall"] = "Maire",
    ["warehouse"] = "Magasinier",
    ["residence"] = "Resident",
    ["guardtower"] = "Garde",
    ["barracks"] = "Soldat",
    ["hospital"] = "Soigneur",
    ["library"] = "Chercheur",
    ["university"] = "Chercheur",
    ["school"] = "Professeur",
    ["bakery"] = "Boulanger",
    ["restaurant"] = "Cuisinier",
    ["mine"] = "Mineur",
    ["farm"] = "Fermier",
    ["plantation"] = "Planteur",
    ["sawmill"] = "Scieur",
    ["smeltery"] = "Fondeur",
    ["apiary"] = "Apiculteur",
    ["graveyard"] = "Croque-mort",
    ["combatacademy"] = "Chevalier",
    ["archery"] = "Archer",
}

-- Traduction des batiments
local buildingTranslations = {
    ["minecolonies:townhall"] = "Hotel de Ville",
    ["minecolonies:warehouse"] = "Entrepot",
    ["minecolonies:residence"] = "Residence",
    ["minecolonies:builder"] = "Cabane Batisseur",
    ["minecolonies:miner"] = "Mine",
    ["minecolonies:lumberjack"] = "Cabane Bucheron",
    ["minecolonies:farmer"] = "Ferme",
    ["minecolonies:fisherman"] = "Cabane Pecheur",
    ["minecolonies:bakery"] = "Boulangerie",
    ["minecolonies:cook"] = "Restaurant",
    ["minecolonies:smeltery"] = "Fonderie",
    ["minecolonies:stonemason"] = "Tailleur Pierre",
    ["minecolonies:crusher"] = "Broyeur",
    ["minecolonies:sifter"] = "Tamiseur",
    ["minecolonies:composter"] = "Composteur",
    ["minecolonies:florist"] = "Fleuriste",
    ["minecolonies:enchanter"] = "Enchanteur",
    ["minecolonies:library"] = "Bibliotheque",
    ["minecolonies:university"] = "Universite",
    ["minecolonies:hospital"] = "Hopital",
    ["minecolonies:school"] = "Ecole",
    ["minecolonies:barracks"] = "Caserne",
    ["minecolonies:guardtower"] = "Tour de Garde",
    ["minecolonies:archery"] = "Champ de Tir",
    ["minecolonies:combatacademy"] = "Academie Combat",
    ["minecolonies:graveyard"] = "Cimetiere",
    ["minecolonies:plantation"] = "Plantation",
    ["minecolonies:apiary"] = "Rucher",
    ["minecolonies:cowboy"] = "Etable Vaches",
    ["minecolonies:shepherd"] = "Bergerie",
    ["minecolonies:pigherder"] = "Porcherie",
    ["minecolonies:chickenherder"] = "Poulailler",
    ["minecolonies:rabbitherder"] = "Clapier",
    ["minecolonies:sawmill"] = "Scierie",
    ["minecolonies:blacksmith"] = "Forge",
    ["minecolonies:stonesmeltery"] = "Fonderie Pierre",
    ["minecolonies:fletcher"] = "Empennage",
    ["minecolonies:dyerh"] = "Teinturerie",
    ["minecolonies:mechanic"] = "Atelier",
    ["minecolonies:concretemixer"] = "Betonniere",
    ["minecolonies:glassblower"] = "Verrerie",
    ["minecolonies:alchemist"] = "Alchimiste",
    ["minecolonies:netherworker"] = "Portail Nether",
    ["minecolonies:tavern"] = "Taverne",
    ["minecolonies:mysticalsite"] = "Site Mystique",
    ["minecolonies:deliveryman"] = "Tour Livraison",
}

-- ============================================
-- SAUVEGARDE / CHARGEMENT
-- ============================================
local function saveHistory()
    local file = fs.open(CONFIG.historyFile, "w")
    if file then
        file.write(textutils.serialize(history))
        file.close()
    end
end

local function loadHistory()
    if fs.exists(CONFIG.historyFile) then
        local file = fs.open(CONFIG.historyFile, "r")
        if file then
            local content = file.readAll()
            file.close()
            local loaded = textutils.unserialize(content)
            if loaded then
                history = loaded
            end
        end
    end
end

local function saveConfig()
    local cfg = {
        theme = currentTheme,
        refreshRate = CONFIG.refreshRate,
        textScale = CONFIG.textScale,
        historyInterval = CONFIG.historyInterval,
        itemsPerPage = CONFIG.itemsPerPage,
        alertSoundInterval = CONFIG.alertSoundInterval,
    }
    local file = fs.open(CONFIG.configFile, "w")
    if file then
        file.write(textutils.serialize(cfg))
        file.close()
    end
end

local function loadConfig()
    if fs.exists(CONFIG.configFile) then
        local file = fs.open(CONFIG.configFile, "r")
        if file then
            local content = file.readAll()
            file.close()
            local cfg = textutils.unserialize(content)
            if cfg then
                if cfg.theme and themes[cfg.theme] then
                    currentTheme = cfg.theme
                    theme = themes[currentTheme]
                end
                if cfg.refreshRate then CONFIG.refreshRate = cfg.refreshRate end
                if cfg.textScale then CONFIG.textScale = cfg.textScale end
                if cfg.historyInterval then CONFIG.historyInterval = cfg.historyInterval end
                if cfg.itemsPerPage then CONFIG.itemsPerPage = cfg.itemsPerPage end
                if cfg.alertSoundInterval then CONFIG.alertSoundInterval = cfg.alertSoundInterval end
            end
        end
    end
end

-- ============================================
-- INITIALISATION PERIPHERIQUES
-- ============================================
local function initPeripherals()
    print("=== MineColonies Dashboard Pro v4 ===")
    print("")
    
    loadConfig()
    loadHistory()
    
    print("[1/4] Recherche moniteur...")
    mon = peripheral.find("monitor")
    if not mon then
        error("Moniteur non trouve!")
    end
    mon.setTextScale(CONFIG.textScale)
    screenW, screenH = mon.getSize()
    contentX = CONFIG.menuWidth + 1
    contentW = screenW - CONFIG.menuWidth
    print("  -> OK: " .. screenW .. "x" .. screenH)
    
    print("[2/4] Recherche Colony Integrator...")
    colony = peripheral.find("colony_integrator") or peripheral.find("colonyIntegrator")
    if not colony then
        error("Colony Integrator non trouve!")
    end
    print("  -> OK")
    
    print("[3/4] Recherche Speaker...")
    speaker = peripheral.find("speaker")
    if speaker then
        print("  -> OK")
    else
        print("  -> Non trouve")
    end
    
    print("[4/4] Recherche Disk Drive...")
    disk = peripheral.find("drive")
    if disk and disk.isDiskPresent() then
        print("  -> OK (disquette presente)")
    elseif disk then
        print("  -> OK (pas de disquette)")
    else
        print("  -> Non trouve")
    end
    
    print("")
    print("Theme: " .. theme.name)
    print("Dashboard demarre! Appuyez sur Q pour quitter.")
    return true
end

-- ============================================
-- RECUPERATION DONNEES
-- ============================================
local function refreshData()
    pcall(function() data.name = colony.getColonyName() or "Colonie" end)
    pcall(function() data.happiness = colony.getHappiness() or 0 end)
    pcall(function() data.isActive = colony.isActive() or false end)
    
    -- Essayer plusieurs methodes pour detecter l'attaque
    local attackDetected = false
    pcall(function()
        -- Methode 1: isUnderAttack
        if colony.isUnderAttack then
            attackDetected = colony.isUnderAttack()
        end
    end)
    if not attackDetected then
        pcall(function()
            -- Methode 2: isUnderRaid (certaines versions)
            if colony.isUnderRaid then
                attackDetected = colony.isUnderRaid()
            end
        end)
    end
    if not attackDetected then
        pcall(function()
            -- Methode 3: verifier les citoyens en combat
            local citizens = colony.getCitizens() or {}
            for _, c in ipairs(citizens) do
                if c.isAsleep == false and c.job and 
                   (c.job:find("knight") or c.job:find("archer") or c.job:find("ranger") or c.job:find("druid")) then
                    -- Verifier si garde en combat (approximatif)
                    if c.state and (c.state:find("FIGHT") or c.state:find("ATTACK") or c.state:find("GUARD")) then
                        attackDetected = true
                        break
                    end
                end
            end
        end)
    end
    data.underAttack = attackDetected
    
    pcall(function() data.citizens = colony.getCitizens() or {} end)
    pcall(function() data.buildings = colony.getBuildings() or {} end)
    pcall(function() data.requests = colony.getRequests() or {} end)
    pcall(function() data.workOrders = colony.getWorkOrders() or {} end)
    pcall(function() data.visitors = colony.getVisitors() or {} end)
    pcall(function() data.research = colony.getResearch() or {} end)
    
    -- DEBUG: Sauvegarder la structure des donnees pour analyse
    if CONFIG.debugMode then
        pcall(function()
            local debugFile = fs.open("/disk/debug_data.txt", "w")
            if debugFile then
                debugFile.writeLine("=== DEBUG COLONY DATA ===")
                debugFile.writeLine("Date: " .. os.date("%Y-%m-%d %H:%M:%S"))
                debugFile.writeLine("")
                
                -- Dump premier citoyen
                if data.citizens and data.citizens[1] then
                    debugFile.writeLine("=== PREMIER CITOYEN ===")
                    local c = data.citizens[1]
                    for k, v in pairs(c) do
                        local valStr = tostring(v)
                        if type(v) == "table" then
                            valStr = "TABLE: {"
                            for k2, v2 in pairs(v) do
                                valStr = valStr .. tostring(k2) .. "=" .. tostring(v2) .. ", "
                            end
                            valStr = valStr .. "}"
                        end
                        debugFile.writeLine("  " .. tostring(k) .. " = " .. valStr)
                    end
                end
                
                debugFile.writeLine("")
                
                -- Dump premier workOrder
                if data.workOrders and data.workOrders[1] then
                    debugFile.writeLine("=== PREMIER WORKORDER ===")
                    local wo = data.workOrders[1]
                    for k, v in pairs(wo) do
                        local valStr = tostring(v)
                        if type(v) == "table" then
                            valStr = "TABLE: {"
                            for k2, v2 in pairs(v) do
                                valStr = valStr .. tostring(k2) .. "=" .. tostring(v2) .. ", "
                            end
                            valStr = valStr .. "}"
                        end
                        debugFile.writeLine("  " .. tostring(k) .. " = " .. valStr)
                    end
                end
                
                debugFile.close()
            end
        end)
    end
    
    -- Alerte sonore si nouvelle attaque
    if data.underAttack and not lastAttackState and speaker then
        -- Jouer plusieurs fois pour attirer l'attention
        speaker.playSound(CONFIG.alertSound, 1, 1)
        os.sleep(0.3)
        speaker.playSound(CONFIG.alertSound, 1, 1.5)
        os.sleep(0.3)
        speaker.playSound(CONFIG.alertSound, 1, 2)
    end
    lastAttackState = data.underAttack
    
    local now = os.epoch("utc") / 1000
    if now - lastHistorySave >= CONFIG.historyInterval then
        lastHistorySave = now
        
        table.insert(history.happiness, data.happiness or 0)
        table.insert(history.citizens, #data.citizens)
        table.insert(history.requests, #data.requests)
        table.insert(history.attacks, data.underAttack and 1 or 0)
        table.insert(history.timestamps, now)
        
        while #history.happiness > CONFIG.maxHistoryPoints do
            table.remove(history.happiness, 1)
            table.remove(history.citizens, 1)
            table.remove(history.requests, 1)
            table.remove(history.attacks, 1)
            table.remove(history.timestamps, 1)
        end
        
        saveHistory()
    end
end

-- ============================================
-- FONCTIONS UTILITAIRES
-- ============================================
local function truncate(s, maxLen)
    s = tostring(s or "")
    if #s > maxLen then
        return string.sub(s, 1, maxLen - 2) .. ".."
    end
    return s
end

-- Extraire une string d'une valeur qui peut etre string ou table
local function extractString(value)
    if value == nil then
        return nil
    end
    if type(value) == "string" then
        return value
    end
    if type(value) == "table" then
        -- Essayer differents champs communs
        return value.displayName or value.name or value.type or value.id or nil
    end
    return tostring(value)
end

local function getJobName(citizen)
    -- Fonction pour traduire un nom de job
    local function translateJob(rawName)
        if not rawName then return nil end
        local name = tostring(rawName)
        
        -- Nettoyer le nom
        name = name:gsub("com%.minecolonies%.job%.", "")
        name = name:gsub("com%.minecolonies%.building%.", "")
        name = name:gsub("com%.minecolonies%.", "")
        name = name:gsub("minecolonies:", "")
        name = name:lower()
        
        -- Chercher dans les traductions
        if jobTranslations[name] then
            return jobTranslations[name]
        end
        
        -- Capitaliser et retourner
        local result = name:gsub("^%l", string.upper)
        result = result:gsub("_", " ")
        return result
    end
    
    -- 1. Chercher dans citizen.work (structure principale pour MineColonies)
    if citizen.work and type(citizen.work) == "table" then
        -- Essayer work.job d'abord (ex: "com.minecolonies.job.builder")
        if citizen.work.job then
            local result = translateJob(citizen.work.job)
            if result then return result end
        end
        -- Essayer work.type (ex: "builder")
        if citizen.work.type then
            local result = translateJob(citizen.work.type)
            if result then return result end
        end
        -- Essayer work.name
        if citizen.work.name then
            local result = translateJob(citizen.work.name)
            if result then return result end
        end
    end
    
    -- 2. Essayer citizen.job directement (ancien format)
    if citizen.job then
        if type(citizen.job) == "string" then
            local result = translateJob(citizen.job)
            if result then return result end
        elseif type(citizen.job) == "table" then
            local result = translateJob(citizen.job.job or citizen.job.type or citizen.job.name)
            if result then return result end
        end
    end
    
    -- 3. Verifier s'il a un lieu de travail mais pas de job defini
    if citizen.work and not citizen.work.job and not citizen.work.type then
        return "Apprenti"
    end
    
    -- 4. Verifier s'il est enfant
    if citizen.isChild == "child" then
        return "Enfant"
    end
    
    return "Chomeur"
end

-- Extraire le nom du builder d'un workOrder
local function getBuilderName(workOrder)
    if not workOrder then return "Non assigne" end
    
    -- Le champ builder contient la POSITION du batiment du builder
    -- On doit trouver quel citoyen a son work.location a cette position
    local builderPos = workOrder.builder
    
    if builderPos and type(builderPos) == "table" and builderPos.x then
        -- Chercher le citoyen dont le work.location correspond
        for _, citizen in ipairs(data.citizens) do
            if citizen.work and type(citizen.work) == "table" then
                local workLoc = citizen.work.location
                if workLoc and type(workLoc) == "table" then
                    -- Comparer les positions
                    if workLoc.x == builderPos.x and 
                       workLoc.y == builderPos.y and 
                       workLoc.z == builderPos.z then
                        return citizen.name or "Builder"
                    end
                end
            end
        end
        
        -- Position trouvee mais pas de citoyen correspondant
        -- Peut-etre que le builder n'est pas encore charge
        return "Builder @ " .. builderPos.x .. "," .. builderPos.z
    end
    
    -- Si builder n'est pas une position, essayer autres formats
    if workOrder.builder then
        local builder = workOrder.builder
        if type(builder) == "string" and builder ~= "" then
            return builder
        end
        if type(builder) == "table" then
            if builder.name then return tostring(builder.name) end
            if builder.displayName then return tostring(builder.displayName) end
        end
    end
    
    -- Verifier isClaimed
    if workOrder.isClaimed then
        return "Builder assigne"
    end
    
    return "Non assigne"
end

local function cleanBuildingName(name)
    name = tostring(name or "")
    
    -- Verifier traduction
    local lowerName = name:lower()
    for key, val in pairs(buildingTranslations) do
        if lowerName:find(key:lower():gsub("minecolonies:", "")) then
            return val
        end
    end
    
    -- Nettoyage basique
    name = name:gsub("minecolonies:", "")
    name = name:gsub("minecraft:", "")
    name = name:gsub("blockhut", "")
    name = name:gsub("^%l", string.upper)
    name = name:gsub("_", " ")
    
    return name
end

local function cleanItemName(name)
    name = tostring(name or "")
    name = name:gsub("minecraft:", "")
    name = name:gsub("minecolonies:", "")
    name = name:gsub("_", " ")
    name = name:gsub("^%l", string.upper)
    return name
end

local function formatTime(seconds)
    if seconds < 60 then return seconds .. "s"
    elseif seconds < 3600 then return math.floor(seconds / 60) .. "m"
    else return math.floor(seconds / 3600) .. "h" end
end

-- ============================================
-- FONCTIONS DE DESSIN
-- ============================================
local function setColors(fg, bg)
    mon.setTextColor(fg or theme.text)
    mon.setBackgroundColor(bg or theme.bg)
end

local function fill(x, y, w, h, bg)
    setColors(nil, bg)
    for i = 0, h - 1 do
        mon.setCursorPos(x, y + i)
        mon.write(string.rep(" ", w))
    end
end

local function writeAt(x, y, text, fg, bg)
    mon.setCursorPos(x, y)
    setColors(fg, bg)
    mon.write(text)
end

local function drawBox(x, y, w, h, title, titleColor)
    fill(x, y, w, h, theme.card)
    if title then
        writeAt(x + 1, y, " " .. truncate(title, w - 4) .. " ", titleColor or theme.cardTitle, theme.card)
    end
end

local function drawButton(x, y, w, text, active, bg)
    local bgColor = active and theme.menuActive or (bg or theme.button)
    fill(x, y, w, 1, bgColor)
    local tx = x + math.floor((w - #text) / 2)
    writeAt(tx, y, text, theme.buttonText, bgColor)
end

local function drawProgressBar(x, y, w, percent, color, showText)
    percent = math.max(0, math.min(100, percent or 0))
    local filled = math.floor(w * percent / 100)
    
    fill(x, y, w, 1, theme.progressBg)
    if filled > 0 then
        fill(x, y, filled, 1, color or theme.progress)
    end
    
    if showText then
        local text = string.format("%d%%", math.floor(percent))
        local tx = x + math.floor((w - #text) / 2)
        writeAt(tx, y, text, theme.text, filled >= tx and (color or theme.progress) or theme.progressBg)
    end
end

local function drawSparkline(x, y, w, dataPoints, color)
    if #dataPoints < 2 then return end
    
    local chars = {" ", ".", ":", "-", "=", "+", "#"}
    
    local minVal, maxVal = math.huge, -math.huge
    for _, v in ipairs(dataPoints) do
        if v < minVal then minVal = v end
        if v > maxVal then maxVal = v end
    end
    if maxVal == minVal then maxVal = minVal + 1 end
    
    local pointsToShow = math.min(#dataPoints, w)
    local startIdx = math.max(1, #dataPoints - w + 1)
    
    local line = ""
    for i = 1, pointsToShow do
        local idx = startIdx + i - 1
        local val = dataPoints[idx] or 0
        local normalized = (val - minVal) / (maxVal - minVal)
        local charIdx = math.floor(normalized * (#chars - 1)) + 1
        line = line .. chars[charIdx]
    end
    
    writeAt(x, y, line, color or theme.graphLine, theme.bg)
end

-- ============================================
-- BOUTONS INTERACTIFS
-- ============================================
local buttons = {}

local function clearButtons()
    buttons = {}
end

local function addButton(x, y, w, h, action, param)
    table.insert(buttons, {x = x, y = y, w = w, h = h, action = action, param = param})
end

local function checkButtonClick(cx, cy)
    for _, btn in ipairs(buttons) do
        if cx >= btn.x and cx < btn.x + btn.w and cy >= btn.y and cy < btn.y + btn.h then
            return btn.action, btn.param
        end
    end
    return nil, nil
end

-- ============================================
-- PAGINATION
-- ============================================
local function getPageInfo(listName, totalItems)
    local page = pageNumbers[listName] or 1
    local perPage = CONFIG.itemsPerPage
    local totalPages = math.max(1, math.ceil(totalItems / perPage))
    
    if page > totalPages then
        page = totalPages
        pageNumbers[listName] = page
    end
    
    local startIdx = (page - 1) * perPage + 1
    local endIdx = math.min(page * perPage, totalItems)
    
    return page, totalPages, startIdx, endIdx
end

local function drawPagination(x, y, w, listName, totalItems)
    local page, totalPages, _, _ = getPageInfo(listName, totalItems)
    
    if totalPages <= 1 then return end
    
    local btnW = 3
    
    -- Bouton precedent
    if page > 1 then
        fill(x, y, btnW, 1, theme.button)
        writeAt(x + 1, y, "<", theme.buttonText, theme.button)
        addButton(x, y, btnW, 1, "page_prev", listName)
    end
    
    -- Numero de page
    local pageText = "Page " .. page .. "/" .. totalPages
    local textX = x + math.floor((w - #pageText) / 2)
    writeAt(textX, y, pageText, theme.textDim, theme.bg)
    
    -- Bouton suivant
    if page < totalPages then
        fill(x + w - btnW, y, btnW, 1, theme.button)
        writeAt(x + w - btnW + 1, y, ">", theme.buttonText, theme.button)
        addButton(x + w - btnW, y, btnW, 1, "page_next", listName)
    end
end

-- ============================================
-- MENU LATERAL
-- ============================================
local function centerText(text, width)
    local pad = math.floor((width - #text) / 2)
    return string.rep(" ", math.max(0, pad)) .. text
end

local function isAlertActive()
    -- Verifier si test d'alerte actif
    local now = os.epoch("utc") / 1000
    if testAlertUntil > now then
        return true
    end
    -- Sinon verifier attaque reelle
    return data.underAttack
end

local function drawMenu()
    local menuW = CONFIG.menuWidth
    
    local alertActive = isAlertActive()
    
    -- Fond du menu (rouge si attaque)
    local menuBg = alertActive and (alertBlink and theme.alert or theme.danger) or theme.menu
    fill(1, 1, menuW, screenH, menuBg)
    
    -- Titre (avec indicateur d'attaque)
    if alertActive then
        writeAt(1, 1, centerText("! ALERTE !", menuW), theme.alertText, menuBg)
    else
        writeAt(1, 1, centerText("MENU", menuW), theme.menuText, menuBg)
    end
    
    -- Pages
    for i, page in ipairs(pages) do
        local y = i + 2
        local isActive = (currentPage == page.id)
        local bg = isActive and theme.menuActive or menuBg
        
        fill(1, y, menuW, 1, bg)
        writeAt(2, y, truncate(page.name, menuW - 2), theme.menuText, bg)
        
        addButton(1, y, menuW, 1, "navigate", page.id)
    end
    
    -- Indicateur d'attaque en bas du menu
    if alertActive then
        local attackY = screenH - 1
        fill(1, attackY, menuW, 1, theme.danger)
        writeAt(1, attackY, centerText("ATTAQUE!", menuW), theme.alertText, theme.danger)
    end
end

-- ============================================
-- BANNIERE D'ALERTE
-- ============================================
local function drawAlertBanner()
    if isAlertActive() then
        alertBlink = not alertBlink
        local bg = alertBlink and theme.alert or theme.danger
        fill(contentX, 1, contentW, 1, bg)
        local text = "!!! ATTAQUE EN COURS !!!"
        writeAt(contentX + math.floor((contentW - #text) / 2), 1, text, theme.alertText, bg)
        return 2
    end
    return 1
end

-- ============================================
-- PAGE: ACCUEIL
-- ============================================
local function drawHomePage(startY)
    local x = contentX + 1
    local w = contentW - 2
    local y = startY
    
    -- Titre colonie
    fill(contentX, y, contentW, 1, theme.header)
    local title = truncate(data.name, contentW - 4)
    writeAt(contentX + math.floor((contentW - #title) / 2), y, title, theme.headerText, theme.header)
    y = y + 2
    
    -- Statut
    local statusText, statusColor
    if data.underAttack then
        statusText = "ATTAQUE!"
        statusColor = theme.danger
    elseif data.isActive then
        statusText = "Colonie Active"
        statusColor = theme.good
    else
        statusText = "Colonie Inactive"
        statusColor = theme.warning
    end
    writeAt(x, y, "Statut: ", theme.textDim, theme.bg)
    writeAt(x + 8, y, statusText, statusColor, theme.bg)
    y = y + 2
    
    -- Barre Bonheur
    local happiness = data.happiness or 0
    local happyPercent = (happiness / 10) * 100
    local happyColor = theme.good
    if happiness < 5 then happyColor = theme.danger
    elseif happiness < 7.5 then happyColor = theme.warning end
    
    writeAt(x, y, "Bonheur: " .. string.format("%.1f", happiness) .. "/10", theme.text, theme.bg)
    y = y + 1
    drawProgressBar(x, y, w - 4, happyPercent, happyColor, false)
    if #history.happiness > 5 then
        drawSparkline(x, y + 1, w - 4, history.happiness, happyColor)
    end
    y = y + 3
    
    -- Barre Citoyens
    local citizenCount = #data.citizens
    local citizenPercent = (citizenCount / CONFIG.maxCitizens) * 100
    
    writeAt(x, y, "Citoyens: " .. citizenCount .. "/" .. CONFIG.maxCitizens, theme.text, theme.bg)
    y = y + 1
    drawProgressBar(x, y, w - 4, citizenPercent, theme.cardTitle, false)
    if #history.citizens > 5 then
        drawSparkline(x, y + 1, w - 4, history.citizens, theme.cardTitle)
    end
    y = y + 3
    
    -- Requetes
    local reqColor = #data.requests > 10 and theme.warning or theme.text
    writeAt(x, y, "Requetes en attente: ", theme.textDim, theme.bg)
    writeAt(x + 20, y, tostring(#data.requests), reqColor, theme.bg)
    y = y + 2
    
    -- Mini chantiers
    local boxH = math.max(3, screenH - y - 1)
    drawBox(contentX, y, contentW, boxH, "Chantiers en cours (" .. #data.workOrders .. ")")
    
    local wy = y + 1
    if #data.workOrders == 0 then
        writeAt(x + 1, wy, "Aucun chantier", theme.textMuted, theme.card)
    else
        for i = 1, math.min(boxH - 1, #data.workOrders) do
            local wo = data.workOrders[i]
            local name = cleanBuildingName(wo.buildingName or wo.type or "?")
            local status = wo.isClaimed and "[En cours]" or "[Attente]"
            local col = wo.isClaimed and theme.good or theme.warning
            writeAt(x + 1, wy, truncate(name, contentW - 15), theme.text, theme.card)
            writeAt(contentX + contentW - 11, wy, status, col, theme.card)
            wy = wy + 1
        end
    end
end

-- ============================================
-- PAGE: CITOYENS
-- ============================================
local function getHealthColor(health)
    if health >= 15 then return theme.good
    elseif health >= 8 then return theme.warning
    else return theme.danger end
end

local function drawCitizensPage(startY)
    local x = contentX + 1
    local w = contentW - 2
    local y = startY
    
    -- Titre style
    fill(contentX, y, contentW, 1, theme.header)
    local title = "[ RESIDENTS - " .. #data.citizens .. " ]"
    writeAt(contentX + math.floor((contentW - #title) / 2), y, title, theme.headerText, theme.header)
    y = y + 2
    
    -- En-tetes de colonnes
    local col1 = x
    local col2 = x + math.floor(w * 0.45)
    local col3 = x + math.floor(w * 0.75)
    
    writeAt(col1, y, "NOM", theme.cardTitle, theme.bg)
    writeAt(col2, y, "METIER", theme.cardTitle, theme.bg)
    writeAt(col3, y, "VIE", theme.cardTitle, theme.bg)
    y = y + 1
    
    -- Ligne de separation
    writeAt(x, y, string.rep("-", w), theme.textDim, theme.bg)
    y = y + 1
    
    -- Liste paginee
    local page, totalPages, startIdx, endIdx = getPageInfo("citizens", #data.citizens)
    
    for i = startIdx, endIdx do
        local citizen = data.citizens[i]
        if citizen then
            local name = citizen.name or "Citoyen #" .. i
            local job = getJobName(citizen)
            local health = 20
            if citizen.health then
                health = type(citizen.health) == "number" and citizen.health or 20
            end
            local healthColor = getHealthColor(health)
            
            writeAt(col1, y, truncate(name, math.floor(w * 0.43)), theme.text, theme.bg)
            writeAt(col2, y, truncate(job, math.floor(w * 0.28)), theme.good, theme.bg)
            writeAt(col3, y, tostring(math.floor(health)), healthColor, theme.bg)
            
            addButton(contentX, y, contentW, 1, "popup_citizen", i)
            y = y + 1
        end
    end
    
    -- Pagination
    drawPagination(contentX, screenH - 1, contentW, "citizens", #data.citizens)
end

-- ============================================
-- PAGE: REQUETES
-- ============================================
local function drawRequestsPage(startY)
    local x = contentX + 1
    local w = contentW - 2
    local y = startY
    
    fill(contentX, y, contentW, 1, theme.header)
    writeAt(contentX + 2, y, "Requetes (" .. #data.requests .. ")", theme.headerText, theme.header)
    y = y + 2
    
    if #data.requests == 0 then
        writeAt(x, y, "Aucune requete!", theme.good, theme.bg)
        return
    end
    
    -- Grouper
    local grouped = {}
    for _, req in ipairs(data.requests) do
        local name = "Item"
        local count = req.count or 1
        if req.items and req.items[1] then
            name = req.items[1].displayName or req.items[1].name or "Item"
        elseif req.name then
            name = req.name
        end
        name = cleanItemName(name)
        grouped[name] = (grouped[name] or 0) + count
    end
    
    -- Trier
    local sorted = {}
    for name, count in pairs(grouped) do
        table.insert(sorted, {name = name, count = count})
    end
    table.sort(sorted, function(a, b) return a.count > b.count end)
    
    -- Pagination
    local page, totalPages, startIdx, endIdx = getPageInfo("requests", #sorted)
    
    for i = startIdx, endIdx do
        local req = sorted[i]
        if req then
            local col = req.count > 20 and theme.danger or (req.count > 10 and theme.warning or theme.text)
            writeAt(x, y, truncate(req.name, w - 8), theme.text, theme.bg)
            writeAt(x + w - 6, y, string.format("x%4d", req.count), col, theme.bg)
            y = y + 1
        end
    end
    
    drawPagination(contentX, screenH - 1, contentW, "requests", #sorted)
end

-- ============================================
-- PAGE: CHANTIERS
-- ============================================
local function drawConstructionPage(startY)
    local x = contentX + 1
    local w = contentW - 2
    local y = startY
    
    fill(contentX, y, contentW, 1, theme.header)
    writeAt(contentX + 2, y, "Chantiers (" .. #data.workOrders .. ")", theme.headerText, theme.header)
    y = y + 2
    
    if #data.workOrders == 0 then
        writeAt(x, y, "Aucun chantier en cours", theme.textMuted, theme.bg)
        return
    end
    
    -- Info selection
    if selectedWorkOrder then
        writeAt(x, y, "Selectionne: ", theme.textDim, theme.bg)
        local wo = data.workOrders[selectedWorkOrder]
        if wo then
            local name = cleanBuildingName(wo.buildingName or wo.type or "?")
            writeAt(x + 13, y, truncate(name, w - 25), theme.cardTitle, theme.bg)
        end
        
        -- Boutons action
        local btnW = 8
        drawButton(x + w - btnW * 2 - 2, y, btnW, "Export", false)
        addButton(x + w - btnW * 2 - 2, y, btnW, 1, "export_single", selectedWorkOrder)
        
        drawButton(x + w - btnW, y, btnW, "Details", false)
        addButton(x + w - btnW, y, btnW, 1, "popup_workorder", selectedWorkOrder)
        
        y = y + 2
    end
    
    -- Liste
    local page, totalPages, startIdx, endIdx = getPageInfo("construction", #data.workOrders)
    
    for i = startIdx, endIdx do
        local wo = data.workOrders[i]
        if wo then
            local name = cleanBuildingName(wo.buildingName or wo.type or "Batiment")
            local builder = getBuilderName(wo)
            local claimed = wo.isClaimed
            local isSelected = (selectedWorkOrder == i)
            
            -- Fond si selectionne
            if isSelected then
                fill(contentX, y, contentW, 2, theme.bgAlt)
            end
            
            -- Indicateur selection
            writeAt(x, y, isSelected and ">" or " ", theme.cardTitle, isSelected and theme.bgAlt or theme.bg)
            
            -- Nom
            writeAt(x + 2, y, truncate(name, w - 15), theme.text, isSelected and theme.bgAlt or theme.bg)
            
            -- Statut
            local status = claimed and "[En cours]" or "[Attente]"
            local statCol = claimed and theme.good or theme.warning
            writeAt(x + w - 10, y, status, statCol, isSelected and theme.bgAlt or theme.bg)
            
            -- Builder
            writeAt(x + 4, y + 1, "Builder: " .. truncate(builder, w - 15), theme.textDim, isSelected and theme.bgAlt or theme.bg)
            
            addButton(contentX, y, contentW, 2, "select_workorder", i)
            y = y + 2
        end
    end
    
    -- Bouton export tout
    y = screenH - 2
    local allBtn = "Exporter tout"
    drawButton(contentX + contentW - #allBtn - 2, y, #allBtn + 2, allBtn, false)
    addButton(contentX + contentW - #allBtn - 2, y, #allBtn + 2, 1, "export_all", nil)
    
    drawPagination(contentX, screenH - 1, contentW, "construction", #data.workOrders)
end

-- ============================================
-- PAGE: BATIMENTS
-- ============================================
local function drawBuildingsPage(startY)
    local x = contentX + 1
    local w = contentW - 2
    local y = startY
    
    -- Titre style
    fill(contentX, y, contentW, 1, theme.header)
    local title = "[ BATIMENTS - " .. #data.buildings .. " ]"
    writeAt(contentX + math.floor((contentW - #title) / 2), y, title, theme.headerText, theme.header)
    y = y + 2
    
    if #data.buildings == 0 then
        writeAt(x, y, "Aucun batiment", theme.textMuted, theme.bg)
        return
    end
    
    -- Creer une table de positions des chantiers en cours pour comparaison rapide
    local workOrderPositions = {}
    for _, wo in ipairs(data.workOrders) do
        -- Utiliser la position du chantier comme cle
        if wo.location or wo.pos or wo.position then
            local loc = wo.location or wo.pos or wo.position
            if type(loc) == "table" then
                local posKey = tostring(loc.x or 0) .. "," .. tostring(loc.y or 0) .. "," .. tostring(loc.z or 0)
                workOrderPositions[posKey] = true
            end
        end
        -- Aussi utiliser l'ID du batiment si disponible
        if wo.buildingId then
            workOrderPositions["id:" .. tostring(wo.buildingId)] = true
        end
        if wo.id then
            workOrderPositions["woid:" .. tostring(wo.id)] = true
        end
    end
    
    -- Statistiques: compter les batiments construits vs en travaux
    local built = 0
    for _, b in ipairs(data.buildings) do
        local level = b.level or 0
        if level > 0 then
            built = built + 1
        end
    end
    local inProgress = #data.workOrders
    
    writeAt(x, y, "Construits: ", theme.textDim, theme.bg)
    writeAt(x + 12, y, tostring(built), theme.good, theme.bg)
    writeAt(x + 18, y, "En travaux: ", theme.textDim, theme.bg)
    writeAt(x + 30, y, tostring(inProgress), inProgress > 0 and theme.warning or theme.text, theme.bg)
    y = y + 2
    
    -- En-tetes de colonnes
    local col1 = x
    local col2 = x + math.floor(w * 0.50)
    local col3 = x + math.floor(w * 0.72)
    
    writeAt(col1, y, "TYPE", theme.cardTitle, theme.bg)
    writeAt(col2, y, "NIVEAU", theme.cardTitle, theme.bg)
    writeAt(col3, y, "STATUT", theme.cardTitle, theme.bg)
    y = y + 1
    
    -- Ligne de separation
    writeAt(x, y, string.rep("-", w), theme.textDim, theme.bg)
    y = y + 1
    
    -- Liste paginee
    local page, totalPages, startIdx, endIdx = getPageInfo("buildings", #data.buildings)
    
    for i = startIdx, endIdx do
        local building = data.buildings[i]
        if building then
            local name = cleanBuildingName(building.type or "?")
            local level = building.level or 0
            local maxLvl = building.maxLevel or 5
            
            -- Determiner le statut
            local status = "OK"
            local statusColor = theme.good
            
            -- Verifier si le batiment est en construction par position
            local isBuilding = false
            
            -- Methode 1: Comparer par position
            if building.location or building.pos or building.position then
                local loc = building.location or building.pos or building.position
                if type(loc) == "table" then
                    local posKey = tostring(loc.x or 0) .. "," .. tostring(loc.y or 0) .. "," .. tostring(loc.z or 0)
                    if workOrderPositions[posKey] then
                        isBuilding = true
                    end
                end
            end
            
            -- Methode 2: Comparer par ID
            if not isBuilding and building.id then
                if workOrderPositions["id:" .. tostring(building.id)] then
                    isBuilding = true
                end
            end
            
            if isBuilding then
                status = "TRAVAUX"
                statusColor = theme.warning
            elseif level == 0 then
                status = "NOUVEAU"
                statusColor = theme.cardTitle
            end
            
            writeAt(col1, y, truncate(name, math.floor(w * 0.48)), theme.text, theme.bg)
            writeAt(col2, y, level .. "/" .. maxLvl, theme.text, theme.bg)
            writeAt(col3, y, status, statusColor, theme.bg)
            
            addButton(contentX, y, contentW, 1, "popup_building", i)
            y = y + 1
        end
    end
    
    drawPagination(contentX, screenH - 1, contentW, "buildings", #data.buildings)
end

-- ============================================
-- PAGE: STATISTIQUES
-- ============================================
local function drawStatsPage(startY)
    local x = contentX + 1
    local w = contentW - 2
    local y = startY
    
    fill(contentX, y, contentW, 1, theme.header)
    writeAt(contentX + 2, y, "Statistiques", theme.headerText, theme.header)
    y = y + 2
    
    local histLen = #history.happiness
    writeAt(x, y, "Points: " .. histLen .. "/" .. CONFIG.maxHistoryPoints, theme.textDim, theme.bg)
    y = y + 2
    
    if histLen > 0 then
        -- Bonheur
        local happySum, happyMin, happyMax = 0, math.huge, -math.huge
        for _, v in ipairs(history.happiness) do
            happySum = happySum + v
            if v < happyMin then happyMin = v end
            if v > happyMax then happyMax = v end
        end
        local happyAvg = happySum / histLen
        
        drawBox(contentX, y, contentW, 5, "Bonheur")
        writeAt(x + 1, y + 1, string.format("Moy: %.1f  Min: %.1f  Max: %.1f", happyAvg, happyMin, happyMax), theme.text, theme.card)
        drawSparkline(x + 1, y + 3, w - 2, history.happiness, theme.good)
        y = y + 6
        
        -- Citoyens
        local citMin, citMax = math.huge, -math.huge
        for _, v in ipairs(history.citizens) do
            if v < citMin then citMin = v end
            if v > citMax then citMax = v end
        end
        
        drawBox(contentX, y, contentW, 5, "Population")
        writeAt(x + 1, y + 1, string.format("Min: %d  Max: %d  Actuel: %d", citMin, citMax, #data.citizens), theme.text, theme.card)
        drawSparkline(x + 1, y + 3, w - 2, history.citizens, theme.cardTitle)
        y = y + 6
        
        -- Attaques
        local attackCount = 0
        for _, v in ipairs(history.attacks) do
            if v > 0 then attackCount = attackCount + 1 end
        end
        writeAt(x, y, "Attaques detectees: " .. attackCount, theme.warning, theme.bg)
    else
        writeAt(x, y, "En attente de donnees...", theme.textMuted, theme.bg)
    end
    
    -- Bouton reset
    y = screenH - 1
    drawButton(contentX + contentW - 14, y, 12, "Reset Stats", false)
    addButton(contentX + contentW - 14, y, 12, 1, "reset_history", nil)
end

-- ============================================
-- PAGE: PARAMETRES
-- ============================================
local function drawSettingsPage(startY)
    local x = contentX + 1
    local w = contentW - 2
    local y = startY
    
    fill(contentX, y, contentW, 1, theme.header)
    writeAt(contentX + 2, y, "Configuration", theme.headerText, theme.header)
    y = y + 2
    
    -- Theme actuel
    writeAt(x, y, "Theme: " .. theme.name, theme.text, theme.bg)
    y = y + 2
    
    -- Grille de themes
    local themeList = {"dark", "light", "minecolonies", "ocean", "forest", "nether"}
    local btnW = math.floor((w - 2) / 2)
    
    for i, tName in ipairs(themeList) do
        local t = themes[tName]
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local bx = x + col * (btnW + 1)
        local by = y + row
        
        local isActive = (currentTheme == tName)
        local bg = isActive and theme.menuActive or theme.button
        
        fill(bx, by, btnW, 1, bg)
        writeAt(bx + 1, by, truncate(t.name, btnW - 2), theme.buttonText, bg)
        addButton(bx, by, btnW, 1, "set_theme", tName)
    end
    y = y + math.ceil(#themeList / 2) + 2
    
    -- Taille texte
    writeAt(x, y, "Taille texte:", theme.text, theme.bg)
    y = y + 1
    
    local scales = {{val = 0.5, name = "Petit"}, {val = 1, name = "Normal"}, {val = 1.5, name = "Grand"}}
    local scaleW = math.floor((w - 2) / 3)
    
    for i, s in ipairs(scales) do
        local bx = x + (i - 1) * (scaleW + 1)
        local isActive = (CONFIG.textScale == s.val)
        local bg = isActive and theme.menuActive or theme.button
        
        fill(bx, y, scaleW, 1, bg)
        writeAt(bx + 1, y, s.name, theme.buttonText, bg)
        addButton(bx, y, scaleW, 1, "set_scale", s.val)
    end
    y = y + 2
    
    -- Refresh rate
    writeAt(x, y, "Rafraichissement:", theme.text, theme.bg)
    y = y + 1
    
    local rates = {1, 3, 5, 10}
    local rateW = math.floor((w - 4) / #rates)
    
    for i, r in ipairs(rates) do
        local bx = x + (i - 1) * (rateW + 1)
        local isActive = (CONFIG.refreshRate == r)
        local bg = isActive and theme.menuActive or theme.button
        
        fill(bx, y, rateW, 1, bg)
        writeAt(bx + math.floor(rateW / 2) - 1, y, r .. "s", theme.buttonText, bg)
        addButton(bx, y, rateW, 1, "set_refresh", r)
    end
    y = y + 2
    
    -- Items par page
    writeAt(x, y, "Items par page:", theme.text, theme.bg)
    y = y + 1
    
    local perPages = {5, 8, 10, 15}
    
    for i, p in ipairs(perPages) do
        local bx = x + (i - 1) * (rateW + 1)
        local isActive = (CONFIG.itemsPerPage == p)
        local bg = isActive and theme.menuActive or theme.button
        
        fill(bx, y, rateW, 1, bg)
        writeAt(bx + math.floor(rateW / 2), y, tostring(p), theme.buttonText, bg)
        addButton(bx, y, rateW, 1, "set_items_per_page", p)
    end
    y = y + 2
    
    -- Intervalle son alerte
    writeAt(x, y, "Son alerte (sec):", theme.text, theme.bg)
    y = y + 1
    
    local soundIntervals = {1, 2, 3, 5}
    
    for i, s in ipairs(soundIntervals) do
        local bx = x + (i - 1) * (rateW + 1)
        local isActive = (CONFIG.alertSoundInterval == s)
        local bg = isActive and theme.menuActive or theme.button
        
        fill(bx, y, rateW, 1, bg)
        writeAt(bx + math.floor(rateW / 2), y, tostring(s), theme.buttonText, bg)
        addButton(bx, y, rateW, 1, "set_sound_interval", s)
    end
    y = y + 2
    
    -- Bouton test alerte
    writeAt(x, y, "Test systeme:", theme.text, theme.bg)
    y = y + 1
    
    local testBtnW = math.floor((w - 2) / 2)
    
    fill(x, y, testBtnW, 1, theme.alert)
    writeAt(x + 2, y, "Test Alerte", theme.alertText, theme.alert)
    addButton(x, y, testBtnW, 1, "test_alert", nil)
    
    fill(x + testBtnW + 1, y, testBtnW, 1, theme.good)
    writeAt(x + testBtnW + 3, y, "Test Son", theme.buttonText, theme.good)
    addButton(x + testBtnW + 1, y, testBtnW, 1, "test_sound", nil)
end

-- ============================================
-- POPUP
-- ============================================
local function drawPopup()
    if not showPopup or not popupData then return end
    
    local pw = math.floor(contentW * 0.9)
    local ph = math.floor(screenH * 0.8)
    local px = contentX + math.floor((contentW - pw) / 2)
    local py = math.floor((screenH - ph) / 2)
    
    fill(px, py, pw, ph, theme.popup)
    
    -- Bordure
    for i = 0, pw - 1 do
        writeAt(px + i, py, "-", theme.popupBorder, theme.popup)
        writeAt(px + i, py + ph - 1, "-", theme.popupBorder, theme.popup)
    end
    for i = 0, ph - 1 do
        writeAt(px, py + i, "|", theme.popupBorder, theme.popup)
        writeAt(px + pw - 1, py + i, "|", theme.popupBorder, theme.popup)
    end
    
    -- Bouton fermer
    writeAt(px + pw - 4, py, "[X]", theme.danger, theme.popup)
    addButton(px + pw - 4, py, 3, 1, "close_popup", nil)
    
    local y = py + 2
    
    if popupData.type == "citizen" then
        local c = data.citizens[popupData.index]
        if c then
            writeAt(px + 2, y, "=== CITOYEN ===", theme.cardTitle, theme.popup)
            y = y + 2
            writeAt(px + 2, y, "Nom: " .. tostring(c.name or "?"), theme.text, theme.popup)
            y = y + 1
            writeAt(px + 2, y, "Metier: " .. getJobName(c), theme.text, theme.popup)
            y = y + 1
            
            -- Afficher tous les champs disponibles (avec protection contre les tables)
            if c.age then
                writeAt(px + 2, y, "Age: " .. tostring(c.age), theme.textDim, theme.popup)
                y = y + 1
            end
            if c.gender then
                writeAt(px + 2, y, "Genre: " .. tostring(c.gender), theme.textDim, theme.popup)
                y = y + 1
            end
            if c.health then
                local health = type(c.health) == "number" and c.health or extractString(c.health) or "?"
                writeAt(px + 2, y, "Sante: " .. tostring(health), theme.text, theme.popup)
                y = y + 1
            end
            if c.saturation then
                local sat = type(c.saturation) == "number" and c.saturation or 0
                writeAt(px + 2, y, "Faim: " .. string.format("%.1f", sat), theme.text, theme.popup)
                y = y + 1
            end
            if c.happiness then
                local hap = type(c.happiness) == "number" and c.happiness or 0
                writeAt(px + 2, y, "Bonheur: " .. string.format("%.1f", hap), theme.text, theme.popup)
                y = y + 1
            end
            if c.location then
                if type(c.location) == "table" then
                    local lx = c.location.x or 0
                    local ly = c.location.y or 0
                    local lz = c.location.z or 0
                    writeAt(px + 2, y, "Position: " .. lx .. ", " .. ly .. ", " .. lz, theme.textDim, theme.popup)
                else
                    writeAt(px + 2, y, "Position: " .. tostring(c.location), theme.textDim, theme.popup)
                end
                y = y + 1
            end
            if c.state then
                writeAt(px + 2, y, "Etat: " .. tostring(extractString(c.state) or c.state), theme.textDim, theme.popup)
            end
        end
        
    elseif popupData.type == "workorder" then
        local wo = data.workOrders[popupData.index]
        if wo then
            local name = cleanBuildingName(wo.buildingName or wo.type or "?")
            writeAt(px + 2, y, "=== " .. truncate(name, pw - 8) .. " ===", theme.cardTitle, theme.popup)
            y = y + 2
            writeAt(px + 2, y, "Builder: " .. getBuilderName(wo), theme.text, theme.popup)
            y = y + 1
            writeAt(px + 2, y, "Statut: " .. (wo.isClaimed and "En cours" or "En attente"), theme.text, theme.popup)
            y = y + 2
            
            writeAt(px + 2, y, "-- Ressources manquantes --", theme.cardTitle, theme.popup)
            y = y + 1
            
            local resources = {}
            pcall(function()
                resources = colony.getWorkOrderResources(wo.id) or {}
            end)
            
            local missing = {}
            for _, res in ipairs(resources) do
                local needed = res.needed or res.count or 0
                local available = res.available or 0
                if available < needed then
                    table.insert(missing, {
                        name = cleanItemName(res.displayName or res.item or "?"),
                        needed = needed,
                        available = available,
                        miss = needed - available
                    })
                end
            end
            
            table.sort(missing, function(a, b) return a.miss > b.miss end)
            
            if #missing == 0 then
                writeAt(px + 3, y, "Toutes ressources OK!", theme.good, theme.popup)
            else
                for i, res in ipairs(missing) do
                    if y < py + ph - 2 then
                        writeAt(px + 3, y, truncate(res.name, pw - 16), theme.text, theme.popup)
                        writeAt(px + pw - 12, y, res.available .. "/" .. res.needed, theme.danger, theme.popup)
                        y = y + 1
                    end
                end
            end
        end
        
    elseif popupData.type == "building" then
        local b = data.buildings[popupData.index]
        if b then
            local name = cleanBuildingName(b.type or "?")
            writeAt(px + 2, y, "=== " .. name .. " ===", theme.cardTitle, theme.popup)
            y = y + 2
            writeAt(px + 2, y, "Niveau: " .. (b.level or 0) .. "/" .. (b.maxLevel or 5), theme.text, theme.popup)
            y = y + 1
            if b.location then
                writeAt(px + 2, y, "Position: " .. b.location.x .. ", " .. b.location.y .. ", " .. b.location.z, theme.textDim, theme.popup)
            end
        end
        
    elseif popupData.type == "success" then
        writeAt(px + 2, y, "SUCCES!", theme.good, theme.popup)
        y = y + 2
        -- Wrap message
        local msg = popupData.message or ""
        while #msg > 0 and y < py + ph - 2 do
            writeAt(px + 2, y, msg:sub(1, pw - 4), theme.text, theme.popup)
            msg = msg:sub(pw - 3)
            y = y + 1
        end
        
    elseif popupData.type == "error" then
        writeAt(px + 2, y, "ERREUR!", theme.danger, theme.popup)
        y = y + 2
        writeAt(px + 2, y, popupData.message or "", theme.text, theme.popup)
        
    elseif popupData.type == "confirm" then
        writeAt(px + 2, y, popupData.title or "Confirmer?", theme.warning, theme.popup)
        y = y + 2
        writeAt(px + 2, y, popupData.message or "", theme.text, theme.popup)
        y = y + 3
        
        local btnW = 8
        drawButton(px + 5, y, btnW, "Oui", false)
        addButton(px + 5, y, btnW, 1, popupData.yesAction, popupData.yesParam)
        
        drawButton(px + pw - btnW - 5, y, btnW, "Non", false)
        addButton(px + pw - btnW - 5, y, btnW, 1, "close_popup", nil)
    end
end

-- ============================================
-- EXPORT JSON
-- ============================================
local function exportMaterials(workOrderIndex)
    if not disk or not disk.isDiskPresent() then
        showPopup = true
        popupData = {type = "error", message = "Inserez une disquette!"}
        return
    end
    
    local allResources = {}
    local workOrdersToExport = {}
    
    if workOrderIndex then
        local wo = data.workOrders[workOrderIndex]
        if wo then
            table.insert(workOrdersToExport, wo)
        end
    else
        workOrdersToExport = data.workOrders
    end
    
    for _, wo in ipairs(workOrdersToExport) do
        local resources = {}
        pcall(function()
            resources = colony.getWorkOrderResources(wo.id) or {}
        end)
        
        for _, res in ipairs(resources) do
            local name = res.item or res.name or "unknown"
            local needed = res.needed or res.count or 0
            local available = res.available or 0
            local missing = math.max(0, needed - available)
            
            if missing > 0 then
                if allResources[name] then
                    allResources[name].needed = allResources[name].needed + needed
                    allResources[name].missing = allResources[name].missing + missing
                else
                    allResources[name] = {
                        name = name,
                        displayName = cleanItemName(res.displayName or res.item or name),
                        needed = needed,
                        missing = missing
                    }
                end
            end
        end
    end
    
    local list = {}
    for _, res in pairs(allResources) do
        table.insert(list, res)
    end
    table.sort(list, function(a, b) return a.missing > b.missing end)
    
    local json = "{\n"
    json = json .. '  "colony": "' .. data.name .. '",\n'
    json = json .. '  "exportDate": "' .. os.date("%Y-%m-%d %H:%M") .. '",\n'
    json = json .. '  "workOrders": ' .. #workOrdersToExport .. ',\n'
    json = json .. '  "totalItems": ' .. #list .. ',\n'
    json = json .. '  "materials": [\n'
    
    for i, res in ipairs(list) do
        json = json .. '    {\n'
        json = json .. '      "item": "' .. res.name .. '",\n'
        json = json .. '      "displayName": "' .. res.displayName .. '",\n'
        json = json .. '      "needed": ' .. res.needed .. ',\n'
        json = json .. '      "missing": ' .. res.missing .. '\n'
        json = json .. '    }'
        if i < #list then json = json .. ',' end
        json = json .. '\n'
    end
    
    json = json .. '  ]\n}'
    
    local filename = workOrderIndex and "materials_" .. workOrderIndex .. ".json" or "materials.json"
    local path = "/disk/" .. filename
    local file = fs.open(path, "w")
    if file then
        file.write(json)
        file.close()
        
        showPopup = true
        popupData = {type = "success", message = "Exporte: " .. path .. "\n" .. #list .. " items manquants"}
        
        if speaker then speaker.playNote("bell", 1, 12) end
    else
        showPopup = true
        popupData = {type = "error", message = "Erreur ecriture!"}
    end
end

-- ============================================
-- RENDU PRINCIPAL
-- ============================================
local function render()
    clearButtons()
    
    fill(1, 1, screenW, screenH, theme.bg)
    
    -- Menu lateral
    drawMenu()
    
    -- Banniere alerte
    local contentStart = drawAlertBanner()
    
    -- Contenu
    if currentPage == "home" then
        drawHomePage(contentStart)
    elseif currentPage == "citizens" then
        drawCitizensPage(contentStart)
    elseif currentPage == "requests" then
        drawRequestsPage(contentStart)
    elseif currentPage == "construction" then
        drawConstructionPage(contentStart)
    elseif currentPage == "buildings" then
        drawBuildingsPage(contentStart)
    elseif currentPage == "stats" then
        drawStatsPage(contentStart)
    elseif currentPage == "settings" then
        drawSettingsPage(contentStart)
    end
    
    -- Popup
    if showPopup then
        drawPopup()
    end
end

-- ============================================
-- GESTION CLICS
-- ============================================
local function handleClick(x, y)
    if showPopup then
        local action, param = checkButtonClick(x, y)
        if action == "close_popup" or action == nil then
            showPopup = false
            popupData = nil
        elseif action == "confirm_reset" then
            history = {happiness = {}, citizens = {}, requests = {}, attacks = {}, timestamps = {}}
            saveHistory()
            showPopup = false
            popupData = nil
        end
        return
    end
    
    local action, param = checkButtonClick(x, y)
    
    if action == "navigate" then
        currentPage = param
        pageNumbers = {}
        selectedWorkOrder = nil
        
    elseif action == "page_prev" then
        pageNumbers[param] = (pageNumbers[param] or 1) - 1
        if pageNumbers[param] < 1 then pageNumbers[param] = 1 end
        
    elseif action == "page_next" then
        pageNumbers[param] = (pageNumbers[param] or 1) + 1
        
    elseif action == "select_workorder" then
        if selectedWorkOrder == param then
            selectedWorkOrder = nil
        else
            selectedWorkOrder = param
        end
        
    elseif action == "popup_citizen" then
        showPopup = true
        popupData = {type = "citizen", index = param}
        
    elseif action == "popup_workorder" then
        showPopup = true
        popupData = {type = "workorder", index = param}
        
    elseif action == "popup_building" then
        showPopup = true
        popupData = {type = "building", index = param}
        
    elseif action == "export_single" then
        exportMaterials(param)
        
    elseif action == "export_all" then
        exportMaterials(nil)
        
    elseif action == "set_theme" then
        currentTheme = param
        theme = themes[param]
        saveConfig()
        
    elseif action == "set_scale" then
        CONFIG.textScale = param
        mon.setTextScale(param)
        screenW, screenH = mon.getSize()
        contentX = CONFIG.menuWidth + 1
        contentW = screenW - CONFIG.menuWidth
        saveConfig()
        
    elseif action == "set_refresh" then
        CONFIG.refreshRate = param
        saveConfig()
        
    elseif action == "set_items_per_page" then
        CONFIG.itemsPerPage = param
        pageNumbers = {}
        saveConfig()
        
    elseif action == "set_sound_interval" then
        CONFIG.alertSoundInterval = param
        saveConfig()
        
    elseif action == "reset_history" then
        showPopup = true
        popupData = {
            type = "confirm",
            title = "Effacer historique?",
            message = "Toutes les stats seront perdues!",
            yesAction = "confirm_reset",
        }
        
    elseif action == "test_alert" then
        -- Simuler une attaque pendant 5 secondes
        testAlertUntil = os.epoch("utc") / 1000 + 5
        if speaker then
            speaker.playSound(CONFIG.alertSound, 1, 1)
        end
        showPopup = true
        popupData = {type = "success", message = "Test d'alerte active pour 5s"}
        
    elseif action == "test_sound" then
        if speaker then
            speaker.playSound(CONFIG.alertSound, 1, 1)
            showPopup = true
            popupData = {type = "success", message = "Son joue!"}
        else
            showPopup = true
            popupData = {type = "error", message = "Speaker non connecte!"}
        end
        
    elseif action == "close_popup" then
        showPopup = false
        popupData = nil
    end
end

-- ============================================
-- BOUCLE PRINCIPALE
-- ============================================
local function playAlertSound()
    if speaker then
        speaker.playSound(CONFIG.alertSound, 1, 1)
    end
end

local function main()
    term.clear()
    term.setCursorPos(1, 1)
    
    if not initPeripherals() then return end
    
    local refreshTimer = os.startTimer(CONFIG.refreshRate)
    local blinkTimer = os.startTimer(0.5)
    local soundTimer = os.startTimer(CONFIG.alertSoundInterval)
    
    while true do
        refreshData()
        render()
        
        -- Jouer son en boucle si alerte active
        local now = os.epoch("utc") / 1000
        if isAlertActive() and (now - lastAlertSound) >= CONFIG.alertSoundInterval then
            playAlertSound()
            lastAlertSound = now
        end
        
        local event, p1, p2, p3 = os.pullEvent()
        
        if event == "timer" then
            if p1 == refreshTimer then
                refreshTimer = os.startTimer(CONFIG.refreshRate)
            elseif p1 == blinkTimer then
                blinkTimer = os.startTimer(0.5)
            elseif p1 == soundTimer then
                soundTimer = os.startTimer(CONFIG.alertSoundInterval)
            end
            
        elseif event == "monitor_touch" then
            handleClick(p2, p3)
            
        elseif event == "key" and p1 == keys.q then
            mon.setBackgroundColor(colors.black)
            mon.clear()
            print("Dashboard arrete.")
            return
        end
    end
end

main()
