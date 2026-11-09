box::use(
    DBI[
        dbReadTable
    ],
    dplyr[
        filter,
        pull,
        select
    ],
    here[
        here
    ],
    testthat[
        test_that,
        teardown_env
    ],
    withr[
        defer,
        with_dir
    ]
)

box::use(
    lib/database[
        create_db_con,
        db_get_species_matched,
        db_get_timeline_data,
        db_get_season_data,
        db_get_species_summary,
        db_get_observation_data
    ]
)

test_db_path <- tempfile("occurence_test_", fileext = ".duckdb")

build_status <- with_dir(
    here(),
    system2(
        "Rscript",
        c(
            shQuote(here("scripts", "get_data_poland.R")),
            "--input",
            # this .csv is used to provide all needed edge-cases for testing
            shQuote(here("tests", "testthat", "fixtures", "occurence_poland_edge_cases.csv")),
            "--output",
            shQuote(test_db_path)
        ),
        stdout = FALSE,
        stderr = FALSE
    )
)
con <- create_db_con(test_db_path)
temp_df <- dbReadTable(con, "occurence_poland")
# con <- create_db_con(here("data", "sample", "occurence_poland_1000"))
# sample_data_path <- "data/sample/occurence_poland_1000.csv"

# sample_duckdb_data <- duckdb_read_csv(con, "occurence_poland_1000", sample_data_path)
# dbReadTable(con, "occurence_poland_1000")

test_that("Creating duckdb connection works", {
    expect_s4_class(con, "duckdb_connection")
})

test_that("db_get_species_matched correctly assignes `No common name provided`", {
    sci_species_no_vern <- temp_df |>
        filter(is.na(vernacularName)) |>
        pull(scientificName)

    processed_species <- as_tibble(db_get_species_matched(con))

    no_common_name_species <- processed_species |>
        filter(startsWith(pull(processed_species, vernacularName), "No common"))

    expect_true(sum(is.na(pull(processed_species, vernacularName))) == 0)

    expect_all_true(
        pull(no_common_name_species, scientificName) == sort(unique(sci_species_no_vern))
    )
})

test_that("db_get_species_matched adds the scientific name when a common name is shared", {
    species_matched <- db_get_species_matched(con)
    shared <- species_matched[species_matched$scientificName %in% c("Testus alpha", "Testus beta"), ]

    expect_equal(
        shared$vernacularName,
        c("Test Shared Name (Testus alpha)", "Test Shared Name (Testus beta)")
    )
})

test_that("db_get_species_matched keeps a common name plain when no other species shares it", {
    species_matched <- db_get_species_matched(con)
    unique_name <- species_matched$vernacularName[species_matched$scientificName == "Testus gamma"]

    expect_equal(unique_name, "Test Unique Name")
})

test_that("db_get_species_matched returns each scientific name once", {
    species_matched <- db_get_species_matched(con)

    expect_equal(sum(species_matched$scientificName == "Testus alpha"), 1)
    expect_false(anyDuplicated(species_matched$scientificName) > 0)
})

test_that("db_get_timeline_data returns a non-empty data.frame with correct n of columns", {
    timeline_test_df <- db_get_timeline_data(con, "Saxicola rubetra")
    expect_s3_class(timeline_test_df, "data.frame")

    expect_equal(ncol(timeline_test_df), 3)

    expect_true(nrow(timeline_test_df) > 0)

    expect_all_true(names(timeline_test_df) %in% c("eventDate", "season", "individualCount"))
})

test_that("db_get_timeline_data sorts data correctly", {
    timeline_test_df <- db_get_timeline_data(con, "Saxicola rubetra")
    expect_all_true(diff(as.numeric(timeline_test_df$eventDate)) <= 0)
})

test_that("db_get_timeline_data does not work for a specimen not present in the database", {
    timeline_wrong_test_df <- db_get_timeline_data(con, "Abstractus polacus")
    expect_true(nrow(timeline_wrong_test_df) == 0)
})

test_that("db_get_season_data returns a non-empty data.frame with correct n of columns", {
    season_test_df <- db_get_season_data(con, "Saxicola rubetra")
    expect_s3_class(season_test_df, "data.frame")

    expect_equal(ncol(season_test_df), 2)

    expect_true(nrow(season_test_df) > 0)

    expect_all_true(names(season_test_df) %in% c("season", "individualCount"))
})

test_that("db_get_season_data does not work for a specimen not present in the database", {
    season_wrong_test_df <- db_get_timeline_data(con, "Abstractus polacus")
    expect_true(nrow(season_wrong_test_df) == 0)
})

test_that("db_get_timeline_data and db_get_season_data return the same number individualCount", {
    season_test_df <- db_get_season_data(con, "Saxicola rubetra")
    timeline_test_df <- db_get_timeline_data(con, "Saxicola rubetra")
    expect_equal(sum(season_test_df$individualCount), sum(timeline_test_df$individualCount))
})

test_that("db_get_species_summary returns one-row data.frame with correct n of columns", {
    season_species_sum_df <- db_get_species_summary(con, "Saxicola rubetra")
    expect_s3_class(season_species_sum_df, "data.frame")

    expect_equal(ncol(season_species_sum_df), 4)

    expect_true(nrow(season_species_sum_df) == 1)

    expect_all_true(names(season_species_sum_df) %in% c("kingdom", "vernacularName", "records", "individuals"))
})

test_that("db_get_species_summary returns kingdom with correct values", {
    expect_true(season_species_sum_df[["kingdom"]] %in% c("Animalia", "Plantae"))
})

test_that("db_get_species_summary does not work for a specimen not present in the database", {
    season_species_sum_wrong_df <- db_get_timeline_data(con, "Abstractus polacus")
    expect_true(nrow(season_species_sum_wrong_df) == 0)
})

test_that("db_get_observation_data returns a data.frame with correct n of columns", {
    season_species_sum_df <- db_get_observation_data(con, "Saxicola rubetra")
    expect_s3_class(season_species_sum_df, "data.frame")
    expect_equal(ncol(season_species_sum_df), 7)
    expect_all_true(
        names(season_species_sum_df) %in%
            c("latitude", "longitude", "scientificName", "eventDate", "individualCount", "season", "locality")
    )
    expect_true(nrow(season_species_sum_df) > 0)
})

test_that("db_get_observation_data returns lat and long vectors of correct type and bounds", {
    expect_vector(season_species_sum_df[["latitude"]], ptype = double())
    expect_vector(season_species_sum_df[["longitude"]], ptype = double())
    # bounds of lat and long for Poland were used
    expect_all_true(season_species_sum_df[["latitude"]] >= 14.1 & season_species_sum_df[["latitude"]] <= 49.0)
    expect_all_true(season_species_sum_df[["longitude"]] >= 24.2 & season_species_sum_df[["latitude"]] <= 54.9)
})

defer(unlink(test_db_path), envir = teardown_env())
