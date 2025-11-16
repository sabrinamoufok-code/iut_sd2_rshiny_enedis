# =========================================================================
# FICHIER : app.R - VERSION FINALE MINIMALISTE V2 (Expert V10)
# Suppression de TOUTES les images (sauf le partenaire ADEME) et des conteneurs inutiles.
# =========================================================================

# --- PARTIE 0 : Librairies et Chargement des Données (Inchangée) ---
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

# 2. CENTROIDS WGS84 FIXES 
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
  skin = "blue",
  
  # --- HEADER ---
  dashboardHeader(title = tags$span(
    # Retiré: tags$img(src = "logo_acceuille.png", ... )
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
      # ONGLET 0 : ACCUEIL / PAGE DE GARDE (Minimaliste Final)
      # ===================================================
      tabItem(tabName = "home",
              h1("Diagnostic de Performance Énergétique (DPE) à Lyon"),
              
              fluidRow(
                # Colonne 1 : Texte Objectif et Contexte
                box(
                  title = "Objectif et Contexte des Données ADEME", solidHeader = TRUE, status = "primary", width = 7,
                  p("Cette plateforme interactive, développée pour GreenTech Solutions, a pour mission de décrypter les Diagnostics de Performance Énergétique (DPE) des logements lyonnais. Nous nous appuyons sur la base de données publique de l'ADEME (Agence de la transition écologique), qui est la source officielle pour évaluer la performance énergétique nationale."),
                  p("L'objectif est d'offrir une vision claire des tendances de consommation énergétique (en kWh/m²) et de l'état du parc immobilier lyonnais, permettant ainsi d'identifier rapidement les zones d'amélioration."),
                  tags$ul(
                    tags$li("L'onglet Analyse DPE vous permet de visualiser les indicateurs clés et d'explorer les corrélations."),
                    tags$li("L'onglet Cartographie montre la concentration des logements filtrés pour une analyse spatiale."),
                    tags$li("L'onglet Données Brutes vous donne accès à la table complète de l'ADEME, filtrée et nettoyée pour l'application.")
                  )
                ),
                
                # Colonne 2 : Partenaire ADEME (SEUL ÉLÉMENT VISUEL RESTANT)
                box(
                  solidHeader = FALSE, status = "success", width = 5,
                  h4("Partenaire ADEME"),
                  tags$img(src='adme.png', width="100%", style="margin-top: 5px;") 
                )
              )
              # LES BLOCS D'IMAGES DU BAS (Échelle DPE, Logo GreenTech) SONT DÉSORMAIS RETIRÉS
      ),
      
      # ===================================================
      # ONGLET 1 : ANALYSE DESCRIPTIVE (INCHANGÉ)
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
                  h3("Visualisations DPE"),
                  plotOutput("histogramme_surface"), downloadButton("downloadHistPlot", "Télécharger ce graphique (PNG)"), br(), br(),
                  plotOutput("graphique_consommation"), downloadButton("downloadConsoBarPlot", "Télécharger ce graphique (PNG)"), br(), br(),
                  plotOutput("boxplot_conso_type"), downloadButton("downloadBoxplotPlot", "Télécharger ce graphique (PNG)"), br(), br(),
                  h3("Régression (Corrélation X/Y)"),
                  fluidRow(column(6, selectInput("var_x_reg", label = "Variable X (Prédictive) :", choices = c("surface_m2", "annee_construction", "consommation_kwh_m2"), selected = "surface_m2")), column(6, selectInput("var_y_reg", label = "Variable Y (Cible) :", choices = c("consommation_kwh_m2", "surface_m2", "annee_construction"), selected = "consommation_kwh_m2"))),
                  plotOutput("scatterplot_regression"), downloadButton("downloadScatterPlot", "Télécharger ce graphique (PNG)"), br(), br()
                )
              )
      ), 
      
      # ===================================================
      # ONGLET 2 : CARTOGRAPHIE (INCHANGÉ)
      # ===================================================
      tabItem(tabName = "map",
              h3("Localisation des Logements Filtrés"),
              p("La taille du cercle indique la concentration de logements filtrés dans l'arrondissement. La couleur indique la consommation moyenne."),
              leafletOutput("map_dpe", height = 600) 
      ),
      
      # ===================================================
      # ONGLET 3 : DICTIONNAIRE (FILTRE RETIRÉ)
      # ===================================================
      tabItem(tabName = "doc",
              h3("Dictionnaire des Données Clés"),
              dataTableOutput("dictionnaire_colonnes")
      ),
      
      # ===================================================
      # ONGLET 4 : DONNÉES BRUTES (RÉTABLI EN STABLE)
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
    
    # Filtrage de l'Arrondissement (déjà en place)
    if (input$code_postal_choisi != "Tous") { data_a_filtrer <- data_a_filtrer %>% filter(code_postal == input$code_postal_choisi) }
    
    data_a_filtrer <- data_a_filtrer %>% filter(annee_construction >= annee_min, annee_construction <= annee_max)
    return(data_a_filtrer)
  })
  
  # 2. Création des Indicateurs Clés de Performance (KPI)
  output$kpi_total_logements <- renderValueBox({ n_logements <- nrow(data_filtree_reactive()); valueBox(value = format(n_logements, big.mark = " "), subtitle = "Logements Filtrés", icon = icon("home"), color = "blue") })
  output$kpi_conso_moyenne <- renderValueBox({ conso_moyenne <- data_filtree_reactive() %>% summarise(moy = mean(consommation_kwh_m2, na.rm=TRUE)) %>% pull(moy); valueBox(value = paste(round(conso_moyenne, 1), "kWh/m²"), subtitle = "Consommation Moyenne", icon = icon("bolt"), color = "orange") })
  output$kpi_surface_mediane <- renderValueBox({ surface_mediane <- data_filtree_reactive() %>% summarise(med = median(surface_m2, na.rm=TRUE)) %>% pull(med); valueBox(value = paste(round(surface_mediane, 0), "m²"), subtitle = "Surface Médiane", icon = icon("ruler-combined"), color = "green") })
  
  # 3-6. Graphiques
  output$histogramme_surface <- renderPlot({
    data_pour_graph <- data_filtree_reactive(); titre_complet <- paste("Distribution de la Surface pour DPE Classe", input$classe_dpe_choisie, "(Arrondissement:", input$code_postal_choisi, ", Années:", input$annee_construction_range[1], "-", input$annee_construction_range[2], ")"); if (nrow(data_pour_graph) > 0) { ggplot(data_pour_graph, aes(x = surface_m2)) + geom_histogram(bins = 30, fill = "#0072B2", color = "white") + labs(title = titre_complet, x = "Surface Habitable (m²)", y = "Nombre de logements") + theme_minimal() } else { ggplot() + annotate("text", x = 0, y = 0, label = "Aucun logement trouvé pour cette sélection.", size = 6) + theme_void() }
  })
  output$graphique_consommation <- renderPlot({
    data_pour_conso <- data_filtree_reactive(); titre_conso <- paste("Consommation Moyenne (kWh/m²) par Arrondissement pour DPE Classe", input$classe_dpe_choisie); if (nrow(data_pour_conso) > 0) { data_conso_summary <- data_pour_conso %>% group_by(code_postal) %>% summarise(consommation_moyenne = mean(consommation_kwh_m2, na.rm = TRUE), .groups = 'drop'); ggplot(data_conso_summary, aes(x = code_postal, y = consommation_moyenne)) + geom_bar(stat = "identity", fill = "#D55E00", color = "white") + labs(title = titre_conso, x = "Code Postal (Arrondissement de Lyon)", y = "Consommation Énergétique Moyenne (kWh/m²)") + theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1)) } else { ggplot() + annotate("text", x = 0, y = 0, label = "Aucun logement trouvé pour cette sélection.", size = 6) + theme_void() }
  })
  output$boxplot_conso_type <- renderPlot({
    data_pour_boxplot <- data_filtree_reactive(); titre_boxplot <- paste("Distribution de la Consommation (kWh/m²) par Type de Logement pour DPE Classe", input$classe_dpe_choisie); if (nrow(data_pour_boxplot) > 0) { ggplot(data_pour_boxplot, aes(x = type_logement_immeuble, y = consommation_kwh_m2, fill = type_logement_immeuble)) + geom_boxplot(alpha=0.7) + labs(title = titre_boxplot, x = "Type de Logement", y = "Consommation Énergétique (kWh/m²)") + coord_cartesian(ylim = c(0, 500)) + theme_minimal() + theme(legend.position = "none") } else { ggplot() + annotate("text", x = 0, y = 0, label = "Aucun logement trouvé pour cette sélection.", size = 6) + theme_void() }
  })
  output$scatterplot_regression <- renderPlot({
    data_pour_scatter <- data_filtree_reactive(); var_x <- input$var_x_reg; var_y <- input$var_y_reg; titre_scatter <- paste("Régression (", var_x, " vs. ", var_y, ") pour DPE Classe", input$classe_dpe_choisie); if (nrow(data_pour_scatter) > 0) { cor_val <- cor(data_pour_scatter[[var_x]], data_pour_scatter[[var_y]], use = "pairwise.complete.obs"); titre_complet_scatter <- paste0(titre_scatter, " (Corrélation: ", round(cor_val, 3), ")"); ggplot(data_pour_scatter, aes(x = .data[[var_x]], y = .data[[var_y]])) + geom_point(alpha = 0.3, color = "#0072B2") + geom_smooth(method = "lm", se = FALSE, color = "#D55E00") + labs(title = titre_complet_scatter, x = var_x, y = var_y) + theme_minimal() } else { ggplot() + annotate("text", x = 0, y = 0, label = "Aucun logement trouvé pour cette sélection.", size = 6) + theme_void() }
  })
  
  # 7. Tableau de Données Brutes (STABLE)
  output$tableau_donnees_brutes <- renderDataTable({
    datatable(data_dpe, 
              options = list(pageLength = 10, scrollX = TRUE),
              rownames = FALSE)
  })
  
  # NOUVEAU OUTPUT : Dictionnaire de Données (Filtre Retiré)
  output$dictionnaire_colonnes <- renderDataTable({
    datatable(col_defs,
              options = list(
                pageLength = 10, 
                scrollX = TRUE,
                dom = 'tip' 
              ),
              rownames = FALSE)
  })
  
  # 8. Cartographie
  output$map_dpe <- renderLeaflet({
    leaflet() %>% addProviderTiles(providers$OpenStreetMap.Mapnik) %>% setView(lng = 4.85, lat = 45.75, zoom = 12) 
  })
  
  observe({
    data_filtree <- data_filtree_reactive(); data_stats <- data_filtree %>% group_by(code_postal) %>% summarise(count = n(), conso_moyenne = mean(consommation_kwh_m2, na.rm = TRUE), .groups = 'drop'); data_map <- left_join(data_stats, lyon_centroids, by = "code_postal"); map_proxy <- leafletProxy("map_dpe", data = data_map) %>% clearShapes() %>% clearControls() 
    if (nrow(data_map) > 0) {
      pal <- colorQuantile("YlOrRd", data_map$conso_moyenne, n = 5); map_proxy %>% setView(lng = 4.85, lat = 45.75, zoom = 12) %>% addCircles(lng = ~lng_wgs84, lat = ~lat_wgs84, weight = 1, radius = ~sqrt(count) * 150, fillColor = ~pal(conso_moyenne), fillOpacity = 0.8, color = "#CC0000", popup = ~paste("Arrondissement: <b>", code_postal, "</b><br>", "Logements Filtrés: ", count, "<br>", "Conso Moyenne: ", round(conso_moyenne, 1), "kWh/m²")) %>% addLegend(pal = pal, values = ~conso_moyenne, title = "Conso Moyenne (kWh/m²)", position = "bottomright")
    }
  })
  
  # 9. Fonctions d'Exportation
  output$downloadData <- downloadHandler(filename = function() { paste("dpe_filtre_", Sys.Date(), ".csv", sep = "") }, content = function(file) { write_csv(data_filtree_reactive(), file) })
  output$downloadHistPlot <- downloadHandler(filename = function() { paste("histogramme_surface_", Sys.Date(), ".png", sep = "") }, content = function(file) { data_pour_graph <- data_filtree_reactive(); p <- ggplot(data_pour_graph, aes(x = surface_m2)) + geom_histogram(bins = 30, fill = "#0072B2", color = "white") + labs(title = "Distribution de la Surface filtrée") + theme_minimal(); ggsave(file, plot = p, device = "png", width = 8, height = 6, units = "in") })
  output$downloadConsoBarPlot <- downloadHandler(filename = function() { paste("barres_conso_arrond_", Sys.Date(), ".png", sep = "") }, content = function(file) { data_pour_conso <- data_filtree_reactive() %>% group_by(code_postal) %>% summarise(consommation_moyenne = mean(consommation_kwh_m2, na.rm = TRUE), .groups = 'drop'); p <- ggplot(data_pour_conso, aes(x = code_postal, y = consommation_moyenne)) + geom_bar(stat = "identity", fill = "#D55E00", color = "white") + labs(title = "Consommation Moyenne (kWh/m²) par Arrondissement") + theme_minimal(); ggsave(file, plot = p, device = "png", width = 8, height = 6, units = "in") })
  output$downloadBoxplotPlot <- downloadHandler(filename = function() { paste("boxplot_conso_type_", Sys.Date(), ".png", sep = "") }, content = function(file) { data_pour_boxplot <- data_filtree_reactive(); p <- ggplot(data_pour_boxplot, aes(x = type_logement_immeuble, y = consommation_kwh_m2, fill = type_logement_immeuble)) + geom_boxplot(alpha=0.7) + labs(title = "Distribution de la Consommation par Type de Logement") + coord_cartesian(ylim = c(0, 500)) + theme_minimal() + theme(legend.position = "none"); ggsave(file, plot = p, device = "png", width = 8, height = 6, units = "in") })
  output$downloadScatterPlot <- downloadHandler(filename = function() { paste("regression_plot_", Sys.Date(), ".png", sep = "") }, content = function(file) { data_pour_scatter <- data_filtree_reactive(); var_x <- input$var_x_reg; var_y <- input$var_y_reg; cor_val <- cor(data_pour_scatter[[var_x]], data_pour_scatter[[var_y]], use = "pairwise.complete.obs"); titre_complet_scatter <- paste0("Régression (", var_x, " vs. ", var_y, ") (Corrélation: ", round(cor_val, 3), ")"); p <- ggplot(data_pour_scatter, aes(x = .data[[var_x]], y = .data[[var_y]])) + geom_point(alpha = 0.3, color = "#0072B2") + geom_smooth(method = "lm", se = FALSE, color = "#D55E00") + labs(title = titre_complet_scatter, x = var_x, y = var_y) + theme_minimal(); ggsave(file, plot = p, device = "png", width = 8, height = 6, units = "in") })
  
  
} # FIN de la fonction server


# --- PARTIE 3 : LANCEMENT DE L'APPLICATION ---
shinyApp(ui = ui, server = server)