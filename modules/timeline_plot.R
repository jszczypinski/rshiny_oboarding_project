timeline_plot_ui <- function(id) {
    ns <- NS(id)
    card(
        card_header("Timeline"),
        plotOutput(ns("plot"))
    )
}

timeline_plot_server <- function(id, data, species) {
    moduleServer(id, function(input, output, session) {
        output$plot <- renderPlot({
            df <- data()
            req(nrow(df) > 0)
            df$eventDate <- as.Date(df$eventDate)

        ggplot(df, aes(x = eventDate, y = individualCount)) +
            geom_line(color = "#007bc2", linewidth = 0.8) +
            geom_point(color = "#007bc2", size = 1.5) +
            scale_x_date(date_labels = "%Y-%m", date_breaks = "2 years") +
            labs(
                x = "Event date",
                y = "Number of observations",
                title = paste("Timeline for", species())
            ) +
            theme_minimal() +
            theme(axis.text.x = element_text(angle = 45, hjust = 1))

        })
    })
}