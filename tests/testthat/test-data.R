test_that("country_aggregates dataset has correct columns and no NAs", {
  # Check if the dataset has the required columns
  required_columns <- c("country_name", "country_group", "group_type")
  expect_true(all(required_columns %in% colnames(country_aggregates)))

  # Check if there are no NAs in the dataset
  expect_true(all(complete.cases(country_aggregates)))
})

test_that("country_codes dataset has correct columns and no NAs", {
  # Check if the dataset has the required columns
  required_columns <- c("country", "is_wb_country", "wb_name", "cldr_short_en",
                        "iso2c", "iso3c", "iso3n", "imf", "continent",
                        "country_name_en_regex")
  expect_true(all(required_columns %in% colnames(country_codes)))
})

test_that(
  "economy_patterns regex matches historical country names (all cases)", {
    # Join test_cases and economy_patterns
    test_cases <- dplyr::left_join(
      economy_patterns,
      test_cases,
      by = "economy_name"
    )

    # Iterate over each row in test_cases
    purrr::pwalk(
      test_cases,
      function(economy_name, economy_regex, iso3c, iso2c, variant_names) {
        # Error if any required field is NA or NULL
        if (any(is.na(c(
          economy_name, economy_regex, iso3c, iso2c, variant_names
        ))) || any(is.null(variant_names))) {
          stop("Missing required fields in test_cases")
        }

        # Get the variants and ISO codes for the current economy
        variants <- c(
          unlist(variant_names),
          economy_name,
          iso2c,
          iso3c
        )

        # Get all variants in lowercase, uppercase, and title-cased
        cased_variants <- unique(c(
          variants,
          tolower(variants),
          toupper(variants),
          stringr::str_to_title(variants)
        ))

        # Test that all variants match the regex (case-insensitive)
        expect_true(
          all(stringr::str_detect(
            cased_variants,
            stringr::regex(economy_regex, ignore_case = TRUE)
          )),
          info = paste(
            "Failed to match one or more variants for", economy_name,
            "(in various cases):",
            paste(
              cased_variants[
                !stringr::str_detect(
                  cased_variants,
                  stringr::regex(economy_regex, ignore_case = TRUE)
                )
              ],
              collapse = ", "
            )
          )
        )
      }
    )
  }
)
