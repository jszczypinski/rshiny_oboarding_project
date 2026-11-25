box::use(
    testthat[
        describe,
        expect_equal,
        expect_false,
        expect_gte,
        expect_lt,
        expect_true,
        it,
        test_path
    ],
    shinytest2[
        AppDriver,
        platform_variant
    ]
)

describe("plot_season module", {
    app <- AppDriver$new(test_path("apps", "plot_season"), name = "plot_season", variant = platform_variant())
    plot <- app$get_value(output = "plot_season-plot")
    app$expect_screenshot(selector = "#plot_season-plot")

    it("shows all four seasons even when some have no data", {
        x_axis <- plot$coordmap$panels[[1]]$domain$discrete_limits$x

        expect_equal(x_axis, c("spring", "summer", "autumn", "winter"))
    })

    it("sends a png image to the browser", {
        expect_true(startsWith(plot$src, "data:image/png;base64"))
    })

    it("fails silently when there is no data", {
        app$set_inputs(dataset = "empty")
        expect_true("shiny.silent.error" %in% app$get_value(output = "plot_season-plot")$type)
    })

    it("shows the title", {
        expect_equal(app$get_text(".card-header"), "Observations per season")
    })

    it("renders the plot inside the card without an error", {
        app$set_inputs(dataset = "two_seasons")
        expect_false(app$get_js("document.querySelector('#plot_season-plot img') === null"))
        expect_false(app$get_js(
            "document.querySelector('#plot_season-plot').classList.contains('shiny-output-error')"
        ))
    })

    it("maps season to x and fill, and individualCount to y", {
        mapping <- plot$coordmap$panels[[1]]$mapping
        expect_equal(mapping$x, "season")
        expect_equal(mapping$y, "individualCount")
        expect_equal(mapping$fill, "season")
    })

    it("scales the y axis to the largest count", {
        y_top <- plot$coordmap$panels[[1]]$domain$top
        expect_gte(y_top, 12)
    })

    it("redraws to fit a narrower window", {
        width_before <- plot$width
        app$set_window_size(width = 600, height = 800)
        app$wait_for_idle()

        plot <- app$get_value(output = "plot_season-plot")

        width_after <- plot$width
        expect_lt(width_after, width_before)
    })

    describe("plot_season module reactivity", {
        app <- AppDriver$new(test_path("apps", "plot_season"), name = "plot_season_reactivity")
        get_plot <- function() app$get_value(output = "plot_season-plot")

        it("redraws when the data changes", {
            src_before <- get_plot()$src
            app$set_inputs(dataset = "all_seasons")
            expect_false(src_before == get_plot()$src)
        })

        it("hides the plot when the data changes to empty", {
            app$set_inputs(dataset = "empty")
            expect_true("shiny.silent.error" %in% get_plot()$type)
        })

        it("shows the plot again when data comes back after beeing empty", {
            app$set_inputs(dataset = "empty")
            app$set_inputs(dataset = "all_seasons")
            expect_true(startsWith(get_plot()$src, "data:image/png;base64"))
        })
    })
})
