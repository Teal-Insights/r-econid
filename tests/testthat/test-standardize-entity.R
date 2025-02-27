test_that("basic country standardization works", {
  test_df <- tibble::tribble(
    ~entity,         ~code,
    "United States",  "USA",
    "united.states",  NA,
    "us",             "US",
    "EU",             NA,
    "NotACountry",    NA
  )

  result <- standardize_entity(test_df, entity, code)

  expect_equal(
    result$entity_name,
    c("United States", "United States", "United States", "EU", "NotACountry")
  )
  expect_equal(
    result$entity_id,
    c("USA", "USA", "USA", NA_character_, NA_character_)
  )
})

test_that("column order prioritizes matches from earlier columns", {
  test_df <- tibble::tribble(
    ~name,    ~code,
    "USA",    "FRA",
    "France", NA
  )

  # Should prefer first column match but raise a warning for ambiguous match
  expect_warning(
    result <- standardize_entity(test_df, name, code),
    "Ambiguous match"
  )
  expect_equal(result$entity_id, c("USA", "FRA"))

  # Reversing column order should change the results
  expect_warning(
    result2 <- standardize_entity(test_df, code, name),
    "Ambiguous match"
  )
  expect_equal(result2$entity_id, c("FRA", "FRA"))
})

test_that("standardization works with a single target column", {
  test_df <- tibble::tribble(
    ~country,
    "United States",
    "France",
    "NotACountry"
  )

  result <- standardize_entity(test_df, country)

  expect_equal(result$entity_name, c("United States", "France", "NotACountry"))
  expect_equal(result$entity_id, c("USA", "FRA", NA_character_))
})

test_that("standardization fails with invalid output columns", {
  test_df <- tibble::tribble(
    ~country,
    "United States"
  )

  # Test single invalid column
  expect_error(
    standardize_entity(
      test_df,
      country,
      output_cols = "invalid_col"
    ),
    "Output columns"
  )

  # Test mix of valid and invalid columns
  expect_error(
    standardize_entity(
      test_df,
      country,
      output_cols = c("entity_name", "bad_col", "worse_col")
    ),
    "Output columns"
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

test_that("match_entity_ids handles basic name matching", {
  names <- c("United States", "France", "NotACountry")
  result <- match_entity_ids(names)

  expect_equal(result, c("USA", "FRA", NA_character_))
})

test_that("match_entity_ids prioritizes code matches over name matches", {
  names <- c("United States", "France")
  codes <- c("FRA", "USA")
  expect_warning(
    expect_warning(
      result <- match_entity_ids(names, codes),
      "Ambiguous match"
    ),
    "Ambiguous match"
  )

  # Should match the codes rather than the names
  expect_equal(result, c("FRA", "USA"))
})

test_that("match_entity_ids_multi handles multiple target columns", {
  test_df <- tibble::tribble(
    ~name,           ~code,    ~abbr,
    "United States", NA,       "US",
    NA,              "FRA",    NA,
    "Unknown",       "Unknown", "UNK"
  )

  # Should try each column in sequence
  result <- match_entity_ids_multi(
    test_df,
    "name",
    "code",
    "abbr",
    warn_ambiguous = TRUE
  )

  expect_equal(result, c("USA", "FRA", NA_character_))

  # Changing column order should affect results for the first row
  result2 <- match_entity_ids_multi(
    test_df,
    "abbr",
    "name",
    "code",
    warn_ambiguous = TRUE
  )

  expect_equal(result2, c("USA", "FRA", NA_character_))
})

test_that("match_entity_ids warns on ambiguous matches", {
  # Mock try_regex_match to return multiple matches for a specific input
  local_mocked_bindings(
    try_regex_match = function(name) {
      if (name == "Ambiguous Country") {
        return(c("CTY1", "CTY2"))
      }
      "UNIQUE"
    }
  )

  # Should warn and return first match for ambiguous case
  expect_warning(
    result <- match_entity_ids("Ambiguous Country", warn_ambiguous = TRUE),
    "Ambiguous match"
  )
  expect_equal(result, "CTY1")

  # Should return single match without warning
  expect_no_warning(
    result <- match_entity_ids("Unique Country", warn_ambiguous = TRUE)
  )
  expect_equal(result, "UNIQUE")
})

test_that("match_entity_ids handles multiple inputs with ambiguity", {
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
      result <- match_entity_ids(names, warn_ambiguous = TRUE),
      "Ambiguous match for \"Another Ambiguous\""
    ),
    "Ambiguous match for \"Ambiguous Country\""
  )
  expect_equal(result, c("CTY1", "UNIQUE", "CTY3"))
})

test_that("match_entity_ids handles NULL codes gracefully", {
  names <- c("United States", "France")
  result <- match_entity_ids(names, codes = NULL)

  expect_equal(result, c("USA", "FRA"))
})

test_that("match_entity_ids is case insensitive", {
  names <- c("FRANCE", "united states", "UnItEd KiNgDoM")
  result <- match_entity_ids(names)

  expect_equal(result, c("FRA", "USA", "GBR"))
})

test_that("output_cols argument correctly filters columns", {
  valid_cols <- c(
    "entity_name", "entity_type", "entity_id", "iso3c", "iso2c"
  )
  test_df <- tibble::tribble(
    ~entity,         ~code,
    "United States",  "USA",
    "France",         "FRA"
  )

  # Test subset of valid columns
  result <- standardize_entity(
    test_df,
    entity,
    code,
    output_cols = c("entity_id", "iso3c")
  )

  # Verify included columns
  expect_true(
    all(c("entity", "code", "entity_id", "iso3c") %in% names(result))
  )
  # Verify excluded valid columns and regex column
  expect_false(
    any(c(
      "entity_name", "entity_type", "iso2c", "entity_regex"
    ) %in% names(result))
  )

  # Test all valid columns
  result_all <- standardize_entity(
    test_df,
    entity,
    code,
    output_cols = valid_cols
  )

  # Verify all valid columns present with original columns
  expect_true(all(c("entity", "code", valid_cols) %in% names(result_all)))
  # Ensure regex column still excluded
  expect_false("entity_regex" %in% names(result_all))
})

test_that("output columns are added in correct order", {
  test_df <- tibble::tribble(
    ~country,
    "United States",
    "France"
  )

  # Test with specific output columns
  result <- standardize_entity(
    test_df,
    country,
    output_cols = c("entity_id", "entity_name", "entity_type")
  )

  # Verify new columns are added to the left of target column in specified order
  expect_equal(
    names(result),
    c("entity_id", "entity_name", "entity_type", "country")
  )

  # Test with different order
  result_reversed <- standardize_entity(
    test_df,
    country,
    output_cols = c("entity_type", "entity_name", "entity_id")
  )

  # Verify new columns are added to the left in specified order
  expect_equal(
    names(result_reversed),
    c("entity_type", "entity_name", "entity_id", "country")
  )

  # Test with single output column
  result_single <- standardize_entity(
    test_df,
    country,
    output_cols = "entity_id"
  )

  # Verify single column is added to the left
  expect_equal(
    names(result_single),
    c("entity_id", "country")
  )
})

test_that("handles existing entity columns correctly", {
  # Create test data with existing entity columns
  df <- data.frame(
    country = c("USA", "China"),
    entity_id = c("old_id1", "old_id2"),
    entity_name = c("Old Name 1", "Old Name 2")
  )

  # Should warn when warn_overwrite = TRUE
  expect_warning(
    standardize_entity(
      df,
      country,
      warn_overwrite = TRUE
    ),
    "Overwriting existing entity columns"
  )

  # Should not warn when warn_overwrite = FALSE
  expect_no_warning(
    standardize_entity(
      df,
      target_cols = country,
      warn_overwrite = FALSE
    )
  )

  # Should actually overwrite the columns
  expect_warning(
    result <- standardize_entity(df, target_cols = country),
    "Overwriting existing entity columns"
  )
  expect_false(identical(df$entity_id, result$entity_id))
  expect_false(identical(df$entity_name, result$entity_name))
})

test_that("prefix parameter works correctly", {
  test_df <- tibble::tribble(
    ~country_name, ~counterpart_name,
    "USA",         "France",
    "Germany",     "Italy"
  )

  # Test with prefix
  result <- test_df |>
    standardize_entity(
      country_name,
      prefix = "country"
    ) |>
    standardize_entity(
      counterpart_name,
      prefix = "counterpart"
    )

  # Check that prefixed columns exist
  expect_true(all(c(
    "country_entity_id", "country_entity_name", "country_entity_type",
    "counterpart_entity_id", "counterpart_entity_name",
    "counterpart_entity_type"
  ) %in% names(result)))

  # Check that values are correct
  expect_equal(result$country_entity_id, c("USA", "DEU"))
  expect_equal(result$counterpart_entity_id, c("FRA", "ITA"))
})

test_that("default_entity_type parameter works correctly", {
  test_df <- tibble::tribble(
    ~entity,
    "United States",
    "NotACountry"
  )

  # Test with default_entity_type
  result <- standardize_entity(
    test_df,
    entity,
    default_entity_type = "other"
  )

  # Check that entity_type is set correctly
  expect_equal(result$entity_type, c("economy", "other"))

  # Test with different default_entity_type
  result2 <- standardize_entity(
    test_df,
    entity,
    default_entity_type = "organization"
  )

  # Check that entity_type is set correctly
  expect_equal(result2$entity_type, c("economy", "organization"))
})

test_that("column placement works with multiple target columns", {
  # Create a test dataframe with columns in a specific order
  test_df <- tibble::tibble(
    id = 1:2,
    extra1 = c("a", "b"),
    name = c("United States", "France"),
    code = c("USA", "FRA"),
    extra2 = c("x", "y")
  )

  # Standardize with multiple target columns
  result <- standardize_entity(
    test_df,
    name,
    code
  )

  # Check that output columns are placed directly to the left of the first
  # target column
  expected_order <- c(
    "id", "extra1", "entity_id", "entity_name",
    "entity_type", "name", "code", "extra2"
  )
  expect_equal(names(result), expected_order)
})
