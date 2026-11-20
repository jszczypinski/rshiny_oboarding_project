options(box.path = here::here())
box::use(
    testthat[
        expect_error,
        expect_true,
        test_that
    ],
    shiny[
        reactive,
        testServer
    ]

)

box::use(
    modules/plot_season[plot_season_server],
    lib/database[
        create_db_con,
        db_get_season_data
    ]
)

con <- create_db_con()

test_that("plot_season module fills the data correctly", {
    season_data <- reactive({
        specimen <- "Haliaeetus albicilla"
        db_get_season_data(con, specimen)
    })
    testServer(plot_season_server, args = list(data = season_data), {
        plot <- output$plot

        x_axis <- output$plot$coordmap$panels[[1]]$domain$discrete_limits$x
        print(plot)
        # Haliaeetus albicilla was not observed during autumn
        expect_true("autumn" %in% x_axis)
    })
})

test_that("plot_season module renders a png plot", {
    season_data <- reactive({
        specimen <- "Haliaeetus albicilla"
        db_get_season_data(con, specimen)
    })
    testServer(plot_season_server, args = list(data = season_data), {
        plot <- output$plot
        expect_true(startsWith(plot$src, "data:image/png;base64"))
    })
})

test_that("season plot silently fails with empty data", {
    season_data <- reactive({
        specimen <- "No real species"
        db_get_season_data(con, specimen)
    })
    testServer(plot_season_server, args = list(data = season_data), {
        expect_error(output$plot, class = "shiny.silent.error")
    })
})
