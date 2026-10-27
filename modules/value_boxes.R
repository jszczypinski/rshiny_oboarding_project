box::use(
    bslib[
        layout_columns,
        value_box
    ],
    fontawesome[
        fa
    ],
    htmltools[
        tagList,
        tags
    ],
    sass[
        sass
    ],
    shiny[
        NS,
        moduleServer,
        renderText,
        renderUI,
        req,
        textOutput,
        uiOutput
    ]
)

ICON_HEIGHT <- "1.75rem"

# bslib's default value box padding (1.5rem) makes the boxes too tall;
# tighten it for these boxes only
BOX_VARS <- list(
    box_padding = "0.5rem 1rem",
    box_value_size = "1.25rem"
)

BOX_RULE <- "
    .value-box-compact {
        .value-box-area,
        .value-box-showcase {
            padding: $box_padding;
        }
        .value-box-title,
        .value-box-value {
            margin-bottom: 0;
        }
        .value-box-value {
            font-size: $box_value_size;
            line-height: 1.3;
        }
    }
"

COMPACT_CSS <- sass(input = list(BOX_VARS, BOX_RULE))

#' @export
value_boxes_ui <- function(id) {
    ns <- NS(id)

    tagList(
        tags$style(COMPACT_CSS),
        layout_columns(
            col_widths = c(6, 6),
            fill = FALSE,
            value_box(
                title = NULL,
                value = uiOutput(ns("names")),
                showcase = uiOutput(ns(".get_kingdom_icon")),
                class = "value-box-compact"
            ),
            value_box(
                title = "Total observations",
                # count and record total on one line keeps the box short
                value = tags$span(
                    class = "fs-4",
                    textOutput(ns("individuals"), inline = TRUE),
                    tags$span(class = "fs-6 fw-normal", textOutput(ns("records"), inline = TRUE))
                ),
                showcase = fa("binoculars", height = ICON_HEIGHT, title = "Observations"),
                class = "value-box-compact"
            )
        )
    )
}

#' Render the species and total-observations value boxes
#'
#' @param id Shiny module ID.
#' @param data Reactive expression returning a one-row data frame with `kingdom`,
#'   `vernacularName`, `records` and `individuals` columns.
#' @param species Reactive expression returning the selected scientific name.
#'
#' @return Registers the module server logic.
#' @export
value_boxes_server <- function(id, data, species) {
    moduleServer(id, function(input, output, session) {
        output$.get_kingdom_icon <- renderUI({
            kingdom <- data()$kingdom
            req(length(kingdom) == 1)

            .get_kingdom_icon(kingdom)
        })

        output$names <- renderUI({
            df <- data()
            req(nrow(df) == 1)

            tags$div(
                tags$em(class = "fs-5", species()),
                tags$br(),
                tags$span(class = "fs-6", df$vernacularName)
            )
        })

        output$individuals <- renderText({
            df <- data()
            req(nrow(df) == 1)

            individuals <- if (is.na(df$individuals)) 0 else df$individuals
            format(individuals, big.mark = " ")
        })

        output$records <- renderText({
            df <- data()
            req(nrow(df) == 1)

            paste("in", format(df$records, big.mark = " "), if (df$records == 1) "record" else "records")
        })
    })
}


#' A helper function to pick the showcase icon for a kingdom
#'
#' @param kingdom Kingdom name (e.g. "Animalia", "Plantae"), may be `NA`.
#' @return A fontawesome icon.
.get_kingdom_icon <- function(kingdom) {
    if (is.na(kingdom)) {
        return(fa("circle-question", height = ICON_HEIGHT, title = "Unknown kingdom"))
    }
    switch(
        kingdom,
        Animalia = fa("paw", height = ICON_HEIGHT, title = "Animal"),
        Plantae = fa("seedling", height = ICON_HEIGHT, title = "Plant"),
        fa("circle-question", height = ICON_HEIGHT, title = kingdom)
    )
}
