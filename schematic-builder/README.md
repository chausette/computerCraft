# ComputerCraft Schematic Builder

## Architecture du système

```
[GPS Host x4]     (en hauteur, modems wireless)
      |
      v
[Turtle Builder] <--wireless--> [Advanced Computer] --- [Moniteur 3x2]
      |                                |
      v                                v
[Coffre Fuel]                    [Schematics]
[Coffre Matériaux]
```

## Installation

### Étape 1 : Réseau GPS (4 Advanced Computers)

Place 4 Advanced Computers en hauteur (y=200+) avec des Wireless Modems.
Espacement minimum de 6 blocs entre chaque.

Sur **chaque** GPS Host, crée le fichier `startup.lua` :

```
edit startup.lua
```

Copie le contenu de `gps_host.lua` et modifie les coordonnées X, Y, Z 
selon la position RÉELLE de ce computer.

Positions suggérées :
- GPS 1 : x=0, y=255, z=0
- GPS 2 : x=12, y=255, z=0  
- GPS 3 : x=0, y=255, z=12
- GPS 4 : x=6, y=260, z=6

### Étape 2 : Advanced Computer (Serveur)

1. Place un Advanced Computer
2. Attache un Wireless Modem (ou Ender Modem)
3. Attache un Advanced Monitor 3x2 (3 large, 2 haut)
4. Copie ces fichiers :
   - `server.lua` → programme principal
   - `ui.lua` → interface moniteur

Pour lancer : `server`

### Étape 3 : Turtle

1. Place une Mining Turtle ou Turtle avec Pickaxe
2. Attache un Wireless Modem
3. Copie ces fichiers :
   - `builder.lua` → programme principal
   - `nbt.lua` → parser de schematics
   - `movement.lua` → gestion des déplacements

Pour lancer : `builder`

### Étape 4 : Upload des Schematics

#### Option A : Pastebin
```
pastebin get <code> schematics/maison.schematic
```

#### Option B : Fichier direct
Place le fichier dans le dossier `schematics/` du serveur.

**IMPORTANT** : Les .schematic sont compressés en GZIP.
Tu dois les décompresser AVANT l'upload :
1. Renomme ton fichier .schematic en .schematic.gz
2. Décompresse avec 7-zip ou gunzip
3. Upload le fichier décompressé

OU utilise le format JSON simplifié (voir schema_format.json)

## Utilisation

### Interface Moniteur

```
┌─────────────────────────────────────┐
│  SCHEMATIC BUILDER v1.0             │
├─────────────────────────────────────┤
│  [1] Charger Schematic              │
│  [2] Config Coffres                 │
│  [3] Config Position                │
│  [4] Démarrer Construction          │
│  [5] Pause/Reprendre                │
├─────────────────────────────────────┤
│  Status: En attente                 │
│  Couche: 0/0  Blocs: 0/0            │
│  Fuel: 1000  Matériaux: OK          │
└─────────────────────────────────────┘
```

### Contrôles tactiles
- Touche le bouton correspondant sur le moniteur
- La vue 2D montre la couche actuelle en cours

## Format JSON Alternatif

Si le parsing NBT pose problème, utilise ce format :

```json
{
  "width": 5,
  "height": 3,
  "length": 5,
  "palette": {
    "0": "minecraft:air",
    "1": "minecraft:stone",
    "2": "minecraft:oak_planks"
  },
  "blocks": [
    [[1,1,1,1,1], [1,0,0,0,1], [1,1,1,1,1]],
    [[1,0,0,0,1], [0,0,0,0,0], [1,0,0,0,1]],
    [[1,1,1,1,1], [1,0,0,0,1], [1,1,1,1,1]]
  ]
}
```

## Mapping des blocs

La turtle a besoin de savoir quel slot contient quel bloc.
Configure cela via le moniteur dans "Config Matériaux".

## Dépannage

### La turtle ne bouge pas
- Vérifie le fuel : `refuel all`
- Vérifie le GPS : `gps locate`

### GPS ne fonctionne pas
- Vérifie que les 4 hosts sont allumés
- Vérifie l'espacement (min 6 blocs)
- Vérifie que tous ont des wireless modems

### Erreur de parsing schematic
- Assure-toi que le fichier est décompressé
- Essaie le format JSON alternatif

## Fichiers

| Fichier | Destination | Description |
|---------|-------------|-------------|
| gps_host.lua | GPS Computers | Programme GPS (startup.lua) |
| nbt.lua | Turtle | Parser NBT/Schematic |
| movement.lua | Turtle | Gestion déplacements GPS |
| builder.lua | Turtle | Programme principal turtle |
| server.lua | Computer | Serveur de contrôle |
| ui.lua | Computer | Interface moniteur |
