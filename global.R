# Connect to database at startup
con <- dbConnect(
    duckdb(),
    dbdir = here("data", "occurence.duckdb"),
    read_only = TRUE
)


# list all files to source from modules
module_files <- list.files(
    path = "modules",
    pattern = "\\.R$",
    full.names = TRUE,
    ignore.case = TRUE
)