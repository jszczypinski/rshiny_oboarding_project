ui <- page_sidebar(
    title = "Biodiversity dashboard",
    sidebar = sidebar(
        title = "Species selection",
        selectizeInput(
            "scientificName",
            "Scientific name",
            choices = species_names,
            options = list(
                placeholder = "Select a species"
            )
        )
    ),

    # Map of Poland in 1st row
    layout_columns(
        col_widths = 12,
        min_height = "50vh",
        card(
            card_header("Observation locations in Poland"),
            plotOutput("poland_map")
        )
    ),
    # 2nd row - plot and a table
    # I am not sure if I usethis kind of plot and table, but the layout should be as it is now
    layout_columns(
        col_widths = c(7, 5),
        min_height = "40vh",
        # Timeline card
        card(
            card_header("Timeline"),
            plotOutput("timeline")
        ),
        # Table card
        card(
            card_header("Observations per Year"),
            tableOutput("yearly_table")
        )
    )
)