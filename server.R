# fmt: skip
box::use(
    shiny[reactive, req])
# fmt: skip
box::use(
    modules/select_species[select_species_server],
    modules/plot_timeline[plot_timeline_server],
    modules/table_timeline[table_timeline_server],
    modules/plot_map[plot_map_server],
    lib/database[
        db_get_species_matched,
        db_get_timeline_data,
        db_get_observation_data
    ],
    lib/species_helpers[compute_default_species]
)

#' @export
server <- function(input, output, session, con) {
    selected_scientific <- select_species_server(
        id = "species_selector",
        species_matched = db_get_species_matched(con),
        preferred_sci = "Haliaeetus albicilla"
    )

    # Use scientific selector for data
    timeline_data <- reactive({
        specimen <- selected_scientific()
        req(specimen)
        db_get_timeline_data(con, specimen)
    })

    observation_data <- reactive({
        specimen <- selected_scientific()
        req(specimen)
        db_get_observation_data(con, specimen)
    })

    # Render modules
    plot_timeline_server(
        id = "plot_timeline",
        data = timeline_data,
        species = selected_scientific
    )

    table_timeline_server(
        id = "table_yearly",
        data = timeline_data
    )

    plot_map_server(
        id = "map_poland",
        data = observation_data,
        species = selected_scientific
    )
}
