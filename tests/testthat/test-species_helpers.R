options(box.path = here::here())
box::use(
    testthat[
        describe,
        it
    ]
)


box::use(
    lib/species_helpers[
        compute_default_species
    ]
)

sci_names <- c("Corvus corax", "Haliaeetus albicilla", "Parus major")
vern_names <- c("Common Raven", "White-tailed Eagle", "Great Tit")

describe("compute_default_species", {
    species_test <- compute_default_species(sci_names, vern_names)

    it("returns a list with `sci` and `vern` elements", {
        expect_type(species_test, "list")
        expect_named(species_test, c("sci", "vern"))
    })

    it("chooses the preferred species when it is present", {
        expect_equal(species_test$sci, "Haliaeetus albicilla")
        expect_equal(species_test$vern, "White-tailed Eagle")
    })

    it("falls back to the first species when the preferred one is missing", {
        fallback_test <- compute_default_species(sci_names, vern_names, preferred_sci = "Abstractus polacus")

        expect_equal(fallback_test$sci, "Corvus corax")
        expect_equal(fallback_test$vern, "Common Raven")
    })

    it("returns the first vernacular name when there are no scientific names", {
        no_sci_test <- compute_default_species(character(0), vern_names)

        expect_null(no_sci_test$sci)
        expect_equal(no_sci_test$vern, "Common Raven")
    })

    it("keeps both elements as NULL when there are no names at all", {
        empty_test <- compute_default_species(character(0), character(0))
        # returns NULL so an empty database shows the placeholder instead of crashing the app at startup
        expect_null(empty_test$sci)
        expect_null(empty_test$vern)
    })
})
