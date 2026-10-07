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
        element_blank,
        geom_col,
        geom_text,
        ggplot,
        labs,
        scale_fill_manual,
        theme,
        theme_minimal
    ]
)
box::use(
    lib/seasons[
        season_colors,
        seasons
    ]
)

#' @export
plot_season_ui <- function(id) {
    ns <- NS(id)

    card(
        card_header("Observations per season"),
        plotOutput(ns("plot"))
    )
}

#' Render a barplot of observations per astronomical season
#'
#' @param id Shiny module ID.
#' @param data Reactive expression returning a data frame with `season`
#'   and `individualCount` columns.
#' @param species Reactive expression returning the selected species name.
#'
#' @return Registers the module server logic.
#' @export
plot_season_server <- function(id, data, species) {
    moduleServer(id, function(input, output, session) {
        output$plot <- renderPlot({
            df <- data()
            req(nrow(df) > 0)

            # Show every season, including those without observations
            df <- merge(data.frame(season = seasons), df, all.x = TRUE)
            df$individualCount[is.na(df$individualCount)] <- 0
            df$season <- factor(
                df$season,
                levels = seasons,
                labels = c("Spring", "Summer", "Autumn", "Winter")
            )

            ggplot(df, aes(x = season, y = individualCount, fill = season)) +
                geom_col(
                    width = 0.7
                ) +
                # The x-axis already names each bar, so no legend is needed
                scale_fill_manual(
                    values = season_colors,
                    guide = "none"
                ) +
                geom_text(
                    aes(label = individualCount),
                    vjust = -0.4,
                    size = 3.5
                ) +
                labs(
                    x = NULL,
                    y = "Number of observations",
                    title = paste("Observations for", species())
                ) +
                theme_minimal() +
                theme(
                    panel.grid.major.x = element_blank()
                )
        })
    })
}
