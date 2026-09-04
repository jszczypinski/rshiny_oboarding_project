select_species_ui <- function(id) {
    ns <- NS(id)
    tagList(
        selectizeInput(
            ns("scientificName"),
            "Scientific name",
            choices = NULL,
            options = list(
                placeholder = "Select a species"
            ) 
        )
    )
}

select_species_server <- function(id, species_names) {
    moduleServer(id,
    function(input, output, session) {
        updateSelectizeInput(
            session,
            "scientificName",
            selected = "Haliaeetus albicilla",
            choices = species_names,
            server = TRUE
        )

        reactive({
            input$scientificName
        })
    })
}