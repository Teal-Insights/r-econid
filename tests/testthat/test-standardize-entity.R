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

# Define valid output columns
valid_cols <- c(
  "entity_id",
  "entity_name",
  "entity_type",
  "iso3c",
  "iso2c"
)

#' Standardize Entity Identifiers
#'
#' @description
#' Standardizes entity identifiers (e.g., name, ISO code) in an economic data
#' frame by matching them against a predefined list of regex patterns to add
#' columns containing standardized identifiers to the data frame.
#'
#' @param data A data frame or tibble containing entity identifiers to
#'   standardize
#' @param ... Columns containing entity names and/or IDs. These can be
#'   specified using unquoted column names (e.g., `entity_name`, `entity_id`)
#'   or quoted column names (e.g., `"entity_name"`, `"entity_id"`).  Must
#'   specify at least one column. If two columns are specified, the first is
#'   assumed to be the entity name and the second is assumed to be the entity
#'   ID.
#' @param output_cols Character vector specifying desired output columns.
#'   Options are "entity_id", "entity_name", "entity_type", "iso3c", "iso2c".
#'   Defaults to c("entity_id", "entity_name", "entity_type").
#' @param prefix Optional character string to prefix the output column names.
#'   Useful when standardizing multiple entities in the same dataset (e.g.,
#'   "country", "counterpart"). If provided, output columns will be named
#'   prefix_entity_id, prefix_entity_name, etc. (with an underscore
#'   automatically inserted between the prefix and the column name).
#' @param fill_mapping Named character vector specifying how to fill missing
#'   values when no entity match is found. Names should be output column names
#'   (without prefix), and values should be input column names (from `...`).
#'   For example, `c(entity_id = "country_code", entity_name = "country_name")`
#'   will fill missing entity_id values with values from the country_code column
#'   and missing entity_name values with values from the country_name column.
#' @param default_entity_type Character or NA; the default entity type to use
#'   for entities that do not match any of the patterns. Options are "economy",
#'   "organization", "aggregate", "other", or NA_character_. Defaults to
#'   NA_character_. This argument is only used when "entity_type" is included in
#'   output_cols.
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#' @param overwrite Logical; whether to overwrite existing entity_* columns
#' @param warn_overwrite Logical; whether to warn when overwriting existing
#'   entity_* columns. Defaults to TRUE.
#' @param .before Column name or position to insert the standardized columns
#'   before. If NULL (default), columns are inserted at the beginning of the
#'   dataframe. Can be a character vector specifying the column name or a
#'   numeric value specifying the column index. If the specified column is not
#'   found in the data, an error is thrown.
#'
#' @return A data frame with standardized entity information merged with the
#'   input data. The standardized columns are placed directly to the left of the
#'   first target column.
#'
#' @examples
#' # Standardize entity names and IDs in a data frame
#' test_df <- tibble::tribble(
#'   ~entity,         ~code,
#'   "United States",  "USA",
#'   "united.states",  NA,
#'   "us",             "US",
#'   "EU",             NA,
#'   "NotACountry",    NA
#' )
#'
#' standardize_entity(test_df, entity, code)
#'
#' # Standardize with fill_mapping for unmatched entities
#' standardize_entity(
#'   test_df,
#'   entity, code,
#'   fill_mapping = c(entity_id = "code", entity_name = "entity")
#' )
#'
#' # Standardize multiple entities in sequence with a prefix
#' df <- data.frame(
#'   country_name = c("United States", "France"),
#'   counterpart_name = c("China", "Germany")
#' )
#' df |>
#'   standardize_entity(
#'     country_name
#'   ) |>
#'   standardize_entity(
#'     counterpart_name,
#'     prefix = "counterpart"
#'   )
#'
#' @export
standardize_entity <- function(
  data,
  ...,
  output_cols = c("entity_id", "entity_name", "entity_type"),
  prefix = NULL,
  fill_mapping = NULL,
  default_entity_type = NA_character_,
  warn_ambiguous = TRUE,
  overwrite = TRUE,
  warn_overwrite = TRUE,
  .before = NULL
) {
  # Gather the columns from ...
  target_cols_syms <- rlang::ensyms(...)

  # Turn syms into strings
  target_cols_names <- purrr::map_chr(target_cols_syms, rlang::as_name)

  # Validate inputs
  validate_entity_inputs(
    data,
    target_cols_names,
    output_cols,
    prefix,
    fill_mapping
  )

  # Apply prefix to output column names if provided
  prefixed_output_cols <- output_cols
  if (!is.null(prefix)) {
    prefixed_output_cols <- paste(prefix, output_cols, sep = "_")
  }

  # Check for existing entity columns
  existing_cols <- intersect(names(data), prefixed_output_cols)

  # Identify target columns that would be overwritten
  target_cols_to_overwrite <- intersect(target_cols_names, existing_cols)

  if (length(existing_cols) > 0) {
    # Ignore warn_overwrite if overwrite is FALSE
    if (overwrite && warn_overwrite) {
      # Only warn about columns that aren't being used as targets
      non_target_existing <- setdiff(existing_cols, target_cols_names)
      if (length(non_target_existing) > 0) {
        cli::cli_warn(
          "Overwriting existing entity columns: {.val {non_target_existing}}"
        )
      }
      # Warn differently about target columns that share output names
      if (length(target_cols_to_overwrite) > 0) {
        cli::cli_warn(
          paste(
            "Target column(s) {.val {target_cols_to_overwrite}} share name(s)",
            "with output columns; original values will be used for matching",
            "then overwritten with standardized values."
          )
        )
      }
    }
  }

  # Save target column data before removing any columns
  # (in case target columns share names with output columns)
  target_data <- data[, target_cols_names, drop = FALSE]

  # Remove existing entity columns if overwrite is TRUE
  if (overwrite && length(existing_cols) > 0) {
    data <- data[, setdiff(names(data), existing_cols), drop = FALSE]
  }

  # Restore target columns from saved data
  for (col in target_cols_names) {
    if (!col %in% names(data)) {
      data[[col]] <- target_data[[col]]
    }
  }

  # Convert all target columns to character UTF-8
  for (col in target_cols_names) {
    data[[col]] <- enc2utf8(as.character(data[[col]]))
  }

  # Get entity patterns (without prefix - we'll rename after matching)
  entity_patterns <- list_entity_patterns()

  # Store original pattern column names for reference
  original_pattern_cols <- names(entity_patterns)

  # Use regex match to map entities to patterns
  entity_mapping <- match_entities_with_patterns(
    data = data,
    target_cols = target_cols_names,
    patterns = entity_patterns,
    warn_ambiguous = warn_ambiguous
  )

  # Now apply prefix to the pattern columns in the result if needed
  if (!is.null(prefix)) {
    # Create a named vector for renaming: new_name = old_name
    rename_vec <- stats::setNames(
      original_pattern_cols,
      paste(prefix, original_pattern_cols, sep = "_")
    )
    entity_mapping <- entity_mapping |>
      dplyr::rename(dplyr::all_of(rename_vec))
  }

  # Handle the case where target columns overlap with output columns
  # match_entities_with_patterns preserves temp names (..target..<col>) for
  # conflicting columns, so entity_mapping has:
  # - pattern columns with standardized values (e.g., entity_id)
  # - temp-named target columns with original values (e.g., ..target..entity_id)
  overlapping_cols <- intersect(target_cols_names, prefixed_output_cols)

  if (length(overlapping_cols) > 0) {
    # The temp names used by match_entities_with_patterns
    temp_target_names <- paste0("..target..", overlapping_cols)
    names(temp_target_names) <- overlapping_cols

    # Build the select columns for entity_mapping:
    # - Use prefixed_output_cols for standardized values
    # - Use temp names for target columns that overlap with output cols
    # - Use original names for target columns that don't overlap
    select_target_cols <- target_cols_names
    for (col in overlapping_cols) {
      select_target_cols[select_target_cols == col] <- temp_target_names[col]
    }

    # Select output columns and target columns with temp names where applicable
    entity_mapping <- entity_mapping |>
      dplyr::select(
        dplyr::all_of(prefixed_output_cols),
        dplyr::any_of(select_target_cols)
      )

    # Rename target columns in data to match the temp names for joining
    for (col in overlapping_cols) {
      names(data)[names(data) == col] <- temp_target_names[col]
    }

    # Build the join columns using temp names for overlapping columns
    join_cols <- target_cols_names
    for (col in overlapping_cols) {
      join_cols[join_cols == col] <- temp_target_names[col]
    }

    # Join entity_mapping to the input data
    results <- dplyr::left_join(
      data,
      entity_mapping,
      by = join_cols
    )

    # Remove the temporary target columns (we have the standardized versions)
    temp_cols_present <- intersect(temp_target_names, names(results))
    if (length(temp_cols_present) > 0) {
      results <- results |>
        dplyr::select(-dplyr::all_of(temp_cols_present))
    }
  } else {
    # No overlap - simple case
    # Select only the prefixed output columns and original data columns
    entity_mapping <- entity_mapping |>
      dplyr::select(
        dplyr::all_of(prefixed_output_cols),
        dplyr::all_of(target_cols_names)
      )

    # Join entity_mapping to the input data
    results <- dplyr::left_join(
      data,
      entity_mapping,
      by = target_cols_names
    )
  }

  # Apply fill_mapping for rows with no matches
  if (!is.null(fill_mapping)) {
    # Get rows with no matches
    no_match_mask <- is.na(results[[prefixed_output_cols[1]]])

    # Apply each mapping
    for (output_col in names(fill_mapping)) {
      input_col <- fill_mapping[[output_col]]
      prefixed_output <- if (!is.null(prefix)) {
        paste(prefix, output_col, sep = "_")
      } else {
        output_col
      }

      # If it's the entity_id column, we need to validate that the values being
      # filled (i.e., in masked rows) are not already in entity_patterns
      if (warn_ambiguous && output_col == "entity_id") {
        # Get the entity_id values that are already in entity_patterns
        existing_ids <- entity_patterns[[1]]

        # Get the entity_id values that are being filled
        filled_ids <- results[[input_col]][no_match_mask]

        # Check if any of the filled ids are already in existing_ids
        if (any(filled_ids %in% existing_ids)) {
          cli::cli_warn(paste(
            "The entity_id value(s)",
            filled_ids[which(filled_ids %in% existing_ids)],
            "being filled over from",
            input_col,
            "in rows that could not be standardized conflict(s) with a",
            "standard entity ID, which may cause ambiguity."
          ))
        }
      }

      # Only apply mapping if output column exists
      if (prefixed_output %in% names(results)) {
        # Fill NA values in the output column with values from the input column
        # but only for rows with no matches
        results[no_match_mask, prefixed_output] <- results[
          no_match_mask,
          input_col
        ]
      }
    }
  }

  # Replace any NA values in entity_type with the default_entity_type
  if ("entity_type" %in% output_cols) {
    prefixed_entity_type <- prefixed_output_cols[output_cols == "entity_type"]

    # Make sure we're working with the correct column name
    if (prefixed_entity_type %in% names(results)) {
      results[[prefixed_entity_type]] <- tidyr::replace_na(
        results[[prefixed_entity_type]],
        default_entity_type
      )
    }
  }

  # Reorder columns
  if (!rlang::quo_is_null(rlang::enquo(.before))) {
    results <- results |>
      dplyr::relocate(
        dplyr::any_of(prefixed_output_cols),
        .before = {{ .before }}
      )
  } else {
    results <- results |>
      dplyr::relocate(
        dplyr::any_of(prefixed_output_cols),
        .before = 1
      )
  }

  results
}

#' Validate inputs for entity standardization
#'
#' @description
#' Validates the input data frame and column names for entity standardization.
#'
#' @param data A data frame or tibble to validate
#' @param target_cols_names Character vector of column names containing entity
#'   identifiers
#' @param output_cols Character vector of requested output columns
#' @param prefix Optional character string to prefix the output column names
#' @param fill_mapping Named character vector specifying how to fill missing
#'   values
#'
#' @return Invisible NULL
#'
#' @keywords internal
validate_entity_inputs <- function(
  data,
  target_cols_names,
  output_cols,
  prefix,
  fill_mapping = NULL
) {
  # Validate data frame
  if (!is.data.frame(data)) {
    cli::cli_abort("Input {.var data} must be a data frame or tibble.")
  }

  # Validate target_cols_names
  missing_cols <- setdiff(target_cols_names, names(data))
  if (length(missing_cols) > 0) {
    cli::cli_abort(
      "Target column(s) {.var {missing_cols}} must be found in data."
    )
  }

  # Validate output_cols against valid_cols
  invalid_cols <- setdiff(output_cols, valid_cols)
  if (length(invalid_cols) > 0) {
    cli::cli_abort(
      paste(
        "Output columns {.val {invalid_cols}} must be one of",
        "{.val {valid_cols}}"
      )
    )
  }

  # Validate prefix if provided
  if (!is.null(prefix)) {
    if (!is.character(prefix) || length(prefix) != 1) {
      cli::cli_abort("Prefix must be a single character string.")
    }
  }

  # Validate fill_mapping if provided
  if (!is.null(fill_mapping)) {
    # Check it's a named character vector
    if (
      !is.character(fill_mapping) ||
        is.null(names(fill_mapping)) ||
        any(names(fill_mapping) == "")
    ) {
      cli::cli_abort("fill_mapping must be a named character vector.")
    }

    # Check that all names in fill_mapping are valid output column names
    invalid_output_names <- setdiff(names(fill_mapping), valid_cols)
    if (length(invalid_output_names) > 0) {
      cli::cli_abort(paste(
        "fill_mapping names {.val {invalid_output_names}} must be valid output",
        "column names: {.val {valid_cols}}"
      ))
    }

    # Check that all values in fill_mapping exist in the data
    missing_input_cols <- setdiff(fill_mapping, names(data))
    if (length(missing_input_cols) > 0) {
      cli::cli_abort(paste(
        "fill_mapping values {.val {missing_input_cols}} must be columns",
        "in the data frame."
      ))
    }
  }

  # No return value needed
  invisible(NULL)
}

#' Safe regex inner join that handles duplicate column names
#'
#' @description
#' Wrapper around regex_inner_join that ensures no duplicate column names
#' in the result by keeping only the first occurrence of each column name.
#'
#' @param x First data frame
#' @param y Second data frame
#' @param by Named character vector for join columns
#' @param ignore_case Logical; whether to ignore case in regex matching
#'
#' @return A data frame with unique column names
#'
#' @keywords internal
safe_regex_inner_join <- function(x, y, by, ignore_case = TRUE) {
  # Perform the join
  result <- regex_inner_join(x, y, by = by, ignore_case = ignore_case)

  # Handle duplicate column names by keeping only the first occurrence
  col_names <- names(result)
  if (anyDuplicated(col_names)) {
    # For each duplicate, keep only the first column
    cols_to_keep <- !duplicated(col_names)
    result <- result[, cols_to_keep, drop = FALSE]
  }

  result
}

#' Match entities with patterns using regex matching
#'
#' @description
#' Given a data frame and a vector of target columns, perform regex matching
#' on the target columns until all entities are matched or we run out of
#' columns to match. Warn about ambiguous matches (duplicate entity_id values).
#' Return a data frame mapping the target columns to the entity patterns.
#'
#' @param data A data frame containing the columns to match
#' @param target_cols Character vector of column names to match
#' @param patterns Data frame containing entity patterns; if NULL, uses
#'   list_entity_patterns()
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#'
#' @return A data frame with the unique combinations of the target columns
#'   mapped to the entity patterns
#'
#' @keywords internal
match_entities_with_patterns <- function(
  data,
  target_cols,
  patterns,
  warn_ambiguous = TRUE
) {
  # Get the .data pronoun for tidy data masking
  .data <- dplyr::.data

  # Get the column names for entity_regex and entity_id in the patterns data
  # frame. These are the ORIGINAL names (not prefixed).
  entity_regex_col <- names(patterns)[6]
  entity_id_col <- names(patterns)[1]

  # Store original pattern column names
  pattern_col_names <- names(patterns)

  # If data frame is empty, return empty result with correct structure
  if (nrow(data) == 0) {
    return(
      patterns |>
        dplyr::slice(0) |>
        dplyr::bind_cols(data)
    )
  }

  # Detect conflicting column names between target_cols and pattern columns
  conflicting_cols <- intersect(target_cols, pattern_col_names)

  # Create a mapping from original target names to temporary names
  # Only rename columns that conflict with pattern column names
  temp_name_map <- stats::setNames(target_cols, target_cols)
  if (length(conflicting_cols) > 0) {
    for (col in conflicting_cols) {
      temp_name_map[[col]] <- paste0("..target..", col)
    }
  }

  # Rename conflicting columns in data before processing
  data_renamed <- data
  for (orig_name in names(temp_name_map)) {
    new_name <- temp_name_map[[orig_name]]
    if (orig_name != new_name && orig_name %in% names(data_renamed)) {
      names(data_renamed)[names(data_renamed) == orig_name] <- new_name
    }
  }

  # Get the temporary target column names
  target_cols_temp <- unname(temp_name_map)

  # Initialize a tibble to hold unmatched unique combinations of target columns
  unmatched_entities <- data_renamed |>
    dplyr::distinct(dplyr::across(dplyr::all_of(target_cols_temp))) |>
    dplyr::select(dplyr::all_of(target_cols_temp)) |>
    dplyr::mutate(.row_id = seq_len(dplyr::n()))

  # Initialize a tibble to hold the matched entities
  # Use pattern columns + temp target columns + .row_id
  all_col_names <- c(pattern_col_names, target_cols_temp)
  matched_entities <- tibble::tibble(
    !!!stats::setNames(
      purrr::map(all_col_names, ~ character(0)),
      all_col_names
    ),
    .row_id = integer()
  )

  # Perform multiple passes of fuzzy matching, one for each target column
  for (col in target_cols_temp) {
    # Skip if the column has all NA values
    if (all(is.na(unmatched_entities[[col]]))) {
      next
    }

    # Perform regex join on the current column for unmatched rows
    # Use safe_regex_inner_join to handle potential duplicate column names
    matched_pass <- safe_regex_inner_join(
      unmatched_entities,
      patterns,
      by = stats::setNames(entity_regex_col, col),
      ignore_case = TRUE
    )

    # Update unmatched_entities by removing matched rows
    unmatched_entities <- unmatched_entities |>
      dplyr::anti_join(matched_pass, by = ".row_id")

    # Combine non-NA matched_pass rows with previous matches
    matched_entities <- dplyr::bind_rows(
      matched_entities,
      matched_pass |>
        dplyr::filter(!is.na(.data[[entity_id_col]]))
    )

    # Break if all unmatched entities are matched
    if (nrow(unmatched_entities) == 0) {
      break
    }
  }

  # Bind any remaining unmatched entities to the matched entities
  result <- dplyr::bind_rows(
    matched_entities,
    unmatched_entities
  ) |>
    dplyr::select(-".row_id")

  # Rename temporary target columns back to original names ONLY if they don't
  # conflict with pattern column names. If there's a conflict, keep the temp
  # name so we preserve both the standardized value and the original target
  # value.
  for (orig_name in names(temp_name_map)) {
    temp_name <- temp_name_map[[orig_name]]
    if (orig_name != temp_name && temp_name %in% names(result)) {
      # Only rename back if orig_name is NOT a pattern column name
      if (!orig_name %in% pattern_col_names) {
        names(result)[names(result) == temp_name] <- orig_name
      }
      # If orig_name IS a pattern column, keep the temp name to preserve both
    }
  }

  # If no patterns columns exist in the result (which happens when all values
  # in data are NA or no matches are found), add these columns with NA values
  missing_cols <- setdiff(pattern_col_names, names(result))
  if (length(missing_cols) > 0) {
    na_patterns <- tibble::tibble(
      !!!stats::setNames(
        purrr::map(missing_cols, ~ rep(NA_character_, nrow(result))),
        missing_cols
      )
    )
    result <- dplyr::bind_cols(result, na_patterns)
  }

  # Only deduplicate if there are truly duplicate columns that we don't need
  # (this shouldn't happen anymore with the fix above)
  if (anyDuplicated(names(result))) {
    result <- result[, !duplicated(names(result)), drop = FALSE]
  }

  # Check for ambiguous matches (multiple matches for the same entity_id) and
  # warn that we will keep only the first match
  if (warn_ambiguous) {
    # Get groups of target values with multiple entity ID matches
    ambiguous_targets <- result |>
      dplyr::group_by(.data[[target_cols[1]]]) |>
      dplyr::filter(!is.na(.data[[entity_id_col]])) |>
      dplyr::summarize(
        entity_ids = list(unique(.data[[entity_id_col]])),
        count = dplyr::n()
      ) |>
      dplyr::filter(.data$count > 1)

    # Warn for each ambiguous match
    if (nrow(ambiguous_targets) > 0) {
      for (i in seq_len(nrow(ambiguous_targets))) {
        original_value <- ambiguous_targets[[target_cols[1]]][i]
        matching_ids <- paste(
          ambiguous_targets$entity_ids[[i]],
          collapse = ", "
        )
        cli::cli_warn(c(
          "!" = paste("Ambiguous match for", original_value),
          "*" = paste(
            "Matches multiple entity IDs:",
            paste(matching_ids, collapse = ", "),
            "\nThe output will contain duplicate rows."
          )
        ))
      }
    }
  }

  result
}
