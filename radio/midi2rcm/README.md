# MIDI to RadioCraft Converter

Convertit des fichiers MIDI en format `.rcm` lisible par RadioCraft (ComputerCraft).

## Installation

```bash
pip install mido
```

## Utilisation

### Convertir un fichier MIDI

```bash
python midi2rcm.py musique.mid
python midi2rcm.py musique.mid -n "Ma Super Musique" -a "MonPseudo"
python midi2rcm.py musique.mid -o sortie.rcm
```

### Créer un fichier exemple

```bash
python midi2rcm.py --sample
```

## Options

| Option | Description |
|--------|-------------|
| `-o, --output` | Chemin du fichier de sortie |
| `-n, --name` | Nom de la musique |
| `-a, --author` | Auteur de la musique |
| `--sample` | Génère un fichier exemple |

## Format .rcm

Le format `.rcm` est un fichier Lua contenant :

```lua
return {
  format = "rcm",
  version = 1,
  name = "Nom",
  author = "Auteur",
  bpm = 120,
  duration = 200,  -- en ticks (20 ticks = 1 seconde)
  tracks = {
    {
      instrument = "harp",
      notes = {
        {t=0, p=12, v=1},  -- tick, pitch (0-24), volume (0-1)
        {t=10, p=15, v=0.8},
      }
    }
  }
}
```

## Instruments supportés

Les instruments MIDI sont convertis vers les instruments noteblock :

- **Piano** → harp
- **Guitar** → guitar
- **Bass** → bass
- **Organ** → bit
- **Flute/Pipe** → flute
- **Xylophone** → xylophone
- **Percussion** → basedrum, snare, hat, bell, cow_bell

## Transfert vers Minecraft

1. Convertis ton fichier MIDI en `.rcm`
2. Copie le contenu du fichier `.rcm`
3. Dans Minecraft, crée un fichier sur la disquette :
   ```
   edit /disk/songs/mamusique.rcm
   ```
4. Colle le contenu (ou utilise un mod comme CraftOS-PC pour le transfert)

## Notes

- Les notes MIDI sont transposées pour rentrer dans la plage noteblock (2 octaves)
- Le timing est converti en ticks Minecraft (20 ticks/seconde)
- Les fichiers complexes peuvent être volumineux
