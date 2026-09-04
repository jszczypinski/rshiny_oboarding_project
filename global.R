# Connect to database at startup
con <- dbConnect(
    duckdb(),
    dbdir = here("data", "occurence.duckdb"),
    read_only = TRUE
)
