# ./server.R

box::use(
    shiny[reactive, req],
    modules/select_species[select_species_server],
    modules/plot_timeline[plot_timeline_server],
    modules/table_timeline[table_timeline_server],
    modules/plot_map[plot_map_server],
    lib/database[
        db_get_species_names,
        db_get_timeline_data,
        db_get_observation_data
    ]
)

#' @export
server <- function(input, output, session, con) {
    selected_species <- select_species_server(
        id = "science_species_selector",
        species_names = db_get_species_names(con, "scientificName")
    )

    timeline_data <- reactive({
        req(selected_species())
        db_get_timeline_data(con, selected_species())
    })

    observation_data <- reactive({
        req(selected_species())
        db_get_observation_data(con, selected_species())
    })

    plot_timeline_server(
        id = "plot_timeline",
        data = timeline_data,
        species = selected_species
    )

    table_timeline_server(
        id = "table_yearly",
        data = timeline_data
    )

    plot_map_server(
        id = "map_poland",
        data = observation_data,
        species = selected_species
    )
}