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


source("lib/get_species_names.R")
source("modules/select_species.R")
source("ui.R")
source("server.R")

shinyApp(ui, server)