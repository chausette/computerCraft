# ComputerCraft Schematic Builder

Système complet pour construire des schematics avec une Turtle, contrôlée via un Advanced Computer avec moniteur tactile.

## 🚀 Installation Rapide (Une seule commande!)

Sur **n'importe quelle machine** (Turtle, Computer, GPS Host), exécutez :

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/schematic-builder/installer.lua
```

L'installateur détecte automatiquement le type de machine et installe les bons fichiers!

---

## 📁 Structure du Repository GitHub

```
schematic-builder/
├── installer.lua          # Installateur universel
├── README.md
├── turtle/
│   ├── nbt.lua            # Parser NBT/Schematic
│   ├── movement.lua       # Gestion GPS et déplacements
│   ├── builder.lua        # Programme principal turtle
│   └── gps_host.lua       # Programme GPS host
└── computer/
    ├── ui.lua             # Interface moniteur
    ├── server.lua         # Programme principal serveur
    └── schematics/
        └── exemple_maison.json
```

---

## 🔧 Installation Manuelle

### GPS Hosts (4 machines en hauteur)

```
wget https://raw.githubusercontent.com/chausette/computerCraft/master/schematic-builder/installer.lua installer
installer
-- Choisir "GPS Host"
-- Entrer les coordonnées X, Y, Z
```

**Positions recommandées** (espacement min 6 blocs, hauteur 200+) :
| Host | X | Y | Z |
|------|-----|-----|-----|
| 1 | 0 | 255 | 0 |
| 2 | 12 | 255 | 0 |
| 3 | 0 | 255 | 12 |
| 4 | 6 | 260 | 6 |

### Serveur (Advanced Computer + Moniteur 3x2)

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/schematic-builder/installer.lua
-- L'installer détecte automatiquement le moniteur
```

### Turtle (Mining Turtle + Wireless Modem)

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/schematic-builder/installer.lua
-- L'installer détecte automatiquement la turtle
```

---

## 🎮 Utilisation

### Démarrage

1. **GPS Hosts** : Redémarrez-les, ils démarrent automatiquement
2. **Serveur** : `server`
3. **Turtle** : `builder`

### Interface Moniteur

```
┌─────────────────────────────────────┐
│    SCHEMATIC BUILDER v1.0           │
├─────────────────────────────────────┤
│  [1. Charger]    [4. Matériaux]     │
│  [2. Coffres]    [5. CONSTRUIRE]    │
│  [3. Position]   [6. Pause]         │
├─────────────────────────────────────┤
│  Status: En attente                 │
│  Couche: 0/0  Blocs: 0/0            │
│  [===========----------] 45%        │
│  Fuel: 1000   Pos: 100,64,200       │
└─────────────────────────────────────┘
```

### Workflow

1. **Charger un Schematic** : Sélectionnez un fichier dans le dossier `schematics/`
2. **Config Coffres** : Définissez les coordonnées du coffre fuel et matériaux
3. **Config Position** : Définissez où la construction commence + direction (N/E/S/O)
4. **Matériaux** : Assignez chaque type de bloc à un slot de la turtle (1-16)
5. **Construire** : Lancez la construction!

---

## 📄 Format des Schematics

### Format JSON (Recommandé)

Plus simple à créer et modifier :

```json
{
    "name": "Ma Construction",
    "width": 5,
    "height": 3,
    "length": 5,
    "palette": {
        "0": "minecraft:air",
        "1": "minecraft:stone",
        "2": "minecraft:oak_planks"
    },
    "blocks": [
        [
            [1,1,1,1,1],
            [1,0,0,0,1],
            [1,1,1,1,1]
        ],
        [
            [1,0,0,0,1],
            [0,0,0,0,0],
            [1,0,0,0,1]
        ],
        [
            [2,2,2,2,2],
            [2,2,2,2,2],
            [2,2,2,2,2]
        ]
    ]
}
```

Structure : `blocks[Y][Z][X]` (couche → rangée → colonne)

### Format .schematic (MCEdit)

⚠️ **Important** : Les fichiers .schematic sont compressés en GZIP.

1. Renommez votre fichier `.schematic` en `.schematic.gz`
2. Décompressez avec 7-zip ou `gunzip`
3. Uploadez le fichier décompressé

---

## 🔧 Dépannage

### "GPS non disponible"
- Vérifiez que les 4 GPS hosts sont allumés
- Vérifiez l'espacement (minimum 6 blocs)
- Vérifiez que tous ont des wireless modems

### "Connexion impossible"
- Vérifiez que HTTP est activé dans la config ComputerCraft
- Vérifiez que le repo GitHub est public

### La turtle ne bouge pas
- Vérifiez le fuel : `refuel all`
- Vérifiez la connexion au serveur

### Erreur de parsing schematic
- Utilisez le format JSON à la place
- Assurez-vous que le .schematic est décompressé

---

## 📐 Architecture

```
[GPS 1] [GPS 2] [GPS 3] [GPS 4]   ← En hauteur (y=200+)
              ↓ wireless
         [TURTLE] ←──wireless──→ [SERVER]
           ↓   ↓                      ↓
    [Coffre] [Coffre]           [Moniteur 3x2]
     Fuel    Matériaux
```

---

## 🎛️ Commandes Clavier (Serveur)

| Touche | Action |
|--------|--------|
| Q | Quitter |
| R | Rafraîchir l'écran |
| P | Ping la turtle |

---

## 📜 License

MIT License - Libre d'utilisation et modification.
