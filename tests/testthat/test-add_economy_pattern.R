library(testthat)
library(dplyr)
library(tibble)

test_that("adds default alias when no aliases are provided", {
  # Ensure a clean internal environment for the test.
  if (exists(".econid_env", envir = .GlobalEnv)) {
    rm(list = ".econid_env", envir = .GlobalEnv)
  }
  withr::defer(rm(list = ".econid_env", envir = .GlobalEnv))

  expected_regex <- "default_regex"

  local_mocked_bindings(
    create_economy_regex = function(aliases) {
      # When no aliases are provided, the function should receive the economy
      # name.
      return(expected_regex)
    },
    .env = environment(add_economy_pattern)
  )

  # Call without aliases and without a custom regex, so the function uses
  # default behavior.
  add_economy_pattern(
    1, "Testland", "TTT", "TT", "developed",
    aliases = NULL, economy_regex = NULL
  )

  # Check that .econid_env was created and a row was appended.
  econ_env <- get(".econid_env", envir = .GlobalEnv)
  cp <- econ_env$custom_economy_patterns
  expect_equal(nrow(cp), 1)
  expect_equal(cp$economy_id[1], "1")
  expect_equal(cp$economy_name[1], "Testland")
  expect_equal(cp$iso3c[1], "TTT")
  expect_equal(cp$iso2c[1], "TT")
  expect_equal(cp$economy_type[1], "developed")
  expect_equal(cp$economy_regex[1], expected_regex)
})

test_that("custom economy_regex overrides generated value", {
  # Clear any existing internal environment.
  if (exists(".econid_env", envir = .GlobalEnv)) {
    rm(list = ".econid_env", envir = .GlobalEnv)
  }
  withr::defer(rm(list = ".econid_env", envir = .GlobalEnv))

  custom_regex <- "custom_pattern"
  called <- FALSE

  # Create a mock for create_economy_regex that tracks if it gets called.
  local_mocked_bindings(
    create_economy_regex = function(aliases) {
      called <<- TRUE
      "should_not_be_used"
    },
    .env = environment(add_economy_pattern)
  )

  # Here we explicitly supply a custom regex; the helper should not be used.
  add_economy_pattern(2, "Testonia", "TSN", "TN", "emerging",
                      aliases = c("alias1", "alias2"),
                      economy_regex = custom_regex)

  econ_env <- get(".econid_env", envir = .GlobalEnv)
  cp <- econ_env$custom_economy_patterns
  expect_equal(nrow(cp), 1)
  expect_equal(cp$economy_regex[1], custom_regex)

  # Assert that our mocked create_economy_regex was not called.
  expect_false(called)
})

test_that("uses provided aliases to create regex", {
  if (exists(".econid_env", envir = .GlobalEnv)) {
    rm(list = ".econid_env", envir = .GlobalEnv)
  }
  withr::defer(rm(list = ".econid_env", envir = .GlobalEnv))

  expected_regex <- "alias_regex"

  local_mocked_bindings(
    create_economy_regex = function(aliases) {
      # Check that the provided aliases are forwarded correctly.
      expect_equal(aliases, c("alias1", "alias2"))
      return(expected_regex)
    },
    .env = environment(add_economy_pattern)
  )

  add_economy_pattern(3, "Econia", "ECN", "EC", "developing",
                      aliases = c("alias1", "alias2"),
                      economy_regex = NULL)

  econ_env <- get(".econid_env", envir = .GlobalEnv)
  cp <- econ_env$custom_economy_patterns
  expect_equal(nrow(cp), 1)
  expect_equal(cp$economy_regex[1], expected_regex)
})

test_that("multiple invocations are cumulative and in order", {
  if (exists(".econid_env", envir = .GlobalEnv)) {
    rm(list = ".econid_env", envir = .GlobalEnv)
  }
  withr::defer(rm(list = ".econid_env", envir = .GlobalEnv))

  # In the first call, we use the default regex via our mock.
  expected_regex <- "regex1"
  local_mocked_bindings(
    create_economy_regex = function(aliases) expected_regex,
    .env = environment(add_economy_pattern)
  )

  add_economy_pattern(1, "Country1", "C1", "C1", "Type1",
                      aliases = NULL,
                      economy_regex = NULL)

  # Second call supplies a custom regex.
  custom_regex <- "custom_regex"
  add_economy_pattern(2, "Country2", "C2", "C2", "Type2",
                      aliases = c("x", "y"),
                      economy_regex = custom_regex)

  econ_env <- get(".econid_env", envir = .GlobalEnv)
  cp <- econ_env$custom_economy_patterns
  expect_equal(nrow(cp), 2)
  expect_equal(cp$economy_id, c("1", "2"))
  expect_equal(cp$economy_name, c("Country1", "Country2"))
  expect_equal(cp$economy_regex, c(expected_regex, custom_regex))
})

test_that("internal environment and table are created if missing", {
  if (exists(".econid_env", envir = .GlobalEnv)) {
    rm(list = ".econid_env", envir = .GlobalEnv)
  }
  withr::defer(rm(list = ".econid_env", envir = .GlobalEnv))

  economy_id   <- 4
  economy_name <- "Newland"
  iso3c        <- "NWL"
  iso2c        <- "NW"
  economy_type <- "developing"

  # In this test, we simply use a mock that returns the economy name.
  local_mocked_bindings(
    create_economy_regex = function(aliases) economy_name,
    .env = environment(add_economy_pattern)
  )

  add_economy_pattern(economy_id, economy_name, iso3c, iso2c, economy_type,
                      aliases = NULL, economy_regex = NULL)

  # Check that the internal environment was created.
  econ_env <- get(".econid_env", envir = .GlobalEnv)
  expect_true(exists("custom_economy_patterns", envir = econ_env))

  cp <- econ_env$custom_economy_patterns
  expected_cols <- c(
    "economy_id", "economy_name", "iso3c",
    "iso2c", "economy_type", "economy_regex"
  )
  expect_equal(names(cp), expected_cols)
})

test_that("returns invisible NULL", {
  if (exists(".econid_env", envir = .GlobalEnv)) {
    rm(list = ".econid_env", envir = .GlobalEnv)
  }
  withr::defer(rm(list = ".econid_env", envir = .GlobalEnv))

  local_mocked_bindings(
    create_economy_regex = function(aliases) "regex",
    .env = environment(add_economy_pattern)
  )

  # Capture the output and visibility of the result.
  vis <- withVisible(
    add_economy_pattern(
      5, "InvisibleLand", "INV", "IV", "TypeX",
      aliases = NULL, economy_regex = NULL
    )
  )
  expect_null(vis$value)
  expect_false(vis$visible)
})
