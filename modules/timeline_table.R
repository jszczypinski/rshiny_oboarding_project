timeline_table_ui <- function(id) {
    ns <- NS(id)
    card(
        card_header("Observations per Year"),
        tableOutput(ns("table"))
    )
}

timeline_table_server <- function(id, data, species) {
    moduleServer(id, function(input, output, session) {
        output$table <- renderTable({
            df <- data()
            req(nrow(df) > 0)
        
        # Format date as readable character strings for renderTable
        data.frame(
            Date = as.character(df$eventDate),
            Observations = as.integer(df$individualCount),
            check.names = FALSE
        )
    }, striped = TRUE, hover = TRUE, bordered = TRUE, width = "100%")
    })
}