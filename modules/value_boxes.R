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

icon_height <- "1.75rem"

# bslib's default value box padding (1.5rem) makes the boxes tall; tighten it for these boxes only
compact_css <- "
.value-box-compact .value-box-area { padding: 0.5rem 1rem; }
.value-box-compact .value-box-showcase { padding: 0.5rem 1rem; }
.value-box-compact .value-box-title,
.value-box-compact .value-box-value { margin-bottom: 0; }
.value-box-compact .value-box-value { font-size: 1.25rem; line-height: 1.3; }
"

#' Pick the showcase icon for a kingdom
#'
#' @param kingdom Kingdom name (e.g. "Animalia", "Plantae"), may be `NA`.
#' @return A fontawesome icon.
kingdom_icon <- function(kingdom) {
    if (is.na(kingdom)) {
        return(fa("circle-question", height = icon_height, title = "Unknown kingdom"))
    }
    switch(
        kingdom,
        Animalia = fa("paw", height = icon_height, title = "Animal"),
        Plantae = fa("seedling", height = icon_height, title = "Plant"),
        fa("circle-question", height = icon_height, title = kingdom)
    )
}

#' @export
value_boxes_ui <- function(id) {
    ns <- NS(id)

    tagList(
        tags$style(compact_css),
        layout_columns(
            col_widths = c(6, 6),
            fill = FALSE,
            value_box(
                title = NULL,
                value = uiOutput(ns("names")),
                showcase = uiOutput(ns("kingdom_icon")),
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
                showcase = fa("binoculars", height = icon_height, title = "Observations"),
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
        output$kingdom_icon <- renderUI({
            kingdom <- data()$kingdom
            req(length(kingdom) == 1)

            kingdom_icon(kingdom)
        })

        output$names <- renderUI({
            df <- data()
            req(nrow(df) == 1)

            # similar sizes for both names (fs-5 vs fs-6) instead of the large default value font
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
