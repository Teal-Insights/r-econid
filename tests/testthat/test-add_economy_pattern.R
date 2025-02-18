library(testthat)
library(dplyr)
library(tibble)

test_that("adds default alias when no aliases are provided", {
  local_clean_econid_patterns()
  expected_regex <- "default_regex"

  local_mocked_bindings(
    create_economy_regex = function(aliases) {
      # When no aliases are provided, the function should receive the economy
      # name.
      return(expected_regex)
    }
  )

  # Updated function call with reordered arguments and removed iso2c, iso3c
  add_economy_pattern(
    economy_id = 1,
    economy_name = "Testland",
    economy_type = "developed",
    aliases = NULL,
    economy_regex = NULL
  )

  # Check that .econid_env was created and a row was appended.
  cp <- get("custom_economy_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 1)
  expect_equal(cp$economy_id[1], "1")
  expect_equal(cp$economy_name[1], "Testland")
  expect_equal(cp$economy_type[1], "developed")
  expect_equal(cp$economy_regex[1], expected_regex)
})

test_that("custom economy_regex overrides generated value", {
  local_clean_econid_patterns()
  custom_regex <- "custom_pattern"
  called <- FALSE

  # Create a mock for create_economy_regex that tracks if it gets called.
  local_mocked_bindings(
    create_economy_regex = function(aliases) {
      called <<- TRUE
      "should_not_be_used"
    }
  )

  # Here we explicitly supply a custom regex; the helper should not be used.
  add_economy_pattern(
    economy_id = 2,
    economy_name = "Testonia",
    economy_type = "emerging",
    aliases = c("alias1", "alias2"),
    economy_regex = custom_regex
  )

  cp <- get("custom_economy_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 1)
  expect_equal(cp$economy_regex[1], custom_regex)

  # Assert that our mocked create_economy_regex was not called.
  expect_false(called)
})

test_that("uses provided aliases to create regex", {
  local_clean_econid_patterns()
  expected_regex <- "alias_regex"

  local_mocked_bindings(
    create_economy_regex = function(aliases) {
      # Check that the provided aliases are forwarded correctly.
      expect_equal(aliases, c("3", "Econia", "alias1", "alias2"))
      return(expected_regex)
    }
  )

  add_economy_pattern(
    economy_id = 3,
    economy_name = "Econia",
    economy_type = "developing",
    aliases = c("alias1", "alias2"),
    economy_regex = NULL
  )

  cp <- get("custom_economy_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 1)
  expect_equal(cp$economy_regex[1], expected_regex)
})

test_that("multiple invocations are cumulative and in order", {
  local_clean_econid_patterns()

  # In the first call, we use the default regex via our mock.
  expected_regex <- "regex1"
  local_mocked_bindings(
    create_economy_regex = function(aliases) expected_regex
  )

  add_economy_pattern(
    economy_id = 1,
    economy_name = "Country1",
    economy_type = "Type1",
    aliases = NULL,
    economy_regex = NULL
  )

  # Second call supplies a custom regex.
  custom_regex <- "custom_regex"
  add_economy_pattern(
    economy_id = 2,
    economy_name = "Country2",
    economy_type = "Type2",
    aliases = c("x", "y"),
    economy_regex = custom_regex
  )

  cp <- get("custom_economy_patterns", envir = .econid_env)
  expect_equal(nrow(cp), 2)
  expect_equal(cp$economy_id, c("1", "2"))
  expect_equal(cp$economy_name, c("Country1", "Country2"))
  expect_equal(cp$economy_regex, c(expected_regex, custom_regex))
})

test_that("internal environment and table are created if missing", {
  local_clean_econid_patterns()

  economy_id   <- 4
  economy_name <- "Newland"
  economy_type <- "developing"

  # In this test, we simply use a mock that returns the economy name.
  local_mocked_bindings(
    create_economy_regex = function(aliases) economy_name
  )

  add_economy_pattern(
    economy_id = economy_id,
    economy_name = economy_name,
    economy_type = economy_type,
    aliases = NULL,
    economy_regex = NULL
  )

  # Check that the internal environment was created.
  cp <- get("custom_economy_patterns", envir = .econid_env)
  expected_cols <- c(
    "economy_id", "economy_name", "iso3c",
    "iso2c", "economy_type", "economy_regex"
  )
  expect_equal(names(cp), expected_cols)
})

test_that("returns invisible NULL", {
  local_clean_econid_patterns()

  local_mocked_bindings(
    create_economy_regex = function(aliases) "regex"
  )

  # Capture the output and visibility of the result.
  vis <- withVisible(
    add_economy_pattern(
      economy_id = 5,
      economy_name = "InvisibleLand",
      economy_type = "TypeX",
      aliases = NULL,
      economy_regex = NULL
    )
  )
  expect_null(vis$value)
  expect_false(vis$visible)
})
