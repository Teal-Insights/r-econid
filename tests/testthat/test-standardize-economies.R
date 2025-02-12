test_that("basic country standardization works", {
  test_df <- tibble::tribble(
    ~economy,         ~code,
    "United States",  "USA",
    "united.states",  NA,
    "us",             "US",
    "EU",             NA,
    "NotACountry",    NA
  )

  result <- standardize_economies(test_df, name_col = economy, code_col = code)

  expect_equal(
    result$economy_name,
    c("United States", "United States", "United States", "EU", "NotACountry")
  )
  expect_equal(
    result$economy_id,
    c("USA", "USA", "USA", NA_character_, NA_character_)
  )
})

test_that("ISO code matching takes precedence", {
  test_df <- tibble::tribble(
    ~name,    ~code,
    "USA",    "FRA",
    "France", NA
  )

  # Should prefer ISO code match but raise a warning
  expect_warning(
    result <- standardize_economies(test_df, name_col = name, code_col = code),
    "Ambiguous match"
  )
  expect_equal(result$economy_id, c("FRA", "FRA"))
})

test_that("standardization works without code column", {
  test_df <- tibble::tribble(
    ~country,
    "United States",
    "France",
    "NotACountry"
  )

  result <- standardize_economies(test_df, name_col = country)

  expect_equal(result$economy_name, c("United States", "France", "NotACountry"))
  expect_equal(result$economy_id, c("USA", "FRA", NA_character_))
})

test_that("standardization fails with invalid output columns", {
  test_df <- tibble::tribble(
    ~country,
    "United States"
  )

  # Test single invalid column
  expect_error(
    standardize_economies(
      test_df,
      name_col = country,
      output_cols = "invalid_col"
    ),
    "Invalid output columns: \"invalid_col\""
  )

  # Test mix of valid and invalid columns
  expect_error(
    standardize_economies(
      test_df,
      name_col = country,
      output_cols = c("economy_name", "bad_col", "worse_col")
    ),
    "Invalid output columns: \"bad_col\" and \"worse_col\""
  )
})

test_that("try_regex_match performs case-insensitive matching", {
  # Test various case combinations for a country name
  expect_equal(try_regex_match("FRANCE"), "FRA")
  expect_equal(try_regex_match("france"), "FRA")
  expect_equal(try_regex_match("FrAnCe"), "FRA")

  # Test with ISO codes in different cases
  expect_equal(try_regex_match("fra"), "FRA")
  expect_equal(try_regex_match("FRA"), "FRA")
})

test_that("match_economy_ids handles basic name matching", {
  names <- c("United States", "France", "NotACountry")
  result <- match_economy_ids(names)

  expect_equal(result, c("USA", "FRA", NA_character_))
})

test_that("match_economy_ids prioritizes code matches over name matches", {
  names <- c("United States", "France")
  codes <- c("FRA", "USA")
  expect_warning(
    expect_warning(
      result <- match_economy_ids(names, codes),
      "Ambiguous match"
    ),
    "Ambiguous match"
  )

  # Should match the codes rather than the names
  expect_equal(result, c("FRA", "USA"))
})

test_that("match_economy_ids warns on ambiguous matches", {
  # Mock try_regex_match to return multiple matches for a specific input
  local_mocked_bindings(
    try_regex_match = function(name) {
      if (name == "Ambiguous Country") {
        return(c("CTY1", "CTY2"))
      }
      return("UNIQUE")
    }
  )

  # Should warn and return first match for ambiguous case
  expect_warning(
    result <- match_economy_ids("Ambiguous Country", warn_ambiguous = TRUE),
    "Ambiguous match"
  )
  expect_equal(result, "CTY1")

  # Should return single match without warning
  expect_no_warning(
    result <- match_economy_ids("Unique Country", warn_ambiguous = TRUE)
  )
  expect_equal(result, "UNIQUE")
})

test_that("match_economy_ids handles multiple inputs with ambiguity", {
  local_mocked_bindings(
    try_regex_match = function(name) {
      switch(name,
        "Ambiguous Country" = c("CTY1", "CTY2"),
        "Another Ambiguous" = c("CTY3", "CTY4"),
        "Unique Country" = "UNIQUE"
      )
    }
  )

  # Expect warnings for both ambiguous matches
  names <- c("Ambiguous Country", "Unique Country", "Another Ambiguous")
  expect_warning(
    expect_warning(
      result <- match_economy_ids(names, warn_ambiguous = TRUE),
      "Ambiguous match for \"Another Ambiguous\""
    ),
    "Ambiguous match for \"Ambiguous Country\""
  )
  expect_equal(result, c("CTY1", "UNIQUE", "CTY3"))
})

test_that("match_economy_ids handles NULL codes gracefully", {
  names <- c("United States", "France")
  result <- match_economy_ids(names, codes = NULL)

  expect_equal(result, c("USA", "FRA"))
})

test_that("match_economy_ids is case insensitive", {
  names <- c("FRANCE", "united states", "UnItEd KiNgDoM")
  result <- match_economy_ids(names)

  expect_equal(result, c("FRA", "USA", "GBR"))
})

test_that("output_cols argument correctly filters columns", {
  valid_cols <- c(
    "economy_name", "economy_type", "economy_id", "iso3c", "iso2c"
  )
  test_df <- tibble::tribble(
    ~economy,         ~code,
    "United States",  "USA",
    "France",         "FRA"
  )

  # Test subset of valid columns
  result <- standardize_economies(
    test_df,
    name_col = economy,
    code_col = code,
    output_cols = c("economy_id", "iso3c")
  )

  # Verify included columns
  expect_true(
    all(c("economy", "code", "economy_id", "iso3c") %in% names(result))
  )
  # Verify excluded valid columns and regex column
  expect_false(
    any(c(
      "economy_name", "economy_type", "iso2c", "economy_regex"
    ) %in% names(result))
  )

  # Test all valid columns
  result_all <- standardize_economies(
    test_df,
    name_col = economy,
    code_col = code,
    output_cols = valid_cols
  )

  # Verify all valid columns present with original columns
  expect_true(all(c("economy", "code", valid_cols) %in% names(result_all)))
  # Ensure regex column still excluded
  expect_false("economy_regex" %in% names(result_all))
})
