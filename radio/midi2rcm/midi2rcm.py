#!/usr/bin/env python3
"""
MIDI to RadioCraft Music (.rcm) Converter
Convertit des fichiers MIDI en format lisible par RadioCraft (ComputerCraft)
"""

import json
import argparse
import sys
from pathlib import Path

try:
    from midiutil import MIDIFile
    import mido
except ImportError:
    print("Installation des dépendances requises...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "mido", "midiutil"])
    import mido

# Mapping des instruments MIDI vers les instruments Noteblock
MIDI_TO_NOTEBLOCK = {
    # Piano (0-7)
    range(0, 8): "harp",
    # Chromatic Percussion (8-15)
    range(8, 16): "xylophone",
    # Organ (16-23)
    range(16, 24): "bit",
    # Guitar (24-31)
    range(24, 32): "guitar",
    # Bass (32-39)
    range(32, 40): "bass",
    # Strings (40-47)
    range(40, 48): "harp",
    # Ensemble (48-55)
    range(48, 56): "harp",
    # Brass (56-63)
    range(56, 64): "didgeridoo",
    # Reed (64-71)
    range(64, 72): "flute",
    # Pipe (72-79)
    range(72, 80): "flute",
    # Synth Lead (80-87)
    range(80, 88): "bit",
    # Synth Pad (88-95)
    range(88, 96): "harp",
    # Synth Effects (96-103)
    range(96, 104): "chime",
    # Ethnic (104-111)
    range(104, 112): "banjo",
    # Percussive (112-119)
    range(112, 120): "iron_xylophone",
    # Sound Effects (120-127)
    range(120, 128): "bell",
}

# Instruments de percussion (canal 10 MIDI)
PERCUSSION_MAP = {
    35: "basedrum",  # Acoustic Bass Drum
    36: "basedrum",  # Bass Drum 1
    37: "snare",     # Side Stick
    38: "snare",     # Acoustic Snare
    39: "snare",     # Hand Clap
    40: "snare",     # Electric Snare
    41: "basedrum",  # Low Floor Tom
    42: "hat",       # Closed Hi-Hat
    43: "basedrum",  # High Floor Tom
    44: "hat",       # Pedal Hi-Hat
    45: "basedrum",  # Low Tom
    46: "hat",       # Open Hi-Hat
    47: "basedrum",  # Low-Mid Tom
    48: "basedrum",  # Hi-Mid Tom
    49: "bell",      # Crash Cymbal 1
    50: "basedrum",  # High Tom
    51: "bell",      # Ride Cymbal 1
    52: "bell",      # Chinese Cymbal
    53: "bell",      # Ride Bell
    54: "cow_bell",  # Tambourine
    55: "bell",      # Splash Cymbal
    56: "cow_bell",  # Cowbell
    57: "bell",      # Crash Cymbal 2
    59: "bell",      # Ride Cymbal 2
    75: "hat",       # Claves
    76: "hat",       # Hi Wood Block
    77: "hat",       # Low Wood Block
}

# Liste des instruments noteblock disponibles
NOTEBLOCK_INSTRUMENTS = [
    "harp", "bass", "basedrum", "snare", "hat", "bell", 
    "flute", "chime", "guitar", "xylophone", "iron_xylophone",
    "cow_bell", "didgeridoo", "bit", "banjo", "pling"
]


def get_noteblock_instrument(midi_program: int, is_percussion: bool = False, note: int = 0) -> str:
    """Convertit un programme MIDI en instrument noteblock"""
    if is_percussion:
        return PERCUSSION_MAP.get(note, "snare")
    
    for midi_range, instrument in MIDI_TO_NOTEBLOCK.items():
        if midi_program in midi_range:
            return instrument
    return "harp"


def midi_note_to_noteblock(midi_note: int) -> tuple:
    """
    Convertit une note MIDI (0-127) en note noteblock (0-24)
    Retourne (pitch, octave_shift) où octave_shift indique si la note est hors range
    """
    # Noteblock range: F#3 (54) to F#5 (78) = 24 notes
    # On centre sur cette plage
    noteblock_base = 54  # F#3 en MIDI
    
    # Ajuste la note dans la plage
    adjusted_note = midi_note
    octave_shift = 0
    
    while adjusted_note < noteblock_base:
        adjusted_note += 12
        octave_shift -= 1
    while adjusted_note > noteblock_base + 24:
        adjusted_note -= 12
        octave_shift += 1
    
    pitch = adjusted_note - noteblock_base
    return (max(0, min(24, pitch)), octave_shift)


def parse_midi(filepath: str) -> dict:
    """Parse un fichier MIDI et extrait les données"""
    mid = mido.MidiFile(filepath)
    
    # Récupère le BPM (tempo)
    bpm = 120  # Défaut
    for track in mid.tracks:
        for msg in track:
            if msg.type == 'set_tempo':
                bpm = int(60000000 / msg.tempo)
                break
    
    # Ticks par beat
    ticks_per_beat = mid.ticks_per_beat
    
    # Parse les pistes
    tracks_data = {}
    current_programs = {}  # Canal -> Programme MIDI
    
    for track_idx, track in enumerate(mid.tracks):
        current_tick = 0
        
        for msg in track:
            current_tick += msg.time
            
            if msg.type == 'program_change':
                current_programs[msg.channel] = msg.program
            
            elif msg.type == 'note_on' and msg.velocity > 0:
                channel = msg.channel
                is_percussion = (channel == 9)  # Canal 10 en MIDI = index 9
                
                program = current_programs.get(channel, 0)
                instrument = get_noteblock_instrument(program, is_percussion, msg.note)
                
                if instrument not in tracks_data:
                    tracks_data[instrument] = []
                
                pitch, _ = midi_note_to_noteblock(msg.note)
                volume = msg.velocity / 127.0
                
                # Convertit les ticks MIDI en ticks RadioCraft (20 ticks = 1 seconde MC)
                # 1 beat = ticks_per_beat ticks MIDI
                # À 120 BPM, 1 beat = 0.5 secondes = 10 ticks MC
                mc_ticks_per_beat = (60 / bpm) * 20
                mc_tick = int((current_tick / ticks_per_beat) * mc_ticks_per_beat)
                
                tracks_data[instrument].append({
                    "tick": mc_tick,
                    "pitch": pitch,
                    "vol": round(volume, 2)
                })
    
    return {
        "bpm": bpm,
        "tracks": tracks_data
    }


def convert_to_rcm(midi_path: str, output_path: str = None, name: str = None, author: str = "Unknown") -> str:
    """Convertit un fichier MIDI en format .rcm"""
    
    midi_path = Path(midi_path)
    if not midi_path.exists():
        raise FileNotFoundError(f"Fichier MIDI non trouvé: {midi_path}")
    
    if output_path is None:
        output_path = midi_path.with_suffix('.rcm')
    else:
        output_path = Path(output_path)
    
    if name is None:
        name = midi_path.stem
    
    print(f"Conversion de {midi_path.name}...")
    
    # Parse le MIDI
    midi_data = parse_midi(str(midi_path))
    
    # Calcule la durée totale
    max_tick = 0
    total_notes = 0
    for instrument, notes in midi_data["tracks"].items():
        total_notes += len(notes)
        for note in notes:
            max_tick = max(max_tick, note["tick"])
    
    # Crée la structure RCM
    rcm_data = {
        "format": "rcm",
        "version": 1,
        "name": name,
        "author": author,
        "bpm": midi_data["bpm"],
        "duration": max_tick,
        "tracks": []
    }
    
    # Convertit les pistes
    for instrument, notes in midi_data["tracks"].items():
        if notes:  # Ignore les pistes vides
            # Trie par tick
            sorted_notes = sorted(notes, key=lambda x: x["tick"])
            rcm_data["tracks"].append({
                "instrument": instrument,
                "notes": sorted_notes
            })
    
    # Génère le Lua
    lua_output = generate_lua(rcm_data)
    
    # Sauvegarde
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(lua_output)
    
    print(f"✓ Conversion terminée!")
    print(f"  - Fichier: {output_path}")
    print(f"  - BPM: {rcm_data['bpm']}")
    print(f"  - Durée: {max_tick} ticks ({max_tick/20:.1f} secondes)")
    print(f"  - Notes: {total_notes}")
    print(f"  - Pistes: {len(rcm_data['tracks'])}")
    
    return str(output_path)


def generate_lua(rcm_data: dict) -> str:
    """Génère le code Lua pour le fichier .rcm"""
    
    lines = [
        "-- RadioCraft Music File",
        f"-- Generated by midi2rcm",
        "return {",
        f'  format = "rcm",',
        f'  version = {rcm_data["version"]},',
        f'  name = "{rcm_data["name"]}",',
        f'  author = "{rcm_data["author"]}",',
        f'  bpm = {rcm_data["bpm"]},',
        f'  duration = {rcm_data["duration"]},',
        "  tracks = {"
    ]
    
    for track in rcm_data["tracks"]:
        lines.append("    {")
        lines.append(f'      instrument = "{track["instrument"]}",')
        lines.append("      notes = {")
        
        # Groupe les notes par ligne pour réduire la taille
        note_strs = []
        for note in track["notes"]:
            note_strs.append(f'{{t={note["tick"]},p={note["pitch"]},v={note["vol"]}}}')
        
        # Écrit 5 notes par ligne
        for i in range(0, len(note_strs), 5):
            chunk = note_strs[i:i+5]
            lines.append("        " + ",".join(chunk) + ",")
        
        lines.append("      }")
        lines.append("    },")
    
    lines.append("  }")
    lines.append("}")
    
    return "\n".join(lines)


def create_sample_rcm():
    """Crée un fichier .rcm d'exemple"""
    sample = {
        "format": "rcm",
        "version": 1,
        "name": "Sample Melody",
        "author": "RadioCraft",
        "bpm": 120,
        "duration": 80,
        "tracks": [
            {
                "instrument": "harp",
                "notes": [
                    {"tick": 0, "pitch": 6, "vol": 1},
                    {"tick": 10, "pitch": 8, "vol": 1},
                    {"tick": 20, "pitch": 10, "vol": 1},
                    {"tick": 30, "pitch": 6, "vol": 1},
                    {"tick": 40, "pitch": 8, "vol": 1},
                    {"tick": 50, "pitch": 10, "vol": 1},
                    {"tick": 60, "pitch": 13, "vol": 1},
                    {"tick": 70, "pitch": 13, "vol": 1},
                ]
            },
            {
                "instrument": "bass",
                "notes": [
                    {"tick": 0, "pitch": 6, "vol": 0.8},
                    {"tick": 20, "pitch": 6, "vol": 0.8},
                    {"tick": 40, "pitch": 8, "vol": 0.8},
                    {"tick": 60, "pitch": 6, "vol": 0.8},
                ]
            }
        ]
    }
    
    lua_output = generate_lua(sample)
    with open("sample.rcm", 'w') as f:
        f.write(lua_output)
    print("✓ Fichier sample.rcm créé!")


def main():
    parser = argparse.ArgumentParser(
        description="Convertit des fichiers MIDI en format RadioCraft (.rcm)"
    )
    parser.add_argument("input", nargs="?", help="Fichier MIDI à convertir")
    parser.add_argument("-o", "--output", help="Fichier de sortie (.rcm)")
    parser.add_argument("-n", "--name", help="Nom de la musique")
    parser.add_argument("-a", "--author", default="Unknown", help="Auteur")
    parser.add_argument("--sample", action="store_true", help="Crée un fichier .rcm d'exemple")
    
    args = parser.parse_args()
    
    if args.sample:
        create_sample_rcm()
        return
    
    if not args.input:
        parser.print_help()
        print("\nExemple: python midi2rcm.py musique.mid -n 'Ma Musique' -a 'Moi'")
        return
    
    try:
        convert_to_rcm(args.input, args.output, args.name, args.author)
    except Exception as e:
        print(f"Erreur: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
