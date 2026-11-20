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
        describe,
        it,
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

describe("create_db_con", {
    it("returns a duckdb connection", {
        expect_s4_class(con, "duckdb_connection")
    })

    it("opens the database read-only by default", {
        expect_error(dbExecute(con, "DELETE FROM occurence_poland"))
    })

    it("reads the path from the OCCURENCE_DB environment variable", {
        # the default argument is evaluated lazily, so the variable must be set before the call
        local_envvar(OCCURENCE_DB = test_db_path)
        env_con <- create_db_con()
        defer(dbDisconnect(env_con, shutdown = TRUE))

        expect_true(dbExistsTable(env_con, "occurence_poland"))
    })
})


describe("db_get_species_matched", {
    species_matched <- db_get_species_matched(con)
    it("correctly assigns species `No common name provided`", {
        sci_species_no_vern <- occurenc_poland_test_df |>
            filter(is.na(vernacularName)) |>
            pull(scientificName)

        no_common_name_species <- species_matched |>
            filter(startsWith(pull(species_matched, vernacularName), "No common"))

        expect_true(sum(is.na(pull(species_matched, vernacularName))) == 0)

        expect_equal(
            pull(no_common_name_species, scientificName),
            sort(unique(sci_species_no_vern))
        )
    })

    it("adds the scientific name when a common name is shared", {
        shared <- species_matched[species_matched$scientificName %in% c("Testus alpha", "Testus beta"), ]

        expect_equal(
            shared$vernacularName,
            c("Test Shared Name (Testus alpha)", "Test Shared Name (Testus beta)")
        )
    })

    it("keeps a common name plain when no other species shares it", {
        unique_name <- species_matched$vernacularName[species_matched$scientificName == "Testus gamma"]

        expect_equal(unique_name, "Test Unique Name")
    })

    it("returns each scientific name once", {
        expect_equal(sum(species_matched$scientificName == "Testus alpha"), 1)
        expect_false(anyDuplicated(species_matched$scientificName) > 0)
    })

    it("is sorted by a scientific name", {
        expect_equal(species_matched$scientificName, sort(species_matched$scientificName, method = "radix"))
    })

    it("returns every species present in the table", {
        expect_setequal(species_matched$scientificName, unique(occurenc_poland_test_df$scientificName))
    })
})

describe("db_get_timeline_data", {
    timeline_df <- db_get_timeline_data(con, "Saxicola rubetra")
    timeline_testus_df <- db_get_timeline_data(con, "Testus alpha")
    timeline_wrong_df <- db_get_timeline_data(con, "Abstractus polacus")

    it("returns a non-empty data.frame with correct n of columns", {
        expect_s3_class(timeline_df, "data.frame")

        expect_true(nrow(timeline_df) > 0)

        expect_named(timeline_df, c("eventDate", "season", "individualCount"), ignore.order = TRUE)
    })

    it("sorts data correctly", {
        expect_false(is.unsorted(rev(timeline_df$eventDate)))
    })

    it("aggregates records into one row per date and season", {
        expect_equal(nrow(timeline_testus_df), 2)
        expect_equal(sum(timeline_testus_df$individualCount), 6)
        expect_false(anyDuplicated(timeline_testus_df[c("eventDate", "season")]) > 0)
    })

    it("returns eventDate as a Date", {
        expect_s3_class(timeline_df$eventDate, "Date")
    })

    it("does not work for a species not present in the database", {
        expect_true(nrow(timeline_wrong_df) == 0)
    })
})

describe("db_get_season_data", {
    season_df <- db_get_season_data(con, "Saxicola rubetra")
    season_wrong_df <- db_get_season_data(con, "Abstractus polacus")

    it("returns a non-empty data.frame with correct n of columns", {
        expect_s3_class(season_df, "data.frame")

        expect_true(nrow(season_df) > 0)

        expect_named(season_df, c("season", "individualCount"), ignore.order = TRUE)
    })

    it("does not work for a species not present in the database", {
        expect_true(nrow(season_wrong_df) == 0)
    })
})

describe("db_get_species_summary", {
    summary_df <- db_get_species_summary(con, "Saxicola rubetra")
    summary_testus_df <- db_get_species_summary(con, "Testus alpha")
    summary_wrong_df <- db_get_species_summary(con, "Abstractus polacus")

    it("returns a one-row data.frame with correct n of columns", {
        expect_s3_class(summary_df, "data.frame")

        expect_true(nrow(summary_df) == 1)

        expect_named(summary_df, c("kingdom", "vernacularName", "records", "individuals"), ignore.order = TRUE)
    })

    it("returns kingdom with correct values", {
        expect_equal(summary_df[["kingdom"]], "Animalia")

        # the fixture row has no kingdom, which the build script backfills for this moss
        plant_summary_df <- db_get_species_summary(con, "Hylocomium splendens")
        expect_equal(plant_summary_df[["kingdom"]], "Plantae")
    })

    it("returns 0 records for a species not present in the database", {
        expect_true(summary_wrong_df[["records"]] == 0)
    })

    it("returns correct totals for a species", {
        expect_equal(summary_testus_df$kingdom, "Animalia")
        expect_equal(summary_testus_df$vernacularName, "Test Shared Name")
        expect_equal(summary_testus_df$records, 2)
        expect_equal(summary_testus_df$individuals, 6)
    })

    it("falls back to a placeholder when there is no common name", {
        no_name_summary_df <- db_get_species_summary(con, "Rutpela maculata")

        expect_equal(no_name_summary_df$vernacularName, "No common name provided")
    })
})

describe("db_get_observation_data", {
    observation_df <- db_get_observation_data(con, "Saxicola rubetra")

    it("returns a non-empty data.frame with correct n of columns", {
        expect_s3_class(observation_df, "data.frame")

        expect_true(nrow(observation_df) > 0)

        expect_named(
            observation_df,
            c("latitude", "longitude", "scientificName", "eventDate", "individualCount", "season", "locality"),
            ignore.order = TRUE
        )
    })

    it("returns one row per record, newest first", {
        expect_equal(nrow(observation_df), sum(occurenc_poland_test_df$scientificName == "Saxicola rubetra"))
        expect_false(is.unsorted(rev(observation_df$eventDate)))
    })

    it("returns lat and long vectors of correct type and bounds", {
        expect_vector(observation_df[["latitude"]], ptype = double())
        expect_vector(observation_df[["longitude"]], ptype = double())
        # bounds of lat and long for Poland were used
        expect_all_true(observation_df[["latitude"]] >= 49.0 & observation_df[["latitude"]] <= 54.9)
        expect_all_true(observation_df[["longitude"]] >= 14.1 & observation_df[["longitude"]] <= 24.2)
    })
})

describe("db_get_timeline_data and db_get_season_data", {
    it("return the same total individualCount", {
        season_test_df <- db_get_season_data(con, "Saxicola rubetra")
        timeline_test_df <- db_get_timeline_data(con, "Saxicola rubetra")

        expect_equal(sum(season_test_df$individualCount), sum(timeline_test_df$individualCount))
    })
})

defer(unlink(test_db_path), envir = teardown_env())
dbDisconnect(con)
