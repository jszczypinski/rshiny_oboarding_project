options(box.path = here::here())

box::use(
    shiny[
        reactive,
        selectInput,
        shinyApp
    ],
    bslib[page_fluid]
)
box::use(
    modules/plot_season[
        plot_season_ui,
        plot_season_server
    ],
    modules/theme[SEASON_COLORS]
)

datasets <- list(
    two_seasons = data.frame(season = names(SEASON_COLORS)[1:2], individualCount = c(5L, 12L)),
    all_seasons = data.frame(season = names(SEASON_COLORS), individualCount = c(5L, 12L, 7L, 1L)),
    empty = data.frame(season = character(0), individualCount = integer(0))
)

ui <- page_fluid(
    selectInput("dataset", "Dataset", choices = names(datasets)),
    plot_season_ui("plot_season")
)
server <- function(input, output, session) {
    plot_season_server("plot_season", data = reactive(datasets[[input$dataset]]))
}

shinyApp(ui, server)
