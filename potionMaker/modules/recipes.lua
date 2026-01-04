-- ============================================
-- Potion Maker - Module Recettes
-- Craft intelligent avec enchaînement d'étapes
-- ============================================

local Recipes = {}

local RECIPES_PATH = "data/recipes.json"

-- Charger les recettes depuis le fichier JSON
function Recipes.load()
    if not fs.exists(RECIPES_PATH) then
        return Recipes.getDefaultRecipes()
    end
    
    local file = fs.open(RECIPES_PATH, "r")
    if not file then
        return Recipes.getDefaultRecipes()
    end
    
    local content = file.readAll()
    file.close()
    
    local ok, data = pcall(textutils.unserialiseJSON, content)
    if ok and data then
        return data
    end
    
    return Recipes.getDefaultRecipes()
end

-- Sauvegarder les recettes
function Recipes.save(recipes)
    if not fs.exists("data") then
        fs.makeDir("data")
    end
    
    local file = fs.open(RECIPES_PATH, "w")
    if not file then
        return false
    end
    
    file.write(textutils.serialiseJSON(recipes))
    file.close()
    return true
end

-- Recettes par défaut (Vanilla 1.21)
function Recipes.getDefaultRecipes()
    return {
        -- Base potions
        bases = {
            awkward = {
                id = "minecraft:potion",
                nbt = "Potion:\"minecraft:awkward\"",
                name = "Potion etrange",
                ingredient = "minecraft:nether_wart",
                base = "water_bottle"
            },
            mundane = {
                id = "minecraft:potion",
                nbt = "Potion:\"minecraft:mundane\"",
                name = "Potion banale",
                ingredient = "minecraft:redstone",
                base = "water_bottle"
            },
            thick = {
                id = "minecraft:potion",
                nbt = "Potion:\"minecraft:thick\"",
                name = "Potion epaisse",
                ingredient = "minecraft:glowstone_dust",
                base = "water_bottle"
            }
        },
        
        -- Potions principales
        potions = {
            -- Potions de soin
            healing = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:healing\"",
                nbt_strong = "Potion:\"minecraft:strong_healing\"",
                name = "Potion de soin",
                ingredient = "minecraft:glistering_melon_slice",
                base = "awkward",
                can_extend = false,
                can_amplify = true
            },
            
            -- Potion de régénération
            regeneration = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:regeneration\"",
                nbt_long = "Potion:\"minecraft:long_regeneration\"",
                nbt_strong = "Potion:\"minecraft:strong_regeneration\"",
                name = "Potion de regeneration",
                ingredient = "minecraft:ghast_tear",
                base = "awkward",
                can_extend = true,
                can_amplify = true
            },
            
            -- Potion de force
            strength = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:strength\"",
                nbt_long = "Potion:\"minecraft:long_strength\"",
                nbt_strong = "Potion:\"minecraft:strong_strength\"",
                name = "Potion de force",
                ingredient = "minecraft:blaze_powder",
                base = "awkward",
                can_extend = true,
                can_amplify = true
            },
            
            -- Potion de rapidité
            swiftness = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:swiftness\"",
                nbt_long = "Potion:\"minecraft:long_swiftness\"",
                nbt_strong = "Potion:\"minecraft:strong_swiftness\"",
                name = "Potion de rapidite",
                ingredient = "minecraft:sugar",
                base = "awkward",
                can_extend = true,
                can_amplify = true
            },
            
            -- Potion de saut
            leaping = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:leaping\"",
                nbt_long = "Potion:\"minecraft:long_leaping\"",
                nbt_strong = "Potion:\"minecraft:strong_leaping\"",
                name = "Potion de saut",
                ingredient = "minecraft:rabbit_foot",
                base = "awkward",
                can_extend = true,
                can_amplify = true
            },
            
            -- Potion de résistance au feu
            fire_resistance = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:fire_resistance\"",
                nbt_long = "Potion:\"minecraft:long_fire_resistance\"",
                name = "Potion de resistance au feu",
                ingredient = "minecraft:magma_cream",
                base = "awkward",
                can_extend = true,
                can_amplify = false
            },
            
            -- Potion de respiration aquatique
            water_breathing = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:water_breathing\"",
                nbt_long = "Potion:\"minecraft:long_water_breathing\"",
                name = "Potion de respiration aquatique",
                ingredient = "minecraft:pufferfish",
                base = "awkward",
                can_extend = true,
                can_amplify = false
            },
            
            -- Potion de vision nocturne
            night_vision = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:night_vision\"",
                nbt_long = "Potion:\"minecraft:long_night_vision\"",
                name = "Potion de vision nocturne",
                ingredient = "minecraft:golden_carrot",
                base = "awkward",
                can_extend = true,
                can_amplify = false
            },
            
            -- Potion d'invisibilité (dérivée de vision nocturne)
            invisibility = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:invisibility\"",
                nbt_long = "Potion:\"minecraft:long_invisibility\"",
                name = "Potion d'invisibilite",
                ingredient = "minecraft:fermented_spider_eye",
                base = "night_vision",
                can_extend = true,
                can_amplify = false
            },
            
            -- Potion de poison
            poison = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:poison\"",
                nbt_long = "Potion:\"minecraft:long_poison\"",
                nbt_strong = "Potion:\"minecraft:strong_poison\"",
                name = "Potion de poison",
                ingredient = "minecraft:spider_eye",
                base = "awkward",
                can_extend = true,
                can_amplify = true
            },
            
            -- Potion de dégâts (dérivée de soin ou poison)
            harming = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:harming\"",
                nbt_strong = "Potion:\"minecraft:strong_harming\"",
                name = "Potion de degats",
                ingredient = "minecraft:fermented_spider_eye",
                base = "healing", -- ou poison
                alternate_base = "poison",
                can_extend = false,
                can_amplify = true
            },
            
            -- Potion de lenteur (dérivée de rapidité ou saut)
            slowness = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:slowness\"",
                nbt_long = "Potion:\"minecraft:long_slowness\"",
                nbt_strong = "Potion:\"minecraft:strong_slowness\"",
                name = "Potion de lenteur",
                ingredient = "minecraft:fermented_spider_eye",
                base = "swiftness",
                alternate_base = "leaping",
                can_extend = true,
                can_amplify = true
            },
            
            -- Potion de faiblesse
            weakness = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:weakness\"",
                nbt_long = "Potion:\"minecraft:long_weakness\"",
                name = "Potion de faiblesse",
                ingredient = "minecraft:fermented_spider_eye",
                base = "water_bottle",
                can_extend = true,
                can_amplify = false
            },
            
            -- Potion de chute lente
            slow_falling = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:slow_falling\"",
                nbt_long = "Potion:\"minecraft:long_slow_falling\"",
                name = "Potion de chute lente",
                ingredient = "minecraft:phantom_membrane",
                base = "awkward",
                can_extend = true,
                can_amplify = false
            },
            
            -- Potion du Maître Tortue
            turtle_master = {
                id = "minecraft:potion",
                nbt_normal = "Potion:\"minecraft:turtle_master\"",
                nbt_long = "Potion:\"minecraft:long_turtle_master\"",
                nbt_strong = "Potion:\"minecraft:strong_turtle_master\"",
                name = "Potion du Maitre Tortue",
                ingredient = "minecraft:turtle_helmet",
                base = "awkward",
                can_extend = true,
                can_amplify = true
            }
        },
        
        -- Modificateurs
        modifiers = {
            extend = {
                ingredient = "minecraft:redstone",
                name = "Prolongee"
            },
            amplify = {
                ingredient = "minecraft:glowstone_dust",
                name = "Renforcee (II)"
            },
            splash = {
                ingredient = "minecraft:gunpowder",
                name = "Splash"
            },
            lingering = {
                ingredient = "minecraft:dragon_breath",
                name = "Persistante"
            }
        },
        
        -- Items de base
        items = {
            water_bottle = {
                id = "minecraft:potion",
                nbt = "Potion:\"minecraft:water\"",
                name = "Fiole d'eau"
            },
            glass_bottle = {
                id = "minecraft:glass_bottle",
                name = "Fiole vide"
            }
        }
    }
end

-- Obtenir la liste des potions disponibles
function Recipes.getPotionList(recipes)
    local list = {}
    for key, potion in pairs(recipes.potions) do
        table.insert(list, {
            key = key,
            name = potion.name,
            can_extend = potion.can_extend,
            can_amplify = potion.can_amplify
        })
    end
    -- Trier par nom
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

-- Calculer les étapes de craft intelligent
-- Retourne une liste d'étapes à suivre pour créer la potion demandée
function Recipes.calculateCraftSteps(recipes, potionKey, variant, form)
    -- variant: "normal", "extended", "amplified"
    -- form: "normal", "splash", "lingering"
    
    local steps = {}
    local potion = recipes.potions[potionKey]
    
    if not potion then
        return nil, "Potion inconnue: " .. potionKey
    end
    
    -- Étape 1: Résoudre la base
    local baseSteps = Recipes.resolveBase(recipes, potion.base)
    for _, step in ipairs(baseSteps) do
        table.insert(steps, step)
    end
    
    -- Étape 2: Créer la potion de base
    table.insert(steps, {
        type = "brew",
        ingredient = potion.ingredient,
        description = "Creer " .. potion.name
    })
    
    -- Étape 3: Appliquer le variant (prolongée/renforcée)
    if variant == "extended" then
        if potion.can_extend then
            table.insert(steps, {
                type = "brew",
                ingredient = recipes.modifiers.extend.ingredient,
                description = "Prolonger la duree"
            })
        else
            return nil, "Cette potion ne peut pas etre prolongee"
        end
    elseif variant == "amplified" then
        if potion.can_amplify then
            table.insert(steps, {
                type = "brew",
                ingredient = recipes.modifiers.amplify.ingredient,
                description = "Renforcer l'effet"
            })
        else
            return nil, "Cette potion ne peut pas etre renforcee"
        end
    end
    
    -- Étape 4: Appliquer la forme (splash/lingering)
    if form == "splash" then
        table.insert(steps, {
            type = "brew",
            ingredient = recipes.modifiers.splash.ingredient,
            description = "Transformer en splash"
        })
    elseif form == "lingering" then
        -- Lingering nécessite d'abord splash
        table.insert(steps, {
            type = "brew",
            ingredient = recipes.modifiers.splash.ingredient,
            description = "Transformer en splash"
        })
        table.insert(steps, {
            type = "brew",
            ingredient = recipes.modifiers.lingering.ingredient,
            description = "Transformer en persistante"
        })
    end
    
    return steps, nil
end

-- Résoudre récursivement la base d'une potion
function Recipes.resolveBase(recipes, baseKey)
    local steps = {}
    
    if baseKey == "water_bottle" then
        -- Point de départ, pas d'étape à ajouter
        table.insert(steps, {
            type = "source",
            item = "water_bottle",
            description = "Utiliser fiole d'eau"
        })
        return steps
    end
    
    -- Vérifier si c'est une potion de base (awkward, mundane, thick)
    local base = recipes.bases[baseKey]
    if base then
        -- Résoudre la base de cette base
        local subSteps = Recipes.resolveBase(recipes, base.base)
        for _, step in ipairs(subSteps) do
            table.insert(steps, step)
        end
        
        table.insert(steps, {
            type = "brew",
            ingredient = base.ingredient,
            description = "Creer " .. base.name
        })
        return steps
    end
    
    -- C'est une potion intermédiaire (ex: invisibilité basée sur vision nocturne)
    local potion = recipes.potions[baseKey]
    if potion then
        -- Résoudre la base de cette potion
        local subSteps = Recipes.resolveBase(recipes, potion.base)
        for _, step in ipairs(subSteps) do
            table.insert(steps, step)
        end
        
        table.insert(steps, {
            type = "brew",
            ingredient = potion.ingredient,
            description = "Creer " .. potion.name .. " (intermediaire)"
        })
        return steps
    end
    
    return steps
end

-- Calculer les ingrédients nécessaires pour une commande
function Recipes.calculateIngredients(recipes, potionKey, variant, form, quantity)
    local steps, err = Recipes.calculateCraftSteps(recipes, potionKey, variant, form)
    if not steps then
        return nil, err
    end
    
    local ingredients = {}
    local waterBottles = 0
    
    for _, step in ipairs(steps) do
        if step.type == "source" then
            waterBottles = waterBottles + quantity
        elseif step.type == "brew" then
            ingredients[step.ingredient] = (ingredients[step.ingredient] or 0) + quantity
        end
    end
    
    return {
        water_bottles = waterBottles,
        ingredients = ingredients,
        steps = steps
    }, nil
end

-- Obtenir le nom complet d'une potion
function Recipes.getFullPotionName(recipes, potionKey, variant, form)
    local potion = recipes.potions[potionKey]
    if not potion then return "Potion inconnue" end
    
    local name = potion.name
    
    if variant == "extended" then
        name = name .. " +"
    elseif variant == "amplified" then
        name = name .. " II"
    end
    
    if form == "splash" then
        name = name .. " (Splash)"
    elseif form == "lingering" then
        name = name .. " (Persistante)"
    end
    
    return name
end

-- Obtenir le NBT correspondant à une potion
function Recipes.getPotionNBT(recipes, potionKey, variant, form)
    local potion = recipes.potions[potionKey]
    if not potion then return nil end
    
    local nbt
    if variant == "extended" and potion.nbt_long then
        nbt = potion.nbt_long
    elseif variant == "amplified" and potion.nbt_strong then
        nbt = potion.nbt_strong
    else
        nbt = potion.nbt_normal
    end
    
    -- Modifier l'ID selon la forme
    local id = "minecraft:potion"
    if form == "splash" then
        id = "minecraft:splash_potion"
    elseif form == "lingering" then
        id = "minecraft:lingering_potion"
    end
    
    return {
        id = id,
        nbt = nbt
    }
end

-- Ajouter une nouvelle recette
function Recipes.addRecipe(recipes, key, recipeData)
    recipes.potions[key] = recipeData
    return Recipes.save(recipes)
end

-- Supprimer une recette
function Recipes.removeRecipe(recipes, key)
    recipes.potions[key] = nil
    return Recipes.save(recipes)
end

return Recipes
