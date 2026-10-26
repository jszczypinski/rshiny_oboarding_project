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
    dplyr[
        full_join,
        if_else,
        mutate,
        tibble
    ],
    ggplot2[
        aes,
        element_blank,
        geom_col,
        geom_text,
        ggplot,
        labs,
        scale_fill_manual,
        scale_x_discrete,
        theme,
        theme_minimal
    ],
    tools[
        toTitleCase
    ]
)
box::use(
    modules/theme[
        SEASON_COLORS
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

            df <- df |>
                full_join(tibble(season = names(SEASON_COLORS)), by = "season") |>
                mutate(
                    individualCount = if_else(
                        is.na(individualCount),
                        0,
                        individualCount
                    ),
                    season = factor(season, levels = names(SEASON_COLORS))
                )

            ggplot(df, aes(x = season, y = individualCount, fill = season)) +
                geom_col(
                    width = 0.7
                ) +
                scale_fill_manual(
                    values = SEASON_COLORS,
                    guide = "none"
                ) +
                scale_x_discrete(
                    labels = toTitleCase(names(SEASON_COLORS))
                ) +
                geom_text(
                    aes(label = individualCount),
                    vjust = -0.4,
                    size = 3.5
                ) +
                labs(
                    x = NULL,
                    y = "Number of observations",
                    title = NULL
                ) +
                theme_minimal() +
                theme(
                    panel.grid.major.x = element_blank()
                )
        })
    })
}
