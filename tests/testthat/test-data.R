test_that(
  "entity_patterns regex matches historical country names (all cases)", {
    # Join test_cases with additional fields from entity_patterns
    test_cases <- dplyr::left_join(
      test_cases,
      entity_patterns,
      by = c(entity_id = "entity_id", entity_name = "entity_name")
    ) |>
      dplyr::select(
        entity_id, entity_name, entity_regex, iso3c, iso2c, variant_names
      )

    # Iterate over each row in test_cases
    purrr::pwalk(
      test_cases[1:100, ],
      function(
        entity_id, entity_name, entity_regex, iso3c, iso2c, variant_names
      ) {
        # Error if any required field is NA or NULL
        if (any(is.na(c(
          entity_id, entity_name, entity_regex, iso3c, iso2c, variant_names
        ))) || any(is.null(variant_names))) {
          cli::cli_abort("Missing required fields in test_cases")
        }

        # Get the variants and ISO codes for the current entity
        variants <- c(
          unlist(variant_names),
          entity_name,
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
            stringr::regex(entity_regex, ignore_case = TRUE)
          )),
          info = paste(
            "Failed to match one or more variants for", entity_name,
            "(in various cases):",
            paste(
              cased_variants[
                !stringr::str_detect(
                  cased_variants,
                  stringr::regex(entity_regex, ignore_case = TRUE)
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
