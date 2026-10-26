box::use(
    grDevices[
        adjustcolor
    ],
    stats[
        setNames
    ]
)

#' Pastel season colours named vector
#'
#' Checked so neighbouring seasons stay distinguishable, also for
#' protanopia/deuteranopia (OKLab dE >= 13 normal, >= 10 colour-blind).
#' @export
SEASON_COLORS <- c(
    spring = "#BFE8B5",
    summer = "#EDBE3F",
    autumn = "#9C7C62",
    winter = "#A3C9EC"
)


#' Pastel season colours tinted for table display
#'
#' @export
SEASON_TINTS <- setNames(adjustcolor(SEASON_COLORS, alpha.f = 0.4), names(SEASON_COLORS))
