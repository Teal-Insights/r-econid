test_that("reset_custom_entity_patterns clears custom patterns", {
  # Save original options to restore later
  original_options <- getOption("econid.custom_entity_patterns")

  # Set up a custom pattern
  custom_pattern <- tibble::tibble(
    entity_id = "TEST",
    entity_name = "Test Entity",
    iso3c = "TST",
    iso2c = "TS",
    entity_type = "test",
    entity_regex = "test pattern"
  )
  options(econid.custom_entity_patterns = custom_pattern)

  # Run the reset function
  result <- reset_custom_entity_patterns()

  # Check that the option was reset to empty tibble
  new_custom <- getOption("econid.custom_entity_patterns")
  expect_true(is.data.frame(new_custom))
  expect_equal(nrow(new_custom), 0)
  expect_equal(names(new_custom), c(
    "entity_id", "entity_name", "iso3c", "iso2c", "entity_type", "entity_regex"
  ))

  # Check that function returns NULL invisibly
  expect_invisible(reset_custom_entity_patterns())
  expect_null(result)

  # Restore original options
  options(econid.custom_entity_patterns = original_options)
})
