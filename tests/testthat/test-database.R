options(box.path = here::here())

box::use(
    DBI[
        dbDisconnect,
        dbExecute,
        dbExistsTable,
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
        local_envvar,
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

stopifnot(build_status == 0)
con <- create_db_con(test_db_path)
occurenc_poland_test_df <- dbReadTable(con, "occurence_poland")

test_that("Creating duckdb connection works", {
    expect_s4_class(con, "duckdb_connection")
})

test_that("create_db_con opens the database read-only by default", {
    expect_error(dbExecute(con, "DELETE FROM occurence_poland"))
})

test_that("create_db_con reads the path from the OCCURENCE_DB environment variable", {
    # the default argument is evaluated lazily, so the variable must be set before the call
    local_envvar(OCCURENCE_DB = test_db_path)
    env_con <- create_db_con()
    defer(dbDisconnect(env_con, shutdown = TRUE))

    expect_true(dbExistsTable(env_con, "occurence_poland"))
})

test_that("db_get_species_matched correctly assigns species `No common name provided`", {
    sci_species_no_vern <- occurenc_poland_test_df |>
        filter(is.na(vernacularName)) |>
        pull(scientificName)

    processed_species <- db_get_species_matched(con)

    no_common_name_species <- processed_species |>
        filter(startsWith(pull(processed_species, vernacularName), "No common"))

    expect_true(sum(is.na(pull(processed_species, vernacularName))) == 0)

    expect_equal(
        pull(no_common_name_species, scientificName),
        sort(unique(sci_species_no_vern))
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

test_that("db_get_species_matched is sorted by scientific name", {
    species_matched <- db_get_species_matched(con)
    expect_equal(species_matched$scientificName, sort(species_matched$scientificName, method = "radix"))
})

test_that("db_get_species_matched returns every species present in the table", {
    species_matched <- db_get_species_matched(con)
    expect_setequal(species_matched$scientificName, unique(occurenc_poland_test_df$scientificName))
})

test_that("db_get_timeline_data returns a non-empty data.frame with correct n of columns", {
    timeline_test_df <- db_get_timeline_data(con, "Saxicola rubetra")
    expect_s3_class(timeline_test_df, "data.frame")

    expect_true(nrow(timeline_test_df) > 0)

    expect_named(timeline_test_df, c("eventDate", "season", "individualCount"), ignore.order = TRUE)
})

test_that("db_get_timeline_data sorts data correctly", {
    timeline_test_df <- db_get_timeline_data(con, "Saxicola rubetra")
    expect_false(is.unsorted(rev(timeline_test_df$eventDate)))
})

test_that("db_get_timeline_data aggregates records into one row per date and season", {
    timeline_df <- db_get_timeline_data(con, "Testus alpha")

    expect_equal(nrow(timeline_df), 2)
    expect_equal(sum(timeline_df$individualCount), 6)
    expect_false(anyDuplicated(timeline_df[c("eventDate", "season")]) > 0)
})

test_that("db_get_timeline_data returns eventDate as a Date", {
    expect_s3_class(db_get_timeline_data(con, "Saxicola rubetra")$eventDate, "Date")
})

test_that("db_get_timeline_data does not work for a species not present in the database", {
    timeline_wrong_test_df <- db_get_timeline_data(con, "Abstractus polacus")
    expect_true(nrow(timeline_wrong_test_df) == 0)
})

test_that("db_get_season_data returns a non-empty data.frame with correct n of columns", {
    season_test_df <- db_get_season_data(con, "Saxicola rubetra")
    expect_s3_class(season_test_df, "data.frame")

    expect_true(nrow(season_test_df) > 0)

    expect_named(season_test_df, c("season", "individualCount"), ignore.order = TRUE)
})

test_that("db_get_season_data does not work for a species not present in the database", {
    season_wrong_test_df <- db_get_season_data(con, "Abstractus polacus")
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

    expect_true(nrow(season_species_sum_df) == 1)

    expect_named(season_species_sum_df, c("kingdom", "vernacularName", "records", "individuals"), ignore.order = TRUE)
})

test_that("db_get_species_summary returns kingdom with correct values", {
    animal_summary_df <- db_get_species_summary(con, "Saxicola rubetra")
    expect_equal(animal_summary_df[["kingdom"]], "Animalia")

    # the fixture row has no kingdom, which the build script backfills for this moss
    plant_summary_df <- db_get_species_summary(con, "Hylocomium splendens")
    expect_equal(plant_summary_df[["kingdom"]], "Plantae")
})

test_that("db_get_species_summary returns 0 records for a species not present in the database", {
    season_species_sum_wrong_df <- db_get_species_summary(con, "Abstractus polacus")
    expect_true(season_species_sum_wrong_df[["records"]] == 0)
})

test_that("db_get_species_summary returns correct totals for a species", {
    summary_df <- db_get_species_summary(con, "Testus alpha")

    expect_equal(summary_df$kingdom, "Animalia")
    expect_equal(summary_df$vernacularName, "Test Shared Name")
    expect_equal(summary_df$records, 2)
    expect_equal(summary_df$individuals, 6)
})

test_that("db_get_species_summary falls back to a placeholder when there is no common name", {
    summary_df <- db_get_species_summary(con, "Rutpela maculata")

    expect_equal(summary_df$vernacularName, "No common name provided")
})

test_that("db_get_observation_data returns a data.frame with correct n of columns", {
    season_species_sum_df <- db_get_observation_data(con, "Saxicola rubetra")
    expect_s3_class(season_species_sum_df, "data.frame")
    expect_named(
        season_species_sum_df,
        c("latitude", "longitude", "scientificName", "eventDate", "individualCount", "season", "locality"),
        ignore.order = TRUE
    )
    expect_true(nrow(season_species_sum_df) > 0)
})

test_that("db_get_observation_data returns one row per record, newest first", {
    season_species_sum_df <- db_get_observation_data(con, "Saxicola rubetra")

    expect_equal(nrow(season_species_sum_df), sum(occurenc_poland_test_df$scientificName == "Saxicola rubetra"))
    expect_false(is.unsorted(rev(season_species_sum_df$eventDate)))
})

test_that("db_get_observation_data returns lat and long vectors of correct type and bounds", {
    season_species_sum_df <- db_get_observation_data(con, "Saxicola rubetra")

    expect_vector(season_species_sum_df[["latitude"]], ptype = double())
    expect_vector(season_species_sum_df[["longitude"]], ptype = double())
    # bounds of lat and long for Poland were used
    expect_all_true(season_species_sum_df[["latitude"]] >= 49.0 & season_species_sum_df[["latitude"]] <= 54.9)
    expect_all_true(season_species_sum_df[["longitude"]] >= 14.1 & season_species_sum_df[["longitude"]] <= 24.2)
})

defer(unlink(test_db_path), envir = teardown_env())
dbDisconnect(con)
