test_that("basic country standardization works", {
  # nolint start
  test_df <- tibble::tribble(
    ~entity         , ~code ,
    NA              , "USA" ,
    "united.states" , NA    ,
    "us"            , "US"
  )
  # nolint end

  result <- standardize_entity(test_df, entity, code)

  expect_equal(
    result$entity_name,
    c(
      "United States",
      "United States",
      "United States"
    )
  )
  expect_equal(
    result$entity_id,
    c("USA", "USA", "USA")
  )
})

test_that("unmatched entities are not filled from existing cols by default", {
  # nolint start
  test_df <- tibble::tribble(
    ~entity       , ~code ,
    "EU"          , NA    ,
    "NotACountry" , NA
  )
  # nolint end

  result <- standardize_entity(test_df, entity, code)

  expect_equal(
    result$entity_name,
    c(
      NA_character_,
      NA_character_
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
  # nolint start
  test_df <- tibble::tribble(
    ~name           , ~code ,
    "United States" , "FRA" ,
    "France"        , NA
  )
  # nolint end

  # Should prefer first column match
  result <- standardize_entity(test_df, code, name)
  expect_equal(result$entity_id, c("FRA", "FRA"))

  # Reversing column order should change the results
  result2 <- standardize_entity(test_df, name, code)
  expect_equal(result2$entity_id, c("USA", "FRA"))
})

test_that("standardization works with a single target column", {
  # nolint start
  test_df <- tibble::tribble(
    ~country        ,
    "United States" ,
    "France"        ,
    "NotACountry"
  )
  # nolint end

  result <- standardize_entity(test_df, country)

  expect_equal(result$entity_name, c("United States", "France", NA_character_))
  expect_equal(result$entity_id, c("USA", "FRA", NA_character_))
})

test_that("standardization fails with invalid output columns", {
  # nolint start
  test_df <- tibble::tribble(
    ~country        ,
    "United States"
  )
  # nolint end

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

test_that("match_entities_with_patterns performs case-insensitive matching", {
  # Create a test dataframe with different case variations
  # nolint start
  test_df <- tibble::tribble(
    ~country ,
    "FRANCE" ,
    "france" ,
    "FrAnCe" ,
    "fra"    ,
    "FRA"
  )
  # nolint end

  # Test the function directly - expect a data frame result with mapped entity
  # columns
  result <- match_entities_with_patterns(
    test_df,
    target_cols = "country",
    patterns = list_entity_patterns(),
    warn_ambiguous = FALSE
  )

  # Expected result should be a data frame with unique combinations of target
  # columns mapped to the selected output columns
  expect_s3_class(result, "data.frame")
  expect_true(
    all(
      c("country", "entity_id", "entity_name", "entity_type") %in% names(result)
    )
  )
  expect_equal(nrow(result), 5) # One row for each unique input
  expect_equal(result$entity_id, rep("FRA", 5))
  expect_equal(result$entity_name, rep("France", 5))
  expect_equal(result$entity_type, rep("economy", 5))
})

test_that("match_entities_with_patterns handles multiple target columns", {
  # nolint start
  test_df <- tibble::tribble(
    ~name           , ~code     , ~abbr ,
    "United States" , NA        , "US"  ,
    NA              , "FRA"     , NA    ,
    "Unknown"       , "Unknown" , "UNK"
  )
  # nolint end

  # Should try each column in sequence and return a data frame
  result <- match_entities_with_patterns(
    test_df,
    target_cols = c("name", "code", "abbr"),
    patterns = list_entity_patterns(),
    warn_ambiguous = FALSE
  )

  # Expected result should be a data frame with all target columns and selected
  # output columns
  expect_s3_class(result, "data.frame")
  expect_true(
    all(
      c("name", "code", "abbr", "entity_id", "entity_name") %in% names(result)
    )
  )
  expect_equal(nrow(result), 3)

  # Check entity_id mapping
  expect_equal(result$entity_id, c("USA", "FRA", NA_character_))

  # Check entity_name mapping
  expect_equal(result$entity_name, c("United States", "France", NA_character_))

  # Changing column order should affect results for the first row
  result2 <- match_entities_with_patterns(
    test_df,
    target_cols = c("abbr", "name", "code"),
    patterns = list_entity_patterns(),
    warn_ambiguous = FALSE
  )

  expect_equal(result2$entity_id, c("USA", "FRA", NA_character_))
  expect_equal(result2$entity_name, c("United States", "France", NA_character_))
})

test_that("match_entities_with_patterns handles output_cols parameter", {
  # nolint start
  test_df <- tibble::tribble(
    ~country        ,
    "United States" ,
    "France"        ,
    "Germany"
  )
  # nolint end

  # Test with different combinations of output_cols
  # Note: We're testing if the right columns come through, not the parameter
  # itself
  result_all <- match_entities_with_patterns(
    test_df,
    target_cols = "country",
    patterns = list_entity_patterns(),
    warn_ambiguous = FALSE
  )

  # Should include all entity columns
  expect_true(
    all(
      c(
        "country",
        "entity_id",
        "entity_name",
        "entity_type",
        "iso3c",
        "iso2c"
      ) %in%
        names(result_all)
    )
  )

  # We can't test with subset of output_cols as the parameter doesn't exist
  # Instead validate the columns that should always be present
  expect_true(
    all(c("country", "entity_id", "entity_name") %in% names(result_all))
  )

  # Check that data is correctly mapped
  expect_equal(result_all$entity_id, c("USA", "FRA", "DEU"))
  expect_equal(result_all$iso3c, c("USA", "FRA", "DEU"))
})

test_that("match_entities_with_patterns handles ambiguous matches", {
  # Create a mock entity_patterns with ambiguous patterns
  # Make sure it has the same structure as the real patterns dataframe
  mock_patterns <- tibble::tibble(
    entity_id = c("USA", "USB"),
    entity_name = c("United States A", "United States B"),
    entity_type = c("economy", "economy"),
    iso3c = c("USA", "USB"),
    iso2c = c("US", "UB"),
    entity_regex = c("^us$", "^us$")
  )

  # Use local_mocked_bindings to temporarily mock the list_entity_patterns
  # function
  local_mocked_bindings(
    list_entity_patterns = function() {
      mock_patterns
    }
  )

  # Create a test dataframe
  test_df <- tibble::tibble(
    country = "us"
  )

  # Test with warn_ambiguous = TRUE
  # This should warn about ambiguous matches and return a data frame with
  # both matches (duplicates)
  expect_warning(
    {
      result <- match_entities_with_patterns(
        test_df,
        target_cols = "country",
        patterns = mock_patterns,
        warn_ambiguous = TRUE
      )
    },
    "Ambiguous match"
  )

  # Should return a data frame with both matches for ambiguous entries
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2) # Now expect 2 rows instead of 1

  # Check that both matches are present
  expect_true(all(c("USA", "USB") %in% result$entity_id))
  expect_true(
    all(c("United States A", "United States B") %in% result$entity_name)
  )

  # All rows should have the same country value
  expect_equal(result$country, c("us", "us"))
})

test_that("output_cols argument correctly filters columns", {
  valid_cols <- c(
    "entity_name",
    "entity_type",
    "entity_id",
    "iso3c",
    "iso2c"
  )
  # nolint start
  test_df <- tibble::tribble(
    ~entity         , ~code ,
    "United States" , "USA" ,
    "France"        , "FRA"
  )
  # nolint end

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
    any(
      c(
        "entity_name",
        "entity_type",
        "iso2c",
        "entity_regex"
      ) %in%
        names(result)
    )
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
  # nolint start
  test_df <- tibble::tribble(
    ~country        ,
    "United States" ,
    "France"
  )
  # nolint end

  # Test with specific output columns
  result <- standardize_entity(
    test_df,
    country,
    output_cols = c("entity_id", "entity_name", "entity_type")
  )

  # Verify new columns are added to the left side of the dataframe
  # (default behavior)
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
      country,
      warn_overwrite = FALSE
    )
  )

  # Should actually overwrite the columns
  expect_warning(
    result <- standardize_entity(df, country),
    "Overwriting existing entity columns"
  )
  expect_false(identical(df$entity_id, result$entity_id))
  expect_false(identical(df$entity_name, result$entity_name))
})

test_that("prefix parameter works correctly", {
  # nolint start
  test_df <- tibble::tribble(
    ~country_name , ~counterpart_name ,
    "USA"         , "France"          ,
    "Germany"     , "Italy"
  )
  # nolint end

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
  expect_true(all(
    c(
      "country_entity_id",
      "country_entity_name",
      "country_entity_type",
      "counterpart_entity_id",
      "counterpart_entity_name",
      "counterpart_entity_type"
    ) %in%
      names(result)
  ))

  # Check that values are correct
  expect_equal(result$country_entity_id, c("USA", "DEU"))
  expect_equal(result$counterpart_entity_id, c("FRA", "ITA"))
})

test_that("default_entity_type parameter works correctly", {
  # nolint start
  test_df <- tibble::tribble(
    ~entity         ,
    "United States" ,
    "NotACountry"
  )
  # nolint end

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
    "entity_id",
    "entity_name",
    "entity_type",
    "id",
    "extra1",
    "name",
    "code",
    "extra2"
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
    "entity_id",
    "entity_name",
    "entity_type",
    "id",
    "extra1",
    "name",
    "code",
    "extra2"
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
    "id",
    "extra1",
    "name",
    "code",
    "entity_id",
    "entity_name",
    "entity_type",
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
  # nolint start
  test_df <- tibble::tribble(
    ~entity         , ~code ,
    "United States" , "USA" , # Should match via patterns
    "NotACountry"   , "ABC" # No match, should use fill_mapping
  )
  # nolint end

  # Test with fill_mapping
  result <- standardize_entity(
    test_df,
    entity,
    code,
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
    entity,
    code
  )

  expect_equal(result_no_fill$entity_id[2], NA_character_)
  expect_equal(result_no_fill$entity_name[2], NA_character_)

  # Test with partial fill_mapping
  result_partial <- standardize_entity(
    test_df,
    entity,
    code,
    fill_mapping = c(entity_id = "code") # Only fill entity_id
  )

  expect_equal(result_partial$entity_id[2], "ABC") # Should be filled
  expect_equal(result_partial$entity_name[2], NA_character_) # Should remain NA
})

test_that("fill_mapping works with prefix", {
  test_df <- tibble::tribble(
    # nolint start
    ~country_name   , ~country_code ,
    "United States" , "USA"         , # Should match
    "Unknown"       , "XYZ" # No match
  )
  # nolint end

  # Test with prefix and fill_mapping
  result <- standardize_entity(
    test_df,
    country_name,
    country_code,
    prefix = "country",
    fill_mapping = c(entity_id = "country_code", entity_name = "country_name")
  )

  # Check prefixed column values
  expect_equal(result$country_entity_id[1], "USA") # Matched
  expect_equal(result$country_entity_name[1], "United States") # Matched

  expect_equal(result$country_entity_id[2], "XYZ") # Filled from mapping
  expect_equal(result$country_entity_name[2], "Unknown") # Filled from mapping
})

test_that("fill_mapping validation works", {
  # nolint start
  test_df <- tibble::tribble(
    ~entity , ~code ,
    "US"    , "USA"
  )
  # nolint end

  # Invalid output column name
  expect_error(
    standardize_entity(
      test_df,
      entity,
      code,
      fill_mapping = c(invalid_col = "code")
    ),
    "fill_mapping names.*must be valid output column names"
  )

  # Invalid input column name
  expect_error(
    standardize_entity(
      test_df,
      entity,
      code,
      fill_mapping = c(entity_id = "missing_column")
    ),
    "fill_mapping values.*must be columns in the data frame"
  )

  # Not a named vector
  expect_error(
    standardize_entity(
      test_df,
      entity,
      code,
      fill_mapping = c("entity", "code")
    ),
    "fill_mapping must be a named character vector"
  )
})

test_that("fill_mapping handles empty and partial vectors correctly", {
  # nolint start
  test_df <- tibble::tribble(
    ~entity         , ~code ,
    "United States" , "USA" , # Should match via patterns
    "NotACountry"   , "ABC" # No match, should use fill_mapping
  )
  # nolint end

  # Test with empty fill_mapping vector
  result_empty <- standardize_entity(
    test_df,
    entity,
    code,
    fill_mapping = c()
  )

  # Should behave the same as NULL (no filling)
  expect_equal(result_empty$entity_id[2], NA_character_)
  expect_equal(result_empty$entity_name[2], NA_character_)

  # Test with only entity_id in fill_mapping
  result_id_only <- standardize_entity(
    test_df,
    entity,
    code,
    fill_mapping = c(entity_id = "code")
  )

  # Should fill entity_id but not entity_name
  expect_equal(result_id_only$entity_id[2], "ABC")
  expect_equal(result_id_only$entity_name[2], NA_character_)

  # Test with only entity_name in fill_mapping
  result_name_only <- standardize_entity(
    test_df,
    entity,
    code,
    fill_mapping = c(entity_name = "entity")
  )

  # Should fill entity_name but not entity_id
  expect_equal(result_name_only$entity_id[2], NA_character_)
  expect_equal(result_name_only$entity_name[2], "NotACountry")
})

test_that("match_entities_with_patterns handles empty or all-NA data", {
  # Test with empty data frame
  empty_df <- tibble::tibble(country = character(0))

  result_empty <- match_entities_with_patterns(
    empty_df,
    target_cols = "country",
    patterns = list_entity_patterns(),
    warn_ambiguous = FALSE
  )

  expect_s3_class(result_empty, "data.frame")
  expect_equal(nrow(result_empty), 0)
  expect_true(
    all(c("country", "entity_id", "entity_name") %in% names(result_empty))
  )

  # Test with all NA values
  na_df <- tibble::tibble(country = c(NA_character_, NA_character_))

  result_na <- match_entities_with_patterns(
    na_df,
    target_cols = "country",
    patterns = list_entity_patterns(),
    warn_ambiguous = FALSE
  )

  expect_s3_class(result_na, "data.frame")
  # Should have one row for the unique NA value
  expect_equal(nrow(result_na), 1)
  expect_true(
    all(c("country", "entity_id", "entity_name") %in% names(result_na))
  )
  expect_true(is.na(result_na$entity_id[1]))
  expect_true(is.na(result_na$entity_name[1]))
})

test_that("match_entities_with_patterns keeps all unique target col combos", {
  # Test with multiple columns where some combinations are duplicated
  # nolint start
  test_df <- tibble::tribble(
    ~name     , ~code , ~year ,
    "France"  , "FRA" ,  2020 ,
    "France"  , "FRA" ,  2021 , # Duplicate name-code combination, different year
    "France"  , "FR"  ,  2020 , # Different code
    "Germany" , "DEU" ,  2020 ,
    "Germany" , "DEU" ,  2020 # Complete duplicate row
  )
  # nolint end

  result <- match_entities_with_patterns(
    test_df,
    target_cols = c("name", "code"),
    patterns = list_entity_patterns(),
    warn_ambiguous = FALSE
  )

  # Should have 3 unique name-code combinations
  expect_equal(nrow(result), 3)

  # Should include all target columns
  expect_true(
    all(c("name", "code", "entity_id", "entity_name") %in% names(result))
  )

  # Check mappings for each unique combination
  expect_equal(
    dplyr::arrange(result, name, code)$entity_id,
    c("FRA", "FRA", "DEU") # Both "France" rows map to FRA, Germany to DEU
  )
})

test_that("match_entities_with_patterns fails gracefully with invalid input", {
  # nolint start
  test_df <- tibble::tribble(
    ~country        ,
    "United States"
  )
  # nolint end

  # Test with invalid target column
  expect_error(
    match_entities_with_patterns(
      test_df,
      target_cols = "invalid_column",
      patterns = list_entity_patterns(),
      warn_ambiguous = FALSE
    ),
    "target_cols"
  )
})

test_that("match_entities_with_patterns handles multiple ambiguous matches", {
  # Create mock patterns with multiple ambiguous matches
  mock_patterns <- tibble::tibble(
    entity_id = c("USA", "USB", "FRA", "FRB"),
    entity_name = c(
      "United States A",
      "United States B",
      "France A",
      "France B"
    ),
    entity_type = c("economy", "economy", "economy", "economy"),
    iso3c = c("USA", "USB", "FRA", "FRB"),
    iso2c = c("US", "UB", "FR", "FB"),
    entity_regex = c("^us$", "^us$", "^fr$", "^fr$") # Ambiguous patterns
  )

  # Use local_mocked_bindings to temporarily mock the list_entity_patterns
  # function
  local_mocked_bindings(
    list_entity_patterns = function() {
      mock_patterns
    }
  )

  # Create a test dataframe with multiple entities that have ambiguous
  # matches
  test_df <- tibble::tibble(
    country = c("us", "fr", "de") # "us" and "fr" are ambiguous, "de" not
  )

  # Test with warn_ambiguous = TRUE
  # Should warn about ambiguous matches and return duplicates for each
  # ambiguous entity
  expect_warning(
    expect_warning(
      {
        result <- match_entities_with_patterns(
          test_df,
          target_cols = "country",
          patterns = mock_patterns,
          warn_ambiguous = TRUE
        )
      },
      "Ambiguous match for fr"
    ),
    "Ambiguous match for us"
  )

  # Should return a data frame with duplicates for ambiguous entries
  expect_s3_class(result, "data.frame")
  # 2 rows for "us", 2 rows for "fr", 1 row for "de"
  expect_equal(nrow(result), 5)

  # Check US matches
  us_matches <- result[result$country == "us", ]
  expect_equal(nrow(us_matches), 2)
  expect_true(all(c("USA", "USB") %in% us_matches$entity_id))

  # Check FR matches
  fr_matches <- result[result$country == "fr", ]
  expect_equal(nrow(fr_matches), 2)
  expect_true(all(c("FRA", "FRB") %in% fr_matches$entity_id))

  # Check DE (no match)
  de_match <- result[result$country == "de", ]
  expect_equal(nrow(de_match), 1)
  expect_true(is.na(de_match$entity_id))
})

test_that("match_entities_with_patterns suppresses warnings per option", {
  # Create mock patterns with ambiguous matches
  mock_patterns <- tibble::tibble(
    entity_id = c("USA", "USB"),
    entity_name = c("United States A", "United States B"),
    entity_type = c("economy", "economy"),
    iso3c = c("USA", "USB"), # Add missing columns
    iso2c = c("US", "UB"), # Add missing columns
    entity_regex = c("^us$", "^us$") # Both patterns match "us"
  )

  # Use local_mocked_bindings to temporarily mock the list_entity_patterns
  # function
  local_mocked_bindings(
    list_entity_patterns = function() {
      mock_patterns
    }
  )

  # Create a test dataframe
  test_df <- tibble::tibble(
    country = "us"
  )

  # Test with warn_ambiguous = FALSE
  # This should NOT warn about ambiguous matches but still return all matches
  expect_no_warning(
    {
      result <- match_entities_with_patterns(
        test_df,
        target_cols = "country",
        patterns = mock_patterns,
        warn_ambiguous = FALSE
      )
    }
  )

  # Should still return a data frame with both matches despite no warning
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_true(all(c("USA", "USB") %in% result$entity_id))
  expect_true(
    all(c("United States A", "United States B") %in% result$entity_name)
  )
})

test_that("match_entities_with_patterns handles case insensitive matches", {
  # Create mock patterns
  mock_patterns <- tibble::tibble(
    entity_id = c("USA"),
    entity_name = c("United States"),
    entity_type = c("economy"),
    iso3c = c("USA"), # Add missing columns
    iso2c = c("US"), # Add missing columns
    entity_regex = c("^united states|usa|us$")
  )

  # Use local_mocked_bindings to temporarily mock the list_entity_patterns
  # function
  local_mocked_bindings(
    list_entity_patterns = function() {
      mock_patterns
    }
  )

  # Create a test dataframe with different case variations
  test_df <- tibble::tibble(
    country = c("us", "US", "Us", "uS")
  )

  # This should not warn about ambiguous matches as these are the same pattern
  # just with different cases
  expect_no_warning(
    {
      result <- match_entities_with_patterns(
        test_df,
        target_cols = "country",
        patterns = mock_patterns,
        warn_ambiguous = TRUE # Even with warnings enabled
      )
    }
  )

  # Should return a data frame with one row for each unique input
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 4) # One per case variation

  # All should be matched to USA
  expect_equal(unique(result$entity_id), "USA")
  expect_equal(unique(result$entity_name), "United States")

  # Each row should preserve its original case
  expect_equal(result$country, c("us", "US", "Us", "uS"))
})

test_that("match_entities_with_patterns performs multiple passes correctly", {
  # Create a test dataframe with different columns that should be matched
  # sequentially
  # nolint start
  test_df <- tibble::tribble(
    ~id , ~name         , ~code , ~description    ,
      1 , NA            , "USA" , "First entry"   , # Should match on code
      2 , "France"      , NA    , "Second entry"  , # Should match on name
      3 , NA            , NA    , "United States" , # Should match on description
      4 , "not a match" , "XXX" , "no match here" # No match in any column
  )
  # nolint end

  # Mock the patterns for this test to ensure predictable matching
  mock_patterns <- tibble::tibble(
    entity_id = c("USA", "FRA"),
    entity_name = c("United States", "France"),
    entity_type = c("economy", "economy"),
    iso3c = c("USA", "FRA"),
    iso2c = c("US", "FR"),
    entity_regex = c("^(united states|usa|us)$", "^(france|fra|fr)$")
  )

  # Use local_mocked_bindings to temporarily mock the list_entity_patterns
  # function
  local_mocked_bindings(
    list_entity_patterns = function() {
      mock_patterns
    }
  )

  # Test the function
  result <- match_entities_with_patterns(
    test_df,
    target_cols = c("name", "code", "description"),
    patterns = mock_patterns,
    warn_ambiguous = FALSE
  )

  # Should be a data frame with all target columns and requested output columns
  expect_s3_class(result, "data.frame")
  expect_true(all(
    c(
      "name",
      "code",
      "description",
      "entity_id",
      "entity_name",
      "iso3c"
    ) %in%
      names(result)
  ))

  # Should have 4 rows (one for each unique combination of target columns)
  expect_equal(nrow(result), 4)

  # Row with code="USA" should match USA
  matched_usa_by_code <- result |>
    dplyr::filter(code == "USA")
  expect_equal(matched_usa_by_code$entity_id, "USA")
  expect_equal(matched_usa_by_code$entity_name, "United States")

  # Row with name="France" should match FRA
  matched_france_by_name <- result |>
    dplyr::filter(name == "France")
  expect_equal(matched_france_by_name$entity_id, "FRA")
  expect_equal(matched_france_by_name$entity_name, "France")

  # Row with description="United States" should match USA
  matched_usa_by_desc <- result |>
    dplyr::filter(description == "United States")
  expect_equal(matched_usa_by_desc$entity_id, "USA")
  expect_equal(matched_usa_by_desc$entity_name, "United States")

  # Row with no matches should have NAs
  no_match_row <- result |>
    dplyr::filter(name == "not a match")
  expect_true(is.na(no_match_row$entity_id))
  expect_true(is.na(no_match_row$entity_name))

  # Change column order to verify priority
  result2 <- match_entities_with_patterns(
    test_df,
    target_cols = c("description", "code", "name"),
    patterns = mock_patterns,
    warn_ambiguous = FALSE
  )

  # Row with description="United States" should match USA
  matched_usa_by_desc2 <- result2 |>
    dplyr::filter(description == "United States")
  expect_equal(matched_usa_by_desc2$entity_id, "USA")

  # Row with code="USA" should still match USA
  matched_usa_by_code2 <- result2 |>
    dplyr::filter(code == "USA")
  expect_equal(matched_usa_by_code2$entity_id, "USA")
})

test_that("fill_mapping validates uniqueness of entity_id values", {
  # Create test data with an entity that won't match any pattern
  test_df <- tibble::tribble(
    # nolint start
    ~entity       , ~code ,
    "NotACountry" , "USA" # Using "USA" which already exists in entity_patterns
  ) # nolint end

  # Use local_mocked_bindings to mock list_entity_patterns
  local_mocked_bindings(
    list_entity_patterns = function() {
      tibble::tibble(
        entity_id = c("USA", "FRA", "DEU"),
        entity_name = c("United States", "France", "Germany"),
        entity_type = c("economy", "economy", "economy"),
        iso3c = c("USA", "FRA", "DEU"),
        iso2c = c("US", "FR", "DE"),
        entity_regex = c("^united states|us$", "^france|fra$", "^germany|deu$")
      )
    }
  )

  # Should throw a warning when trying to fill with an existing entity_id
  expect_warning(
    result <- standardize_entity(
      test_df,
      entity,
      fill_mapping = c(entity_id = "code") # "code" contains "USA"
    ),
    "The entity_id value"
  )

  #But should still perform the fill
  expect_equal(result$entity_id, "USA")

  # But should work when filling with a different, non-conflicting ID
  test_df2 <- tibble::tribble(
    # nolint start
    ~entity       , ~code ,
    "NotACountry" , "XYZ" # XYZ doesn't exist in entity_patterns
  ) # nolint end

  # This should work fine
  result <- standardize_entity(
    test_df2,
    entity,
    fill_mapping = c(entity_id = "code")
  )

  expect_equal(result$entity_id, "XYZ")
})

test_that("validate_entity_inputs catches invalid inputs", {
  # Test invalid data frame input
  expect_error(
    standardize_entity(
      list(a = 1, b = 2), # Not a data frame
      col1,
      output_cols = c("entity_id", "entity_name")
    ),
    "Input .* must be a data frame or tibble"
  )

  # Test non-existent target columns
  test_df <- tibble::tribble(
    # nolint start
    ~existing_col   ,
    "United States"
  ) # nolint end

  expect_error(
    standardize_entity(
      test_df,
      non_existent_col, # Column that doesn't exist
      output_cols = c("entity_id", "entity_name")
    ),
    "Target column\\(s\\) .* must be found in data"
  )
})

test_that("prefix validation works correctly", {
  test_df <- tibble::tribble(
    # nolint start
    ~country        ,
    "United States"
  ) # nolint end

  # Test invalid prefix types
  expect_error(
    standardize_entity(
      test_df,
      country,
      prefix = c("prefix1", "prefix2") # Multiple strings
    ),
    "Prefix must be a single character string"
  )

  expect_error(
    standardize_entity(
      test_df,
      country,
      prefix = 123 # Number instead of string
    ),
    "Prefix must be a single character string"
  )

  # Verify that a valid prefix still works
  expect_no_error(
    standardize_entity(
      test_df,
      country,
      prefix = "test"
    )
  )
})

test_that("entity_id as target column gets replaced with standardized values", {
  df <- data.frame(
    entity_name = c("United States", "China", "NotACountry"),
    entity_id = c("USA", "CHN", "ZZZ"),
    obs_value = c(1, 2, 3)
  )

  expect_warning(
    result <- standardize_entity(
      data = df,
      entity_id,
      entity_name
    )
  )

  # Check structure
  expect_true(all(
    c("entity_id", "entity_name", "entity_type", "obs_value") %in% names(result)
  ))

  # Should have correct number of rows (no duplication)
  expect_equal(nrow(result), 3)

  # USA and CHN should match and get standardized values

  expect_equal(result$entity_id[1], "USA")
  expect_equal(result$entity_id[2], "CHN")

  # ZZZ should not match, so entity_id should be NA
  expect_true(is.na(result$entity_id[3]))

  # entity_name should be populated for matched rows
  expect_equal(result$entity_name[1], "United States")
  expect_equal(result$entity_name[2], "China")
  expect_true(is.na(result$entity_name[3]))

  # Original obs_value should be preserved
  expect_equal(result$obs_value, c(1, 2, 3))
})
