library(shiny)
library(bslib)
library(DBI)
library(duckdb)
library(here)

# Connect to database at startup
con <- dbConnect(
    duckdb(),
    dbdir = here("data", "occurence.duckdb"),
    read_only = TRUE
)


# source all in modules dir
module_files <- list.files(
    path = "modules",
    pattern = "\\.R$",
    full.names = TRUE,
    ignore.case = TRUE
)

invisible(lapply(module_files, source))
source("lib/get_species_names.R")
source("ui.R")
source("server.R")

shinyApp(ui, server)