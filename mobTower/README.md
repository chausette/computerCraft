# Mob Tower Manager v1.1

Un programme ComputerCraft pour gérer et automatiser votre tour à mobs.

**Version 1.21 NeoForge** - Compatible avec CC: Tweaked + Advanced Peripherals

![Version](https://img.shields.io/badge/version-1.1-blue)
![Minecraft](https://img.shields.io/badge/Minecraft-1.21.x-green)
![Loader](https://img.shields.io/badge/Loader-NeoForge-orange)

## Fonctionnalités

- 📊 **Dashboard temps réel** sur moniteur 3x2
- 🔢 **Statistiques** : mobs tués (estimation), items collectés, temps actif
- 📈 **Graphique de production** par heure (historique 12h)
- 📦 **Tri automatique** des drops vers les barils
- ⚠️ **Alertes visuelles** pour items rares et stockage plein
- 💡 **Contrôle du spawn** via redstone (lampes)
- 👤 **Détection du joueur** avec Player Detector
- 💾 **Sauvegarde persistante** des statistiques
- 🧙 **Setup Wizard** pour configuration facile

## Mods Requis

| Mod | Version | Téléchargement |
|-----|---------|----------------|
| CC: Tweaked | 1.21.1 | [Modrinth](https://modrinth.com/mod/cc-tweaked) |
| Advanced Peripherals | 1.21.1 | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/advanced-peripherals) |

## Matériel Requis

| Quantité | Item | Usage |
|----------|------|-------|
| 1 | Advanced Computer | Exécute le programme |
| 1 | Monitor 3x2 | Affichage du dashboard |
| 1 | Player Detector (AP) | Détecte ta présence |
| 1 | Double Coffre | Coffre collecteur |
| 23 | Barils | Stockage trié |
| - | Wired Modems | Connexion réseau |
| - | Network Cables | Connexion réseau |

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

1. Sélectionner le Player Detector
2. Sélectionner le moniteur
3. Configurer la sortie redstone (côté + inversion)
4. Sélectionner le coffre collecteur
5. Attribuer chaque baril à un type d'item

### Configuration manuelle

Vous pouvez modifier `mobTower/config.lua` directement :

```lua
local config = {
    player = {
        name = "VotrePseudo",
        detectionRange = 16  -- Portée du Player Detector
    },
    
    redstone = {
        side = "back",       -- Côté de sortie redstone
        inverted = false     -- Inverser le signal
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
│ # MOB TOWER v1.1        [ON ]    Session: 02:34:15 │
├─────────────────────────────────────────────────────┤
│ STATISTIQUES     *   │ PRODUCTION /HEURE           │
│                      │ Max: ~847/h                 │
│ Mobs session: ~1,247 │                             │
│ Mobs total:  ~45,832 │ ▄▆█▇▅▃▆█▇▅▄▆█▇             │
│                      │ -12h              now       │
│ Items session: 3,892 │                             │
│ Items total: 142,847 │                             │
│ Rares:             3 │                             │
├──────────────────────┼─────────────────────────────┤
│ STOCKAGE             │ * ITEMS RARES               │
│                      │                             │
│ [████████░░░] 76%    │ > Zombie Head      14:32   │
│                      │ > Diamond Sword    14:21   │
│ > Rotten Flesh: 94%  │ > Iron Armor       13:58   │
├──────────────────────┴─────────────────────────────┤
│ [S] Spawn  [C] Config  [R] Reset  [Q] Quitter      │
└─────────────────────────────────────────────────────┘
```

**Note :** Le symbole `~` indique une estimation (les mobs sont comptés via les drops).

### Comment fonctionne l'estimation des mobs

Sans Entity Sensor (non disponible en 1.21), le programme estime les mobs tués en comptant les items collectés :

| Item | Estimation |
|------|------------|
| 1 Rotten Flesh | ~1 Zombie |
| 2 Bones | ~1 Skeleton |
| 1 Gunpowder | ~1 Creeper |
| 1 Ender Pearl | ~1 Enderman |

### Items triés automatiquement

**Drops de mobs :**
- Rotten Flesh, Iron Ingot, Carrot, Potato (Zombie)
- Bone, Arrow, Bow (Skeleton)
- Gunpowder (Creeper/Witch)
- Ender Pearl (Enderman)
- Redstone, Glowstone, Sugar, Glass Bottle, Stick (Witch)

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

### "Aucun Player Detector trouvé"

- Vérifiez qu'Advanced Peripherals est installé
- Vérifiez que le Player Detector est connecté avec un wired modem
- Vérifiez que le modem est activé (clic droit)

### Le tri ne fonctionne pas

- Vérifiez que tous les barils ont un wired modem activé
- Vérifiez que le coffre collecteur est bien configuré
- Vérifiez les logs dans `mobTower/data/debug.log`

### Les lampes ne répondent pas

- Vérifiez le côté configuré pour la redstone
- Essayez d'inverser le signal dans la config
- Assurez-vous que la redstone est bien connectée aux lampes

## Limitations (Version 1.21)

⚠️ Cette version est adaptée pour Minecraft 1.21 où certains mods ne sont pas disponibles :

- **Pas d'Entity Sensor** : Les mobs ne peuvent pas être comptés directement. Le programme estime les kills à partir des drops collectés.
- **Pas de Redstone Integrator** : La redstone sort directement du computer (un seul côté disponible).

## Crédits

- **Auteur** : MikeChausette
- **Mods utilisés** : 
  - CC: Tweaked
  - Advanced Peripherals

## Licence

Ce projet est open source. Utilisez-le, modifiez-le, partagez-le !

---

*Créé avec ❤️ pour la communauté Minecraft*
