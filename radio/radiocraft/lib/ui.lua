-- RadioCraft - UI Manager
-- Interface utilisateur sur moniteur tactile

local UI = {}
UI.__index = UI

-- Couleurs du thème
UI.COLORS = {
    bg = colors.black,
    fg = colors.white,
    accent = colors.cyan,
    accent2 = colors.purple,
    success = colors.lime,
    warning = colors.orange,
    error = colors.red,
    muted = colors.gray,
    highlight = colors.lightBlue,
    button = colors.blue,
    buttonText = colors.white,
    selected = colors.cyan,
    progress = colors.lime,
    progressBg = colors.gray,
}

function UI.new(monitor)
    local self = setmetatable({}, UI)
    self.monitor = monitor
    self.width, self.height = monitor.getSize()
    self.currentTab = "jukebox"
    self.scrollOffset = {}
    self.buttons = {}
    self.touchAreas = {}
    return self
end

-- Clear l'écran
function UI:clear()
    self.monitor.setBackgroundColor(UI.COLORS.bg)
    self.monitor.clear()
    self.buttons = {}
    self.touchAreas = {}
end

-- Dessine du texte
function UI:text(x, y, text, fg, bg)
    self.monitor.setCursorPos(x, y)
    if fg then self.monitor.setTextColor(fg) end
    if bg then self.monitor.setBackgroundColor(bg) end
    self.monitor.write(text)
end

-- Dessine un texte centré
function UI:centerText(y, text, fg, bg)
    local x = math.floor((self.width - #text) / 2) + 1
    self:text(x, y, text, fg, bg)
end

-- Dessine un rectangle
function UI:rect(x, y, w, h, color)
    self.monitor.setBackgroundColor(color)
    for dy = 0, h - 1 do
        self.monitor.setCursorPos(x, y + dy)
        self.monitor.write(string.rep(" ", w))
    end
end

-- Dessine un bouton
function UI:button(x, y, w, h, text, id, active)
    local bg = active and UI.COLORS.selected or UI.COLORS.button
    local fg = UI.COLORS.buttonText
    
    self:rect(x, y, w, h, bg)
    
    -- Centre le texte
    local textX = x + math.floor((w - #text) / 2)
    local textY = y + math.floor(h / 2)
    self:text(textX, textY, text, fg, bg)
    
    -- Enregistre la zone cliquable
    table.insert(self.buttons, {
        id = id,
        x1 = x, y1 = y,
        x2 = x + w - 1, y2 = y + h - 1
    })
end

-- Dessine une barre de progression
function UI:progressBar(x, y, w, progress, max)
    max = max or 100
    local filled = math.floor((progress / max) * w)
    
    self.monitor.setCursorPos(x, y)
    self.monitor.setBackgroundColor(UI.COLORS.progress)
    self.monitor.write(string.rep(" ", filled))
    self.monitor.setBackgroundColor(UI.COLORS.progressBg)
    self.monitor.write(string.rep(" ", w - filled))
    self.monitor.setBackgroundColor(UI.COLORS.bg)
    
    -- Zone cliquable pour seek
    table.insert(self.touchAreas, {
        id = "progress_bar",
        x1 = x, y1 = y,
        x2 = x + w - 1, y2 = y,
        data = {width = w}
    })
end

-- Dessine le header avec tabs
function UI:drawHeader()
    local tabs = {
        {id = "jukebox", label = "JUKEBOX"},
        {id = "ambiance", label = "AMBIANCE"},
        {id = "composer", label = "COMPOSER"},
        {id = "settings", label = "CONFIG"},
    }
    
    self:rect(1, 1, self.width, 2, UI.COLORS.accent2)
    self:centerText(1, "= RadioCraft =", UI.COLORS.buttonText, UI.COLORS.accent2)
    
    local tabWidth = math.floor(self.width / #tabs)
    for i, tab in ipairs(tabs) do
        local x = (i - 1) * tabWidth + 1
        local active = self.currentTab == tab.id
        local bg = active and UI.COLORS.selected or UI.COLORS.muted
        local fg = UI.COLORS.buttonText
        
        self:rect(x, 2, tabWidth, 1, bg)
        local labelX = x + math.floor((tabWidth - #tab.label) / 2)
        self:text(labelX, 2, tab.label, fg, bg)
        
        table.insert(self.buttons, {
            id = "tab_" .. tab.id,
            x1 = x, y1 = 2,
            x2 = x + tabWidth - 1, y2 = 2
        })
    end
end

-- Dessine le footer avec contrôles
function UI:drawFooter(player)
    local y = self.height - 1
    
    self:rect(1, y, self.width, 2, UI.COLORS.muted)
    
    -- Contrôles de lecture
    local controls = {
        {id = "prev", label = "|<", x = 2},
        {id = "stop", label = "[]", x = 6},
        {id = "play", label = player and player:isPlaying() and "||" or ">", x = 10},
        {id = "next", label = ">|", x = 14},
        {id = "shuffle", label = "~", x = 19, active = player and player.shuffle},
        {id = "repeat", label = player and (player.repeatMode == "one" and "1" or player.repeatMode == "all" and "@" or "-"), x = 23},
    }
    
    for _, ctrl in ipairs(controls) do
        local bg = ctrl.active and UI.COLORS.selected or UI.COLORS.button
        self:rect(ctrl.x, y, 3, 1, bg)
        self:text(ctrl.x, y, ctrl.label, UI.COLORS.buttonText, bg)
        
        table.insert(self.buttons, {
            id = "ctrl_" .. ctrl.id,
            x1 = ctrl.x, y1 = y,
            x2 = ctrl.x + 2, y2 = y
        })
    end
    
    -- Volume
    local volX = self.width - 10
    self:text(volX, y, "Vol:", UI.COLORS.fg, UI.COLORS.muted)
    local vol = player and player.speakers and player.speakers.masterVolume or 1
    self:progressBar(volX + 4, y, 6, vol, 1)
    
    -- Now playing
    if player and player:getCurrentTrack() then
        local track = player:getCurrentTrack()
        local name = track.name or "Unknown"
        if #name > self.width - 4 then
            name = string.sub(name, 1, self.width - 7) .. "..."
        end
        self:centerText(self.height, name, UI.COLORS.accent, UI.COLORS.muted)
    end
end

-- Dessine l'onglet Jukebox
function UI:drawJukebox(player, discs)
    local y = 4
    
    self:text(2, y, "Disques disponibles:", UI.COLORS.accent)
    y = y + 1
    
    discs = discs or {
        {id = "cat", name = "Cat", author = "C418"},
        {id = "blocks", name = "Blocks", author = "C418"},
        {id = "chirp", name = "Chirp", author = "C418"},
        {id = "far", name = "Far", author = "C418"},
        {id = "mall", name = "Mall", author = "C418"},
        {id = "mellohi", name = "Mellohi", author = "C418"},
        {id = "stal", name = "Stal", author = "C418"},
        {id = "strad", name = "Strad", author = "C418"},
        {id = "ward", name = "Ward", author = "C418"},
        {id = "wait", name = "Wait", author = "C418"},
        {id = "pigstep", name = "Pigstep", author = "Lena Raine"},
        {id = "otherside", name = "Otherside", author = "Lena Raine"},
    }
    
    local offset = self.scrollOffset.jukebox or 0
    local visible = self.height - 8
    
    for i = 1, visible do
        local idx = i + offset
        if idx <= #discs then
            local disc = discs[idx]
            local isPlaying = player and player:getCurrentTrack() 
                and player:getCurrentTrack().name == disc.name
            
            local bg = isPlaying and UI.COLORS.selected or UI.COLORS.bg
            local fg = isPlaying and UI.COLORS.buttonText or UI.COLORS.fg
            
            self:rect(2, y, self.width - 2, 1, bg)
            self:text(2, y, string.format("%-12s %s", disc.name, disc.author), fg, bg)
            
            table.insert(self.buttons, {
                id = "disc_" .. disc.id,
                x1 = 2, y1 = y,
                x2 = self.width - 1, y2 = y
            })
            
            y = y + 1
        end
    end
    
    -- Scroll indicators
    if offset > 0 then
        self:text(self.width, 4, "^", UI.COLORS.accent)
    end
    if offset + visible < #discs then
        self:text(self.width, self.height - 4, "v", UI.COLORS.accent)
    end
end

-- Dessine l'onglet Ambiance
function UI:drawAmbiance(ambiance)
    local y = 4
    
    self:text(2, y, "Stations d'ambiance:", UI.COLORS.accent)
    y = y + 1
    
    local stations = ambiance:getStations()
    local current = ambiance:getCurrentStation()
    
    for _, station in ipairs(stations) do
        local isPlaying = current and current.id == station.id
        local bg = isPlaying and UI.COLORS.selected or UI.COLORS.bg
        local fg = isPlaying and UI.COLORS.buttonText or UI.COLORS.fg
        
        self:rect(2, y, self.width - 2, 1, bg)
        self:text(2, y, string.format("[%s] %s", station.icon, station.name), fg, bg)
        
        if isPlaying then
            self:text(self.width - 4, y, " ON ", UI.COLORS.success, bg)
        end
        
        table.insert(self.buttons, {
            id = "station_" .. station.id,
            x1 = 2, y1 = y,
            x2 = self.width - 1, y2 = y
        })
        
        y = y + 1
    end
    
    -- Volume ambiance
    y = y + 1
    self:text(2, y, "Volume:", UI.COLORS.fg)
    self:progressBar(10, y, self.width - 12, ambiance:getVolume(), 1)
end

-- Dessine l'onglet Composer (simplifié)
function UI:drawComposer(composer)
    local y = 4
    
    local comp = composer:getComposition()
    self:text(2, y, "Composition: " .. comp.name, UI.COLORS.accent)
    y = y + 1
    self:text(2, y, "BPM: " .. comp.bpm .. " | Pistes: " .. composer:getTrackCount(), UI.COLORS.muted)
    y = y + 2
    
    -- Boutons de contrôle
    self:button(2, y, 8, 1, "Nouveau", "comp_new", false)
    self:button(11, y, 10, 1, "Charger", "comp_load", false)
    self:button(22, y, 10, 1, "Sauver", "comp_save", false)
    y = y + 2
    
    -- Pistes
    self:text(2, y, "Pistes:", UI.COLORS.accent)
    y = y + 1
    
    for i, track in ipairs(composer:getTracks()) do
        local isCurrent = i == composer:getCurrentTrack()
        local bg = isCurrent and UI.COLORS.selected or UI.COLORS.bg
        local fg = isCurrent and UI.COLORS.buttonText or UI.COLORS.fg
        
        self:rect(2, y, self.width - 2, 1, bg)
        self:text(2, y, string.format("%d. %s (%d notes)", i, track.instrument, #track.notes), fg, bg)
        
        table.insert(self.buttons, {
            id = "track_" .. i,
            x1 = 2, y1 = y,
            x2 = self.width - 1, y2 = y
        })
        
        y = y + 1
    end
    
    y = y + 1
    self:button(2, y, 12, 1, "+ Piste", "comp_add_track", false)
    
    -- Instructions
    y = self.height - 5
    self:text(2, y, "Utilisez l'editeur avance", UI.COLORS.muted)
    y = y + 1
    self:text(2, y, "avec 'edit' pour composer", UI.COLORS.muted)
end

-- Dessine l'onglet Settings
function UI:drawSettings(speakers, player)
    local y = 4
    
    self:text(2, y, "Speakers connectes:", UI.COLORS.accent)
    y = y + 1
    
    local speakerList = speakers:list()
    if #speakerList == 0 then
        self:text(2, y, "Aucun speaker trouve!", UI.COLORS.error)
    else
        for _, spk in ipairs(speakerList) do
            self:text(2, y, string.format("- %s [%s]", spk.name, spk.zone), UI.COLORS.fg)
            y = y + 1
        end
    end
    
    y = y + 1
    self:text(2, y, "Zones:", UI.COLORS.accent)
    y = y + 1
    
    local zones = speakers:listZones()
    for _, zone in ipairs(zones) do
        self:text(2, y, string.format("%s: %d spk, vol %.0f%%", 
            zone.name, zone.count, zone.volume * 100), UI.COLORS.fg)
        y = y + 1
    end
    
    y = y + 1
    self:text(2, y, "Volume Master:", UI.COLORS.accent)
    y = y + 1
    self:progressBar(2, y, self.width - 4, speakers.masterVolume, 1)
    
    y = y + 2
    self:button(2, y, 15, 1, "Rafraichir", "refresh_speakers", false)
    self:button(18, y, 15, 1, "Test son", "test_sound", false)
end

-- Dessine tout l'écran
function UI:draw(player, ambiance, composer, speakers)
    self:clear()
    self:drawHeader()
    
    if self.currentTab == "jukebox" then
        self:drawJukebox(player)
    elseif self.currentTab == "ambiance" then
        self:drawAmbiance(ambiance)
    elseif self.currentTab == "composer" then
        self:drawComposer(composer)
    elseif self.currentTab == "settings" then
        self:drawSettings(speakers, player)
    end
    
    self:drawFooter(player)
    
    -- Reset colors
    self.monitor.setBackgroundColor(UI.COLORS.bg)
    self.monitor.setTextColor(UI.COLORS.fg)
end

-- Gère un clic
function UI:handleClick(x, y)
    -- Cherche dans les boutons
    for _, btn in ipairs(self.buttons) do
        if x >= btn.x1 and x <= btn.x2 and y >= btn.y1 and y <= btn.y2 then
            return btn.id
        end
    end
    
    -- Cherche dans les zones tactiles
    for _, area in ipairs(self.touchAreas) do
        if x >= area.x1 and x <= area.x2 and y >= area.y1 and y <= area.y2 then
            return area.id, x - area.x1, area.data
        end
    end
    
    return nil
end

-- Change d'onglet
function UI:setTab(tab)
    self.currentTab = tab
end

-- Scroll
function UI:scroll(tab, direction)
    self.scrollOffset[tab] = (self.scrollOffset[tab] or 0) + direction
    if self.scrollOffset[tab] < 0 then
        self.scrollOffset[tab] = 0
    end
end

return UI
