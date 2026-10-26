box::use(
    bslib[
        card,
        card_header
    ],
    dplyr[
        coalesce
    ],
    htmltools[
        doRenderTags,
        tagList,
        tags
    ],
    leaflet[
        addCircleMarkers,
        addControl,
        addLegend,
        addProviderTiles,
        colorFactor,
        fitBounds,
        leaflet,
        leafletOptions,
        leafletOutput,
        providers,
        renderLeaflet
    ],
    purrr[
        pmap_chr
    ],
    shiny[
        NS,
        moduleServer,
        req
    ],
    tools[
        toTitleCase
    ]
)

box::use(
    modules/theme[
        SEASON_COLORS
    ]
)
# Poland's bounding box (south-west and north-east corners), used as the fixed map view
POLAND_BOUNDS <- list(lng1 = 14.1, lat1 = 49.0, lng2 = 24.2, lat2 = 54.9)

SEASON_PALETTE <- colorFactor(
    palette = unname(SEASON_COLORS),
    levels = names(SEASON_COLORS),
    na.color = "#BDBDBD"
)

#' @export
plot_leaflet_map_ui <- function(id) {
    ns <- NS(id)

    card(
        card_header("Observation locations in Poland"),
        leafletOutput(ns("map"))
    )
}

#' Render occurrence locations on an interactive map
#'
#' Markers are coloured by season and sized by the number of individuals;
#' clicking a marker shows its details.
#'
#' @param id Shiny module ID.
#' @param data Reactive expression returning a data frame with `longitude`, `latitude`,
#'   `eventDate`, `individualCount`, `season` and `locality` columns.
#' @param species Reactive expression returning the selected species name.
#'
#' @return Registers the module server logic.
#' @export
plot_leaflet_map_server <- function(id, data, species) {
    moduleServer(id, function(input, output, session) {
        output$map <- renderLeaflet({
            df <- data()
            req(nrow(df) > 0)

            individuals <- ifelse(is.na(df$individualCount), 1, df$individualCount)
            popups <- pmap_chr(
                list(
                    date = format(df$eventDate),
                    season = coalesce(df$season, "unknown"),
                    count = individuals,
                    locality = coalesce(df$locality, "unknown")
                ),
                function(date, season, count, locality) {
                    as.character(doRenderTags(tagList(
                        tags$b(species()),
                        tags$br(),
                        "Date: ",
                        date,
                        tags$br(),
                        "Season: ",
                        season,
                        tags$br(),
                        "Individuals: ",
                        count,
                        tags$br(),
                        "Locality: ",
                        locality
                    )))
                }
            )

            leaflet(df, options = leafletOptions(zoomSnap = 0.25)) |>
                # Using light grey basemap because it needs no API key)
                addProviderTiles(providers$Esri.WorldGrayCanvas) |>
                addCircleMarkers(
                    lng = ~ as.numeric(longitude),
                    lat = ~ as.numeric(latitude),
                    radius = 4 + 2 * sqrt(individuals),
                    fillColor = ~ SEASON_PALETTE(season),
                    fillOpacity = 0.85,
                    color = "#4D4D4D",
                    weight = 1,
                    opacity = 0.9,
                    popup = popups
                ) |>
                addLegend(
                    position = "bottomright",
                    colors = unname(SEASON_COLORS),
                    labels = toTitleCase(names(SEASON_COLORS)),
                    title = "Season",
                    opacity = 0.85
                ) |>
                addControl(
                    html = paste(
                        sum(!is.na(as.numeric(df$longitude)) & !is.na(as.numeric(df$latitude))),
                        "records shown"
                    ),
                    position = "topright"
                ) |>
                fitBounds(
                    lng1 = POLAND_BOUNDS$lng1,
                    lat1 = POLAND_BOUNDS$lat1,
                    lng2 = POLAND_BOUNDS$lng2,
                    lat2 = POLAND_BOUNDS$lat2
                )
        })
    })
}
