<?php
/**
 * Convertisseur Litematic (.litematic) vers JSON
 * Pour ComputerCraft Schematic Builder
 * 
 * Usage: php litematic2json.php fichier.litematic [sortie.json]
 * 
 * Nécessite: PHP 7.4+ avec extension zlib
 */

// ============================================
// LECTEUR NBT
// ============================================

class NBTReader {
    private $data;
    private $pos = 0;
    
    public function __construct($data) {
        $this->data = $data;
        $this->pos = 0;
    }
    
    private function readByte() {
        $val = ord($this->data[$this->pos]);
        $this->pos++;
        return $val;
    }
    
    private function readSignedByte() {
        $val = $this->readByte();
        return $val >= 128 ? $val - 256 : $val;
    }
    
    private function readShort() {
        $val = unpack('n', substr($this->data, $this->pos, 2))[1];
        $this->pos += 2;
        if ($val >= 32768) $val -= 65536;
        return $val;
    }
    
    private function readInt() {
        $val = unpack('N', substr($this->data, $this->pos, 4))[1];
        $this->pos += 4;
        if ($val >= 2147483648) $val -= 4294967296;
        return $val;
    }
    
    private function readLong() {
        $high = $this->readInt();
        $low = $this->readInt();
        // PHP ne gère pas bien les 64-bit, on retourne juste la partie basse
        return $low;
    }
    
    private function readFloat() {
        $val = unpack('G', substr($this->data, $this->pos, 4))[1];
        $this->pos += 4;
        return $val;
    }
    
    private function readDouble() {
        $val = unpack('E', substr($this->data, $this->pos, 8))[1];
        $this->pos += 8;
        return $val;
    }
    
    private function readString() {
        $len = $this->readShort();
        if ($len <= 0) return "";
        $str = substr($this->data, $this->pos, $len);
        $this->pos += $len;
        return $str;
    }
    
    private function readByteArray() {
        $len = $this->readInt();
        $arr = [];
        for ($i = 0; $i < $len; $i++) {
            $arr[] = $this->readSignedByte();
        }
        return $arr;
    }
    
    private function readIntArray() {
        $len = $this->readInt();
        $arr = [];
        for ($i = 0; $i < $len; $i++) {
            $arr[] = $this->readInt();
        }
        return $arr;
    }
    
    private function readLongArray() {
        $len = $this->readInt();
        $arr = [];
        for ($i = 0; $i < $len; $i++) {
            // Lire les 8 bytes comme 2 entiers 32-bit
            $high = $this->readInt();
            $low = $this->readInt();
            // Stocker comme tableau pour préserver les 64 bits
            $arr[] = ['high' => $high, 'low' => $low];
        }
        return $arr;
    }
    
    private function readTag($tagType) {
        switch ($tagType) {
            case 0: return null; // TAG_End
            case 1: return $this->readSignedByte(); // TAG_Byte
            case 2: return $this->readShort(); // TAG_Short
            case 3: return $this->readInt(); // TAG_Int
            case 4: return $this->readLong(); // TAG_Long
            case 5: return $this->readFloat(); // TAG_Float
            case 6: return $this->readDouble(); // TAG_Double
            case 7: return $this->readByteArray(); // TAG_Byte_Array
            case 8: return $this->readString(); // TAG_String
            case 9: return $this->readList(); // TAG_List
            case 10: return $this->readCompound(); // TAG_Compound
            case 11: return $this->readIntArray(); // TAG_Int_Array
            case 12: return $this->readLongArray(); // TAG_Long_Array
            default:
                throw new Exception("Unknown tag type: $tagType at position {$this->pos}");
        }
    }
    
    private function readList() {
        $itemType = $this->readByte();
        $len = $this->readInt();
        $arr = [];
        for ($i = 0; $i < $len; $i++) {
            $arr[] = $this->readTag($itemType);
        }
        return $arr;
    }
    
    private function readCompound() {
        $compound = [];
        while (true) {
            $tagType = $this->readByte();
            if ($tagType == 0) break; // TAG_End
            
            $name = $this->readString();
            $value = $this->readTag($tagType);
            $compound[$name] = $value;
        }
        return $compound;
    }
    
    public function parse() {
        $tagType = $this->readByte();
        if ($tagType != 10) {
            throw new Exception("Le fichier doit commencer par un TAG_Compound");
        }
        $name = $this->readString();
        $value = $this->readCompound();
        return ['name' => $name, 'value' => $value];
    }
}

// ============================================
// EXTRACTEUR DE BLOCS LITEMATICA
// ============================================

class LitematicExtractor {
    
    /**
     * Extrait les blocs d'un long array compacté (format Litematica)
     */
    public static function extractBlockStates($longArray, $palette, $volume) {
        $paletteSize = count($palette);
        $bitsPerBlock = max(2, ceil(log($paletteSize, 2)));
        
        $blocks = [];
        $bitIndex = 0;
        
        // Convertir le long array en bits
        $bits = '';
        foreach ($longArray as $long) {
            // Chaque "long" est stocké comme high/low
            $high = $long['high'];
            $low = $long['low'];
            
            // Convertir en bits (64 bits au total)
            for ($i = 31; $i >= 0; $i--) {
                $bits .= (($high >> $i) & 1) ? '1' : '0';
            }
            for ($i = 31; $i >= 0; $i--) {
                $bits .= (($low >> $i) & 1) ? '1' : '0';
            }
        }
        
        // Extraire chaque bloc
        for ($i = 0; $i < $volume; $i++) {
            $blockBits = substr($bits, $i * $bitsPerBlock, $bitsPerBlock);
            if (strlen($blockBits) < $bitsPerBlock) {
                $blockBits = str_pad($blockBits, $bitsPerBlock, '0');
            }
            // Inverser les bits (little endian)
            $blockBits = strrev($blockBits);
            $paletteIndex = bindec($blockBits);
            
            if ($paletteIndex >= $paletteSize) {
                $paletteIndex = 0;
            }
            
            $blocks[] = $paletteIndex;
        }
        
        return $blocks;
    }
    
    /**
     * Méthode alternative: extraction directe des longs
     */
    public static function extractBlockStatesDirect($longArray, $paletteSize, $volume) {
        $bitsPerBlock = max(2, (int)ceil(log($paletteSize + 1, 2)));
        $blocksPerLong = (int)floor(64 / $bitsPerBlock);
        $mask = (1 << $bitsPerBlock) - 1;
        
        $blocks = array_fill(0, $volume, 0);
        $blockIndex = 0;
        
        foreach ($longArray as $long) {
            // Reconstruire le long 64-bit
            $high = $long['high'] & 0xFFFFFFFF;
            $low = $long['low'] & 0xFFFFFFFF;
            
            // Extraire les blocs de ce long
            for ($i = 0; $i < $blocksPerLong && $blockIndex < $volume; $i++) {
                $bitOffset = $i * $bitsPerBlock;
                
                if ($bitOffset < 32) {
                    $value = ($low >> $bitOffset) & $mask;
                    // Si ça dépasse sur high
                    if ($bitOffset + $bitsPerBlock > 32) {
                        $bitsFromHigh = $bitOffset + $bitsPerBlock - 32;
                        $value |= (($high & ((1 << $bitsFromHigh) - 1)) << (32 - $bitOffset));
                    }
                } else {
                    $value = ($high >> ($bitOffset - 32)) & $mask;
                }
                
                $blocks[$blockIndex] = $value;
                $blockIndex++;
            }
        }
        
        return $blocks;
    }
}

// ============================================
// CONVERTISSEUR PRINCIPAL
// ============================================

function convertLitematic($inputFile, $outputFile = null) {
    echo "Lecture de: $inputFile\n";
    
    // Vérifier le fichier
    if (!file_exists($inputFile)) {
        die("ERREUR: Fichier non trouvé: $inputFile\n");
    }
    
    // Lire et décompresser
    $compressed = file_get_contents($inputFile);
    
    // Les fichiers litematic sont compressés en GZIP
    $data = @gzdecode($compressed);
    if ($data === false) {
        // Essayer sans décompression
        $data = $compressed;
    }
    
    // Parser le NBT
    echo "Parsing NBT...\n";
    $reader = new NBTReader($data);
    $nbt = $reader->parse();
    $root = $nbt['value'];
    
    // Debug: afficher la structure
    if (isset($root['Metadata'])) {
        echo "Metadata trouvée\n";
    }
    
    // Trouver les régions
    if (!isset($root['Regions'])) {
        die("ERREUR: Pas de 'Regions' dans le fichier\n");
    }
    
    $regions = $root['Regions'];
    $regionNames = array_keys($regions);
    
    echo "Régions trouvées: " . implode(", ", $regionNames) . "\n";
    
    // Utiliser la première région
    $regionName = $regionNames[0];
    $region = $regions[$regionName];
    
    // Dimensions
    $size = $region['Size'];
    $width = abs($size['x']);
    $height = abs($size['y']);
    $length = abs($size['z']);
    
    echo "Dimensions: {$width}x{$height}x{$length}\n";
    
    // Palette
    $paletteRaw = $region['BlockStatePalette'];
    $palette = [];
    $paletteMap = [];
    
    foreach ($paletteRaw as $index => $blockState) {
        $blockName = $blockState['Name'];
        $palette[$index] = $blockName;
        $paletteMap[$index] = $blockName;
    }
    
    echo "Palette: " . count($palette) . " blocs\n";
    
    // Blocs
    $blockStates = $region['BlockStates'];
    $volume = $width * $height * $length;
    
    echo "Volume: $volume blocs\n";
    echo "Extraction des blocs...\n";
    
    // Extraire les blocs
    $blocks = LitematicExtractor::extractBlockStatesDirect($blockStates, count($palette), $volume);
    
    // Construire le tableau 3D [Y][Z][X]
    $blocks3D = [];
    $blockIndex = 0;
    
    for ($y = 0; $y < $height; $y++) {
        $layer = [];
        for ($z = 0; $z < $length; $z++) {
            $row = [];
            for ($x = 0; $x < $width; $x++) {
                $index = ($y * $length + $z) * $width + $x;
                $row[] = $blocks[$index] ?? 0;
            }
            $layer[] = $row;
        }
        $blocks3D[] = $layer;
    }
    
    // Créer le JSON de sortie
    $output = [
        'name' => pathinfo($inputFile, PATHINFO_FILENAME),
        'source' => 'litematic',
        'width' => $width,
        'height' => $height,
        'length' => $length,
        'palette' => $paletteMap,
        'blocks' => $blocks3D
    ];
    
    // Nom du fichier de sortie
    if ($outputFile === null) {
        $outputFile = pathinfo($inputFile, PATHINFO_FILENAME) . '.json';
    }
    
    // Sauvegarder
    $json = json_encode($output, JSON_PRETTY_PRINT);
    file_put_contents($outputFile, $json);
    
    echo "Converti avec succès: $outputFile\n";
    echo "Taille: " . round(strlen($json) / 1024, 2) . " KB\n";
    
    // Statistiques
    $blockCounts = array_count_values($blocks);
    echo "\nMatériaux nécessaires:\n";
    arsort($blockCounts);
    foreach ($blockCounts as $paletteIdx => $count) {
        $blockName = $palette[$paletteIdx] ?? "unknown:$paletteIdx";
        if ($blockName !== 'minecraft:air') {
            echo "  $blockName: $count\n";
        }
    }
    
    return $outputFile;
}

// ============================================
// MAIN
// ============================================

if (php_sapi_name() === 'cli') {
    if ($argc < 2) {
        echo "Usage: php litematic2json.php <fichier.litematic> [sortie.json]\n";
        echo "\n";
        echo "Convertit un fichier Litematica en JSON pour ComputerCraft.\n";
        exit(1);
    }
    
    $input = $argv[1];
    $output = $argv[2] ?? null;
    
    try {
        convertLitematic($input, $output);
    } catch (Exception $e) {
        echo "ERREUR: " . $e->getMessage() . "\n";
        exit(1);
    }
}
