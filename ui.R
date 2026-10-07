box::use(
    bslib
    [
        layout_columns,
        page_sidebar,
        sidebar
    ]
)
box::use(
    modules/select_species[select_species_ui],
    modules/plot_leaflet_map[plot_leaflet_map_ui],
    modules/table_timeline[table_timeline_ui],
    modules/plot_season[plot_season_ui]
)

#' @export
ui <- page_sidebar(
    title = "Biodiversity dashboard",
    sidebar = sidebar(
        title = "Species selection",
        select_species_ui("species_selector")
    ),

    layout_columns(
        min_height = "50vh",
        plot_leaflet_map_ui("leaflet_map")
    ),
    layout_columns(
        col_widths = c(7, 5),
        min_height = "40vh",
        plot_season_ui("plot_season"),
        table_timeline_ui("table_yearly")
    )
)
