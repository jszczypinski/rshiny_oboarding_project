options(box.path = getwd())
box::use(
    shiny[
        moduleServer,
        NS,
        reactive,
        reactiveVal,
        observe,
        bindEvent,
        req,
        selectizeInput,
        tagList,
        updateSelectizeInput
    ],
    stats[setNames]
    )
box::use(
    lib/species_helpers[compute_default_species]
)


#' Species selector UI
#' @export
select_species_ui <- function(id) {
    ns <- NS(id)
    
    tagList(
        selectizeInput(
            inputId = ns("scientific_name"),
            label = "Scientific Name",
            choices = NULL,
            options = list(
                placeholder = "Select a species",
                maxOptions = 1000
            )
        ),
        selectizeInput(
            inputId = ns("vernacular_name"),
            label = "Common Name",
            choices = NULL,
            options = list(
                placeholder = "Select a species",
                maxOptions = 1000
            )
        )
    )
}


#' Species selector server
#' @export
select_species_server <- function(
    id,
    species_matched
) { 
    moduleServer(id, function(input, output, session) {

        # Get matched species
        scientific_names <- species_matched$scientificName
        vernacular_names <- species_matched$vernacularName

        # Get character vectors with matched species
        sci_to_vern <- setNames(vernacular_names, scientific_names)
        vern_to_sci <- setNames(scientific_names, vernacular_names)

        # set default species
        default_species <- compute_default_species(scientific_names, vernacular_names)
        default_scientific <- default_species$sci
        default_vernacular <-  default_species$vern

        # create a reactive value of default_scientific - a starting choice
        selected_scientific <- reactiveVal(default_scientific)

        # Initialize selectize input
        updateSelectizeInput(
            session,
            inputId = "scientific_name",
            selected = default_scientific,
            choices = scientific_names,
            server = TRUE,
            options = list(
                placeholder = "Select a species",
                maxOptions = 1000
            )
        )

        # Initialize selectize input
        updateSelectizeInput(
            session,
            inputId = "vernacular_name",
            selected = default_vernacular,
            choices = vernacular_names,
            server = TRUE,
            options = list(
                placeholder = "Select a species",
                maxOptions = 1000
            )
        )
        # Observe changes in the choices made by users
        observe({
            sci_name <- input$scientific_name
        
            if (is.null(sci_name) || sci_name == "") {
                return()
            }
        
            if (!sci_name %in% names(sci_to_vern)) {
                return()
            }
        
            selected_scientific(sci_name)
        }) |>
            bindEvent(input$scientific_name)

        observe({
            vern_name <- input$vernacular_name

            if (is.null(vern_name) || vern_name == "") {
                return()
            }

            if(!vern_name %in% names(vern_to_sci)) {
                return()
            }
            selected_scientific(vern_to_sci[[vern_name]])
        }) |>
            bindEvent(input$vernacular_name)
      
        # Update both boxes when central state changes  
        observe({
            sci_name <- selected_scientific()
            req(sci_name)
            
            if (!sci_name %in% names(sci_to_vern)) {
                return()
            }
            
            vern_name <- sci_to_vern[[sci_name]]

            if(!identical(input$scientific_name, sci_name)) {
                updateSelectizeInput(
                    session = session,
                    inputId = "scientific_name",
                    choices = scientific_names,
                    selected = sci_name,
                    server = TRUE
                )
            }

            if(!identical(input$vernacular_name, vern_name)) {
              updateSelectizeInput(
                session = session,
                inputId = "vernacular_name",
                choices = vernacular_names,
                selected = vern_name,
                server = TRUE
              )  
            }

        }) |>
          bindEvent(selected_scientific())

        reactive(selected_scientific())
    })
}
