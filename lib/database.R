# database.R

box::use(
    DBI[dbConnect, dbGetQuery, dbQuoteIdentifier],
    duckdb[duckdb],
    here[here]
)

#' Create DuckDB connection
#'
#' @param db_path Path to the DuckDB file.
#' @param read_only Logical; open read-only?
#'
#' @return DBI connection.
#' @export
create_db_con <- function(
    db_path = here("data", "occurence.duckdb"),
    read_only = TRUE
) {
    dbConnect(
        duckdb(),
        dbdir = db_path,
        read_only = read_only
    )
}

#' Get distinct species names
#'
#' @param con DBI connection.
#' @param name_col Column name.
#'
#' @return Character vector of names.
#' @export
db_get_species_names <- function(
    con,
    name_col = c("scientificName", "vernacularName")
) {
    name_col <- match.arg(name_col)

    query <- sprintf(
        "
        SELECT DISTINCT %s
        FROM occurence_poland
        WHERE %s IS NOT NULL
        ORDER BY %s
        ",
        DBI::dbQuoteIdentifier(con, name_col),
        DBI::dbQuoteIdentifier(con, name_col),
        DBI::dbQuoteIdentifier(con, name_col)
    )

    dbGetQuery(con, query)[[name_col]]
}

#' Get timeline data for a species
#'
#' @param con DBI connection.
#' @param species Species name.
#'
#' @return Data frame with eventDate and individualCount.
#' @export
db_get_timeline_data <- function(con, species) {
    dbGetQuery(
        con,
        "
        SELECT
            CAST(eventDate AS DATE) AS eventDate,
            SUM(individualCount) AS individualCount
        FROM occurence_poland
        WHERE scientificName = ?
          AND eventDate IS NOT NULL
        GROUP BY CAST(eventDate AS DATE)
        ORDER BY eventDate DESC
        ",
        params = list(species)
    )
}

#' Get observation data for a species
#'
#' @param con DBI connection.
#' @param species Species name.
#'
#' @return Data frame with lat/lon and other fields.
#' @export
db_get_observation_data <- function(con, species) {
    dbGetQuery(
        con,
        "
        SELECT
            TRY_CAST(latitudeDecimal AS DOUBLE) AS latitude,
            TRY_CAST(longitudeDecimal AS DOUBLE) AS longitude,
            scientificName,
            eventDate,
            individualCount
        FROM occurence_poland
        WHERE scientificName = ?
        ORDER BY eventDate DESC
        LIMIT 5000
        ",
        params = list(species)
    )
}