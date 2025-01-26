test_that("basic country standardization works", {
  test_df <- tibble::tribble(
    ~economy,         ~code,
    "United States",  "USA",
    "united.states",  NA,
    "us",             "US",
    "EU",             NA,
    "NotACountry",    NA
  )

  expect_message(
    result <- standardize_economy(test_df, name_col = economy, code_col = code),
    "classified as aggregates"
  )

  expect_equal(result$economy_name, c("United States", "United States", "United States", "EU", "NotACountry"))
  expect_equal(result$economy_id, c("USA", "USA", "USA", NA_character_, NA_character_))
  expect_equal(result$economy_type, c(rep("Country/Economy", 3), "Aggregate", "Aggregate"))
})

test_that("ISO code matching takes precedence", {
  test_df <- tibble::tribble(
    ~name,    ~code,
    "USA",    "FRA",  # Should prefer ISO code match
    "France", NA
  )

  result <- standardize_economy(test_df, name_col = name, code_col = code)
  expect_equal(result$economy_id, c("FRA", "FRA"))
})

test_that("standardization works without code column", {
  test_df <- tibble::tribble(
    ~country,
    "United States",
    "France",
    "NotACountry"
  )

  result <- standardize_economy(test_df, name_col = country)

  expect_equal(result$economy_name, c("United States", "France", "NotACountry"))
  expect_equal(result$economy_id, c("USA", "FRA", NA_character_))
  expect_equal(result$economy_type, c("Country/Economy", "Country/Economy", "Aggregate"))
})

test_that("standardization fails with invalid output columns", {
  test_df <- tibble::tribble(
    ~country,
    "United States"
  )

  # Test single invalid column
  expect_error(
    standardize_economy(test_df, name_col = country, output_cols = "invalid_col"),
    "Invalid output columns: \"invalid_col\""
  )

  # Test mix of valid and invalid columns
  expect_error(
    standardize_economy(test_df, name_col = country, 
                       output_cols = c("economy_name", "bad_col", "worse_col")),
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
