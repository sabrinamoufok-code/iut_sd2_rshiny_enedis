# =========================================================================
# FICHIER : app.R - VERSION STABLE FINALE (V36)
# Finalisation : Suppression du bouton et de la logique d'ancrage.
# Correction : Description de la Cartographie dans l'onglet Accueil.
# =========================================================================

# --- PARTIE 0 : Librairies et Chargement des Données ---
library(shiny)
library(ggplot2)
library(dplyr)
library(readr)
library(DT) 
library(shinydashboard) 
library(leaflet) 
library(leaflet.extras) 
library(shinyjs) 
library(tibble) 

# 1. Chargement des données
data_dpe <- read_csv("data/dpe_final_lyon.csv") %>%
  mutate(code_postal = as.character(code_postal))

# 2. CENTROIDS WGS84 FIXES (Coordonnées centrales pour les arrondissements de Lyon)
lyon_centroids <- tribble(
  ~code_postal, ~lat_wgs84, ~lng_wgs84,
  "69001", 45.768, 4.834,
  "69002", 45.754, 4.828,
  "69003", 45.762, 4.856,
  "69004", 45.783, 4.833,
  "69005", 45.760, 4.810,
  "69006", 45.772, 4.856,
  "69007", 45.741, 4.847,
  "69008", 45.733, 4.870,
  "69009", 45.770, 4.805
)

# 3. Dictionnaire de données pour l'onglet Documentation
col_defs <- tribble(
  ~Nom_Champ, ~Description_DPE_ADEME,
  "dpe_classe", "Classe de consommation d'énergie (Etiquette DPE) suivant le référentiel DPE (ex: C, D, E).",
  "consommation_kwh_m2", "Consommation d'énergie primaire totale rapportée à la surface (kWhep/m²/an). C'est l'indicateur principal du DPE.",
  "surface_m2", "Surface habitable du logement renseignée.",
  "annee_construction", "Année de construction du bien immobilier.",
  "type_logement_immeuble", "Type de bâtiment (Appartement, immeuble, ou maison individuelle).",
  "departement", "Numéro du département (69 pour le Rhône).",
  "code_postal", "Code postal de la commune / arrondissement de Lyon.",
  "source_type", "Méthode utilisée pour générer le DPE (ex: Méthode 3CL)."
)


# --- PARTIE 1 : L'INTERFACE UTILISATEUR (UI) ---

ui <- dashboardPage(
  skin = "purple",
  
  # --- HEADER ---
  dashboardHeader(title = tags$span(
    "GreenTech Solutions: Analyse DPE Lyon"
  )),
  
  # --- MENU LATÉRAL (SideBar) ---
  dashboardSidebar(
    useShinyjs(),
    sidebarMenu(
      menuItem("Accueil & Contexte", tabName = "home", icon = icon("info-circle")), 
      menuItem("Analyse DPE", tabName = "analyse", icon = icon("chart-bar")),
      menuItem("Cartographie", tabName = "map", icon = icon("globe")),
      menuItem("Dictionnaire de Données", tabName = "doc", icon = icon("book")),
      menuItem("Données Brutes", tabName = "data", icon = icon("table"))
    )
  ),
  
  # --- CORPS DU DASHBOARD (Body) ---
  dashboardBody(
    tags$head(
      tags$base(href = "/"),
      tags$style(HTML(".shiny-plot-output .main-container { white-space: normal !important; }"))
    ),
    
    tabItems(
      
      # ===================================================
      # ONGLET 0 : ACCUEIL / CONTEXTE 
      # ===================================================
      tabItem(tabName = "home",
              
              fluidRow(
                # Colonne de gauche (Contexte, Images, et Description des Onglets)
                box(
                  title = "Contexte", solidHeader = TRUE, status = "primary", width = 8,
                  
                  # IMAGE 1 : Logo Partenaire (Centrée)
                  tags$div(style="text-align: center;", 
                           tags$img(src='logo_aceuille.png', width="60%", style="margin-top: 20px;"),
                           tags$p(style="font-size: 0.8em; text-align: center; margin-top: 5px;", 
                                  "Source: GreenTech Solutions")
                  ),
                  
                  # PARAGRAPHE DE CONTEXTE GÉNÉRAL
                  p("Le Diagnostic de Performance Énergétique (DPE) évalue la performance énergétique des logements en les classant de A (faible consommation) à G (forte consommation). Ce site propose une analyse des logements du Rhône, explorant l'impact du DPE sur différentes variables telles que les coûts énergétiques et les émissions de gaz à effet de serre."),
                  
                  # Description des Onglets
                  h4("Navigation et Fonctionnalités"),
                  p("Cette application est structurée autour de quatre onglets principaux pour faciliter votre analyse :"),
                  tags$ul(
                    tags$li("Analyse DPE : Contient tous les graphiques et les indicateurs clés de performance (KPI). C'est ici que vous appliquerez les filtres pour affiner les visualisations."),
                    tags$li("Dictionnaire de Données : Présente la définition de chaque colonne utilisée dans la base de données DPE (ADEME)."),
                    tags$li("Données Brutes : Permet de visualiser la table complète des données brutes après leur nettoyage initial."),
                    # Description Carto mise à jour (V36)
                    tags$li("Cartographie : Carte des différents arrondissements de Lyon.")
                  )
                ),
                
                # Colonne de droite (Objectifs et Filtres)
                box(
                  title = "Objectifs et Filtres", solidHeader = TRUE, status = "success", width = 4, 
                  
                  # OBJECTIF DE L'ANALYSE
                  h4("Notre but : "),
                  p("L'objectif de cette application est de fournir une interface simple pour visualiser les données DPE de l'ADEME pour la métropole de Lyon, permettant d'identifier les tendances de consommation et le type de biens immobiliers qui nécessitent une rénovation énergétique."),
                  h4("Filtres : "),
                  p("Pour affiner votre recherche, utilisez les filtres ci-dessous. (Note: Les filtres principaux sont dans l'onglet Analyse DPE)"),
                  
                  h4("Sélectionner le type de logement:"),
                  selectInput("type_logement_accueil", label = NULL, 
                              choices = c("Tous", sort(unique(data_dpe$type_logement_immeuble))), selected = "Tous"),
                  
                  h4("Sélectionner le code postal:"),
                  selectInput("code_postal_accueil", label = NULL, 
                              choices = c("Tous", lyon_centroids$code_postal), 
                              selected = "Tous"),
                  
                  # Bouton d'exportation
                  downloadButton("downloadData_accueil", "Exporter les données en CSV", class = "btn-info"),
                  br(), br(),
                  
                  # IMAGE 2 : Logo ADEME 
                  h4("Partenaire ADEME"),
                  tags$img(src='adme.png', width="100%", style="margin-top: 5px;") 
                )
              )
      ),
      
      # ===================================================
      # ONGLET 1 : ANALYSE DPE 
      # ===================================================
      tabItem(tabName = "analyse",
              sidebarLayout(
                sidebarPanel(
                  h3("Filtres de Données"),
                  selectInput("classe_dpe_choisie", label = "1. Filtrer par Classe DPE :", choices = c("Toutes", sort(unique(data_dpe$dpe_classe))), selected = "Toutes"), 
                  selectInput("code_postal_choisi", label = "2. Filtrer par Arrondissement :", choices = c("Tous", sort(unique(data_dpe$code_postal))), selected = "Tous"),
                  sliderInput("annee_construction_range", label = "3. Filtrer par Année de Construction :", min = min(data_dpe$annee_construction, na.rm = TRUE), max = max(data_dpe$annee_construction, na.rm = TRUE), value = range(data_dpe$annee_construction, na.rm = TRUE), sep = ""),
                  h3("Exportation Données (CSV)"),
                  downloadButton("downloadData", "Exporter les données filtrées (.csv)", class = "btn-primary"),
                  br(), br()
                ),
                mainPanel(
                  h3("Indicateurs Clés de Performance (KPI)"),
                  fluidRow(valueBoxOutput("kpi_total_logements", width = 4), valueBoxOutput("kpi_conso_moyenne", width = 4), valueBoxOutput("kpi_surface_mediane", width = 4)),
                  
                  # Le bouton d'ancrage est supprimé ici (V36)
                  
                  h3("Visualisations DPE Détaillées"),
                  
                  # --- TAB BOX POUR ORGANISER LES GRAPHIQUES ---
                  tabBox(
                    width = 12, 
                    
                    # SOUS-ONGLET 1 : Distribution de la Surface
                    tabPanel("Distribution de la Surface", 
                             h4("Titre : Répartition de la surface habitable des logements filtrés"),
                             p("Cet histogramme montre la fréquence des logements en fonction de leur surface en m². Il permet d'identifier si les données filtrées concernent principalement de petits appartements (moins de 60m²) ou de grandes maisons."),
                             plotOutput("histogramme_surface"), 
                             downloadButton("downloadHistPlot", "Télécharger ce graphique (PNG)")
                    ),
                    
                    # SOUS-ONGLET 2 : Consommation par Arrondissement
                    tabPanel("Consommation par Arrondissement", 
                             h4("Titre : Consommation énergétique moyenne par arrondissement de Lyon"),
                             p("Ce graphique à barres compare la consommation moyenne (kWh/m²/an) par code postal pour les logements filtrés, utile pour identifier les arrondissements ayant les plus grands besoins de rénovation."),
                             plotOutput("graphique_consommation"), 
                             downloadButton("downloadConsoBarPlot", "Télécharger ce graphique (PNG)")
                    ),
                    
                    # SOUS-ONGLET 3 : Consommation par Type de Logement
                    tabPanel("Consommation par Type", 
                             h4("Titre : Distribution de la consommation selon le type de logement"),
                             p("Ce boxplot montre la répartition de la consommation d'énergie entre les appartements, les immeubles et les maisons individuelles. Les boîtes basses indiquent une meilleure efficacité."),
                             plotOutput("boxplot_conso_type"), 
                             downloadButton("downloadBoxplotPlot", "Télécharger ce graphique (PNG)")
                    ),
                    
                    # SOUS-ONGLET 4 : Distribution par Année
                    tabPanel("Distribution par Année de Construction", 
                             h4("Titre : Nombre de logements par année de construction"),
                             p("Cet histogramme montre la distribution des logements en fonction de leur année de construction, permettant de cibler les périodes de construction les plus énergivores (souvent avant 1975) pour les politiques de rénovation."),
                             plotOutput("histogramme_annee_construction"), 
                             downloadButton("downloadAnneeConsoPlot", "Télécharger ce graphique (PNG)")
                    )
                  ),
                  
                  # --- CIBLE DE L'ANCRE POUR LA RÉGRESSION ---
                  tags$div(id='correlation_section',
                           h3("Analyse de Corrélation")
                  ),
                  tabBox(
                    title = "Régression Linéaire",
                    width = 12,
                    
                    tabPanel("Corrélation de Variables",
                             h4("Titre : Relation entre deux variables du DPE"),
                             p("Ce nuage de points permet de visualiser la corrélation entre deux variables sélectionnées (X et Y). La ligne rouge indique la tendance linéaire. La corrélation est affichée dans le titre du graphique."),
                             fluidRow(
                               column(6, selectInput("var_x_reg", label = "Variable X (Prédictive) :", choices = c("surface_m2", "annee_construction", "consommation_kwh_m2"), selected = "surface_m2")), 
                               column(6, selectInput("var_y_reg", label = "Variable Y (Cible) :", choices = c("consommation_kwh_m2", "surface_m2", "annee_construction"), selected = "consommation_kwh_m2"))
                             ),
                             plotOutput("scatterplot_regression"), 
                             downloadButton("downloadScatterPlot", "Télécharger ce graphique (PNG)")
                    )
                  )
                )
              )
      ), 
      
      # ===================================================
      # ONGLET 2 : CARTOGRAPHIE 
      # ===================================================
      tabItem(tabName = "map",
              h3("Localisation des Logements Filtrés"),
              p("La taille du cercle indique la concentration de logements filtrés dans l'arrondissement. La couleur indique la consommation moyenne."),
              leafletOutput("map_dpe", height = 600) 
      ),
      
      # ===================================================
      # ONGLET 3 : DICTIONNAIRE (Filtre retiré)
      # ===================================================
      tabItem(tabName = "doc",
              h3("Dictionnaire des Données Clés"),
              dataTableOutput("dictionnaire_colonnes")
      ),
      
      # ===================================================
      # ONGLET 4 : DONNÉES BRUTES 
      # ===================================================
      tabItem(tabName = "data",
              h3("Présentation des Données Brutes"),
              p("Cette table présente les données DPE de l'ADEME pour Lyon après le nettoyage et le filtrage initial."),
              dataTableOutput("tableau_donnees_brutes")
      )
    )
  )
) 


# --- PARTIE 2 : LE SERVEUR (LOGIQUE) ---
server <- function(input, output, session) {
  
  # 1. Création d'un ensemble de données 'réactif' (Filtre central)
  data_filtree_reactive <- reactive({
    annee_min <- input$annee_construction_range[1]
    annee_max <- input$annee_construction_range[2]
    
    data_a_filtrer <- data_dpe
    
    # Filtrage de la Classe DPE
    if (input$classe_dpe_choisie != "Toutes") {
      data_a_filtrer <- data_a_filtrer %>%
        filter(dpe_classe == input$classe_dpe_choisie)
    }
    
    # Filtrage de l'Arrondissement
    if (input$code_postal_choisi != "Tous") { 
      data_a_filtrer <- data_a_filtrer %>% 
        filter(code_postal == input$code_postal_choisi) 
    }
    
    # Filtrage des Années
    data_a_filtrer <- data_a_filtrer %>% filter(annee_construction >= annee_min, annee_construction <= annee_max)
    return(data_a_filtrer)
  })
  
  # 2. Création des Indicateurs Clés de Performance (KPI)
  output$kpi_total_logements <- renderValueBox({ n_logements <- nrow(data_filtree_reactive()); valueBox(value = format(n_logements, big.mark = " "), subtitle = "Logements Filtrés", icon = icon("home"), color = "blue") })
  output$kpi_conso_moyenne <- renderValueBox({ conso_moyenne <- data_filtree_reactive() %>% summarise(moy = mean(consommation_kwh_m2, na.rm=TRUE)) %>% pull(moy); valueBox(value = paste(round(conso_moyenne, 1), "kWh/m²"), subtitle = "Consommation Moyenne", icon = icon("bolt"), color = "orange") })
  output$kpi_surface_mediane <- renderValueBox({ surface_mediane <- data_filtree_reactive() %>% summarise(med = median(surface_m2, na.rm=TRUE)) %>% pull(med); valueBox(value = paste(round(surface_mediane, 0), "m²"), subtitle = "Surface Médiane", icon = icon("ruler-combined"), color = "green") })
  
  # 3-6. Graphiques (Titres simplifiés pour les renderPlot)
  output$histogramme_surface <- renderPlot({
    data_pour_graph <- data_filtree_reactive(); titre_complet <- "Distribution de la Surface filtrée"; if (nrow(data_pour_graph) > 0) { ggplot(data_pour_graph, aes(x = surface_m2)) + geom_histogram(bins = 30, fill = "#0072B2", color = "white") + labs(title = titre_complet, x = "Surface Habitable (m²)", y = "Nombre de logements") + theme_minimal() } else { ggplot() + annotate("text", x = 0, y = 0, label = "Aucun logement trouvé pour cette sélection.", size = 6) + theme_void() }
  })
  output$graphique_consommation <- renderPlot({
    data_pour_conso <- data_filtree_reactive(); titre_conso <- "Consommation Moyenne par Arrondissement"; if (nrow(data_pour_conso) > 0) { data_conso_summary <- data_pour_conso %>% group_by(code_postal) %>% summarise(consommation_moyenne = mean(consommation_kwh_m2, na.rm = TRUE), .groups = 'drop'); ggplot(data_conso_summary, aes(x = code_postal, y = consommation_moyenne)) + geom_bar(stat = "identity", fill = "#D55E00", color = "white") + labs(title = titre_conso, x = "Code Postal (Arrondissement de Lyon)", y = "Consommation Énergétique Moyenne (kWh/m²)") + theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1)) } else { ggplot() + annotate("text", x = 0, y = 0, label = "Aucun logement trouvé pour cette sélection.", size = 6) + theme_void() }
  })
  output$boxplot_conso_type <- renderPlot({
    data_pour_boxplot <- data_filtree_reactive(); titre_boxplot <- "Distribution de la Consommation par Type de Logement"; if (nrow(data_pour_boxplot) > 0) { ggplot(data_pour_boxplot, aes(x = type_logement_immeuble, y = consommation_kwh_m2, fill = type_logement_immeuble)) + geom_boxplot(alpha=0.7) + labs(title = titre_boxplot, x = "Type de Logement", y = "Consommation Énergétique (kWh/m²)") + coord_cartesian(ylim = c(0, 500)) + theme_minimal() + theme(legend.position = "none") } else { ggplot() + annotate("text", x = 0, y = 0, label = "Aucun logement trouvé pour cette sélection.", size = 6) + theme_void() }
  })
  # GRAPHIQUE V21
  output$histogramme_annee_construction <- renderPlot({
    data_pour_graph <- data_filtree_reactive(); titre_complet <- "Distribution par Année de Construction"; if (nrow(data_pour_graph) > 0) { ggplot(data_pour_graph, aes(x = annee_construction)) + geom_histogram(bins = 40, fill = "#0072B2", color = "white") + labs(title = titre_complet, x = "Année de Construction", y = "Nombre de logements") + theme_minimal() } else { ggplot() + annotate("text", x = 0, y = 0, label = "Aucun logement trouvé pour cette sélection.", size = 6) + theme_void() }
  })
  output$scatterplot_regression <- renderPlot({
    data_pour_scatter <- data_filtree_reactive(); var_x <- input$var_x_reg; var_y <- input$var_y_reg; titre_scatter <- "Régression (Corrélation X/Y)"; if (nrow(data_pour_scatter) > 0) { cor_val <- cor(data_pour_scatter[[var_x]], data_pour_scatter[[var_y]], use = "pairwise.complete.obs"); titre_complet_scatter <- paste0(titre_scatter, " (Corrélation: ", round(cor_val, 3), ")"); ggplot(data_pour_scatter, aes(x = .data[[var_x]], y = .data[[var_y]])) + geom_point(alpha = 0.3, color = "#0072B2") + geom_smooth(method = "lm", se = FALSE, color = "#D55E00") + labs(title = titre_complet_scatter, x = var_x, y = var_y) + theme_minimal() } else { ggplot() + annotate("text", x = 0, y = 0, label = "Aucun logement trouvé pour cette sélection.", size = 6) + theme_void() }
  })
  
  # L'observeEvent pour scrollToCorrelation a été retiré ici (V36)
  
  # 8. Tableau de Données Brutes
  output$tableau_donnees_brutes <- renderDataTable({
    datatable(data_dpe, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
  })
  
  # 9. Dictionnaire de Données
  output$dictionnaire_colonnes <- renderDataTable({
    datatable(col_defs, options = list(pageLength = 10, scrollX = TRUE, dom = 'tip'), rownames = FALSE)
  })
  
  # 10. Cartographie (LOGIQUE AVEC CERCLES DE CONCENTRATION)
  output$map_dpe <- renderLeaflet({
    # Initialisation de la carte (une seule fois)
    leaflet(options = leafletOptions(minZoom = 11, maxZoom = 13)) %>% 
      addProviderTiles(providers$OpenStreetMap.Mapnik) %>% 
      setView(lng = 4.85, lat = 45.75, zoom = 12) 
  })
  
  observe({
    data_filtree <- data_filtree_reactive()
    
    # 1. Calcul des statistiques par code postal (Concentration et Classe majoritaire)
    data_stats <- data_filtree %>% 
      group_by(code_postal) %>% 
      summarise(count = n(), 
                conso_moyenne = mean(consommation_kwh_m2, na.rm = TRUE), 
                classe_majoritaire = names(which.max(table(dpe_classe))), 
                .groups = 'drop')
    
    # Fusion avec les coordonnées fixes de Lyon
    data_map <- left_join(data_stats, lyon_centroids, by = "code_postal")
    
    map_proxy <- leafletProxy("map_dpe", data = data_map) %>% clearShapes() %>% clearControls() 
    
    # Si le jeu de données n'est pas vide
    if (nrow(data_map) > 0) { 
      
      # Définition de la palette de couleurs DPE 
      dpe_colors <- c(
        "A" = "#008000", "B" = "#3CB371", "C" = "#ADFF2F", 
        "D" = "#FFD700", "E" = "#FFA500", "F" = "#FF4500", "G" = "#DC143C"
      )
      
      # Création de la palette de couleurs (basée sur la classe majoritaire)
      pal <- colorFactor(
        palette = dpe_colors,
        domain = data_map$classe_majoritaire,
        levels = names(dpe_colors) 
      )
      
      # Ajout des cercles de concentration
      map_proxy %>% 
        addCircles(lng = ~lng_wgs84, 
                   lat = ~lat_wgs84, 
                   weight = 1, 
                   # Taille basée sur la racine carrée de la concentration
                   radius = ~sqrt(count) * 150, 
                   fillColor = ~pal(classe_majoritaire), 
                   fillOpacity = 0.8, 
                   color = "#333", 
                   popup = ~paste("Arrondissement: <b>", code_postal, "</b><br>", 
                                  "Logements Filtrés: ", count, "<br>", 
                                  "Conso Moyenne: ", round(conso_moyenne, 1), "kWh/m²", "<br>",
                                  "Classe Majoritaire: ", classe_majoritaire)) %>% 
        addLegend(pal = pal, 
                  values = ~classe_majoritaire, 
                  title = "Classe DPE Maj.", 
                  position = "bottomright")
    } 
  })
  
  # 11. Fonctions d'Exportation
  output$downloadData <- downloadHandler(filename = function() { paste("dpe_filtre_", Sys.Date(), ".csv", sep = "") }, content = function(file) { write_csv(data_filtree_reactive(), file) })
  output$downloadData_accueil <- downloadHandler(filename = function() { paste("dpe_filtre_accueil_", Sys.Date(), ".csv", sep = "") }, 
                                                 content = function(file) { 
                                                   data_accueil_filtree <- data_dpe
                                                   
                                                   # Filtrage du type de logement de l'accueil
                                                   if (input$type_logement_accueil != "Tous") {
                                                     data_accueil_filtree <- data_accueil_filtree %>%
                                                       filter(type_logement_immeuble == input$type_logement_accueil)
                                                   }
                                                   
                                                   # Filtrage du code postal de l'accueil
                                                   if (input$code_postal_accueil != "Tous") { 
                                                     data_accueil_filtree <- data_accueil_filtree %>% 
                                                       filter(code_postal == input$code_postal_accueil) 
                                                   }
                                                   write_csv(data_accueil_filtree, file) 
                                                 })
  
  # Fonctions d'exportation des graphiques
  output$downloadHistPlot <- downloadHandler(filename = function() { paste("histogramme_surface_", Sys.Date(), ".png", sep = "") }, content = function(file) { data_pour_graph <- data_filtree_reactive(); p <- ggplot(data_pour_graph, aes(x = surface_m2)) + geom_histogram(bins = 30, fill = "#0072B2", color = "white") + labs(title = "Distribution de la Surface filtrée") + theme_minimal(); ggsave(file, plot = p, device = "png", width = 8, height = 6, units = "in") })
  output$downloadConsoBarPlot <- downloadHandler(filename = function() { paste("barres_conso_arrond_", Sys.Date(), ".png", sep = "") }, content = function(file) { data_pour_conso <- data_filtree_reactive() %>% group_by(code_postal) %>% summarise(consommation_moyenne = mean(consommation_kwh_m2, na.rm = TRUE), .groups = 'drop'); p <- ggplot(data_pour_conso, aes(x = code_postal, y = consommation_moyenne)) + geom_bar(stat = "identity", fill = "#D55E00", color = "white") + labs(title = "Consommation Moyenne par Arrondissement") + theme_minimal(); ggsave(file, plot = p, device = "png", width = 8, height = 6, units = "in") })
  output$downloadBoxplotPlot <- downloadHandler(filename = function() { paste("boxplot_conso_type_", Sys.Date(), ".png", sep = "") }, content = function(file) { data_pour_boxplot <- data_filtree_reactive(); p <- ggplot(data_pour_boxplot, aes(x = type_logement_immeuble, y = consommation_kwh_m2, fill = type_logement_immeuble)) + geom_boxplot(alpha=0.7) + labs(title = "Distribution de la Consommation par Type de Logement") + coord_cartesian(ylim = c(0, 500)) + theme_minimal() + theme(legend.position = "none"); ggsave(file, plot = p, device = "png", width = 8, height = 6, units = "in") })
  output$downloadAnneeConsoPlot <- downloadHandler(filename = function() { paste("distribution_annee_construction_", Sys.Date(), ".png", sep = "") }, content = function(file) { data_pour_graph <- data_filtree_reactive(); p <- ggplot(data_pour_graph, aes(x = annee_construction)) + geom_histogram(bins = 40, fill = "#0072B2", color = "white") + labs(title = "Distribution par Année de Construction") + theme_minimal(); ggsave(file, plot = p, device = "png", width = 8, height = 6, units = "in") })
  output$downloadScatterPlot <- downloadHandler(
    filename = function() {
      paste("regression_plot_", Sys.Date(), ".png", sep = "")
    },
    content = function(file) {
      # Recréation des variables nécessaires
      data_pour_scatter <- data_filtree_reactive()
      var_x <- input$var_x_reg
      var_y <- input$var_y_reg
      
      if (nrow(data_pour_scatter) > 0) {
        # Calcul et titre de la corrélation
        cor_val <- cor(data_pour_scatter[[var_x]], data_pour_scatter[[var_y]], use = "pairwise.complete.obs")
        titre_complet_scatter <- paste0("Régression (Corrélation: ", round(cor_val, 3), ")")
        
        # Construction du graphique
        p <- ggplot(data_pour_scatter, aes(x = .data[[var_x]], y = .data[[var_y]])) + 
          geom_point(alpha = 0.3, color = "#0072B2") + 
          geom_smooth(method = "lm", se = FALSE, color = "#D55E00") + 
          labs(title = titre_complet_scatter, x = var_x, y = var_y) + 
          theme_minimal()
        
        # Sauvegarde en PNG
        ggsave(file, plot = p, device = "png", width = 8, height = 6, units = "in")
      }
    }
  ) 
  
} # FIN de la fonction server


# --- PARTIE 3 : LANCEMENT DE L'APPLICATION ---
shinyApp(ui = ui, server = server)