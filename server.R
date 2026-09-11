# ./server.R

box::use(
    shiny[reactive, req, reactiveVal, isolate],
    modules/select_species[select_species_server],
    modules/plot_timeline[plot_timeline_server],
    modules/table_timeline[table_timeline_server],
    modules/plot_map[plot_map_server],
    lib/database[
        db_get_species_matched,
        db_get_timeline_data,
        db_get_observation_data
    ],
    lib/species_helpers[
        compute_default_species,
        setup_species_selector_sync
    ]
)

#' @export
server <- function(input, output, session, con) {
    # Get matched species
    species_matched <- db_get_species_matched(con)
    scientific_names <- species_matched$scientificName
    vernacular_names <- species_matched$vernacularName

    # Single source of truth: selected scientific name
    selected_scientific <- reactiveVal(NULL)
    user_interacted <- reactiveVal(FALSE)

    # Scientific name selector
    sci_names_selector <- select_species_server(
        id = "science_species_selector",
        name_col = "scientificName",
        species_names = scientific_names
    )

    # Vernacular name selector
    vern_names_selector <- select_species_server(
        id = "vernacular_species_selector",
        name_col = "vernacularName",
        species_names = vernacular_names
    )

    # ---- Set predefined starting species (no visible update) ----

    defaults <- compute_default_species(scientific_names, vernacular_names)

    # Initialize central state
    if (!is.null(defaults$sci)) {
        selected_scientific(defaults$sci)
    }

    # Set both selectors explicitly at startup
    if (!is.null(defaults$sci) && !is.null(defaults$vern)) {
        isolate({
            sci_names_selector$set_selected(defaults$sci)
            vern_names_selector$set_selected(defaults$vern)
        })
    }
    # -------------------------------------------------------------

    # Wire up syncing between the two selectors
    setup_species_selector_sync(
        sci_selector = sci_names_selector,
        vern_selector = vern_names_selector,
        scientific_names = scientific_names,
        vernacular_names = vernacular_names,
        selected_scientific = selected_scientific,
        user_interacted = user_interacted
    )

    # Use scientific selector for data
    timeline_data <- reactive({
        species <- selected_scientific()
        req(species)
        db_get_timeline_data(con, species)
    })

    observation_data <- reactive({
        species <- selected_scientific()
        req(species)
        db_get_observation_data(con, species)
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