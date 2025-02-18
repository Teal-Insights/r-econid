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
    entity_type = "developed",
    aliases = NULL,
    entity_regex = NULL
  )

  # Check that .econid_env was created and a row was appended.
  cp <- get("custom_entity_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 1)
  expect_equal(cp$entity_id[1], "1")
  expect_equal(cp$entity_name[1], "Testland")
  expect_equal(cp$entity_type[1], "developed")
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
    entity_type = "emerging",
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
    entity_type = "developing",
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
    entity_type = "Type1",
    aliases = NULL,
    entity_regex = NULL
  )

  # Second call supplies a custom regex.
  custom_regex <- "custom_regex"
  add_entity_pattern(
    entity_id = 2,
    entity_name = "Country2",
    entity_type = "Type2",
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
  entity_type <- "developing"

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
      entity_type = "TypeX",
      aliases = NULL,
      entity_regex = NULL
    )
  )
  expect_null(vis$value)
  expect_false(vis$visible)
})
