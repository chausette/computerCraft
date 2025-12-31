# Système de Stockage ComputerCraft

Un système complet de gestion d'inventaire avec tri automatique, recherche, favoris et contrôle à distance via Pocket Computer.

## 📦 Contenu

- `config.lua` - Configuration (coffres, catégories, favoris)
- `storage.lua` - Gestion de l'inventaire et des transferts
- `network.lua` - Communication serveur/client
- `ui_monitor.lua` - Interface graphique moniteur
- `startup.lua` - Programme principal serveur
- `pocket_client.lua` - Client pour Pocket Computer
- `installer.lua` - Assistant d'installation

## 🔧 Prérequis

### Matériel nécessaire

| Élément | Quantité | Utilisation |
|---------|----------|-------------|
| Ordinateur avancé | 1 | Serveur principal |
| Pocket Computer | 1+ | Contrôle à distance |
| Modem sans fil | 2+ | Communication |
| Networking Cable | Variable | Connexion coffres |
| Wired Modem | Variable | Connexion coffres |
| Moniteur | 1+ | Affichage (optionnel) |
| Coffres | 3+ | Entrée, sortie, stockage |

### Mods requis

- **ComputerCraft: Tweaked** (ou CC)
- **CC:T Peripherals** ou équivalent pour les modems câblés

## 🏗️ Architecture

```
                    [Modem Sans Fil]
                          │
    ┌─────────────────────┼─────────────────────┐
    │                ORDINATEUR                 │
    │                 SERVEUR                   │
    └─────────────────────┬─────────────────────┘
                          │
              ┌───────────┼───────────┐
              │    Câble Réseau       │
              │                       │
    ┌─────────┴─────────┐   ┌────────┴────────┐
    │  [Wired Modem]    │   │  [Wired Modem]  │
    │        │          │   │        │        │
    │  [Coffre Entrée]  │   │ [Coffre Sortie] │
    └───────────────────┘   └─────────────────┘
              │
    ┌─────────┴─────────────────────────┐
    │        Coffres de Stockage         │
    │  [Coffre 1] [Coffre 2] [Coffre 3] │
    └────────────────────────────────────┘
```

## 📥 Installation

### Méthode 1 : Copie manuelle

1. **Sur l'ordinateur serveur**, copiez tous les fichiers `.lua` (sauf `pocket_client.lua`)

2. **Sur le Pocket Computer**, copiez uniquement `pocket_client.lua` et renommez-le en `startup.lua`

### Méthode 2 : Via l'installateur

1. Copiez `installer.lua` sur l'ordinateur
2. Exécutez : `installer`
3. Suivez les instructions

## ⚙️ Configuration

### 1. Identifier vos périphériques

Sur l'ordinateur serveur, exécutez :
```lua
peripheral.getNames()
```

Notez les noms de vos coffres (ex: `minecraft:chest_0`)

### 2. Modifier config.lua

```lua
-- Coffre d'entrée (où vous déposez les items)
config.INPUT_CHEST = "minecraft:chest_0"

-- Coffre de sortie (où récupérer les commandes)
config.OUTPUT_CHEST = "minecraft:chest_1"

-- Moniteur (optionnel)
config.MONITOR_NAME = "monitor_0"

-- Coffres de stockage
config.storage_chests = {
    {name = "minecraft:chest_2", category = nil},
    {name = "minecraft:chest_3", category = nil},
    {name = "minecraft:chest_4", category = nil},
    -- Ajoutez autant de coffres que nécessaire
}
```

### 3. Personnaliser les catégories

Les catégories utilisent des **patterns** pour trier automatiquement :

```lua
config.categories = {
    {
        name = "Minerais",
        color = colors.yellow,
        patterns = {"ore", "ingot", "diamond", "iron", "gold"}
    },
    {
        name = "Nourriture",
        color = colors.red,
        patterns = {"apple", "bread", "beef", "carrot"}
    },
    -- La dernière catégorie (Divers) capture tout le reste
}
```

## 🚀 Utilisation

### Démarrage

1. **Serveur** : Redémarrez l'ordinateur ou exécutez `startup`
2. **Pocket** : Allumez-le (démarre automatiquement si renommé en startup)

### Commandes serveur (clavier)

| Touche | Action |
|--------|--------|
| `Q` | Quitter |
| `R` | Rescanner l'inventaire |
| `M` | Changer de page moniteur |
| `S` | Forcer le tri |
| `←` `→` | Navigation pages |

### Menu Pocket

```
[1] Rechercher un item    - Trouver par nom
[2] Favoris               - Accès rapide
[3] Par catégorie         - Parcourir le stock
[4] Vider coffre entrée   - Trier les items déposés
[5] Statistiques          - Vue d'ensemble
[6] Configuration         - Gérer coffres/catégories
[0] Quitter
```

### Commander un item

1. Recherchez ou parcourez les catégories
2. Sélectionnez l'item avec son numéro
3. Choisissez "Commander"
4. Entrez la quantité
5. Récupérez dans le coffre de sortie

### Ajouter un coffre de stockage

**Via le Pocket :**
1. Menu → Configuration → Gérer les coffres
2. `[A]jouter`
3. Sélectionnez un coffre libre

**Via config.lua :**
```lua
config.addChest("minecraft:chest_5", nil)
```

### Gérer les favoris

**Ajouter :**
1. Recherchez l'item
2. Sélectionnez-le
3. "Ajouter aux favoris"

**Supprimer :**
1. Menu → Configuration → Gérer les favoris
2. `[S]upprimer`

## 📊 Affichage Moniteur

Le moniteur affiche 3 pages (touche `M` pour changer) :

### Page Principale
- Statistiques globales
- Barre de capacité
- Alertes de stock bas

### Page Inventaire
- Items groupés par catégorie
- Navigation par pages

### Page Favoris
- Liste des favoris avec quantités
- Indicateur de stock

## 🔄 Tri Automatique

Le serveur trie automatiquement le coffre d'entrée toutes les 5 secondes.

**Logique de tri :**
1. Cherche un coffre contenant déjà cet item (pour regrouper)
2. Sinon, cherche un slot vide dans n'importe quel coffre

## 🚨 Alertes de Stock

Configurez des alertes dans `config.lua` :

```lua
config.stock_alerts = {
    ["minecraft:torch"] = 64,    -- Alerte si < 64 torches
    ["minecraft:coal"] = 32,     -- Alerte si < 32 charbon
}
```

Les alertes s'affichent :
- Sur le moniteur (page principale)
- Dans les statistiques du Pocket

## ❓ Dépannage

### "Serveur non trouvé"
- Vérifiez que le modem sans fil est connecté
- Vérifiez que le serveur est démarré
- Les deux doivent être à portée (32 blocs sans fil)

### "Coffre d'entrée non trouvé"
- Vérifiez le nom dans `config.lua`
- Assurez-vous que le wired modem est connecté et activé (clic droit)

### Items non triés
- Vérifiez qu'il y a de la place dans les coffres de stockage
- Les coffres doivent être connectés au réseau câblé

### Moniteur vide
- Vérifiez le nom du moniteur dans `config.lua`
- Essayez `monitor_0`, `monitor_1`, etc.

## 📝 API Réseau

Pour créer vos propres clients :

```lua
-- Requêtes disponibles
{type = "get_inventory"}
{type = "get_by_category"}
{type = "get_favorites"}
{type = "search", query = "diamond"}
{type = "retrieve_item", itemName = "minecraft:diamond", count = 10}
{type = "sort_input"}
{type = "empty_input"}
{type = "add_favorite", itemName = "minecraft:torch"}
{type = "add_chest", chestName = "minecraft:chest_5"}
-- etc.
```

## 📄 Licence

Libre d'utilisation et de modification. Amusez-vous bien ! 🎮
