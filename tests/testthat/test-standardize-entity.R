test_that("basic country standardization works", {
  test_df <- tibble::tribble(
    ~entity,         ~code,
    NA,               "USA",
    "united.states",  NA,
    "us",             "US"
  )

  result <- standardize_entity(test_df, entity, code)

  expect_equal(
    result$entity_name,
    c(
      "United States", "United States", "United States"
    )
  )
  expect_equal(
    result$entity_id,
    c("USA", "USA", "USA")
  )
})

test_that("unmatched entities are not filled from existing cols by default", {
  test_df <- tibble::tribble(
    ~entity,         ~code,
    "EU",             NA,
    "NotACountry",    NA
  )

  result <- standardize_entity(test_df, entity, code)

  expect_equal(
    result$entity_name,
    c(
      NA_character_, NA_character_
    )
  )
  expect_equal(
    result$entity_id,
    c(NA_character_, NA_character_)
  )
})

# TODO: Test that unmatched entities are filled from existing cols when fill
# mapping is provided

test_that("column order prioritizes matches from earlier columns", {
  test_df <- tibble::tribble(
    ~name,           ~code,
    "United States", "FRA",
    "France",        NA
  )

  # Should prefer first column match
  result <- standardize_entity(test_df, code, name)
  expect_equal(result$entity_id, c("FRA", "FRA"))

  # Reversing column order should change the results
  result2 <- standardize_entity(test_df, name, code)
  expect_equal(result2$entity_id, c("USA", "FRA"))
})

test_that("standardization works with a single target column", {
  test_df <- tibble::tribble(
    ~country,
    "United States",
    "France",
    "NotACountry"
  )

  result <- standardize_entity(test_df, country)

  expect_equal(result$entity_name, c("United States", "France", NA_character_))
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

test_that("match_entity_ids handles multiple target columns", {
  test_df <- tibble::tribble(
    ~name,           ~code,    ~abbr,
    "United States", NA,       "US",
    NA,              "FRA",    NA,
    "Unknown",       "Unknown", "UNK"
  )

  # Should try each column in sequence
  result <- match_entity_ids(
    test_df,
    target_cols = c("name", "code", "abbr"),
    warn_ambiguous = TRUE
  )

  expect_equal(result, c("USA", "FRA", NA_character_))

  # Changing column order should affect results for the first row
  result2 <- match_entity_ids(
    test_df,
    target_cols = c("abbr", "name", "code"),
    warn_ambiguous = TRUE
  )

  expect_equal(result2, c("USA", "FRA", NA_character_))
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

test_that("column placement works without .before", {
  # Create a test dataframe with columns in a specific order
  test_df <- tibble::tibble(
    id = 1:2,
    extra1 = c("a", "b"),
    name = c("United States", "France"),
    code = c("USA", "FRA"),
    extra2 = c("x", "y")
  )

  # Standardize with multiple target columns *without* .before
  result <- standardize_entity(
    test_df,
    name,
    code
  )

  # Check that output columns are placed at the left side of the dataframe
  # (default behavior)
  expected_order <- c(
    "entity_id", "entity_name", "entity_type",
    "id", "extra1", "name", "code", "extra2"
  )
  expect_equal(names(result), expected_order)
})

test_that(".before parameter works correctly", {
  # Create a test dataframe with columns in a specific order
  test_df <- tibble::tibble(
    id = 1:2,
    extra1 = c("a", "b"),
    name = c("United States", "France"),
    code = c("USA", "FRA"),
    extra2 = c("x", "y")
  )

  # Test placing before a different column
  result_before_id <- standardize_entity(
    test_df,
    name,
    code,
    .before = "id"
  )
  expected_before_id_order <- c(
    "entity_id", "entity_name", "entity_type",
    "id", "extra1", "name", "code", "extra2"
  )
  expect_equal(names(result_before_id), expected_before_id_order)

  # Test placing before the last column
  result_before_extra2 <- standardize_entity(
    test_df,
    name,
    code,
    .before = "extra2"
  )
  expected_before_extra2_order <- c(
    "id", "extra1", "name", "code",
    "entity_id", "entity_name", "entity_type",
    "extra2"
  )
  expect_equal(names(result_before_extra2), expected_before_extra2_order)

  # Test placing before a column that doesn't exist
  expect_error(
    standardize_entity(
      test_df,
      name,
      code,
      .before = "not_a_column"
    ),
    "Can't select columns that don't exist"
  )
})

test_that("fill_mapping parameter works correctly", {
  test_df <- tibble::tribble(
    ~entity,         ~code,
    "United States",  "USA",  # Should match via patterns
    "NotACountry",    "ABC"   # No match, should use fill_mapping
  )

  # Test with fill_mapping
  result <- standardize_entity(
    test_df,
    entity, code,
    fill_mapping = c(entity_id = "code", entity_name = "entity")
  )

  # Check that matched entities are filled from the database
  expect_equal(result$entity_id[1], "USA")
  expect_equal(result$entity_name[1], "United States")

  # Check that unmatched entities are filled from the specified columns
  expect_equal(result$entity_id[2], "ABC")
  expect_equal(result$entity_name[2], "NotACountry")

  # Test without fill_mapping (should leave NA for unmatched)
  result_no_fill <- standardize_entity(
    test_df,
    entity, code
  )

  expect_equal(result_no_fill$entity_id[2], NA_character_)
  expect_equal(result_no_fill$entity_name[2], NA_character_)

  # Test with partial fill_mapping
  result_partial <- standardize_entity(
    test_df,
    entity, code,
    fill_mapping = c(entity_id = "code")  # Only fill entity_id
  )

  expect_equal(result_partial$entity_id[2], "ABC")  # Should be filled
  expect_equal(result_partial$entity_name[2], NA_character_)  # Should remain NA
})

test_that("fill_mapping works with prefix", {
  test_df <- tibble::tribble(
    ~country_name, ~country_code,
    "United States", "USA",  # Should match
    "Unknown",       "XYZ"   # No match
  )

  # Test with prefix and fill_mapping
  result <- standardize_entity(
    test_df,
    country_name, country_code,
    prefix = "country",
    fill_mapping = c(entity_id = "country_code", entity_name = "country_name")
  )

  # Check prefixed column values
  expect_equal(result$country_entity_id[1], "USA")  # Matched
  expect_equal(result$country_entity_name[1], "United States")  # Matched

  expect_equal(result$country_entity_id[2], "XYZ")  # Filled from mapping
  expect_equal(result$country_entity_name[2], "Unknown")  # Filled from mapping
})

test_that("fill_mapping validation works", {
  test_df <- tibble::tribble(
    ~entity, ~code,
    "US",    "USA"
  )

  # Invalid output column name
  expect_error(
    standardize_entity(
      test_df,
      entity, code,
      fill_mapping = c(invalid_col = "code")
    ),
    "fill_mapping names.*must be valid output column names"
  )

  # Invalid input column name
  expect_error(
    standardize_entity(
      test_df,
      entity, code,
      fill_mapping = c(entity_id = "missing_column")
    ),
    "fill_mapping values.*must be columns in the data frame"
  )

  # Not a named vector
  expect_error(
    standardize_entity(
      test_df,
      entity, code,
      fill_mapping = c("entity", "code")
    ),
    "fill_mapping must be a named character vector"
  )
})

test_that("fill_mapping handles empty and partial vectors correctly", {
  test_df <- tibble::tribble(
    ~entity,         ~code,
    "United States",  "USA",  # Should match via patterns
    "NotACountry",    "ABC"   # No match, should use fill_mapping
  )

  # Test with empty fill_mapping vector
  result_empty <- standardize_entity(
    test_df,
    entity, code,
    fill_mapping = c()
  )

  # Should behave the same as NULL (no filling)
  expect_equal(result_empty$entity_id[2], NA_character_)
  expect_equal(result_empty$entity_name[2], NA_character_)

  # Test with only entity_id in fill_mapping
  result_id_only <- standardize_entity(
    test_df,
    entity, code,
    fill_mapping = c(entity_id = "code")
  )

  # Should fill entity_id but not entity_name
  expect_equal(result_id_only$entity_id[2], "ABC")
  expect_equal(result_id_only$entity_name[2], NA_character_)

  # Test with only entity_name in fill_mapping
  result_name_only <- standardize_entity(
    test_df,
    entity, code,
    fill_mapping = c(entity_name = "entity")
  )

  # Should fill entity_name but not entity_id
  expect_equal(result_name_only$entity_id[2], NA_character_)
  expect_equal(result_name_only$entity_name[2], "NotACountry")
})

# TODO: Ambiguity tests
# Should raise a warning if an entity matches more than one of entity_patterns
# even after cycling through all target columns
# Should *not* raise a warning just because more than one entity matches an
# entity_pattern
# Probably mock list_entity_patterns in the tests
# Make sure to check multiple ambiguous matches as well as a single one
