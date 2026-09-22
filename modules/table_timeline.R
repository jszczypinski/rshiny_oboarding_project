box::use(
    shiny[
        NS,
        moduleServer,
        renderTable,
        req,
        tableOutput
    ],
    bslib[
        card,
        card_header
    ]
)

#' @export
table_timeline_ui <- function(id) {
    ns <- NS(id)

    card(
        card_header("Observations per Year"),
        tableOutput(ns("table"))
    )
}

#' Render a table of observation dates and counts
#'
#' @param id Shiny module ID.
#' @param data Reactive expression returning occurrence data with `eventDate`
#'   and `individualCount` columns.
#'
#' @return Registers the module server logic.
#' @export
table_timeline_server <- function(id, data) {
    moduleServer(id, function(input, output, session) {
        output$table <- renderTable({
            df <- data()
            req(nrow(df) > 0)

            data.frame(
                Date = as.character(df$eventDate),
                Observations = as.integer(df$individualCount),
                check.names = FALSE
            )
        },
        striped = TRUE,
        hover = TRUE,
        bordered = TRUE
        )
    })
}
