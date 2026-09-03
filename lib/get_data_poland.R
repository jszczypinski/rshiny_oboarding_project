library(duckdb)
library(DBI)
library(here)

con <- dbConnect(
  duckdb(),
  dbdir = here("data", "occurence.duckdb"),
  read_only = FALSE
)

# Filter data from Poland only with observed eventDate, scientificName and geo data
# Will add vocabularName in the future 
DBI::dbExecute(
    con, 
    "CREATE OR REPLACE TABLE occurence_poland_base  AS
    SELECT *
    FROM read_csv('data/biodiversity-data/occurence.csv')
    WHERE (
    LOWER(country) IN ('poland') 
    OR countryCode = 'PL'
    )
    AND eventDate IS NOT NULL   
    AND latitudeDecimal IS NOT NULL 
    AND longitudeDecimal IS NOT NULL
    AND scientificName IS NOT NULL"
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