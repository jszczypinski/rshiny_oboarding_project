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


# Create species list for the dropdown menu on sidebar
species_names <- DBI::dbGetQuery(
    con,
    "SELECT DISTINCT scientificName
    FROM occurence_poland
    WHERE scientificName IS NOT NULL
    ORDER BY scientificName"
)$scientificName

source("ui.R")
source("server.R")

shinyApp(ui, server)