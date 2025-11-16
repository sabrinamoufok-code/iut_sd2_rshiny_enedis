# --- 0. Configuration de l'Environnement et des Cibles ---
library(dplyr)
library(readr)
library(janitor)

# --- CRÉATION DU DOSSIER ET CHEMINS ---
if (!dir.exists("data")) {
  dir.create("data")
  cat("Dossier 'data/' créé.\n")
}

# Fichiers sources (Doivent être corrigés manuellement : séparateur virgule, UTF-8)
CHEMIN_NEUFS_BRUT <- "dpe-v2-logements-neufs.csv"
CHEMIN_EXISTANTS_BRUT <- "dpe-v2-logements-existants.csv"
CHEMIN_FINAL <- "data/dpe_final_lyon.csv"

# Codes postaux des 9 arrondissements de Lyon (Notre cible)
CODES_POSTAUX_LYON <- c("69001", "69002", "69003", "69004", "69005", "69006", "69007", "69008", "69009")


# --- 1. Fonction de Chargement et Filtrage ROBUSTE (Gestion des Colonnes Manquantes) ---

charger_et_filtrer_dpe <- function(file_name, type_logement) {
  cat(paste("\n--- Démarrage du chargement et du filtrage de :", file_name, "---\n"))
  
  # Lecture ULTIME : Adaptée au format CSV STANDARD (séparateur: virgule)
  data <- read.csv(
    file_name,
    header = TRUE,
    sep = ",",
    quote = "\"",
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    check.names = FALSE,
    comment.char = "",
    colClasses = "character"
  )
  
  # ÉTAPE 1: Nettoyage des noms de colonnes
  data_clean_names <- data %>%
    janitor::clean_names()
  
  # ÉTAPE 1.5: GÉRER LES COLONNES MANQUANTES ET LES VARIATIONS DE NOMMAGE
  
  # a) Gérer l'absence de 'annee_construction' (pour Neufs)
  if (!("annee_construction" %in% names(data_clean_names))) {
    data_clean_names <- data_clean_names %>% mutate(annee_construction = NA_character_)
    cat("  -> Correction: Ajout de la colonne 'annee_construction' manquante.\n")
  }
  
  # b) Gérer la variation de nom de la colonne 'N°_département_(BAN)'
  # Le nom attendu est soit 'nn_departement_ban' (précédent) soit 'n_departement_ban' (le plus probable)
  col_departement <- if ("n_departement_ban" %in% names(data_clean_names)) "n_departement_ban" else "nn_departement_ban"
  
  # ÉTAPE 2: FILTRAGE sur le nom de colonne nettoyé (code_postal_brut)
  data_filtree <- data_clean_names %>%
    filter(code_postal_brut %in% CODES_POSTAUX_LYON)
  
  if (nrow(data_filtree) == 0) {
    cat(paste("  ATTENTION : Le fichier", file_name, "ne contient AUCUNE ligne pour Lyon après filtrage.\n"))
    return(tibble())
  }
  
  # 3. Standardisation et Sélection (MODIFIÉ POUR INCLURE GES ET TYPE D'ÉNERGIE)
  data_final <- data_filtree %>%
    select(
      # Utilisation des noms de colonnes nettoyés les plus probables
      dpe_classe = etiquette_dpe,
      ges_classe = etiquette_ges, # <-- DONNÉE AJOUTÉE
      type_energie = type_installation_chauffage, # <-- DONNÉE AJOUTÉE
      consommation_kwh_m2 = conso_5_usages_m2_e_finale,
      surface_m2 = surface_habitable_logement,
      annee_construction = annee_construction,
      type_logement_immeuble = type_batiment,
      departement = !!sym(col_departement), # Utilise le nom de colonne corrigé
      code_postal = code_postal_brut,
      longitude = coordonnee_cartographique_x_ban,
      latitude = coordonnee_cartographique_y_ban
    ) %>%
    
    # Conversion des Types et Nettoyage
    mutate(
      source_type = type_logement,
      across(c(consommation_kwh_m2, surface_m2, annee_construction, latitude, longitude), as.numeric),
      dpe_classe = as.factor(dpe_classe),
      ges_classe = as.factor(ges_classe), # <-- CONVERSION AJOUTÉE
      type_energie = as.factor(type_energie) # <-- CONVERSION AJOUTÉE
    ) %>%
    # Re-sélectionner pour garder le bon ordre ET inclure les nouvelles colonnes
    select(
      dpe_classe, ges_classe, type_energie, # <-- NOUVELLES COLONNES AJOUTÉES ICI
      consommation_kwh_m2, surface_m2, annee_construction,
      type_logement_immeuble, departement, code_postal,
      latitude, longitude, source_type
    ) %>%
    filter(
      !is.na(latitude),
      !is.na(longitude),
      !is.na(consommation_kwh_m2),
      !is.na(type_energie), # <-- FILTRE AJOUTÉ
      dpe_classe %in% LETTERS[1:7],
      ges_classe %in% LETTERS[1:7] # <-- FILTRE AJOUTÉ
    )
  
  cat(paste("Fichier", file_name, "filtré pour Lyon. Lignes conservées :", nrow(data_final), "\n"))
  return(data_final)
}


# --- 2. Exécution et Fusion ---

dpe_neufs <- charger_et_filtrer_dpe(CHEMIN_NEUFS_BRUT, "Neuf")
dpe_existants <- charger_et_filtrer_dpe(CHEMIN_EXISTANTS_BRUT, "Ancien")

# Fusionner les deux jeux de données
Logements_complet <- bind_rows(dpe_neufs, dpe_existants)

# Enregistrement du Fichier Final
write_csv(Logements_complet, CHEMIN_FINAL)

cat(paste("\n--- FIN ---"))
cat(paste("\nTotal logements fusionnés pour Lyon :", nrow(Logements_complet), "lignes.\n"))
cat(paste("Fichier final prêt à être lu :", CHEMIN_FINAL, "\n"))
