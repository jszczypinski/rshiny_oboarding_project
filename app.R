library(shiny)
library(bslib)
library(DBI)
library(duckdb)
library(here)

source("global.R")
invisible(do.call(lapply, list(module_files, source)))
source("lib/get_species_names.R")
source("ui.R")
source("server.R")

shinyApp(ui, server)