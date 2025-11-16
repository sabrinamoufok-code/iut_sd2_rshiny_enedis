## Projet RShiny - GreenTechApp
Ce projet, mené par Hadjer Merabet et Sabrina Moufok, a pour objectif de créer une application RShiny permettant d'étudier l'impact du Diagnostic de Performance Énergétique (DPE) sur la consommation énergétique des logements dans le département du Rhône.

## Liens Rapides
Application en Ligne : https://hadjermerabet.shinyapps.io/Projet_R/

Démonstration Vidéo (YouTube) : (Lien à insérer)

## Structure du Dépôt
Ce dépôt est organisé en plusieurs dossiers pour séparer le code de l'application, la préparation des données, les rapports et la documentation.

app/ (Application RShiny) : L'application Shiny (V36) fonctionnelle. Elle permet une exploration interactive des données de logements avec des filtres dynamiques, des indicateurs clés (KPI), des graphiques, une carte interactive et des possibilités d'exporter les données et les graphiques.

data_preparation/ (Code de la base de données) : Contient le script R (code_base_de_données.R) utilisé pour nettoyer, fusionner et préparer les données brutes (dpe-v2...csv) en une base de données propre (dpe_final_lyon.csv) utilisée par l'application.

rapport/ (Analyse RMarkdown) : Le rapport (R Markdown) présentant les analyses statistiques, les visualisations et l'interprétation des résultats.

docs/ (Documentation) :Documentation fonctionnelle : Description des fonctionnalités principales et guide d'utilisation de l'application. Documentation technique : Explication de l'architecture de l'application, des packages utilisés et instructions pour le déploiement.

## Outils Utilisés
R & RStudio : Développement de l'application et analyses statistiques.

RShiny & ShinyDashboard : Création de l'interface utilisateur interactive.

GitHub : Gestion de versions et collaboration.

Draw.io : Schéma de l'architecture.

CapCut : Montage de la vidéo de présentation.

Gemini & ChatGPT : Support au code et à la documentation.
