library(testthat)
library(dplyr)
library(tibble)

test_that("adds default alias when no aliases are provided", {
  local_clean_econid_patterns()
  expected_regex <- "default_regex"

  local_mocked_bindings(
    create_entity_regex = function(aliases) {
      # When no aliases are provided, the function should receive the entity
      # name.
      expected_regex
    }
  )

  # Updated function call with reordered arguments and removed iso2c, iso3c
  add_entity_pattern(
    entity_id = 1,
    entity_name = "Testland",
    entity_type = "economy",
    aliases = NULL,
    entity_regex = NULL
  )

  # Check that .econid_env was created and a row was appended.
  cp <- get("custom_entity_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 1)
  expect_equal(cp$entity_id[1], "1")
  expect_equal(cp$entity_name[1], "Testland")
  expect_equal(cp$entity_type[1], "economy")
  expect_equal(cp$entity_regex[1], expected_regex)
})

test_that("custom entity_regex overrides generated value", {
  local_clean_econid_patterns()
  custom_regex <- "custom_pattern"
  called <- FALSE

  # Create a mock for create_entity_regex that tracks if it gets called.
  local_mocked_bindings(
    create_entity_regex = function(aliases) {
      called <<- TRUE
      "should_not_be_used"
    }
  )

  # Here we explicitly supply a custom regex; the helper should not be used.
  add_entity_pattern(
    entity_id = 2,
    entity_name = "Testonia",
    entity_type = "economy",
    aliases = c("alias1", "alias2"),
    entity_regex = custom_regex
  )

  cp <- get("custom_entity_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 1)
  expect_equal(cp$entity_regex[1], custom_regex)

  # Assert that our mocked create_entity_regex was not called.
  expect_false(called)
})

test_that("uses provided aliases to create regex", {
  local_clean_econid_patterns()
  expected_regex <- "alias_regex"

  local_mocked_bindings(
    create_entity_regex = function(aliases) {
      # Check that the provided aliases are forwarded correctly.
      expect_equal(aliases, c("3", "Econia", "alias1", "alias2"))
      expected_regex
    }
  )

  add_entity_pattern(
    entity_id = 3,
    entity_name = "Econia",
    entity_type = "economy",
    aliases = c("alias1", "alias2"),
    entity_regex = NULL
  )

  cp <- get("custom_entity_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 1)
  expect_equal(cp$entity_regex[1], expected_regex)
})

test_that("multiple invocations are cumulative and in order", {
  local_clean_econid_patterns()

  # In the first call, we use the default regex via our mock.
  expected_regex <- "regex1"
  local_mocked_bindings(
    create_entity_regex = function(aliases) expected_regex
  )

  add_entity_pattern(
    entity_id = 1,
    entity_name = "Country1",
    entity_type = "economy",
    aliases = NULL,
    entity_regex = NULL
  )

  # Second call supplies a custom regex.
  custom_regex <- "custom_regex"
  add_entity_pattern(
    entity_id = 2,
    entity_name = "Country2",
    entity_type = "economy",
    aliases = c("x", "y"),
    entity_regex = custom_regex
  )

  cp <- get("custom_entity_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 2)
  expect_equal(cp$entity_id, c("1", "2"))
  expect_equal(cp$entity_name, c("Country1", "Country2"))
  expect_equal(cp$entity_regex, c(expected_regex, custom_regex))
})

test_that("internal environment and table are created if missing", {
  local_clean_econid_patterns()

  entity_id   <- 4
  entity_name <- "Newland"
  entity_type <- "economy"

  # In this test, we simply use a mock that returns the entity name.
  local_mocked_bindings(
    create_entity_regex = function(aliases) entity_name
  )

  add_entity_pattern(
    entity_id = entity_id,
    entity_name = entity_name,
    entity_type = entity_type,
    aliases = NULL,
    entity_regex = NULL
  )

  # Check that the internal environment was created.
  cp <- get("custom_entity_patterns", envir = .econid_env)
  expected_cols <- c(
    "entity_id", "entity_name", "iso3c",
    "iso2c", "entity_type", "entity_regex"
  )
  expect_equal(names(cp), expected_cols)
})

test_that("returns invisible NULL", {
  local_clean_econid_patterns()

  local_mocked_bindings(
    create_entity_regex = function(aliases) "regex"
  )

  # Capture the output and visibility of the result.
  vis <- withVisible(
    add_entity_pattern(
      entity_id = 5,
      entity_name = "InvisibleLand",
      entity_type = "economy",
      aliases = NULL,
      entity_regex = NULL
    )
  )
  expect_null(vis$value)
  expect_false(vis$visible)
})

test_that("error is thrown when duplicating default pattern entity_id", {
  local_clean_econid_patterns()

  # Mock the default patterns
  local_mocked_bindings(
    list_entity_patterns = function() {
      tibble::tibble(
        entity_id = "duplicate_id1",
        entity_name = "Original Entity",
        iso3c = "ORI",
        iso2c = "OR",
        entity_type = "economy",
        entity_regex = "original_regex"
      )
    }
  )

  # Try to add a duplicate of the default pattern and expect an error
  expect_error(
    add_entity_pattern(
      entity_id = "duplicate_id1",
      entity_name = "Original Entity",
      entity_type = "economy"
    ),
    paste0(
      "The entity_id 'duplicate_id1' already exists in the custom ",
      "patterns. Please use a unique identifier."
    )
  )
})

test_that("error is thrown when duplicating custom pattern entity_id", {
  local_clean_econid_patterns()

  # Add a custom pattern
  add_entity_pattern(
    entity_id = "duplicate_id2",
    entity_name = "Original Entity",
    entity_type = "economy"
  )

  # Try to add another with the same entity_id
  expect_error(
    add_entity_pattern(
      entity_id = "duplicate_id2",
      entity_name = "Different Entity", 
      entity_type = "organization"
    ),
    paste0(
      "The entity_id 'duplicate_id2' already exists in the custom ",
      "patterns. Please use a unique identifier."
    )
  )

  # Verify only one pattern was added
  cp <- get("custom_entity_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 1)
  expect_equal(cp$entity_name[1], "Original Entity")
})
