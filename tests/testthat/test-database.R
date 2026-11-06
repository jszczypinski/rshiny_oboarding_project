box::use(
    testthat[
        test_that,
        expec
    ],
    here[here]
)

box::use(
    lib/database[create_db_con]
)

# con <- create_db_con(here("data", "sample", "occurence_poland_1000"))
# sample_data_path <- "data/sample/occurence_poland_1000.csv"

# sample_duckdb_data <- duckdb_read_csv(con, "occurence_poland_1000", sample_data_path)
# dbReadTable(con, "occurence_poland_1000")

test_that("Creating duckdb connection works", {
    con <- create_db_con(here("data", "sample", "occurence_poland_1000"))
    expect_s4_class(con, "duckdb_connection")
})
