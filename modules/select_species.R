# modules/select_species.R

box::use(
    shiny[
        moduleServer,
        NS,
        reactive,
        selectizeInput,
        tagList,
        updateSelectizeInput
    ]
)


#' Species selector UI
select_species_ui <- function(id, name_col = c("scientificName", "vernacularName")) {
    name_col <- match.arg(name_col)
    ns <- NS(id)
    
    label <- if (name_col == "scientificName") "Scientific Name" else "Common Name"
    
    tagList(
        selectizeInput(
            inputId = ns("species"),
            label = label,
            choices = NULL,
            options = list(
                placeholder = "Select a species",
                maxOptions = 1000
            )
        )
    )
}


#' Species selector server
select_species_server <- function(
    id,
    name_col = c("scientificName", "vernacularName"),
    species_names
) {
    name_col <- match.arg(name_col)
    
    moduleServer(id, function(input, output, session) {
        
        # Use White Eagle as default if it exists, otherwise first species
        if (name_col == "scientificName") {
            default_name <- "Haliaeetus albicilla"
        } else {
            default_name <- "White-tailed Eagle"
        }
        
        # Check if default exists in the list
        if (default_name %in% species_names) {
            selected_specimen <- default_name
        } else if (length(species_names) > 0) {
            selected_specimen <- species_names[1]
        } else {
            selected_specimen <- character(0)
        }
        
        # Initialize selectize input
        updateSelectizeInput(
            session,
            inputId = "species",
            selected = selected_specimen,
            choices = species_names,
            server = TRUE,
            options = list(
                placeholder = "Select a species",
                maxOptions = 1000
            )
        )
        
        # Return reactive with selected value
        selected <- reactive({
            input[["species"]]
        })
        
        # Expose an update function that always re-supplies choices
        set_selected <- function(value) {
            # Clear first to avoid stale options (selectize.js quirk)
            updateSelectizeInput(
                session,
                inputId = "species",
                selected = character(0),
                choices = species_names,
                server = TRUE,
                options = list(
                    placeholder = "Select a species",
                    maxOptions = 1000
                )
            )
            # Then set the real value
            updateSelectizeInput(
                session,
                inputId = "species",
                selected = value,
                choices = species_names,
                server = TRUE,
                options = list(
                    placeholder = "Select a species",
                    maxOptions = 1000
                )
            )
        }
        
        list(selected = selected, set_selected = set_selected)
    })
}