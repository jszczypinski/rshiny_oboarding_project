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

#' @export
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

#' Species selector server
#'
#' @param id Shiny module ID.
#' @param species_names Character vector of species names.
#'
#' @return A reactive expression that returns the selected species name.
#' @export
select_species_server <- function(id, species_names) {
    moduleServer(id, function(input, output, session) {
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