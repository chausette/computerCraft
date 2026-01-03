# Mob Tower Manager v1.0

Un programme ComputerCraft pour gérer et automatiser votre tour à mobs avec Tom's Peripherals.

![Version](https://img.shields.io/badge/version-1.0-blue)
![Minecraft](https://img.shields.io/badge/Minecraft-1.18%2B-green)
![ComputerCraft](https://img.shields.io/badge/ComputerCraft-Tweaked-orange)

## Fonctionnalités

- 📊 **Dashboard temps réel** sur moniteur 3x2
- 🔢 **Statistiques complètes** : mobs tués, items collectés, temps actif
- 📈 **Graphique de production** par heure (historique 12h)
- 📦 **Tri automatique** des drops vers les barils
- ⚠️ **Alertes visuelles** pour items rares et stockage plein
- 💡 **Contrôle du spawn** via lampes More Red
- 💾 **Sauvegarde persistante** des statistiques
- 🧙 **Setup Wizard** pour configuration facile

## Matériel Requis

| Quantité | Item | Usage |
|----------|------|-------|
| 1 | Advanced Computer | Exécute le programme |
| 1 | Monitor 3x2 | Affichage du dashboard |
| 2 | Entity Sensor (Tom's) | Détection des mobs |
| 1 | Inventory Manager (Tom's) | Tri des items |
| 1 | Redstone Integrator (Tom's) | Contrôle des lampes |
| 1 | Double Coffre | Coffre collecteur |
| 23 | Barils | Stockage trié |
| - | Wired Modems | Connexion réseau |
| - | Network Cables | Connexion réseau |
| - | Bundled Cable (More Red) | Contrôle lampes |

## Installation

### Méthode rapide (recommandée)

Dans l'ordinateur ComputerCraft, exécutez :

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/mobTower/install.lua
```

### Méthode manuelle

1. Téléchargez tous les fichiers du dossier `mobTower/`
2. Placez-les dans le même dossier sur l'ordinateur
3. Exécutez `mobTower/mobTower.lua`

## Configuration

### Premier lancement

Au premier lancement, le **Setup Wizard** vous guidera pour :

1. Sélectionner l'Entity Sensor du haut (darkroom)
2. Sélectionner l'Entity Sensor du bas (zone kill)
3. Sélectionner l'Inventory Manager
4. Sélectionner le Redstone Integrator
5. Choisir le côté et la couleur du bundled cable
6. Sélectionner le moniteur
7. Sélectionner le coffre collecteur
8. Attribuer chaque baril à un type d'item

### Configuration manuelle

Vous pouvez modifier `mobTower/config.lua` directement :

```lua
local config = {
    player = {
        name = "VotrePseudo"  -- Pour la détection du joueur
    },
    
    redstone = {
        side = "back",       -- Côté du bundled cable
        color = "white"      -- Couleur du câble
    },
    
    display = {
        refreshRate = 1,     -- Rafraîchissement (secondes)
        graphHours = 12,     -- Heures dans le graphique
        alertDuration = 5    -- Durée des alertes (secondes)
    },
    
    sorting = {
        interval = 5,        -- Intervalle de tri (secondes)
        enabled = true       -- Tri automatique actif
    }
}
```

## Utilisation

### Raccourcis clavier

| Touche | Action |
|--------|--------|
| `S` | Toggle spawn ON/OFF |
| `C` | Reconfigurer (relance le wizard) |
| `R` | Reset statistiques de session |
| `Q` | Quitter le programme |

### Interface du moniteur

```
┌─────────────────────────────────────────────────────┐
│ ⚔ MOB TOWER v1.0        [ON ]    ⏱ Session: 02:34  │
├─────────────────────────┬───────────────────────────┤
│ STATS EN DIRECT      ●  │ PRODUCTION /HEURE         │
│                         │ Max: 847/h                │
│ Mobs attente:      12   │                           │
│ Tués session:   1,247   │ ▄▆█▇▅▃▆█▇▅▄▆█▇           │
│ Tués total:    45,832   │ -12h              now     │
│                         │                           │
│ Items session:  3,892   │                           │
│ Items total:  142,847   │                           │
├─────────────────────────┼───────────────────────────┤
│ STOCKAGE                │ ★ ITEMS RARES             │
│                         │                           │
│ [████████░░░] 76%       │ ● Zombie Head      14:32  │
│                         │ ● Diamond Sword    14:21  │
│ ⚠ Rotten Flesh: 94%     │ ● Iron Armor       13:58  │
├─────────────────────────┴───────────────────────────┤
│ [S] Spawn  [C] Config  [R] Reset  [Q] Quitter       │
└─────────────────────────────────────────────────────┘
```

### Items triés automatiquement

Le programme peut trier automatiquement :

**Drops de mobs :**
- Rotten Flesh, Iron Ingot, Carrot, Potato (Zombie)
- Bone, Arrow, Bow (Skeleton)
- Gunpowder (Creeper/Witch)
- Ender Pearl (Enderman)
- Redstone, Glowstone, Sugar, Glass Bottle, Stick (Witch)
- String (Spider - si activé)

**Équipements :**
- Casques, Plastrons, Jambières, Bottes (toutes matières)
- Épées, Arcs (enchantés ou non)

**Items rares (avec alerte) :**
- Têtes de mob
- Music Discs
- Équipements enchantés

## Architecture des fichiers

```
mobTower/
├── install.lua         # Installer/updater
├── startup.lua         # Auto-démarrage
├── mobTower.lua        # Programme principal
├── config.lua          # Configuration
├── lib/
│   ├── ui.lua          # Interface graphique
│   ├── peripherals.lua # Gestion périphériques
│   ├── storage.lua     # Tri et inventaires
│   └── utils.lua       # Fonctions utilitaires
├── data/
│   ├── stats.dat       # Statistiques sauvegardées
│   └── debug.log       # Log de debug
└── README.md           # Cette documentation
```

## Mise à jour

Pour mettre à jour le programme :

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/mobTower/install.lua
```

Puis choisissez l'option **2. Mise à jour**.

Votre configuration et vos statistiques seront préservées.

## Dépannage

### "HTTP n'est pas active"

Activez HTTP dans la config du mod :
1. Ouvrez `config/computercraft-server.toml`
2. Mettez `http_enable = true`
3. Redémarrez le serveur

### "Aucun Entity Sensor trouvé"

- Vérifiez que les sensors sont connectés avec des wired modems
- Vérifiez que les modems sont activés (clic droit)
- Vérifiez que le network cable relie tout à l'ordinateur

### Les mobs ne sont pas comptés

- Vérifiez que votre pseudo est correct dans la config
- Vérifiez que l'Entity Sensor du bas est dans la zone de kill
- Assurez-vous d'être à portée du sensor (8 blocs par défaut)

### Le tri ne fonctionne pas

- Vérifiez que l'Inventory Manager est connecté au réseau
- Vérifiez que tous les barils ont un wired modem activé
- Vérifiez que le coffre collecteur est bien configuré

## Crédits

- **Auteur** : MikeChausette
- **Mods requis** : 
  - CC: Tweaked
  - Tom's Peripherals
  - More Red (optionnel, pour les lampes)

## Licence

Ce projet est open source. Utilisez-le, modifiez-le, partagez-le !

---

*Créé avec ❤️ pour la communauté Minecraft*
