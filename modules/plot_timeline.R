# modules/plot_timeline.R

box::use(
    shiny[
        NS,
        moduleServer,
        plotOutput,
        renderPlot,
        req
    ],
    bslib[
        card,
        card_header
    ],
    ggplot2[
        aes,
        element_text,
        geom_line,
        geom_point,
        ggplot,
        labs,
        scale_x_date,
        theme,
        theme_minimal
    ]
)

#' @export
plot_timeline_ui <- function(id) {
    ns <- NS(id)

    card(
        card_header("Timeline"),
        plotOutput(ns("plot"))
    )
}

#' Render an observation timeline plot
#'
#' @param id Shiny module ID.
#' @param data Reactive expression returning occurrence data with `eventDate`
#'   and `individualCount` columns.
#' @param species Reactive expression returning the selected species name.
#'
#' @return Registers the module server logic.
#' @export
plot_timeline_server <- function(id, data, species) {
    moduleServer(id, function(input, output, session) {
        output$plot <- renderPlot({
            df <- data()
            req(nrow(df) > 0)

            df$eventDate <- as.Date(df$eventDate)

            ggplot(df, aes(x = eventDate, y = individualCount)) +
                geom_line(
                    color = "#007bc2",
                    linewidth = 0.8
                ) +
                geom_point(
                    color = "#007bc2",
                    size = 1.5
                ) +
                scale_x_date(
                    date_labels = "%Y-%m",
                    date_breaks = "2 years"
                ) +
                labs(
                    x = "Event date",
                    y = "Number of observations",
                    title = paste("Timeline for", species())
                ) +
                theme_minimal() +
                theme(
                    axis.text.x = element_text(
                        angle = 45,
                        hjust = 1
                    )
                )
        })
    })
}