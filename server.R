library(shiny)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggplot2)
library(sf)
library(DBI)


server <- function(input, output, session) {
    # Add species options on the server side
    updateSelectizeInput(
        session,
        "scientificName",
        choices = species_names,
        server = TRUE
    )

    #  by eventDate directly in DuckDB
    get_timeline_species_data <- reactive({
        # Ensures a species is selected before sending a query 
        # Let me know if this is needed.
        req(input$scientificName, input$scientificName != "")

        DBI::dbGetQuery(
            con,
            "SELECT 
                CAST(eventDate AS DATE) AS eventDate, 
                SUM(individualCount) AS individualCount
             FROM occurence_poland
             WHERE scientificName = ?
               AND eventDate IS NOT NULL
             GROUP BY CAST(eventDate AS DATE)
             ORDER BY eventDate DESC",
            params = list(input$scientificName)
        )
    })


    get_observation_data <- reactive({
        req(input$scientificName, nzchar(input$scientificName))

        DBI::dbGetQuery(
            con,
            "
            SELECT
                TRY_CAST(latitudeDecimal AS DOUBLE) AS latitude,
                TRY_CAST(longitudeDecimal AS DOUBLE) AS longitude,
                scientificName,
                eventDate,
                individualCount
            FROM occurence_poland
            WHERE scientificName = ?
            ORDER BY eventDate DESC
            LIMIT 5000
            ",
            params = list(input$scientificName)
        )
    })


    # Render Timeline Plot
    output$timeline <- renderPlot({
        timeline_data <- get_timeline_species_data()
        req(nrow(timeline_data) > 0)

        # Ensure Date type in R for ggplot scale
        timeline_data$eventDate <- as.Date(timeline_data$eventDate)

        ggplot(timeline_data, aes(x = eventDate, y = individualCount)) +
            geom_line(color = "#007bc2", linewidth = 0.8) +
            geom_point(color = "#007bc2", size = 1.5) +
            scale_x_date(date_labels = "%Y-%m", date_breaks = "2 years") +
            labs(
                x = "Event date",
                y = "Number of observations",
                title = paste("Timeline for", input$scientificName)
            ) +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))
    })


    # Render Summary Table
    output$yearly_table <- renderTable({
        timeline_data <- get_timeline_species_data()
        req(nrow(timeline_data) > 0)


        # Format date as readable character strings for renderTable
        data.frame(
            Date = as.character(timeline_data$eventDate),
            Observations = as.integer(timeline_data$individualCount),
            check.names = FALSE
        )
    }, striped = TRUE, hover = TRUE, bordered = TRUE, width = "100%")

    # Redner map of Poland
    output$poland_map <- renderPlot({
        poland_map <- ne_countries(country = "Poland", returnclass = "sf")
    
        observation_data <- get_observation_data()
        req(nrow(observation_data) > 0)
    
        # convert langitude and latitude vars to sf points layer
        sf_points_data <- st_as_sf(
            observation_data,
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
                title = paste("Observation locations:", input$scientificName),
                subtitle = sprintf("%d records shown", nrow(observation_data))
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
}