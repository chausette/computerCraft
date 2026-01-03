# RadioCraft 🎵

Système radio complet pour ComputerCraft avec Advanced Peripherals.

![Version](https://img.shields.io/badge/version-1.1-blue)
![CC:Tweaked](https://img.shields.io/badge/CC:Tweaked-1.89+-green)

## 🚀 Installation rapide

Dans un computer ComputerCraft, exécutez :

```lua
wget https://raw.githubusercontent.com/chausette/computerCraft/master/radio/install.lua install
install
```

Ou en une seule commande :

```lua
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/radio/install.lua
```

## 📦 Commandes de l'installer

| Commande | Description |
|----------|-------------|
| `install` | Menu interactif |
| `install install` | Installation directe |
| `install update` | Mise à jour |
| `install uninstall` | Désinstallation |
| `install status` | Affiche le statut |

## ✨ Fonctionnalités

### 🎵 Jukebox
- Lecture de tous les disques Minecraft vanilla (16 disques)
- Queue de lecture avec shuffle et repeat
- Contrôles play/pause/stop/next/previous

### 🌲 Ambiance
9 stations thématiques :
- 🌿 Nature - Sons de forêt, oiseaux
- 🕳️ Grotte - Ambiance souterraine
- 🔥 Nether - Sons infernaux
- 🌊 Ocean - Ambiance sous-marine
- 🌧️ Pluie - Orage et pluie
- 🌌 End - Ambiance dimension de l'End
- 👻 Horreur - Sons effrayants
- 🏘️ Village - Vie de village
- ☮️ Calme - Ambiance zen

### 🎼 Composer
- Éditeur de mélodies noteblock
- 16 instruments disponibles
- Multi-pistes
- Sauvegarde sur disquette (format `.rcm`)

### 🔊 Multi-Speakers
- Connectez autant de speakers que vous voulez via wired modem
- Système de zones audio
- Volume par zone + volume master

## 🛠️ Prérequis

### Mods requis
- **CC: Tweaked** (ComputerCraft)
- **Advanced Peripherals** (recommandé pour les speakers)

### Matériel in-game
```
┌─────────────┐     ┌─────────────┐
│   MONITEUR  │     │   COMPUTER  │
│    (3x2)    │─────│  (Advanced) │
└─────────────┘     └──────┬──────┘
                           │
                    ┌──────┴──────┐
                    │ DISK DRIVE  │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
         ┌────┴────┐  ┌────┴────┐  ┌────┴────┐
         │ SPEAKER │  │ SPEAKER │  │ SPEAKER │
         └─────────┘  └─────────┘  └─────────┘
           (via wired modem)
```

## 🎮 Utilisation

### Lancer RadioCraft

```lua
cd /radiocraft
startup
```

### Interface

```
┌─────────────────────────────────┐
│         = RadioCraft =          │
├────────┬────────┬───────┬───────┤
│ JUKEBOX│AMBIANCE│COMPOSER│CONFIG │
├────────┴────────┴───────┴───────┤
│                                 │
│   [Contenu de l'onglet]         │
│                                 │
├─────────────────────────────────┤
│ |< [] > >| ~ @    Vol: ████░░  │
│      ♫ Now Playing: Cat         │
└─────────────────────────────────┘
```

### Contrôles clavier

| Touche | Action |
|--------|--------|
| `Q` | Quitter |
| `Space` | Play/Pause |
| `S` | Stop |
| `R` | Rafraîchir les speakers |

## 🎹 Convertisseur MIDI

Le projet inclut un convertisseur Python pour transformer des fichiers MIDI en format `.rcm`.

### Installation

```bash
cd midi2rcm
pip install mido
```

### Utilisation

```bash
python midi2rcm.py ma_musique.mid -n "Ma Musique" -a "MonPseudo"
```

### Transfert vers Minecraft

1. Convertissez votre MIDI
2. Copiez le contenu du fichier `.rcm`
3. Dans Minecraft, avec une disquette :
   ```lua
   edit /disk/songs/mamusique.rcm
   ```
4. Collez et sauvegardez (Ctrl+S, Ctrl+E)

## 📁 Structure des fichiers

```
/radiocraft/
├── startup.lua          # Programme principal
├── .version             # Version installée
├── lib/
│   ├── speakers.lua     # Gestion multi-speakers
│   ├── player.lua       # Lecteur musique
│   ├── ambiance.lua     # Stations d'ambiance
│   ├── composer.lua     # Éditeur de mélodies
│   └── ui.lua           # Interface moniteur
└── music/
    ├── demo.rcm         # Musique exemple
    └── epic_adventure.rcm
```

## 🎵 Format .rcm

```lua
return {
  format = "rcm",
  version = 1,
  name = "Ma Musique",
  author = "Pseudo",
  bpm = 120,
  duration = 200,  -- en ticks (20 = 1 seconde)
  tracks = {
    {
      instrument = "harp",
      notes = {
        {t=0, p=12, v=1},  -- tick, pitch (0-24), volume (0-1)
      }
    }
  }
}
```

## 🎸 Instruments Noteblock

| ID | Nom |
|----|-----|
| harp | Harpe (défaut) |
| bass | Basse |
| basedrum | Grosse caisse |
| snare | Caisse claire |
| hat | Hi-hat |
| bell | Cloche |
| flute | Flûte |
| chime | Carillon |
| guitar | Guitare |
| xylophone | Xylophone |
| iron_xylophone | Vibraphone |
| cow_bell | Cloche vache |
| didgeridoo | Didgeridoo |
| bit | 8-bit |
| banjo | Banjo |
| pling | Pling |

## ❓ Dépannage

### "HTTP API non disponible"
Activez l'API HTTP dans la config du serveur/client :
```
computercraft-server.toml -> http.enabled = true
```

### "Aucun speaker trouvé"
- Vérifiez que le speaker est connecté via modem
- Clic droit sur le modem pour l'activer
- Testez avec `peripheral.getNames()`

### "Moniteur trop petit"
Minimum recommandé : 3x2 blocs de moniteur

## 📝 Licence

Projet open source - Utilisez et modifiez librement !

## 🙏 Crédits

- Musiques vanilla : C418, Lena Raine, Samuel Åberg, Aaron Cherof
- ComputerCraft : dan200
- CC:Tweaked : SquidDev
- Advanced Peripherals : SirEndii
