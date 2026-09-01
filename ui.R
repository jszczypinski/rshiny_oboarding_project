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
        card(
            card_header("Observation locations in Poland"),
            plotOutput("poland_map", height = "550px")
        )
    ),

    # 2nd row - plot and a table
    # I am not sure if I usethis kind of plot and table, but the layout should be as it is now
    div(
        # had to fixed the height for the entire second row cause the map was shrinking
        style = "height: 460px;", 
        layout_columns(
            col_widths = c(7, 5),

            # Timeline card
            card(
                card_header("Timeline"),
                div(
                    style = "height: 420px; overflow: hidden;",
                    plotOutput("timeline", height = "400px")
                )
            ),

            # Table card
            card(
                card_header("Observations per Year"),
                div(
                    style = "height: 420px; overflow-y: auto;",
                    tableOutput("yearly_table")
                )
            )
        )
    )
)