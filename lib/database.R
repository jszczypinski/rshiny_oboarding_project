box::use(
    DBI[dbConnect, dbGetQuery, dbQuoteIdentifier],
    duckdb[duckdb],
    here[here]
)

#' Create DuckDB connection
#'
#' @param db_path Path to the DuckDB file. Defaults to the `OCCURENCE_DB` environment
#'   variable, or `data/occurence.duckdb` when it is unset or empty.
#' @param read_only Logical; open read-only?
#'
#' @return DBI connection.
#' @export
create_db_con <- function(
    db_path = Sys.getenv("OCCURENCE_DB", here("data", "occurence.duckdb")),
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
db_get_species_matched <- function(con) {
    dbGetQuery(
        con,
        "
        WITH species AS (
            SELECT
                scientificName,
                -- Some scientific names in the database do not have a common name provided
                COALESCE(MIN(vernacularName), 'No common name provided') AS vernacularName
            FROM occurence_poland
            WHERE scientificName IS NOT NULL
            GROUP BY scientificName
        )
        SELECT
            scientificName,
            -- Some common names in the database are shared by several scientific names 
            CASE
                WHEN COUNT(*) OVER (PARTITION BY vernacularName) > 1
                    THEN vernacularName || ' (' || scientificName || ')'
                ELSE vernacularName
            END AS vernacularName
        FROM species
        ORDER BY scientificName
        "
    )
}

#' Get timeline data for a species
#'
#' @param con DBI connection.
#' @param species Species name.
#'
#' @return Data frame with eventDate, season and individualCount.
#' @export
db_get_timeline_data <- function(con, species) {
    dbGetQuery(
        con,
        "
        SELECT
            CAST(eventDate AS DATE) AS eventDate,
            season,
            SUM(individualCount) AS individualCount
        FROM occurence_poland
        WHERE scientificName = ?
          AND eventDate IS NOT NULL
        GROUP BY CAST(eventDate AS DATE), season
        ORDER BY eventDate DESC
        ",
        params = list(species)
    )
}

#' Get seasonal data for a species
#'
#' @param con DBI connection.
#' @param species Species name.
#'
#' @return Data frame with season and individualCount.
#' @export
db_get_season_data <- function(con, species) {
    dbGetQuery(
        con,
        "
        SELECT
            season,
            SUM(individualCount) AS individualCount
        FROM occurence_poland
        WHERE scientificName = ?
          AND season IS NOT NULL
        GROUP BY season
        ",
        params = list(species)
    )
}

#' Get a one-row summary of a species for the value boxes
#'
#' @param con DBI connection.
#' @param species Species name.
#'
#' @return Data frame with kingdom, vernacularName, records and individuals.
#' @export
db_get_species_summary <- function(con, species) {
    summary <- dbGetQuery(
        con,
        "
        SELECT
            MIN(kingdom) AS kingdom,
            COALESCE(MIN(vernacularName), 'No common name provided') AS vernacularName,
            COUNT(*) AS records,
            SUM(individualCount) AS individuals
        FROM occurence_poland
        WHERE scientificName = ?
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
            latitudeDecimal AS latitude,
            longitudeDecimal AS longitude,
            scientificName,
            eventDate,
            individualCount,
            season,
            locality
        FROM occurence_poland
        WHERE scientificName = ?
        ORDER BY eventDate DESC
        LIMIT 5000
        ",
        params = list(species)
    )
}
