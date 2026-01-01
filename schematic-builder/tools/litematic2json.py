#!/usr/bin/env python3
"""
Convertisseur Litematic (.litematic) vers JSON
Pour ComputerCraft Schematic Builder

Usage: python litematic2json.py fichier.litematic [sortie.json]

Nécessite: pip install nbtlib
"""

import sys
import json
import gzip
import struct
from pathlib import Path

# ============================================
# LECTEUR NBT SIMPLE
# ============================================

class NBTReader:
    def __init__(self, data):
        self.data = data
        self.pos = 0
    
    def read_byte(self):
        val = self.data[self.pos]
        self.pos += 1
        return val
    
    def read_signed_byte(self):
        val = self.read_byte()
        return val - 256 if val >= 128 else val
    
    def read_short(self):
        val = struct.unpack('>h', self.data[self.pos:self.pos+2])[0]
        self.pos += 2
        return val
    
    def read_int(self):
        val = struct.unpack('>i', self.data[self.pos:self.pos+4])[0]
        self.pos += 4
        return val
    
    def read_long(self):
        val = struct.unpack('>q', self.data[self.pos:self.pos+8])[0]
        self.pos += 8
        return val
    
    def read_float(self):
        val = struct.unpack('>f', self.data[self.pos:self.pos+4])[0]
        self.pos += 4
        return val
    
    def read_double(self):
        val = struct.unpack('>d', self.data[self.pos:self.pos+8])[0]
        self.pos += 8
        return val
    
    def read_string(self):
        length = struct.unpack('>H', self.data[self.pos:self.pos+2])[0]
        self.pos += 2
        if length == 0:
            return ""
        string = self.data[self.pos:self.pos+length].decode('utf-8')
        self.pos += length
        return string
    
    def read_byte_array(self):
        length = self.read_int()
        arr = []
        for _ in range(length):
            arr.append(self.read_signed_byte())
        return arr
    
    def read_int_array(self):
        length = self.read_int()
        arr = []
        for _ in range(length):
            arr.append(self.read_int())
        return arr
    
    def read_long_array(self):
        length = self.read_int()
        arr = []
        for _ in range(length):
            arr.append(self.read_long())
        return arr
    
    def read_tag(self, tag_type):
        if tag_type == 0:  # TAG_End
            return None
        elif tag_type == 1:  # TAG_Byte
            return self.read_signed_byte()
        elif tag_type == 2:  # TAG_Short
            return self.read_short()
        elif tag_type == 3:  # TAG_Int
            return self.read_int()
        elif tag_type == 4:  # TAG_Long
            return self.read_long()
        elif tag_type == 5:  # TAG_Float
            return self.read_float()
        elif tag_type == 6:  # TAG_Double
            return self.read_double()
        elif tag_type == 7:  # TAG_Byte_Array
            return self.read_byte_array()
        elif tag_type == 8:  # TAG_String
            return self.read_string()
        elif tag_type == 9:  # TAG_List
            return self.read_list()
        elif tag_type == 10:  # TAG_Compound
            return self.read_compound()
        elif tag_type == 11:  # TAG_Int_Array
            return self.read_int_array()
        elif tag_type == 12:  # TAG_Long_Array
            return self.read_long_array()
        else:
            raise ValueError(f"Unknown tag type: {tag_type}")
    
    def read_list(self):
        item_type = self.read_byte()
        length = self.read_int()
        arr = []
        for _ in range(length):
            arr.append(self.read_tag(item_type))
        return arr
    
    def read_compound(self):
        compound = {}
        while True:
            tag_type = self.read_byte()
            if tag_type == 0:  # TAG_End
                break
            name = self.read_string()
            value = self.read_tag(tag_type)
            compound[name] = value
        return compound
    
    def parse(self):
        tag_type = self.read_byte()
        if tag_type != 10:
            raise ValueError("File must start with TAG_Compound")
        name = self.read_string()
        value = self.read_compound()
        return {'name': name, 'value': value}


# ============================================
# EXTRACTEUR LITEMATICA
# ============================================

def extract_blocks(long_array, palette_size, volume):
    """Extrait les blocs du long array compacté Litematica"""
    
    bits_per_block = max(2, (palette_size - 1).bit_length())
    mask = (1 << bits_per_block) - 1
    
    blocks = []
    bit_index = 0
    
    for i in range(volume):
        # Trouver dans quel long on est
        long_index = (i * bits_per_block) // 64
        bit_offset = (i * bits_per_block) % 64
        
        if long_index >= len(long_array):
            blocks.append(0)
            continue
        
        # Extraire la valeur
        value = (long_array[long_index] >> bit_offset) & mask
        
        # Si la valeur s'étend sur le long suivant
        if bit_offset + bits_per_block > 64 and long_index + 1 < len(long_array):
            bits_in_next = bit_offset + bits_per_block - 64
            value |= (long_array[long_index + 1] & ((1 << bits_in_next) - 1)) << (bits_per_block - bits_in_next)
        
        blocks.append(value & mask)
    
    return blocks


# ============================================
# CONVERTISSEUR PRINCIPAL
# ============================================

def convert_litematic(input_file, output_file=None):
    print(f"Lecture de: {input_file}")
    
    # Lire le fichier
    with open(input_file, 'rb') as f:
        compressed = f.read()
    
    # Décompresser (GZIP)
    try:
        data = gzip.decompress(compressed)
    except:
        data = compressed
    
    # Parser NBT
    print("Parsing NBT...")
    reader = NBTReader(data)
    nbt = reader.parse()
    root = nbt['value']
    
    # Trouver les régions
    if 'Regions' not in root:
        raise ValueError("Pas de 'Regions' dans le fichier")
    
    regions = root['Regions']
    region_names = list(regions.keys())
    print(f"Régions trouvées: {', '.join(region_names)}")
    
    # Utiliser la première région
    region_name = region_names[0]
    region = regions[region_name]
    
    # Dimensions
    size = region['Size']
    width = abs(size['x'])
    height = abs(size['y'])
    length = abs(size['z'])
    
    print(f"Dimensions: {width}x{height}x{length}")
    
    # Palette
    palette_raw = region['BlockStatePalette']
    palette = {}
    
    for idx, block_state in enumerate(palette_raw):
        block_name = block_state['Name']
        palette[idx] = block_name
    
    print(f"Palette: {len(palette)} blocs")
    
    # Blocs
    block_states = region['BlockStates']
    volume = width * height * length
    
    print(f"Volume: {volume} blocs")
    print("Extraction des blocs...")
    
    # Extraire les blocs
    blocks = extract_blocks(block_states, len(palette), volume)
    
    # Construire le tableau 3D [Y][Z][X]
    blocks_3d = []
    
    for y in range(height):
        layer = []
        for z in range(length):
            row = []
            for x in range(width):
                index = (y * length + z) * width + x
                row.append(blocks[index] if index < len(blocks) else 0)
            layer.append(row)
        blocks_3d.append(layer)
    
    # Créer le JSON de sortie
    output = {
        'name': Path(input_file).stem,
        'source': 'litematic',
        'width': width,
        'height': height,
        'length': length,
        'palette': {str(k): v for k, v in palette.items()},
        'blocks': blocks_3d
    }
    
    # Nom du fichier de sortie
    if output_file is None:
        output_file = Path(input_file).stem + '.json'
    
    # Sauvegarder
    with open(output_file, 'w') as f:
        json.dump(output, f, indent=2)
    
    file_size = Path(output_file).stat().st_size / 1024
    print(f"Converti avec succès: {output_file}")
    print(f"Taille: {file_size:.2f} KB")
    
    # Statistiques
    block_counts = {}
    for block_idx in blocks:
        block_counts[block_idx] = block_counts.get(block_idx, 0) + 1
    
    print("\nMatériaux nécessaires:")
    sorted_counts = sorted(block_counts.items(), key=lambda x: -x[1])
    for palette_idx, count in sorted_counts:
        block_name = palette.get(palette_idx, f"unknown:{palette_idx}")
        if block_name != 'minecraft:air':
            print(f"  {block_name}: {count}")
    
    return output_file


# ============================================
# MAIN
# ============================================

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python litematic2json.py <fichier.litematic> [sortie.json]")
        print()
        print("Convertit un fichier Litematica en JSON pour ComputerCraft.")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    try:
        convert_litematic(input_file, output_file)
    except Exception as e:
        print(f"ERREUR: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
