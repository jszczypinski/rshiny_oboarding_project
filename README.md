# Biodiversity Dashboard (Poland)

Shiny dashboard visualizing biodiversity occurrence records from Poland (GBIF-derived data).

## Quick start

Install packages using `renv`

```r
renv::restore()
```

## Getting a workable dataset

The app expects a DuckDB database with a table `occurence_poland`.

### Use the sample CSV

To get data for development work use a .csv provided in `data/sample/`

```r
source("R/get_data_poland.R")

get_data_poland(
    input_csv = "data/sample/occurence_poland_1000.csv",
    output_db = "data/occurence_poland.duckdb"
)
```

Alternatively you can run `get_data_poland.R` from terminal as it is configured with `optparse`

```bash
Rscript scripts/create_poland_sample.R --input PATH --output PATH
```

### Use full GBIF data

1. Download occurrence data for Poland from [https://www.gbif.org/](https://www.gbif.org/) as a CSV.
2. Save it, e.g., as `data/raw/occurence.csv`.
3. Run:

   ```r
   source("R/get_data_poland.R")

   get_data_poland(
       input_csv = "data/raw/occurence.csv",
       output_db = "data/occurence.duckdb"
   )
   ```

## Configuration

The app uses the environment variable `OCCURENCE_DB` to locate the DuckDB database.  
If not set, it defaults to `data/occurence.duckdb`.