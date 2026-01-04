# Potion Maker 🧪

Système automatisé de brassage de potions pour **Minecraft 1.21** avec **ComputerCraft**.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Minecraft](https://img.shields.io/badge/Minecraft-1.21-green)
![Loader](https://img.shields.io/badge/Loader-NeoForge-orange)

## Fonctionnalités

- ✅ **Craft intelligent** : calcul automatique des étapes intermédiaires
- ✅ **File d'attente FIFO** : premier commandé, premier servi
- ✅ **Interface tactile** : moniteur 3x2 avec dashboard
- ✅ **Contrôle à distance** : via Pocket Computer
- ✅ **Tri automatique** : du coffre input vers les stockages
- ✅ **Alertes stock bas** : affichage + son
- ✅ **Recettes modifiables** : base de données JSON
- ✅ **Persistance** : file d'attente sauvegardée entre redémarrages

## Prérequis

### Mods requis
- ComputerCraft: Tweaked
- Advanced Peripherals
- Tom's Peripherals (optionnel)

### Matériel Minecraft
- 1 Advanced Computer
- 1 Advanced Monitor (3x2)
- 2 Alambics (Brewing Stands)
- 5 Coffres vanilla
- 1 Speaker
- Wired Modems + câbles réseau
- 1 Pocket Computer (optionnel)

## Installation

### Sur l'ordinateur principal

```lua
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/potionMaker/install.lua
```

L'assistant de configuration se lancera automatiquement.

### Sur le Pocket Computer

```lua
wget https://raw.githubusercontent.com/chausette/computerCraft/master/potionMaker/pocket/potion_remote.lua remote
```

Puis lancez avec : `remote`

## Configuration des coffres

Le wizard vous demandera d'assigner chaque coffre :

| Coffre | Usage |
|--------|-------|
| **Input** | Dépôt des items (tri automatique) |
| **Fioles d'eau** | Stock de fioles d'eau |
| **Ingrédients** | Stock d'ingrédients |
| **Potions** | Stockage des potions terminées |
| **Output** | Distribution des potions demandées |

## Utilisation

### Interface Moniteur

- **Dashboard** : Vue d'ensemble (alambics, file d'attente, alertes)
- **Commander** : Sélectionner et commander des potions
- **Potions** : Voir le stock et distribuer
- **Stock** : Voir les ingrédients disponibles

### Types de potions

Chaque potion peut être créée en :
- **Normal** : Effet standard
- **Prolongée (+)** : Durée augmentée (redstone)
- **Renforcée (II)** : Effet amplifié (glowstone)

Et sous forme :
- **Normal** : Potion buvable
- **Splash** : Potion lançable (gunpowder)
- **Persistante** : Nuage persistant (dragon's breath)

## Ajouter des recettes

Éditez `data/recipes.json` :

```json
{
  "potions": {
    "ma_potion": {
      "name": "Ma Super Potion",
      "ingredient": "minecraft:mon_ingredient",
      "base": "awkward",
      "can_extend": true,
      "can_amplify": false
    }
  }
}
```

Le système calculera automatiquement les étapes nécessaires !

## Réseau

- **Protocole** : `potion_network`
- **Canal** : `500`

## Structure des fichiers

```
potionMaker/
├── install.lua          # Installateur
├── wizard.lua           # Assistant de configuration
├── startup.lua          # Démarrage automatique
├── main.lua             # Programme principal
├── modules/
│   ├── config.lua       # Gestion configuration
│   ├── recipes.lua      # Recettes & craft intelligent
│   ├── inventory.lua    # Gestion des coffres
│   ├── brewing.lua      # Contrôle des alambics
│   ├── queue.lua        # File d'attente FIFO
│   ├── ui.lua           # Interface moniteur
│   ├── network.lua      # Communication réseau
│   └── sound.lua        # Gestion du speaker
├── data/
│   ├── config.json      # Configuration (généré)
│   ├── recipes.json     # Base de données potions
│   └── queue.json       # File d'attente (généré)
└── pocket/
    └── potion_remote.lua
```

## Commandes clavier

Sur le terminal du serveur :
- `Q` : Quitter le programme
- `R` : Relancer le wizard

## Dépannage

### "Configuration non trouvée"
Lancez `wizard` pour reconfigurer.

### "Périphérique non connecté"
Vérifiez que tous les modems filaires sont activés (clic droit).

### Le pocket ne trouve pas le serveur
- Vérifiez que le serveur tourne (`main.lua`)
- Le pocket doit avoir un modem sans fil équipé
- Vérifiez que vous êtes à portée

## Licence

MIT License - Libre d'utilisation et modification.

---

Créé avec ❤️ pour la communauté ComputerCraft
