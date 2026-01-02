# 🔨 TURTLE TOOLS

Suite de programmes pour Mining Turtle (ComputerCraft / CC:Tweaked)

- **QUARRY** : Mine automatiquement une zone
- **FILL** : Remplit une zone avec dirt ou cobblestone
- **MONITOR** : Surveille les turtles depuis un Pocket Computer

---

## 📦 Installation

### Sur une Turtle

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/quarry/installer.lua
```

Installe automatiquement : `menu.lua`, `quarry.lua`, `fill.lua`

### Sur un Pocket Computer

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/quarry/installer.lua
```

Installe automatiquement : `monitor.lua`

---

## 🎮 Utilisation

### Menu principal (Turtle)

```
menu
```

Affiche un menu pour choisir entre QUARRY et FILL.

### Lancer directement un programme

```
quarry
```
ou
```
fill
```

---

## ⛏️ QUARRY - Miner une zone

### Fonctionnalités

- Mine une zone rectangulaire entre 2 coordonnées
- Tranche par tranche (de haut en bas)
- Dépôt automatique au coffre
- Gestion du fuel
- **Reprise automatique** après arrêt
- **Monitoring wireless** sur Pocket

### Configuration

1. Position actuelle (GPS auto ou manuel)
2. Direction (0=Nord, 1=Est, 2=Sud, 3=Ouest)
3. Coin 1 de la zone (X, Y, Z)
4. Coin 2 de la zone (X, Y, Z)
5. Coffre fuel (optionnel)

### Préparation

- **Slot 16** : Fuel (charbon)
- Place un **coffre SOUS** la turtle

---

## 🧱 FILL - Remplir une zone

### Fonctionnalités

- Remplit une zone avec **dirt** ou **cobblestone**
- De bas en haut, tranche par tranche
- Récupère les matériaux au coffre
- Gestion du fuel
- **Reprise automatique** après arrêt
- **Monitoring wireless** sur Pocket

### Configuration

1. Position actuelle (GPS auto ou manuel)
2. Direction (0=Nord, 1=Est, 2=Sud, 3=Ouest)
3. **Matériau** : Dirt ou Cobblestone
4. Coin 1 de la zone (X, Y, Z)
5. Coin 2 de la zone (X, Y, Z)
6. Coffre matériaux (recommandé)
7. Coffre fuel (optionnel)

### Préparation

- **Slots 1-15** : Matériaux (dirt ou cobblestone)
- **Slot 16** : Fuel (charbon)
- Place un **coffre** avec les matériaux

---

## 📱 MONITOR - Surveillance Pocket

### Fonctionnalités

- Affiche en temps réel les infos des turtles
- Fonctionne avec QUARRY et FILL
- Plusieurs turtles supportées
- Pas d'interaction, lecture seule

### Lancement

```
monitor
```

### Informations affichées

```
================================
   TURTLE MONITOR
================================

Turtle_5              QUARRY
------------------------------
Status:  mining
Progres: 45%
████████████░░░░░░░░░░░░░░░░░░
Blocs:   1523/3400
Tranche: Z=207 (5/10)
Pos:     105,52,207
Dir:     Nord (-Z)
Fuel:    3200
Temps:   12:34
ETA:     15:20

Zone: 10x20x15
------------------------------
Q=Quit                      OK
```

### Commandes

| Touche | Action |
|--------|--------|
| **Q** | Quitter |
| **L** | Liste des turtles |
| **S** | Vue single (une turtle) |
| **R** | Rafraîchir |

### Canal wireless

**Canal : 400**

Les turtles envoient automatiquement leur status sur ce canal.

---

## 🔄 Reprise automatique

Les programmes QUARRY et FILL sauvegardent leur progression.

### Fichiers de sauvegarde

- `quarry_save.txt` : Progression du minage
- `fill_save.txt` : Progression du remplissage

### Quand tu relances le programme

```
Sauvegarde trouvee!

Zone: 10x20x15
Derniere position: 105, 52, 207
Tranche: Z=207 / 215
Blocs mines: 1523
Blocs restants: 1877

Que voulez-vous faire?
  1. Reprendre
  2. Nouvelle configuration
  3. Annuler

Choix [1]:
```

### Cas d'utilisation

| Situation | Solution |
|-----------|----------|
| Serveur redémarre | Relance → Reprendre |
| Chunk déchargé | Relance → Reprendre |
| Ctrl+T | Relance → Reprendre |
| Plus de fuel | Ajoute fuel → Reprendre |

---

## 📡 Communication Wireless

### Architecture

```
┌─────────────┐     Canal 400     ┌─────────────┐
│   TURTLE    │ ═══════════════►  │   POCKET    │
│  quarry.lua │    Status         │ monitor.lua │
│   fill.lua  │    wireless       │             │
└─────────────┘                   └─────────────┘
```

### Données transmises

| Donnée | Description |
|--------|-------------|
| `program` | "quarry" ou "fill" |
| `turtleId` | ID de la turtle |
| `turtleName` | Nom de la turtle |
| `x, y, z` | Position actuelle |
| `facing` | Direction (0-3) |
| `status` | mining, filling, idle, refuel... |
| `progress` | Progression en % |
| `blocksMined` | Blocs minés (quarry) |
| `blocksPlaced` | Blocs placés (fill) |
| `totalBlocks` | Total de blocs |
| `currentSliceZ` | Tranche en cours |
| `fuel` | Fuel actuel |
| `elapsed` | Temps écoulé |
| `eta` | Temps restant estimé |
| `zone` | Dimensions de la zone |
| `material` | Matériau (fill) |
| `materialCount` | Matériaux restants (fill) |

---

## 🗂️ Slots de l'inventaire

### QUARRY

```
┌────┬────┬────┬────┐
│ 1  │ 2  │ 3  │ 4  │  ← Blocs minés
├────┼────┼────┼────┤
│ 5  │ 6  │ 7  │ 8  │  ← Blocs minés
├────┼────┼────┼────┤
│ 9  │ 10 │ 11 │ 12 │  ← Blocs minés
├────┼────┼────┼────┤
│ 13 │ 14 │ -- │ 16 │  ← 16: Fuel
└────┴────┴────┴────┘
```

### FILL

```
┌────┬────┬────┬────┐
│ 1  │ 2  │ 3  │ 4  │  ← Matériaux
├────┼────┼────┼────┤
│ 5  │ 6  │ 7  │ 8  │  ← Matériaux
├────┼────┼────┼────┤
│ 9  │ 10 │ 11 │ 12 │  ← Matériaux
├────┼────┼────┼────┤
│ 13 │ 14 │ 15 │ 16 │  ← 16: Fuel
└────┴────┴────┴────┘
```

---

## ⚙️ Équipement requis

### Turtle

- **Mining Turtle** (avec pickaxe)
- **Wireless Modem** (pour monitoring)
- Fuel (charbon, charbon de bois...)

### Pocket Computer

- **Pocket Computer**
- **Wireless Modem** (intégré ou attaché)

---

## 💡 Conseils

1. **Commence petit** : Teste sur une zone 5x5x5

2. **Nomme ta turtle** : `label set MaTurtle` pour l'identifier sur le monitor

3. **Prévois du fuel** : L'estimation est affichée avant de commencer

4. **Coffre assez grand** : Double coffre recommandé

5. **GPS optionnel** : Les programmes fonctionnent sans GPS (mode manuel)

6. **Plusieurs turtles** : Le monitor supporte plusieurs turtles en même temps

---

## 🔧 Dépannage

### "Pas de fuel!"

```
refuel 16
```
ou mets du charbon dans le slot 16

### "GPS non disponible"

Normal si pas de réseau GPS. Entre les coordonnées manuellement (F3)

### Le monitor n'affiche rien

- Vérifie que le modem est wireless
- Vérifie que la turtle a un modem wireless
- Vérifie que la turtle est en cours de minage/remplissage

### La turtle s'arrête

- Plus de fuel → Ajoute du fuel et relance
- Inventaire plein → Configure un coffre de dépôt
- Plus de matériaux (fill) → Remplis le coffre matériaux

---

## 📜 Fichiers

| Fichier | Description |
|---------|-------------|
| `installer.lua` | Installateur automatique |
| `menu.lua` | Menu principal turtle |
| `quarry.lua` | Programme de minage |
| `fill.lua` | Programme de remplissage |
| `monitor.lua` | Surveillance pocket |

---

## 📝 Licence

Programme libre d'utilisation et de modification.
Créé pour ComputerCraft / CC:Tweaked sur Minecraft.
