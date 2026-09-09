# ./server.R

box::use(
    shiny[reactive, req, observeEvent, isolate, reactiveVal],
    modules/select_species[select_species_server],
    modules/plot_timeline[plot_timeline_server],
    modules/table_timeline[table_timeline_server],
    modules/plot_map[plot_map_server],
    lib/database[
        db_get_species_matched,
        db_get_timeline_data,
        db_get_observation_data
    ],
    stats[setNames]
)


#' @export
server <- function(input, output, session, con) {
    # Get matched species
    species_matched <- db_get_species_matched(con)
    scientific_names <- species_matched$scientificName
    vernacular_names <- species_matched$vernacularName
  
    # Create lookup: scientific -> vernacular
    sci_to_vern <- setNames(vernacular_names, scientific_names)
    vern_to_sci <- setNames(scientific_names, vernacular_names)

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

    # Default scientific name
    default_sci <-
        if ("Haliaeetus albicilla" %in% scientific_names) {
            "Haliaeetus albicilla"
        } else if (length(scientific_names) > 0) {
            scientific_names[1]
        } else {
            NULL
        }

    # Corresponding vernacular name
    default_vern <-
        if (!is.null(default_sci) && default_sci %in% names(sci_to_vern)) {
            sci_to_vern[[default_sci]]
        } else if (length(vernacular_names) > 0) {
            vernacular_names[1]
        } else {
            NULL
        }

    # Initialize central state
    if (!is.null(default_sci)) {
        selected_scientific(default_sci)
    }

    # Set both selectors explicitly at startup (inside isolate to avoid triggering observers)
    if (!is.null(default_sci) && !is.null(default_vern)) {
        isolate({
            sci_names_selector$set_selected(default_sci)
            vern_names_selector$set_selected(default_vern)
        })
    }
    # -------------------------------------------------------------

    # When user changes scientific, update central state
    observeEvent(sci_names_selector$selected(), {
        sci_name <- sci_names_selector$selected()
        if (is.null(sci_name) || sci_name == "") return()
        if (!sci_name %in% names(sci_to_vern)) return()
            
        # Mark that the user has interacted
        user_interacted(TRUE)
        
        selected_scientific(sci_name)
    }, 
    ignoreInit = TRUE
)

    # When user changes vernacular, translate and update central state
    observeEvent(vern_names_selector$selected(), {
        vern_name <- vern_names_selector$selected()
        if (is.null(vern_name) || vern_name == "") return()
        if (!vern_name %in% names(vern_to_sci)) return()

        # Mark that the user has interacted
        user_interacted(TRUE)

        selected_scientific(vern_to_sci[[vern_name]])
    }, 
    ignoreInit = TRUE
)

    # When central state changes, update BOTH selectors
    observeEvent(selected_scientific(), {

        if (!user_interacted()) return()

        sci_name <- selected_scientific()
        req(sci_name)

        # Update scientific selector only if it differs
        current_sci <- sci_names_selector$selected()
        if (!identical(current_sci, sci_name)) {
            isolate({
                sci_names_selector$set_selected(sci_name)
            })
        }

        # Update vernacular selector
        if (sci_name %in% names(sci_to_vern)) {
            vern_name <- sci_to_vern[[sci_name]]
            current_vern <- vern_names_selector$selected()
            if (!identical(current_vern, vern_name)) {
                isolate({
                    vern_names_selector$set_selected(vern_name)
                })
            }
        }
    }, 
    ignoreInit = TRUE
)


    # Use scientific selector for data
    timeline_data <- reactive({
        species <- sci_names_selector$selected()
        req(species)
        db_get_timeline_data(con, species)
    })
    
    observation_data <- reactive({
        species <- sci_names_selector$selected()
        req(species)
        db_get_observation_data(con, species)
    })
    
    # Render modules
    plot_timeline_server(
        id = "plot_timeline",
        data = timeline_data,
        species = sci_names_selector$selected
    )
    
    table_timeline_server(
        id = "table_yearly",
        data = timeline_data
    )
    
    plot_map_server(
        id = "map_poland",
        data = observation_data,
        species = sci_names_selector$selected
    )
}