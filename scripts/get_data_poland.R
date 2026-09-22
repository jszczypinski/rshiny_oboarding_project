#!/usr/bin/env Rscript

library(duckdb)
library(DBI)
library(here)
library(optparse)

# Define optparse command-line options
# For now input and output will suffice
option_list <- list(
    make_option(
        c("-i", "--input"),
        type = "character",
        default = NULL,
        help = "Path to input CSV file with occurrence data",
        metavar = "PATH"
    ),
    make_option(
        c("-o", "--output"),
        type = "character",
        default = here("data", "occurence.duckdb"),
        help = "Path to output DuckDB database file [default: data/occurence.duckdb]",
        metavar = "PATH"
    )
)

# Create parser and parse arguments

opt_parser <- OptionParser(
    option_list = option_list,
    description = "Prepare occurence data for Poland and create filtered DuckDB database"
)

opt <- parse_args(opt_parser)

# Validate arguments

if(is.null(opt$input)) {
    print_help(opt_parser)
    stop("You must provide --input <path-to-csv>", call = .FALSE)
}

input_csv  <- opt$input
output_db  <- opt$output

# Connect to DuckDB
con <- dbConnect(
  duckdb(),
  dbdir = output_db,
  read_only = FALSE
)

# Filter data from Poland only with observed eventDate, scientificName and geo data
# Will add vernacularName in the future 
DBI::dbExecute(
    con,
    sprintf(
        "
        CREATE OR REPLACE TABLE occurence_poland_base AS
        SELECT *
        FROM read_csv('%s')
        WHERE (
            LOWER(country) IN ('poland')
            OR countryCode = 'PL'
        )
        AND eventDate IS NOT NULL
        AND latitudeDecimal IS NOT NULL
        AND longitudeDecimal IS NOT NULL
        AND scientificName IS NOT NULL
        ",
        input_csv
    )
)

# Select from observations in Poland only those species for which there is a total of >5 observations
# Just to make it run faster for now.
# Keep only those species in occurence_poland 
DBI::dbExecute(
    con,
    "CREATE OR REPLACE TABLE occurence_poland AS
    SELECT base.*
    FROM occurence_poland_base AS base
    JOIN (
        SELECT scientificName
        FROM occurence_poland_base
        GROUP BY scientificName
        HAVING SUM(individualCount) > 5
    ) AS good_species
    ON base.scientificName = good_species.scientificName"
)

dbDisconnect(con)