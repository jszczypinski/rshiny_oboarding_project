get_species_names <- function(
    con,
    name_col = c("scientificName", "vernacularName")
) {
    DBI::dbGetQuery(
        con,
        paste(
            "SELECT DISTINCT", name_col,
            "FROM occurence_poland",
            "WHERE", name_col, 
            "IS NOT NULL",
            "ORDER BY", name_col)
    )[[name_col]]
}