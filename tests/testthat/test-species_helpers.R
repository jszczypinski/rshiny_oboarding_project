options(box.path = here::here())
box::use(
    testthat[
        test_that
    ]
)


box::use(
    lib/species_helpers[
        compute_default_species
    ]
)

sci_names <- c("Corvus corax", "Haliaeetus albicilla", "Parus major")
vern_names <- c("Common Raven", "White-tailed Eagle", "Great Tit")

test_that("compute_default_species returns a list with `sci` and `vern` elements", {
    species_test <- compute_default_species(sci_names, vern_names)

    expect_type(species_test, "list")
    expect_named(species_test, c("sci", "vern"))
})

test_that("compute_default_species choose the preferred specimen when it is present", {
    species_test <- compute_default_species(sci_names, vern_names)

    expect_equal(species_test$sci, "Haliaeetus albicilla")
    expect_equal(species_test$vern, "White-tailed Eagle")
})

test_that("compute_default_species falls back to the first species when the preferred one is missing", {
    species_test <- compute_default_species(sci_names, vern_names, preferred_sci = "Abstractus polacus")

    expect_equal(species_test$sci, "Corvus corax")
    expect_equal(species_test$vern, "Common Raven")
})

test_that("compute_default_species returns the first vernacular name when there are no scientific names", {
    species_test <- compute_default_species(character(0), vern_names)

    expect_null(species_test$sci)
    expect_equal(species_test$vern, "Common Raven")
})

test_that("compute_default_species keeps both elements as NULL when there are no names at all", {
    species_test <- compute_default_species(character(0), character(0))
    # returns NULL so an empty database shows the placeholder instead of crashing the app at startup".
    expect_null(species_test$sci)
    expect_null(species_test$vern)
})
