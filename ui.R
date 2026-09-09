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
        select_species_ui("science_species_selector", name_col = "scientificName"),
        select_species_ui("vernacular_species_selector", name_col = "vernacularName") 
    ),
    
    layout_columns(
        col_widths = 12,
        min_height = "50vh",
        plot_map_ui("map_poland")
    ),
    layout_columns(
        col_widths = c(7, 5),
        min_height = "40vh",
        plot_timeline_ui("plot_timeline"),
        table_timeline_ui("table_yearly")
    )
)