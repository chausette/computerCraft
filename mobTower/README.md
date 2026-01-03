# 🗼 Mob Tower Manager v1.4

Un programme ComputerCraft pour gérer et automatiser votre tour à mobs.

**Compatible Minecraft 1.21.x NeoForge**

![Version](https://img.shields.io/badge/version-1.4-blue)
![Minecraft](https://img.shields.io/badge/Minecraft-1.21.x-green)
![Loader](https://img.shields.io/badge/Loader-NeoForge-orange)

---

## ✨ Fonctionnalités

- 📊 **Dashboard temps réel** sur moniteur
- 🖱️ **Interface tactile réactive** - touchez le moniteur !
- 📦 **Vue détaillée du stock** avec pagination
- 🔄 **Tri manuel forcé** de tous les barils
- 🔢 **Statistiques** : mobs tués (estimation), items collectés
- 📈 **Graphique de production** par heure
- 📦 **Tri automatique** des drops vers les barils
- 🗑️ **Coffre overflow** pour les items non triés
- ⚠️ **Alertes visuelles** pour items rares
- 💡 **Contrôle du spawn** via bouton tactile
- 👤 **Détection du joueur** (optionnel)
- 💾 **Sauvegarde automatique** des stats

---

## 🆕 Nouveautés v1.4

- ✅ **Boutons plus réactifs** (refresh 0.5s au lieu de 1s)
- ✅ **Vue STOCK** : voir le remplissage de chaque baril avec pagination
- ✅ **Bouton TRI** : forcer le tri/réorganisation de tous les barils
- ✅ 5 boutons en bas : STOCK, TRI, CONFIG, RESET, QUIT
- ✅ Barre de progression pendant le tri manuel

---

## 📋 Mods Requis

| Mod | Obligatoire | Téléchargement |
|-----|-------------|----------------|
| CC: Tweaked | ✅ Oui | [Modrinth](https://modrinth.com/mod/cc-tweaked) |
| Advanced Peripherals | ❌ Optionnel | [CurseForge](https://www.curseforge.com/minecraft/mc-mods/advanced-peripherals) |

---

## 📥 Installation

Dans l'ordinateur ComputerCraft :

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/mobTower/install.lua
```

---

## 🎮 Utilisation

### 🖱️ Interface tactile

**Touchez directement le moniteur** pour interagir :

| Bouton | Action |
|--------|--------|
| `ON/OFF` | Toggle spawn (lampes) |
| `STOCK` | Voir le détail de tous les barils |
| `TRI` | Forcer le tri de tous les barils |
| `CONFIG` | Reconfigurer |
| `RESET` | Reset statistiques de session |
| `QUIT` | Arrêter le programme |

### 📦 Vue STOCK

Affiche le remplissage de chaque baril avec :
- Nom de l'item
- Barre de progression colorée (vert → orange → rouge)
- Pourcentage et slots utilisés
- Navigation par pages (PREC / SUIV)

### 🔄 Tri manuel

Le bouton **TRI** :
1. Parcourt chaque baril de tri
2. Vérifie si des items sont mal placés
3. Les déplace vers le bon baril
4. Trie aussi le coffre collecteur
5. Affiche une barre de progression

---

## ⚙️ Configuration

### Wizard navigable

Navigation :
- ⬆️⬇️ Flèches haut/bas
- ↵ Entrée pour sélectionner
- Page Up/Down pour aller plus vite

Étapes :
1. 👤 Pseudo Minecraft
2. 📡 Scan des périphériques
3. 🔍 Player Detector (optionnel)
4. 🖥️ Moniteur
5. 🔴 Côté redstone
6. 📥 Coffre collecteur
7. 🗑️ Coffre overflow
8. 🗂️ Attribution des barils

---

## 📦 Items triés

### Drops de mobs
- Rotten Flesh, Bone, Arrow, Gunpowder, Ender Pearl
- String, Spider Eye, Slime Ball, Phantom Membrane
- Blaze Rod, Ghast Tear, Magma Cream

### Drops Witch
- Redstone, Glowstone, Sugar, Glass Bottle, Stick

### Armes & Outils (patterns)
- Arcs (bow, crossbow)
- Épées, Pioches, Haches, Pelles, Houes

### Armures (patterns)
- Casques, Plastrons, Jambières, Bottes

### Potions (patterns)
- Potions normales, Splash, Lingering

---

## 📜 Changelog

### v1.4
- ✅ Boutons plus réactifs
- ✅ Vue STOCK avec pagination
- ✅ Bouton TRI manuel
- ✅ Barre de progression du tri

### v1.3
- ✅ Wizard navigable
- ✅ Coffre overflow

### v1.2
- ✅ Boutons tactiles
- ✅ Plus d'items triés

### v1.1
- ✅ Compatible Minecraft 1.21.x
- ✅ Version tout-en-un

---

*Créé par MikeChausette* 🧦
