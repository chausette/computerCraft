-- RadioCraft Diagnostic Tool
-- Execute ce script pour tester si tout fonctionne

print("=== RadioCraft Diagnostic ===")
print("")

-- Test 1: Speakers
print("[1] Detection des speakers...")
local speakerCount = 0
local speakerName = nil
for _, name in ipairs(peripheral.getNames()) do
    if peripheral.getType(name) == "speaker" then
        speakerCount = speakerCount + 1
        speakerName = name
        print("    Trouve: " .. name)
    end
end

if speakerCount == 0 then
    print("    ERREUR: Aucun speaker trouve!")
    print("    -> Connectez un speaker au computer")
    return
else
    print("    OK: " .. speakerCount .. " speaker(s)")
end

-- Test 2: Son simple
print("")
print("[2] Test son noteblock...")
local speaker = peripheral.wrap(speakerName)
local ok, err = pcall(function()
    speaker.playNote("harp", 1, 12)
end)
if ok then
    print("    OK: playNote fonctionne")
else
    print("    ERREUR: " .. tostring(err))
end

sleep(0.5)

-- Test 3: Son Minecraft
print("")
print("[3] Test son Minecraft...")
local sounds = {
    "minecraft:block.note_block.harp",
    "minecraft:entity.experience_orb.pickup",
    "minecraft:entity.chicken.ambient",
    "minecraft:ambient.cave",
}

for _, sound in ipairs(sounds) do
    local ok, err = pcall(function()
        speaker.playSound(sound, 1, 1)
    end)
    if ok then
        print("    OK: " .. sound)
    else
        print("    ERREUR: " .. sound .. " - " .. tostring(err))
    end
    sleep(0.3)
end

-- Test 4: Fichiers RCM
print("")
print("[4] Recherche fichiers .rcm...")
local paths = {"/radiocraft/music", "/disk/songs"}
local rcmCount = 0

for _, path in ipairs(paths) do
    if fs.exists(path) then
        print("    Dossier " .. path .. " existe")
        for _, file in ipairs(fs.list(path)) do
            if string.match(file, "%.rcm$") then
                rcmCount = rcmCount + 1
                print("      - " .. file)
            end
        end
    else
        print("    Dossier " .. path .. " N'EXISTE PAS")
    end
end

if rcmCount == 0 then
    print("    Aucun fichier .rcm trouve!")
    print("    -> Les fichiers demo.rcm doivent etre dans /radiocraft/music/")
end

-- Test 5: Test disque (info seulement)
print("")
print("[5] Info sur les disques...")
print("    ATTENTION: Les speakers CC:Tweaked ne peuvent")
print("    PAS jouer les sons de disques Minecraft!")
print("    Seuls les fichiers .rcm fonctionnent pour la musique.")

-- Resume
print("")
print("=== Resume ===")
print("Speakers: " .. speakerCount)
print("Fichiers .rcm: " .. rcmCount)
print("")

if rcmCount == 0 then
    print("SOLUTION: Creez un fichier .rcm de test:")
    print("  edit /radiocraft/music/test.rcm")
    print("")
    print("Collez ce contenu:")
    print('return {format="rcm",version=1,name="Test",')
    print('author="Test",bpm=120,duration=80,tracks={{')
    print('instrument="harp",notes={{t=0,p=12,v=1},')
    print('{t=10,p=14,v=1},{t=20,p=16,v=1},{t=30,p=12,v=1}}}}}')
end

print("")
print("Appuyez sur une touche...")
os.pullEvent("key")
