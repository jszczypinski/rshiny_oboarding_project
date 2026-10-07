#' Astronomical seasons, in calendar order, as stored in the `season` column
#' @export
seasons <- c("spring", "summer", "autumn", "winter")

#' Pastel season colours, named by the display label and in the same order as `seasons`
#'
#' Checked so neighbouring seasons stay distinguishable, also for
#' protanopia/deuteranopia (OKLab dE >= 13 normal, >= 10 colour-blind).
#' @export
season_colors <- c(
    Spring = "#BFE8B5", # green
    Summer = "#EDBE3F", # warm yellow (lighter yellows vanish on white and blend with spring)
    Autumn = "#9C7C62", # brown
    Winter = "#A3C9EC" # blue
)
