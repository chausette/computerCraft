# 🔥 Furnace Manager v2.0

Gestionnaire automatique de fours pour **ComputerCraft / CC:Tweaked**

![Version](https://img.shields.io/badge/version-2.0-blue)
![Minecraft](https://img.shields.io/badge/Minecraft-1.18%2B-green)
![ComputerCraft](https://img.shields.io/badge/CC%3ATweaked-1.100%2B-orange)

---

## ✨ Fonctionnalités

### 🎯 Automatisation complète
- Distribution automatique des items à cuire
- Collecte automatique des items cuits
- Gestion intelligente du carburant

### 🧠 Routage intelligent
- **Smoker** → Nourriture (viandes, poissons, pommes de terre)
- **Blast Furnace** → Minerais (fer, or, cuivre, ancient debris)
- **Furnace** → Tout le reste

### 📊 Statistiques de production
- Items cuits cette session
- Total historique
- Items par heure en temps réel

### ⚠️ Système d'alertes
- Carburant bas (clignotant)
- Coffre de sortie plein
- Coffre d'entrée vide

### 📺 Interface moniteur avancée
- Vue en temps réel de chaque four
- Pourcentage de progression **ET** temps restant estimé
- Indicateurs de type de four (F/B/S)
- Support tactile (pause/play)

### 💾 Persistance
- Configuration sauvegardée
- Statistiques conservées entre les sessions

### ⚡ Mode économie
- Carburant distribué uniquement quand nécessaire
- Évite le gaspillage de charbon

---

## 📦 Installation rapide

### Méthode 1 : Une seule commande
```
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/furnace/setup.lua
```

### Méthode 2 : Installation manuelle
```
wget https://raw.githubusercontent.com/chausette/computerCraft/master/furnace/setup.lua setup
wget https://raw.githubusercontent.com/chausette/computerCraft/master/furnace/furnace.lua furnace
```

---

## 🔧 Configuration matérielle

### Requis
| Composant | Quantité | Notes |
|-----------|----------|-------|
| Advanced Computer | 1 | Recommandé pour les couleurs |
| Wired Modem | 1+ | Sur chaque périphérique |
| Networking Cable | Variable | Pour relier les composants |
| Coffres | 3 | Entrée, Sortie, Carburant |
| Four(s) | 1+ | Furnace, Blast Furnace, Smoker |

### Optionnel
| Composant | Notes |
|-----------|-------|
| Advanced Monitor | Jusqu'à 2x2 blocs, tactile |

### Schéma de connexion
```
                      [Advanced Monitor 2x2]
                              |
                       [Wired Modem]
                              |
[Coffre Input]---[Cable]---[Advanced Computer]---[Cable]---[Coffre Output]
                              |
                       [Cable]---[Coffre Fuel]
                              |
        [Furnace]---[Cable]---+---[Cable]---[Blast Furnace]
                              |
                       [Cable]---[Smoker]
```

> ⚠️ **Important** : Clic droit sur chaque Wired Modem pour l'activer (point rouge visible)

---

## 🚀 Utilisation

### Premier lancement
```
setup
```
Suivez l'assistant pour :
1. Télécharger les fichiers
2. Configurer les coffres
3. Définir les options

### Lancer le gestionnaire
```
furnace
```

### Commandes clavier
| Touche | Action |
|--------|--------|
| `Q` | Quitter |
| `P` / `Espace` | Pause / Reprendre |
| `R` | Rafraîchir les périphériques |
| `S` | Sauvegarder la configuration |

### Contrôle tactile (moniteur)
- **Toucher l'écran** : Pause / Reprendre

---

## 📺 Interface moniteur

```
╔════════════════════════════════════╗
║      FURNACE MANAGER v2.0          ║
╠════════════════════════════════════╣
║ Fours: 3              Fuel:  64    ║
║ Cuits: 127 (1543 total)    45/h    ║
╠════════════════════════════════════╣
║ ! Carburant bas                    ║
╠════════════════════════════════════╣
║ FOURS:                             ║
║ F1 Raw iron x12                    ║
║   [████████░░]  78%  ~2s     F: 6  ║
║ B2 Raw gold x4                     ║
║   [██████░░░░]  62%  ~1s     F: 8  ║
║ S3 Beef x8                         ║
║   [████░░░░░░]  45%  ~3s     F: 7  ║
║ F4 Vide                            ║
║   [ Inactif ]                F: 8  ║
╠════════════════════════════════════╣
║ Touch: Pause              14:32    ║
╚════════════════════════════════════╝
```

### Légende des icônes
| Icône | Type | Couleur |
|-------|------|---------|
| **F** | Furnace | Orange |
| **B** | Blast Furnace | Bleu clair |
| **S** | Smoker | Marron |

### Indicateurs de carburant
| Couleur | Niveau |
|---------|--------|
| 🟢 Vert | > 4 |
| 🟠 Orange | 1-4 |
| 🔴 Rouge | 0 |

---

## ⚙️ Options de configuration

Le setup permet de configurer :

| Option | Description | Défaut |
|--------|-------------|--------|
| Routage intelligent | Dirige les items vers le bon type de four | Oui |
| Mode économie | Ne distribue le fuel que si nécessaire | Oui |
| Niveau min. fuel | Carburant minimum par four | 8 |
| Intervalle MAJ | Temps entre les mises à jour (sec) | 2 |

---

## 🔄 Mise à jour

```
setup
```
Puis choisir l'option **1. Installer / Mettre à jour**

Ou directement :
```
setup install
```

---

## 🐛 Dépannage

### "Pas de configuration"
→ Lancez `setup` et configurez le système

### "Aucun four détecté"
→ Vérifiez que les modems sont activés (point rouge)
→ Vérifiez les connexions des câbles

### Les items ne se transfèrent pas
→ Vérifiez l'orientation des coffres
→ Vérifiez que le coffre d'entrée contient des items cuisables

### Le moniteur n'affiche rien
→ Vérifiez la connexion du modem sur le moniteur
→ Essayez : `monitor [nom_moniteur] furnace`

### Erreur HTTP
→ Activez HTTP dans la config ComputerCraft :
```
# computercraft-server.toml
[http]
enabled = true
```

---

## 📝 Items supportés par le routage intelligent

### Smoker (nourriture)
- Beef, Porkchop, Chicken, Mutton, Rabbit
- Cod, Salmon
- Potato, Kelp

### Blast Furnace (minerais)
- Raw Iron, Raw Gold, Raw Copper
- Iron Ore, Gold Ore, Copper Ore
- Deepslate variants
- Ancient Debris

### Furnace (reste)
- Sand → Glass
- Cobblestone → Stone
- Clay → Terracotta
- Logs → Charcoal
- Et plus...

---

## 📜 Changelog

### v2.0
- ✨ Routage intelligent par type de four
- 📊 Statistiques de production
- ⚠️ Système d'alertes
- 👆 Interface tactile
- 💾 Configuration persistante
- ⚡ Mode économie carburant
- ⏱️ Temps restant estimé + pourcentage

### v1.0
- 🎉 Version initiale

---

## 📄 Licence

MIT - Libre d'utilisation et de modification

---

## 🤝 Contribution

Les issues et pull requests sont les bienvenues sur GitHub !

---

Créé avec ❤️ pour ComputerCraft / CC:Tweaked
