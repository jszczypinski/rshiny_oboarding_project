box::use(
    bslib[
        card,
        card_header
    ],
    htmltools[
        htmlEscape
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
    shiny[
        NS,
        moduleServer,
        req
    ]
)
box::use(
    lib/seasons[
        season_colors,
        seasons
    ]
)

# Same colours as the season plot; records without a season are grey
season_palette <- colorFactor(
    palette = unname(season_colors),
    levels = seasons,
    na.color = "#BDBDBD"
)

# Poland's bounding box (south-west and north-east corners), used as the fixed map view
poland_bounds <- list(lng1 = 14.1, lat1 = 49.0, lng2 = 24.2, lat2 = 54.9)

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
            popups <- paste0(
                "<b>",
                htmlEscape(species()),
                "</b><br>",
                "Date: ",
                htmlEscape(format(df$eventDate)),
                "<br>",
                "Season: ",
                htmlEscape(ifelse(is.na(df$season), "unknown", df$season)),
                "<br>",
                "Individuals: ",
                individuals,
                "<br>",
                "Locality: ",
                htmlEscape(ifelse(is.na(df$locality), "unknown", df$locality))
            )

            # zoomSnap 0.25 allows in-between zoom levels, so Poland fills the card snugly
            leaflet(df, options = leafletOptions(zoomSnap = 0.25)) |>
                # Light grey basemap that needs no API key (CartoDB now watermarks tiles without one)
                addProviderTiles(providers$Esri.WorldGrayCanvas) |>
                addCircleMarkers(
                    lng = ~longitude,
                    lat = ~latitude,
                    # sqrt keeps a flock of 76 visible without hiding single observations
                    radius = 4 + 2 * sqrt(individuals),
                    fillColor = ~ season_palette(season),
                    fillOpacity = 0.85,
                    # dark outline keeps the pastel fills visible on the light tiles
                    color = "#4D4D4D",
                    weight = 1,
                    opacity = 0.9,
                    popup = popups
                ) |>
                addLegend(
                    position = "bottomright",
                    colors = unname(season_colors),
                    labels = names(season_colors),
                    title = "Season",
                    opacity = 0.85
                ) |>
                addControl(
                    html = paste(nrow(df), "records shown"),
                    position = "topright"
                ) |>
                # Always show the whole of Poland (its bounding box), whatever the card size
                fitBounds(
                    lng1 = poland_bounds$lng1,
                    lat1 = poland_bounds$lat1,
                    lng2 = poland_bounds$lng2,
                    lat2 = poland_bounds$lat2
                )
        })
    })
}
