# ./ui.R

box::use(
    bslib[
        layout_columns,
        page_sidebar,
        sidebar
    ],
    modules/select_species[select_species_ui],
    modules/plot_map[plot_map_ui],
    modules/plot_timeline[plot_timeline_ui],
    modules/table_timeline[table_timeline_ui]
)

#' @export
ui <- page_sidebar(
    title = "Biodiversity dashboard",
    sidebar = sidebar(
        title = "Species selection",
        select_species_ui("science_species_selector")
    ),

    # Map of Poland in 1st row
    layout_columns(
        col_widths = 12,
        min_height = "50vh",
        plot_map_ui("map_poland")
    ),
    # 2nd row - plot and a table
    # I am not sure if I usethis kind of plot and table, but the layout should be as it is now
    layout_columns(
        col_widths = c(7, 5),
        min_height = "40vh",
        # Timeline card
        plot_timeline_ui("plot_timeline"),
        # Table card
        table_timeline_ui("table_yearly")
    )
)