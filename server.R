library(shiny)
library(rnaturalearth)
library(rnaturalearthdata)
library(ggplot2)
library(sf)
library(DBI)

server <- function(input, output, session) {
    # Add species options on the server side
    selected_species <- select_species_server(
        id = "science_species_selector",
        species_names = get_species_names(con, "scientificName")
    )

    #  by eventDate directly in DuckDB
    timeline_data <- reactive({
        # Ensures a species is selected before sending a query 
        # Let me know if this is needed.
        req(selected_species())

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
            params = list(selected_species())
        )
    })


    observation_data <- reactive({
        req(selected_species())

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
            params = list(selected_species())
        )
    })


    # Render Timeline Plot
    timeline_plot_server(
        id = "timeline_plot",
        data = timeline_data,
        species = selected_species
    )

    # Render Summary Table
    timeline_table_server(
        id = "yearly_table",
        data = timeline_data,
        species = selected_species
    )

    # Redner map of Poland
    map_plot_server(
        id = "poland_map",
        data = observation_data,
        species = selected_species
    )
}