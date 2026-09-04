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
        map_plot_ui("poland_map")
    ),
    # 2nd row - plot and a table
    # I am not sure if I usethis kind of plot and table, but the layout should be as it is now
    layout_columns(
        col_widths = c(7, 5),
        min_height = "40vh",
        # Timeline card
        timeline_plot_ui("timeline_plot"),
        # Table card
        timeline_table_ui("yearly_table")
    )
)