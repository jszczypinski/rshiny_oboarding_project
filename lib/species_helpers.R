box::use(
    stats[setNames]
)

#' Compute default scientific and vernacular names
#'
#' @param scientific_names Character vector of scientific names.
#' @param vernacular_names Character vector of vernacular names.
#' @param preferred_sci Optional preferred scientific name (e.g. "Haliaeetus albicilla").
#' @return A list with elements `sci` and `vern`, or `NULL` if no valid pair.
#' @export
compute_default_species <- function(
    scientific_names,
    vernacular_names,
    preferred_sci = "Haliaeetus albicilla"
) {
    # Default scientific name
    default_sci <-
        if (preferred_sci %in% scientific_names) {
            preferred_sci
        } else if (length(scientific_names) > 0) {
            scientific_names[1]
        } else {
            NULL
        }

    if (is.null(default_sci)) {
        # Fallback if no scientific names at all
        default_vern <-
            if (length(vernacular_names) > 0) {
                vernacular_names[1]
            } else {
                NULL
            }
        return(list(sci = NULL, vern = default_vern))
    }

    # Build lookup
    sci_to_vern <- setNames(vernacular_names, scientific_names)

    default_vern <-
        if (default_sci %in% names(sci_to_vern)) {
            sci_to_vern[[default_sci]]
        } else if (length(vernacular_names) > 0) {
            vernacular_names[1]
        } else {
            NULL
        }

    list(sci = default_sci, vern = default_vern)
}
