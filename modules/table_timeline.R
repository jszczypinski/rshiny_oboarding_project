box::use(
    shiny[
        NS,
        moduleServer,
        req
    ],
    bslib[
        card,
        card_header
    ],
    reactable[
        reactable,
        renderReactable,
        reactableOutput,
        colDef
    ],
    grDevices[
        adjustcolor
    ],
    stats[
        setNames
    ]
)
box::use(
    modules/theme[
        SEASON_TINTS
    ]
)
#' @export
table_timeline_ui <- function(id) {
    ns <- NS(id)

    card(
        card_header("Observations per Year"),
        reactableOutput(ns("table"))
    )
}

#' Render a table of observation dates and counts
#'
#' @param id Shiny module ID.
#' @param data Reactive expression returning occurrence data with `eventDate`
#'   and `individualCount` columns.
#'
#' @return Registers the module server logic.
#' @export
table_timeline_server <- function(id, data) {
    moduleServer(id, function(input, output, session) {
        output$table <- renderReactable(
            {
                df <- data()
                req(nrow(df) > 0)

                reactable(
                    data = df,
                    columns = list(
                        eventDate = colDef(name = "Date", filterable = TRUE, sortable = TRUE),
                        # only used for the row colour
                        season = colDef(show = FALSE),
                        individualCount = colDef(
                            name = "Observations",
                            sortable = TRUE
                        )
                    ),
                    # tint each row with its season colour; rows without a season stay white
                    rowStyle = function(index) {
                        season <- df$season[index]
                        if (is.na(season)) {
                            return(NULL)
                        }
                        list(background = SEASON_TINTS[[season]])
                    },
                    pagination = FALSE
                )
            }
        )
    })
}
