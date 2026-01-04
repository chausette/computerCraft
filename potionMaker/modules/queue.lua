-- ============================================
-- Potion Maker - Module Queue
-- File d'attente FIFO persistante
-- ============================================

local Queue = {}

local QUEUE_PATH = "data/queue.json"

-- Structure de la file
local queue = {
    commands = {},
    nextId = 1
}

-- Charger la file depuis le fichier
function Queue.load()
    if not fs.exists(QUEUE_PATH) then
        queue = { commands = {}, nextId = 1 }
        return queue
    end
    
    local file = fs.open(QUEUE_PATH, "r")
    if not file then
        queue = { commands = {}, nextId = 1 }
        return queue
    end
    
    local content = file.readAll()
    file.close()
    
    local ok, data = pcall(textutils.unserialiseJSON, content)
    if ok and data then
        queue = data
        if not queue.commands then queue.commands = {} end
        if not queue.nextId then queue.nextId = 1 end
    else
        queue = { commands = {}, nextId = 1 }
    end
    
    return queue
end

-- Sauvegarder la file
function Queue.save()
    if not fs.exists("data") then
        fs.makeDir("data")
    end
    
    local file = fs.open(QUEUE_PATH, "w")
    if not file then
        return false
    end
    
    file.write(textutils.serialiseJSON(queue))
    file.close()
    return true
end

-- Ajouter une commande à la file
function Queue.add(command)
    local newCommand = {
        id = queue.nextId,
        potion = command.potion,
        variant = command.variant or "normal",  -- normal, extended, amplified
        form = command.form or "normal",         -- normal, splash, lingering
        quantity = command.quantity or 3,
        status = "pending",                      -- pending, processing, completed, failed
        addedAt = os.epoch("utc"),
        startedAt = nil,
        completedAt = nil,
        error = nil,
        source = command.source or "monitor"     -- monitor, pocket
    }
    
    table.insert(queue.commands, newCommand)
    queue.nextId = queue.nextId + 1
    
    Queue.save()
    
    return newCommand.id
end

-- Obtenir la prochaine commande en attente
function Queue.getNext()
    for i, cmd in ipairs(queue.commands) do
        if cmd.status == "pending" then
            return cmd, i
        end
    end
    return nil, nil
end

-- Marquer une commande comme en cours
function Queue.markProcessing(commandId)
    for i, cmd in ipairs(queue.commands) do
        if cmd.id == commandId then
            cmd.status = "processing"
            cmd.startedAt = os.epoch("utc")
            Queue.save()
            return true
        end
    end
    return false
end

-- Marquer une commande comme terminée
function Queue.markCompleted(commandId, produced)
    for i, cmd in ipairs(queue.commands) do
        if cmd.id == commandId then
            cmd.status = "completed"
            cmd.completedAt = os.epoch("utc")
            cmd.produced = produced or cmd.quantity
            Queue.save()
            return true
        end
    end
    return false
end

-- Marquer une commande comme échouée
function Queue.markFailed(commandId, error)
    for i, cmd in ipairs(queue.commands) do
        if cmd.id == commandId then
            cmd.status = "failed"
            cmd.completedAt = os.epoch("utc")
            cmd.error = error
            Queue.save()
            return true
        end
    end
    return false
end

-- Supprimer une commande
function Queue.remove(commandId)
    for i, cmd in ipairs(queue.commands) do
        if cmd.id == commandId then
            table.remove(queue.commands, i)
            Queue.save()
            return true
        end
    end
    return false
end

-- Obtenir toutes les commandes
function Queue.getAll()
    return queue.commands
end

-- Obtenir les commandes en attente
function Queue.getPending()
    local pending = {}
    for _, cmd in ipairs(queue.commands) do
        if cmd.status == "pending" then
            table.insert(pending, cmd)
        end
    end
    return pending
end

-- Obtenir les commandes en cours
function Queue.getProcessing()
    local processing = {}
    for _, cmd in ipairs(queue.commands) do
        if cmd.status == "processing" then
            table.insert(processing, cmd)
        end
    end
    return processing
end

-- Obtenir les commandes terminées (historique)
function Queue.getCompleted(limit)
    local completed = {}
    for _, cmd in ipairs(queue.commands) do
        if cmd.status == "completed" or cmd.status == "failed" then
            table.insert(completed, cmd)
        end
    end
    
    -- Trier par date de complétion (plus récent en premier)
    table.sort(completed, function(a, b)
        return (a.completedAt or 0) > (b.completedAt or 0)
    end)
    
    -- Limiter si demandé
    if limit and #completed > limit then
        local limited = {}
        for i = 1, limit do
            table.insert(limited, completed[i])
        end
        return limited
    end
    
    return completed
end

-- Obtenir une commande par ID
function Queue.getById(commandId)
    for _, cmd in ipairs(queue.commands) do
        if cmd.id == commandId then
            return cmd
        end
    end
    return nil
end

-- Compter les commandes par statut
function Queue.count()
    local counts = {
        total = #queue.commands,
        pending = 0,
        processing = 0,
        completed = 0,
        failed = 0
    }
    
    for _, cmd in ipairs(queue.commands) do
        counts[cmd.status] = (counts[cmd.status] or 0) + 1
    end
    
    return counts
end

-- Nettoyer l'historique (garder les N dernières terminées)
function Queue.cleanup(keepCount)
    keepCount = keepCount or 50
    
    local completed = Queue.getCompleted()
    local toRemove = {}
    
    -- Marquer les anciennes commandes à supprimer
    for i = keepCount + 1, #completed do
        table.insert(toRemove, completed[i].id)
    end
    
    -- Supprimer
    for _, id in ipairs(toRemove) do
        Queue.remove(id)
    end
    
    return #toRemove
end

-- Réinitialiser une commande échouée
function Queue.retry(commandId)
    for i, cmd in ipairs(queue.commands) do
        if cmd.id == commandId and cmd.status == "failed" then
            cmd.status = "pending"
            cmd.error = nil
            cmd.startedAt = nil
            cmd.completedAt = nil
            Queue.save()
            return true
        end
    end
    return false
end

-- Annuler une commande en attente
function Queue.cancel(commandId)
    for i, cmd in ipairs(queue.commands) do
        if cmd.id == commandId and cmd.status == "pending" then
            table.remove(queue.commands, i)
            Queue.save()
            return true
        end
    end
    return false
end

-- Vider la file (sauf en cours)
function Queue.clear()
    local newCommands = {}
    
    for _, cmd in ipairs(queue.commands) do
        if cmd.status == "processing" then
            table.insert(newCommands, cmd)
        end
    end
    
    queue.commands = newCommands
    Queue.save()
end

-- Obtenir la position dans la file
function Queue.getPosition(commandId)
    local position = 0
    
    for _, cmd in ipairs(queue.commands) do
        if cmd.status == "pending" then
            position = position + 1
            if cmd.id == commandId then
                return position
            end
        end
    end
    
    return nil -- Non trouvé ou pas en attente
end

return Queue
