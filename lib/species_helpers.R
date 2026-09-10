# lib/species_helpers.R

box::use(
    shiny[observeEvent, isolate, reactiveVal, req],
    stats[setNames]
)

#' Compute default scientific and vernacular names
#'
#' @param scientific_names Character vector of scientific names.
#' @param vernacular_names Character vector of vernacular names.
#' @param preferred_sci Optional preferred scientific name (e.g. "Haliaeetus albicilla").
#' @return A list with elements `sci` and `vern`, or `NULL` if no valid pair.
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

#' Wire up two species selectors so they stay in sync
#'
#' This function creates the reactive observers that:
#' - Track user interaction with either selector.
#' - Maintain a central `selected_scientific` reactiveVal.
#' - Sync both selectors after the first user interaction.
#'
#' @param sci_selector Result of `select_species_server(...)` for scientific names.
#' @param vern_selector Result of `select_species_server(...)` for vernacular names.
#' @param scientific_names Vector of scientific names.
#' @param vernacular_names Vector of vernacular names.
#' @param selected_scientific A `reactiveVal` to hold the canonical scientific name.
#' @param user_interacted A `reactiveVal` (logical) indicating whether the user has interacted with the app.
#' @return A list with elements `selected_scientific`, `user_interacted`.
setup_species_selector_sync <- function(
    sci_selector,
    vern_selector,
    scientific_names,
    vernacular_names,
    selected_scientific,
    user_interacted
) {
    # Lookups
    sci_to_vern <- setNames(vernacular_names, scientific_names)
    vern_to_sci <- setNames(scientific_names, vernacular_names)

    # When user changes scientific, update central state
    observeEvent(sci_selector$selected(), {
        sci_name <- sci_selector$selected()
        if (is.null(sci_name) || sci_name == "") return()
        if (!sci_name %in% names(sci_to_vern)) return()

        user_interacted(TRUE)
        selected_scientific(sci_name)
    }, ignoreInit = TRUE)

    # When user changes vernacular, translate and update central state
    observeEvent(vern_selector$selected(), {
        vern_name <- vern_selector$selected()
        if (is.null(vern_name) || vern_name == "") return()
        if (!vern_name %in% names(vern_to_sci)) return()

        user_interacted(TRUE)
        selected_scientific(vern_to_sci[[vern_name]])
    }, ignoreInit = TRUE)

    # When central state changes, update BOTH selectors (but only after user interaction)
    observeEvent(selected_scientific(), {
        if (!user_interacted()) return()

        sci_name <- selected_scientific()
        req(sci_name)

        # Update scientific selector only if it differs
        current_sci <- sci_selector$selected()
        if (!identical(current_sci, sci_name)) {
            isolate({
                sci_selector$set_selected(sci_name)
            })
        }

        # Update vernacular selector
        if (sci_name %in% names(sci_to_vern)) {
            vern_name <- sci_to_vern[[sci_name]]
            current_vern <- vern_selector$selected()
            if (!identical(current_vern, vern_name)) {
                isolate({
                    vern_selector$set_selected(vern_name)
                })
            }
        }
    }, ignoreInit = TRUE)

    invisible(list(
        selected_scientific = selected_scientific,
        user_interacted = user_interacted
    ))
}