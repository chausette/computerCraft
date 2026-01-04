# Potion Maker 🧪

Système automatisé de brassage de potions pour **Minecraft 1.21** avec **ComputerCraft**.

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

| Coffre | Usage |
|--------|-------|
| **Input** | Dépôt des items (tri automatique) |
| **Fioles d'eau** | Stock de fioles d'eau |
| **Ingrédients** | Stock d'ingrédients |
| **Potions** | Stockage des potions terminées |
| **Output** | Distribution des potions demandées |

## Utilisation

### Interface Moniteur

- **Accueil** : Vue d'ensemble (alambics, file d'attente, alertes)
- **Cmd** : Commander des potions
- **Potions** : Voir le stock et distribuer vers output
- **Stock** : Voir les ingrédients disponibles

### Types de potions

- **Normal** : Effet standard
- **Durée+** : Durée augmentée (redstone)
- **Force II** : Effet amplifié (glowstone)

### Formes

- **Normal** : Potion buvable
- **Splash** : Potion lançable
- **Persist** : Nuage persistant

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

## Réseau

- **Protocole** : `potion_network`
- **Canal** : `500`

## Commandes clavier

- `Q` : Quitter
- `R` : Reconfigurer (relancer wizard)

---

Créé avec ❤️ pour la communauté ComputerCraft
