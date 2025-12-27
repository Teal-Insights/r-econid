test_that("list_entity_patterns combines built-in and custom patterns", {
  # Save original options to restore later
  original_options <- getOption("econid.custom_entity_patterns")

  # Test 1: With custom patterns
  custom_pattern <- tibble::tibble(
    entity_id = "TEST",
    entity_name = "Test Entity",
    iso3c = "TST",
    iso2c = "TS",
    entity_type = "test",
    entity_regex = "test pattern"
  )
  options(econid.custom_entity_patterns = custom_pattern)

  result <- list_entity_patterns()

  # Check that result includes both built-in and custom patterns
  expect_true(all(custom_pattern$entity_id %in% result$entity_id))
  expect_true(nrow(result) == nrow(entity_patterns) + nrow(custom_pattern))

  # Test 2: With NULL custom patterns
  options(econid.custom_entity_patterns = NULL)

  result_null <- list_entity_patterns()

  # Check that result equals built-in patterns when custom is NULL
  expect_equal(nrow(result_null), nrow(entity_patterns))
  expect_equal(result_null, entity_patterns)

  # Check that option was set with empty tibble
  new_custom <- getOption("econid.custom_entity_patterns")
  expect_true(is.data.frame(new_custom))
  expect_equal(nrow(new_custom), 0)
  expect_equal(
    names(new_custom),
    c(
      "entity_id",
      "entity_name",
      "iso3c",
      "iso2c",
      "entity_type",
      "entity_regex"
    )
  )

  # Restore original options
  options(econid.custom_entity_patterns = original_options)
})
