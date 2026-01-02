# 🔨 QUARRY MINER

Programme de minage automatique pour Mining Turtle (ComputerCraft / CC:Tweaked)

Creuse automatiquement une zone rectangulaire entre deux coordonnées.

---

## 📋 Fonctionnalités

- **Minage par tranche** : Creuse de haut en bas, tranche par tranche
- **GPS optionnel** : Fonctionne avec ou sans réseau GPS
- **Dépôt automatique** : Retourne au coffre quand l'inventaire est plein
- **Gestion du fuel** : Calcule le fuel nécessaire et se recharge automatiquement
- **Reprise des chutes** : Gère le sable et gravier qui tombent

---

## 📦 Installation

### Option 1 : Installer automatique

```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/quarry/installer.lua
```

### Option 2 : Téléchargement direct

```
wget https://raw.githubusercontent.com/chausette/computerCraft/master/quarry/quarry.lua
```

### Option 3 : Pastebin

```
pastebin get [CODE] quarry.lua
```

---

## 🚀 Utilisation

### Lancer le programme

```
quarry
```

### Étapes de configuration

Le programme te guide avec des questions :

```
1. Position actuelle de la turtle
   → Automatique si GPS disponible
   → Sinon, entre X, Y, Z manuellement (F3 dans Minecraft)

2. Direction actuelle
   → 0 = Nord (-Z)
   → 1 = Est (+X)
   → 2 = Sud (+Z)
   → 3 = Ouest (-X)

3. Coin 1 de la zone
   → Coordonnées X, Y, Z du premier coin

4. Coin 2 de la zone
   → Coordonnées X, Y, Z du coin opposé

5. Coffre fuel (optionnel)
   → Si tu veux un coffre séparé pour le fuel
```

### Écran de confirmation

Avant de démarrer, le programme affiche :

```
Resume:
  Zone: 10 x 20 x 15
  Volume: 3000 blocs
  De (100,40,200) a (109,59,214)

Fuel:
  Actuel: 5000
  Estime necessaire: 4200
  OK - Fuel suffisant

Demarrer le minage? [O/n]:
```

---

## ⚙️ Préparation avant le minage

### 1. Fuel

Mets du combustible dans le **slot 16** de la turtle :
- Charbon
- Charbon de bois
- Blaze rod
- Etc.

Le slot 16 est réservé au fuel et ne sera pas vidé dans le coffre.

### 2. Coffre de dépôt

**Option A** : Place un coffre **SOUS** la turtle avant de lancer le programme

**Option B** : Mets un coffre dans l'inventaire de la turtle, elle le posera automatiquement

### 3. Position de départ

Place la turtle là où tu veux que soit le point de dépôt. C'est là qu'elle reviendra pour vider son inventaire.

### 4. Coffre fuel (optionnel)

Si tu configures un coffre fuel séparé :
- Place un coffre aux coordonnées indiquées
- Remplis-le de charbon
- La turtle ira se recharger si elle manque de fuel

---

## 📐 Comment définir la zone

### Trouver les coordonnées

1. Appuie sur **F3** dans Minecraft
2. Regarde la ligne "XYZ" pour ta position
3. Note les coordonnées des deux coins opposés de la zone

### Exemple

Tu veux miner une zone de 10x10 blocs, profonde de 20 blocs :

```
Coin 1 (surface, coin nord-ouest):
  X: 100
  Y: 64    ← niveau du sol
  Z: 200

Coin 2 (fond, coin sud-est):
  X: 109   ← 100 + 9 = zone de 10 blocs
  Y: 44    ← 64 - 20 = profondeur de 20 blocs
  Z: 209   ← 200 + 9 = zone de 10 blocs
```

**Note** : L'ordre des coins n'a pas d'importance, le programme calcule automatiquement min/max.

---

## 🔄 Méthode de minage

Le programme utilise la méthode **tranche par tranche** :

```
Vue de dessus (une tranche Z) :

    X →
  ┌─────────┐
Y │ ← ← ← ← │  Ligne 1 (haut)
↓ │ → → → → │  Ligne 2
  │ ← ← ← ← │  Ligne 3
  │ → → → → │  Ligne 4 (bas)
  └─────────┘

Puis passe à la tranche Z suivante
```

### Avantages de cette méthode

- Optimal pour les carrières
- Gère bien le gravier/sable qui tombe
- Mouvements efficaces (serpentin)

---

## 📊 Pendant le minage

L'écran affiche en temps réel :

```
=== QUARRY EN COURS ===

Position: 105, 52, 207
Blocs mines: 1523
Fuel: 3200
Temps: 12:34

Ctrl+T pour arreter
```

### Actions automatiques

| Situation | Action |
|-----------|--------|
| Inventaire plein | Retourne au coffre, dépose, revient |
| Fuel bas | Utilise le slot 16 ou va au coffre fuel |
| Gravier/sable | Attend et re-creuse jusqu'à ce que ce soit vide |
| Obstacle | Creuse à travers |

---

## ⚠️ Arrêter le programme

- **Ctrl + T** : Arrête proprement la turtle
- La turtle s'arrête où elle est
- Relance `quarry` pour recommencer (nouvelle config)

---

## 🗂️ Slots de l'inventaire

```
┌────┬────┬────┬────┐
│ 1  │ 2  │ 3  │ 4  │  ← Slots de minage
├────┼────┼────┼────┤
│ 5  │ 6  │ 7  │ 8  │  ← Slots de minage
├────┼────┼────┼────┤
│ 9  │ 10 │ 11 │ 12 │  ← Slots de minage
├────┼────┼────┼────┤
│ 13 │ 14 │ 15 │ 16 │
│    │    │Coff│Fuel│  ← 15: Coffre (optionnel)
│    │    │ re │    │  ← 16: Fuel (réservé)
└────┴────┴────┴────┘
```

- **Slots 1-14** : Stockage des blocs minés
- **Slot 15** : Coffre à poser (optionnel)
- **Slot 16** : Fuel (charbon, etc.)

---

## 🔧 Résolution de problèmes

### "Pas de fuel!"

- Mets du charbon dans le slot 16
- Tape `refuel 16` pour recharger manuellement

### La turtle ne bouge pas

- Vérifie qu'elle a du fuel : `print(turtle.getFuelLevel())`
- Vérifie qu'elle n'est pas bloquée physiquement

### GPS non disponible

- Normal si tu n'as pas de réseau GPS
- Le programme fonctionne en mode manuel
- Tu dois juste entrer les coordonnées toi-même

### "Fuel insuffisant"

Le programme t'avertit si le fuel actuel est inférieur à l'estimation. Tu peux :
- Ajouter du fuel dans le slot 16
- Configurer un coffre fuel pour le rechargement auto
- Lancer quand même (la turtle s'arrêtera si elle n'a plus de fuel)

### L'inventaire se remplit trop vite

- Vérifie que le coffre de dépôt est bien placé
- Vérifie que la turtle peut accéder au coffre (pas de bloc devant)

---

## 📈 Calcul du fuel

Le programme estime le fuel nécessaire :

```
Fuel = Volume de la zone
     + Trajets aller-retour au coffre
     + Marge de sécurité (30%)
```

### Consommation de fuel

| Action | Fuel |
|--------|------|
| Avancer/Reculer | 1 |
| Monter/Descendre | 1 |
| Tourner | 0 |
| Creuser | 0 |

### Exemple

Zone de 10x10x20 = 2000 blocs
- Déplacements dans la zone : ~2000
- Retours au coffre (~30 trajets de 50 blocs) : ~3000
- **Total estimé : ~6500 fuel**

Un charbon = 80 fuel, donc ~82 charbons nécessaires.

---

## 💡 Conseils

1. **Commence petit** : Teste d'abord sur une zone 5x5x5

2. **Prévois large** : Mets plus de fuel que l'estimation

3. **Coffre assez grand** : Un double coffre peut contenir plus de blocs

4. **Position sûre** : Place la turtle en surface, pas dans un trou

5. **Éclaire la zone** : Si tu mines en surface, éclaire pour éviter les mobs

---

## 📝 Exemple complet

```
> quarry

================================
   QUARRY MINER v1.0
================================

Recherche GPS...
GPS non disponible - Mode manuel

Configuration manuelle:

Position actuelle de la turtle:
  (GPS non disponible)
  X: 100
  Y: 65
  Z: 200

Direction actuelle:
  0=Nord(-Z) 1=Est(+X) 2=Sud(+Z) 3=Ouest(-X)
  Direction: 0

Coin 1 de la zone:
  X: 105
  Y: 60
  Z: 205

Coin 2 de la zone:
  X: 115
  Y: 40
  Z: 215

Configurer un coffre fuel? [o/N]: n

Resume:
  Zone: 11 x 21 x 11
  Volume: 2541 blocs
  De (105,40,205) a (115,60,215)

Fuel:
  Actuel: 5000
  Estime necessaire: 3800
  OK - Fuel suffisant

Coffre depot:
  Position: 100, 65, 200

IMPORTANT:
  - Place un coffre SOUS la turtle
  - Fuel dans le slot 16

Demarrer le minage? [O/n]: o

Demarrage du minage...
Verification du coffre de depot...

=== QUARRY EN COURS ===
Position: 107, 58, 206
Blocs mines: 234
Fuel: 4850
Temps: 2:15
```

---

## 📜 Licence

Programme libre d'utilisation et de modification.

Créé pour ComputerCraft / CC:Tweaked sur Minecraft.