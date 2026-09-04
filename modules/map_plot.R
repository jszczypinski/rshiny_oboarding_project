map_plot_ui <- function(id) {
    ns <- NS(id)

    card(
        card_header("Observation locations in Poland"),
        plotOutput(ns("poland_map"))
    )
}

map_plot_server <- function(id, data, species){
    moduleServer(id, function(input, output, session){
        output$poland_map <- renderPlot({
            poland_map <- ne_countries(country = "Poland", returnclass = "sf")
        
            df <- data()
            req(nrow(df) > 0)
        
            # convert langitude and latitude vars to sf points layer
            sf_points_data <- st_as_sf(
                df,
                coords = c("longitude", "latitude"),
                crs = 4326
            )
        
            ggplot() +
                geom_sf(data = poland_map, fill = "grey90", color = "grey50", linewidth = 0.3) +
                geom_sf(
                    data = sf_points_data,
                    aes(),
                    shape = 21,
                    fill = "#007bc2",
                    color = "#007bc2",
                    size = 1.2,
                    stroke = 0.3,
                    alpha = 0.7
                ) +
                coord_sf(
                    crs = st_crs(poland_map),
                    datum = NA
                ) +
                labs(
                    title = paste("Observation locations:", species()),
                    subtitle = sprintf("%d records shown", nrow(df))
                ) +
                theme_minimal(base_size = 11) +
                theme(
                    panel.grid.major = element_line(color = "grey90"),
                    panel.grid.minor = element_blank(),
                    axis.text = element_text(size = 9),
                    axis.title = element_blank(),
                    legend.position = "none"
                )
        })
    })
}