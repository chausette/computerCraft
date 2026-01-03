# 🏰 MineColonies Dashboard Pro v4

Dashboard tactile avancé pour **MineColonies** avec **CC:Tweaked** et **Advanced Peripherals**.

![Version](https://img.shields.io/badge/version-4.0-blue)
![Minecraft](https://img.shields.io/badge/Minecraft-1.19%2B-green)
![License](https://img.shields.io/badge/license-MIT-yellow)

## 📸 Aperçu

Un dashboard complet sur moniteur tactile pour gérer votre colonie MineColonies :

- 📊 Vue d'ensemble avec statistiques en temps réel
- 👥 Liste des citoyens avec métiers et santé
- 📦 Requêtes de ressources groupées
- 🔨 Suivi des chantiers avec builders assignés
- 🏠 Liste des bâtiments avec niveaux
- 📈 Historique et graphiques
- 🚨 Alertes d'attaque avec son

---

## 📋 Prérequis

### Mods requis
- [CC:Tweaked](https://modrinth.com/mod/cc-tweaked) (ComputerCraft)
- [Advanced Peripherals](https://modrinth.com/mod/advancedperipherals)
- [MineColonies](https://modrinth.com/mod/minecolonies)

### Matériel en jeu
| Bloc | Quantité | Usage |
|------|----------|-------|
| Advanced Computer | 1 | Exécuter le programme |
| Advanced Monitor | 6 (3x2) | Affichage tactile |
| Colony Integrator | 1 | Connexion à la colonie |
| Speaker | 1 | Alertes sonores (optionnel) |
| Disk Drive + Disk | 1 | Export JSON (optionnel) |

---

## 🚀 Installation

### Méthode 1 : Téléchargement direct (recommandé)

Sur l'ordinateur en jeu, exécutez :

```lua
wget https://raw.githubusercontent.com/chausette/computerCraft/master/mycolony/colony_pro_v4.lua
```

### Méthode 2 : Script d'installation

```lua
wget run https://raw.githubusercontent.com/chausette/computerCraft/master/mycolony/install.lua
```

### Méthode 3 : Copier-coller

1. Ouvrez l'éditeur : `edit colony_pro_v4.lua`
2. Collez le code
3. Sauvegardez avec `Ctrl+S`

---

## ⚙️ Configuration matérielle

### Disposition recommandée

```
        [Monitor 3x2]
             |
[Speaker]--[Computer]--[Colony Integrator]
             |
        [Disk Drive]
```

### Placement du Colony Integrator

⚠️ **Important** : Le Colony Integrator doit être placé **dans les limites de votre colonie** pour fonctionner.

---

## 🎮 Utilisation

### Lancer le dashboard

```lua
colony_pro_v4
```

### Navigation

- **Clic sur le menu** : Changer de page
- **Clic sur un citoyen** : Voir les détails
- **Clic sur un chantier** : Sélectionner pour export
- **Touche Q** : Quitter le programme

### Pages disponibles

| Page | Description |
|------|-------------|
| 🏠 Accueil | Vue d'ensemble, bonheur, citoyens |
| 👥 Citoyens | Liste avec métier, santé, détails |
| 📦 Requêtes | Ressources demandées (groupées) |
| 🔨 Chantiers | Travaux en cours, builders assignés |
| 🏗️ Bâtiments | Liste des structures, niveaux |
| 📊 Statistiques | Historique, graphiques |
| ⚙️ Configuration | Thèmes, options, tests |

---

## 🎨 Thèmes

6 thèmes de couleurs disponibles :

| Thème | Description |
|-------|-------------|
| Sombre | Fond noir, accents bleus |
| Clair | Fond blanc, texte sombre |
| MineColonies | Couleurs officielles du mod |
| Océan | Tons bleus et cyans |
| Forêt | Tons verts naturels |
| Nether | Rouge et orange |

---

## 📤 Export JSON

### Export des matériaux de construction

Le dashboard peut exporter la liste des matériaux manquants pour vos chantiers.

**Fichier généré** : `/disk/materials.json`

```json
{
  "colony": "Ma Colonie",
  "exportDate": "2025-01-03 16:30",
  "workOrders": 2,
  "totalItems": 45,
  "materials": [
    {
      "item": "minecraft:oak_planks",
      "displayName": "Oak Planks",
      "needed": 150,
      "delivered": 63,
      "missing": 87
    }
  ]
}
```

### Utilisation

1. Page **Chantiers**
2. Cliquez sur un chantier pour le sélectionner
3. Cliquez sur **[Export]** pour un seul chantier
4. Ou **[Exporter tout]** pour tous les chantiers

---

## 🚨 Système d'alertes

### Détection d'attaque

Le dashboard détecte automatiquement les attaques sur votre colonie via :
- `colony.isUnderAttack()`
- `colony.isUnderRaid()`
- État des gardes en combat

### Alertes visuelles

- Menu latéral **rouge clignotant**
- Bannière **"!!! ATTAQUE EN COURS !!!"**
- Titre du menu : **"! ALERTE !"**

### Alertes sonores

- Son configurable (défaut : cloche)
- Intervalle ajustable (1-5 secondes)
- Répétition automatique pendant l'attaque

### Test des alertes

Page **Configuration** → **[Test Alerte]** : Simule une attaque pendant 5 secondes

---

## ⚙️ Configuration

### Fichier de configuration

Les paramètres sont sauvegardés dans `colony_config.dat`

### Options disponibles

| Option | Valeurs | Description |
|--------|---------|-------------|
| Thème | 6 choix | Couleurs de l'interface |
| Taille texte | 0.5 / 1.0 / 1.5 | Échelle d'affichage |
| Rafraîchissement | 1s / 3s / 5s / 10s | Fréquence de mise à jour |
| Items/page | 5 / 8 / 10 / 15 | Pagination des listes |
| Son alerte | 1s / 2s / 3s / 5s | Intervalle du son |

### Configuration dans le code

```lua
local CONFIG = {
    refreshRate = 3,           -- Secondes entre rafraîchissements
    textScale = 0.5,           -- Échelle du texte
    alertSound = "minecraft:block.bell.use",
    alertSoundInterval = 2,    -- Secondes entre sons d'alerte
    exportPath = "/disk/materials.json",
    itemsPerPage = 8,
    maxCitizens = 100,         -- Pour la barre de progression
}
```

---

## 📊 Données affichées

### Citoyens

| Champ | Description |
|-------|-------------|
| Nom | Nom complet du citoyen |
| Métier | Traduit en français |
| Vie | Points de vie avec code couleur |
| Bonheur | Niveau de satisfaction |
| Saturation | Niveau de faim |
| État | Activité actuelle |

### Code couleur santé

| Couleur | Vie | État |
|---------|-----|------|
| 🟢 Vert | ≥15 | Bonne santé |
| 🟠 Orange | ≥8 | Blessé |
| 🔴 Rouge | <8 | Critique |

### Chantiers

| Champ | Description |
|-------|-------------|
| Nom | Type de bâtiment |
| Builder | Nom du bâtisseur assigné |
| Statut | En cours / En attente |

---

## 🔧 Dépannage

### "Colony Integrator non trouvé"

- Vérifiez que le Colony Integrator est adjacent à l'ordinateur
- Assurez-vous qu'il est dans les limites de la colonie

### "Moniteur non trouvé"

- Vérifiez la connexion des moniteurs
- Les 6 moniteurs doivent former un bloc 3x2

### Les citoyens affichent "Chomeur"

- L'API MineColonies peut avoir un format différent
- Activez `debugMode = true` dans CONFIG
- Consultez `/disk/debug_data.txt`

### Le builder affiche "Non assigné"

- Le chantier n'a peut-être pas encore de builder assigné
- Vérifiez dans MineColonies que le travail est bien attribué

### Pas de son d'alerte

- Vérifiez qu'un Speaker est connecté
- Testez avec **[Test Son]** dans Configuration

---

## 📁 Fichiers

| Fichier | Description |
|---------|-------------|
| `colony_pro_v4.lua` | Programme principal |
| `colony_config.dat` | Configuration sauvegardée |
| `colony_history.dat` | Historique des statistiques |
| `/disk/materials.json` | Export des matériaux |
| `/disk/debug_data.txt` | Données de debug (si activé) |

---

## 🔄 Changelog

### v4.0
- ✨ Nouveau layout avec menu latéral
- ✨ Pagination sur toutes les listes
- ✨ Détection des métiers via `citizen.work.job`
- ✨ Détection du builder via position
- ✨ Barres de progression (bonheur, citoyens)
- ✨ Export JSON individuel ou groupé
- ✨ Son d'alerte en boucle configurable
- ✨ 6 thèmes de couleurs
- ✨ Boutons de test (alerte, son)
- 🐛 Correction affichage des métiers
- 🐛 Correction affichage des builders

### v3.0
- Navigation par onglets
- Export JSON des matériaux
- Historique et statistiques
- 6 thèmes de couleurs

### v2.0
- Support tactile
- Alertes d'attaque

### v1.0
- Version initiale

---

## 📜 Licence

Ce projet est sous licence MIT. Vous êtes libre de l'utiliser, le modifier et le redistribuer.

---

## 🤝 Contribution

Les contributions sont les bienvenues !

1. Fork le projet
2. Créez une branche (`git checkout -b feature/amelioration`)
3. Committez (`git commit -m 'Ajout fonctionnalité'`)
4. Push (`git push origin feature/amelioration`)
5. Ouvrez une Pull Request

---

## 💬 Support

- **Issues GitHub** : Pour les bugs et suggestions
- **Wiki** : Documentation détaillée (à venir)

---

Fait avec ❤️ pour la communauté MineColonies
