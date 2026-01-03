# 🗼 Mob Tower Manager v1.3

Un programme ComputerCraft pour gérer et automatiser votre tour à mobs.

**Compatible Minecraft 1.21.x NeoForge**

![Version](https://img.shields.io/badge/version-1.3-blue)
![Minecraft](https://img.shields.io/badge/Minecraft-1.21.x-green)
![Loader](https://img.shields.io/badge/Loader-NeoForge-orange)

---

## ✨ Fonctionnalités

- 📊 **Dashboard temps réel** sur moniteur
- 🖱️ **Interface tactile** - touchez le moniteur pour interagir !
- 🔢 **Statistiques** : mobs tués (estimation), items collectés
- 📈 **Graphique de production** par heure
- 📦 **Tri automatique** des drops vers les barils
- 🗑️ **Coffre overflow** pour les items non triés
- ⚠️ **Alertes visuelles** pour items rares
- 💡 **Contrôle du spawn** via bouton tactile
- 👤 **Détection du joueur** (optionnel)
- 💾 **Sauvegarde automatique** des stats

---

## 🆕 Nouveautés v1.3

- ✅ **Wizard navigable** avec flèches haut/bas (fini les listes interminables !)
- ✅ **Coffre overflow** pour les items sans règle de tri
- ✅ Navigation rapide: PageUp/PageDown, Home/End
- ✅ Meilleure organisation du wizard

### v1.2
- ✅ **Boutons tactiles** sur le moniteur
- ✅ **Plus d'items triés** : arcs, potions, outils, armures
- ✅ Support `player_detector` (Advanced Peripherals 1.21)

---

## 📋 Mods Requis

| Mod | Obligatoire | Téléchargement |
|-----|-------------|----------------|
| CC: Tweaked | ✅ Oui | [Modrinth](https://modrinth.com/mod/cc-tweaked) |
| Advanced Peripherals | ❌ Optionnel | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/advanced-peripherals) |

> Advanced Peripherals ajoute le **Player Detector** pour détecter ta présence.

---

## 🔧 Matériel Requis

| Quantité | Item | Usage |
|----------|------|-------|
| 1 | Advanced Computer | Exécute le programme |
| 1 | Monitor (3x2 recommandé) | Affichage du dashboard |
| 1 | Player Detector | Détecte ta présence (optionnel) |
| 1 | Double Coffre | Coffre collecteur |
| X | Barils | Stockage trié (1 par type d'item) |
| - | Wired Modems | Connexion réseau |
| - | Network Cables | Connexion réseau |

---

## 📥 Installation

### Méthode rapide (recommandée)

Dans l'ordinateur ComputerCraft, exécute :

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/mobTower/install.lua
```

### Méthode manuelle

1. Crée le dossier :
```
mkdir /mobTower
mkdir /mobTower/data
```

2. Télécharge le programme :
```
wget https://raw.githubusercontent.com/chausette/computerCraft/master/mobTower/mobTower.lua /mobTower/mobTower.lua
```

3. (Optionnel) Pour l'auto-démarrage :
```
wget https://raw.githubusercontent.com/chausette/computerCraft/master/mobTower/startup.lua /startup.lua
```

4. Lance le programme :
```
/mobTower/mobTower.lua
```

---

## ⚙️ Configuration

### Premier lancement - Wizard navigable

Au premier lancement, le **Setup Wizard** te guidera avec une interface navigable :

**Navigation :**
- ⬆️⬇️ Flèches haut/bas pour naviguer
- ↵ Entrée pour sélectionner
- Page Up/Down pour aller plus vite
- Home/End pour aller au début/fin

**Étapes :**
1. 👤 Entrer ton pseudo Minecraft
2. 📡 Scan des périphériques
3. 🔍 Sélectionner le Player Detector (optionnel)
4. 🖥️ Sélectionner le moniteur
5. 🔴 Configurer le côté redstone pour les lampes
6. 📥 Sélectionner le **coffre collecteur** (entrée des items)
7. 🗑️ Sélectionner le **coffre overflow** (items non triés)
8. 🗂️ Attribuer chaque baril à un type d'item

### Coffre Overflow

Le coffre overflow reçoit tous les items qui n'ont pas de règle de tri configurée. Pratique pour ne pas bloquer le système avec des items inattendus !

### Reconfigurer

Appuie sur `C` dans le programme, puis `O` pour relancer le wizard.

---

## 🎮 Utilisation

### 🖱️ Interface tactile (NOUVEAU !)

**Touchez directement le moniteur** pour interagir :

| Bouton | Action |
|--------|--------|
| `ON/OFF` (en haut) | Toggle spawn ON/OFF |
| `CONFIG` | Reconfigurer |
| `RESET` | Reset statistiques de session |
| `QUITTER` | Arrêter le programme |

### ⌨️ Raccourcis clavier (si terminal actif)

| Touche | Action |
|--------|--------|
| `S` | Toggle spawn ON/OFF |
| `C` | Reconfigurer |
| `R` | Reset statistiques de session |
| `Q` | Quitter |

### Interface du moniteur

```
┌─────────────────────────────────────────────────────┐
│ # MOB TOWER v1.1        [ON ]    Session: 02:34:15 │
├─────────────────────────────────────────────────────┤
│ STATISTIQUES     *   │ PRODUCTION /HEURE           │
│                      │ Max: ~847/h                 │
│ Mobs session: ~1,247 │                             │
│ Mobs total:  ~45,832 │ ▄▆█▇▅▃▆█▇▅▄▆█▇             │
│                      │                             │
│ Items session: 3,892 │                             │
│ Items total: 142,847 │                             │
│ Rares:             3 │                             │
├──────────────────────┼─────────────────────────────┤
│ STOCKAGE             │ * ITEMS RARES               │
│ [████████░░░] 76%    │ > Zombie Head      14:32   │
│ > Rotten Flesh: 94%  │ > Diamond Sword    14:21   │
├──────────────────────┴─────────────────────────────┤
│ [S] Spawn  [C] Config  [R] Reset  [Q] Quitter      │
└─────────────────────────────────────────────────────┘
```

---

## 📊 Comment fonctionne l'estimation des mobs

Sans Entity Sensor (non disponible en 1.21), le programme **estime** les mobs tués à partir des drops collectés :

| Item | Estimation |
|------|------------|
| 1 Rotten Flesh | ~1 Zombie |
| 2 Bones | ~1 Skeleton |
| 1 Gunpowder | ~1 Creeper |
| 1 Ender Pearl | ~1 Enderman |
| 2 String | ~1 Spider |

C'est pourquoi les stats affichent `~` devant le nombre de mobs.

---

## 📦 Items triés automatiquement

### Drops de mobs
- **Zombie** : Rotten Flesh, Iron Ingot, Carrot, Potato
- **Skeleton** : Bone, Arrow
- **Creeper** : Gunpowder
- **Enderman** : Ender Pearl
- **Spider** : String, Spider Eye
- **Witch** : Redstone, Glowstone, Sugar, Glass Bottle, Stick
- **Slime** : Slime Ball
- **Phantom** : Phantom Membrane
- **Blaze** : Blaze Rod
- **Ghast** : Ghast Tear

### Armes & Outils (tous types)
- 🏹 **Arcs** : Bow, Crossbow
- ⚔️ **Épées** : toutes matières
- ⛏️ **Pioches** : toutes matières
- 🪓 **Haches** : toutes matières
- 🔨 **Pelles** : toutes matières
- 🌾 **Houes** : toutes matières

### Armures (tous types)
- 🪖 Casques
- 🦺 Plastrons
- 🩳 Jambières
- 👢 Bottes

### Potions
- 🧪 Potions normales
- 💥 Potions Splash
- 💨 Potions Lingering

### Items rares (avec alerte)
- 💀 Têtes de mob / Crânes
- 💿 Music Discs
- ✨ Items enchantés

---

## 🔌 Connexion du matériel

```
                    ┌─────────────┐
                    │   MONITOR   │
                    │    3x2      │
                    └──────┬──────┘
                           │ (wired modem)
    ┌──────────────────────┼──────────────────────┐
    │                      │                      │
┌───┴───┐            ┌─────┴─────┐          ┌─────┴─────┐
│PLAYER │            │ ADVANCED  │          │  COFFRE   │
│DETECT │            │ COMPUTER  │──────────│COLLECTEUR │
└───────┘            └─────┬─────┘ redstone └───────────┘
                           │
                     ┌─────┴─────┐
                     │  LAMPES   │
                     │ (spawn)   │
                     └───────────┘
```

1. Place des **wired modems** sur chaque périphérique
2. Connecte-les avec des **network cables**
3. **Clic droit** sur chaque modem pour l'activer (point rouge)
4. Connecte la **redstone** du computer aux lampes de ta tour

---

## ❓ Dépannage

### "HTTP n'est pas active"

Active HTTP dans la config du mod :
1. Ouvre `config/computercraft-server.toml`
2. Trouve `http { enabled = false }`
3. Change en `http { enabled = true }`
4. Redémarre le serveur/jeu

### "Aucun moniteur trouvé"

- Vérifie que le wired modem est bien **activé** (point rouge visible)
- Vérifie que le câble réseau connecte bien le computer au moniteur

### Le tri ne fonctionne pas

- Vérifie que tous les barils ont un wired modem **activé**
- Vérifie que le coffre collecteur est bien configuré

### Les lampes ne répondent pas

- Vérifie le côté configuré pour la redstone
- Essaie d'inverser le signal dans la config (touche C)

---

## 📁 Structure des fichiers

```
/mobTower/
├── mobTower.lua    # Programme principal (tout-en-un)
└── data/
    ├── config.dat  # Configuration sauvegardée
    └── stats.dat   # Statistiques sauvegardées

/startup.lua        # Auto-démarrage (optionnel)
```

---

## 📜 Changelog

### v1.3 (1.21 NeoForge)
- ✅ **Wizard navigable** avec flèches haut/bas
- ✅ **Coffre overflow** pour items non triés
- ✅ Navigation rapide: PageUp/PageDown, Home/End
- ✅ Tri des inventaires par nom

### v1.2 (1.21 NeoForge)
- ✅ **Boutons tactiles** sur le moniteur !
- ✅ **Plus d'items** : arcs, crossbow, potions, outils, armures
- ✅ Support `player_detector` (underscore)
- ✅ Shulker boxes comme inventaires
- ✅ Amélioration de l'interface

### v1.1 (1.21 NeoForge)
- ✅ Compatible Minecraft 1.21.x
- ✅ Utilise CC: Tweaked natif pour les inventaires
- ✅ Player Detector optionnel (Advanced Peripherals)
- ✅ Estimation des mobs via les drops
- ✅ Version tout-en-un (un seul fichier)

### v1.0
- Version initiale pour Tom's Peripherals (incompatible 1.21)

---

## 📝 Licence

Ce projet est open source. Utilise-le, modifie-le, partage-le !

---

*Créé par MikeChausette* 🧦
