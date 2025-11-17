#  Projet GreenTechApp : Analyse des DPE et Consommations

> **Projet réalisé par :** Hadjer Merabet & Sabrina Moufok  
> **Contexte :** IUT SD2 - Projet Enedis

Ce projet a pour objectif d'analyser l'impact du **Diagnostic de Performance Énergétique (DPE)** sur la consommation électrique des logements. L'étude se concentre particulièrement sur le département du **Rhône (69)**, en comparant les logements neufs et anciens.

### 🔗 Accès au projet
* **Application RShiny :** [Lancer GreenTechApp](https://hadjermerabet.shinyapps.io/Projet_R/)
* **Démonstration Vidéo :** [Voir sur YouTube](https://www.youtube.com/watch?v=WvpREMDcods)

---

##  Architecture du projet

Voici le détail des fichiers et scripts présents dans ce dépôt, classés par catégorie :

### 1. 💻 Application RShiny (Le Cœur du Projet)
* **`app.R`** :
  Script principal de l'application. Il contient à la fois l'interface utilisateur (**ui**) et la logique serveur (**server**). Il gère les cartes interactives, les filtres dynamiques et l'affichage des graphiques.


### 2. Base de Données et ETL
* **`database_code.R`** :
  Script de préparation des données (ETL). Il permet de nettoyer les fichiers bruts et de générer la structure de données consolidée utilisée par l'application.
* **Fichiers sources (CSV) :**
  * `dpe-v2-logements-neufs.csv` : Données brutes des logements neufs.
  * `dpe-v2-logements-existants.csv` : Données brutes des logements anciens.
  * `adresses-69.csv` : Base d'adresses spécifique pour la géolocalisation dans le Rhône.

### 3.  Analyse Statistique
* **`R markdown`** :
  Fichier source contenant le code de l'analyse exploratoire. Il permet de générer automatiquement le rapport statistique complet.
* **`Analyse des DPE de la ville de Lyon...`** :
  Le rapport final (PDF/HTML) issu du RMarkdown. Il présente les conclusions statistiques sur la répartition des étiquettes DPE et les consommations.

### 4.  Documentation
* **`Documentation Fonctionnelle.pdf`** :
  *Destiné à l'utilisateur.* Explique comment utiliser l'application (filtres, navigation, exports).
* **`Documentation Technique.pdf`** :
  *Destiné au développeur.* Détaille l'architecture du code, les choix techniques et la liste des packages R nécessaires au déploiement.

---
