test_that("process_custom_economies handles valid inputs", {
  custom_economies <- list(
    "Test Economy" = "TST",
    "Complex Economy" = list(
      id = "CPX",
      aliases = c("Complex", "CE")
    )
  )
  
  result <- process_custom_economies(custom_economies)
  
  expect_s3_class(result, "tbl_df")
  expect_named(result, c("economy_name", "economy_regex", "iso3c", "iso2c"))
  expect_equal(result$economy_name, c("Test Economy", "Complex Economy"))
  expect_equal(result$iso3c, c("TST", "CPX"))
})

test_that("process_custom_economies validates inputs", {
  expect_error(
    process_custom_economies("not a list"),
    "must be a list"
  )
  
  expect_error(
    process_custom_economies(list(Invalid = list(name = "test"))),
    "must have an 'id' specified"
  )
})

test_that("validate_custom_names handles valid inputs", {
  # Test named vector
  named_vector <- c("United States" = "USA", "United Kingdom" = "GBR")
  expect_equal(validate_custom_names(named_vector), named_vector)
  
  # Test named list
  named_list <- list("United States" = "USA", "United Kingdom" = "GBR")
  expect_equal(validate_custom_names(named_list), c("United States" = "USA", "United Kingdom" = "GBR"))
})

test_that("validate_custom_names catches invalid inputs", {
  expect_error(validate_custom_names(c("USA", "GBR")), "must be a named vector")
  expect_error(validate_custom_names(list(a = 1, b = 2)), "must be character values")
})

test_that("create_economy_regex generates correct patterns", {
  expect_equal(
    create_economy_regex("United States"),
    "united.?states"
  )
  
  expect_equal(
    create_economy_regex("Test.Pattern(*)"),
    "test\\.pattern\\(\\*\\)"
  )
})

test_that("try_iso_match handles ISO code matching", {
  test_patterns <- tibble::tibble(
    economy_name = c("United States", "France"),
    economy_regex = c("united.?states", "france"),
    iso3c = c("USA", "FRA"),
    iso2c = c("US", "FR")
  )
  
  # Test exact ISO3 match
  usa_match <- try_iso_match("USA", test_patterns)
  expect_equal(usa_match$name, "United States")
  expect_equal(usa_match$iso3c, "USA")
  
  # Test case insensitive match
  fra_match <- try_iso_match("fra", test_patterns)
  expect_equal(fra_match$name, "France")
  
  # Test no match
  no_match <- try_iso_match("XYZ", test_patterns)
  expect_null(no_match)
})

test_that("try_regex_match handles pattern matching", {
  test_patterns <- tibble::tribble(
    ~economy_name,    ~economy_regex,      ~iso3c, ~iso2c,
    "United States",  "united.?states",    "USA",  "US",
    "United Kingdom", "united.?kingdom",   "GBR",  "GB",
    "US",            "^us$",              "USA",  "US"
  )
  
  # Test basic match
  us_match <- try_regex_match("United States", test_patterns, warn_ambiguous = TRUE)
  expect_equal(us_match$name, "United States")
  expect_equal(us_match$iso3c, "USA")
  
  # Test ambiguous match warning
  expect_warning(
    try_regex_match("US", test_patterns, warn_ambiguous = TRUE),
    "Ambiguous match"
  )
  
  # Test no warning when warn_ambiguous = FALSE
  expect_no_warning(
    try_regex_match("US", test_patterns, warn_ambiguous = FALSE)
  )
})

test_that("standardize_with_custom_names applies mappings correctly", {
  custom_names <- c(
    "usa" = "United States",
    "uk" = "United Kingdom"
  )
  
  input <- c("USA", "uk", "France", NA)
  expected <- c("United States", "United Kingdom", "France", NA)
  
  result <- standardize_with_custom_names(input, custom_names)
  expect_equal(result, expected)
})


test_that("basic country standardization works", {
  test_df <- tibble::tribble(
    ~economy,         ~code,
    "United States",  "USA",
    "united.states",  NA,
    "us",             "US",
    "EU",             NA,
    "NotACountry",    NA
  )
  
  result <- standardize_economy(test_df, name_col = economy, code_col = code)
  
  expect_equal(result$economy_name, c("United States", "United States", "United States", "European Union", "NotACountry"))
  expect_equal(result$economy_id, c("USA", "USA", "USA", "EUU", NA_character_))
  expect_equal(result$economy_type, c(rep("Country/Economy", 3), "Aggregate", "Aggregate"))
})

test_that("custom name mappings work correctly", {
  test_df <- tibble::tribble(
    ~country,
    "America",
    "UK",
    "MyCustomEconomy"
  )
  
  result <- standardize_economy(
    test_df,
    name_col = country,
    custom_names = list("America" = "United States", "UK" = "United Kingdom"),
    custom_economies = list(
      "MyCustomEconomy" = list(
        id = "MCE",
        aliases = c("CustomEconomy", "SpecialZone")
      )
    )
  )
  
  expect_equal(result$economy_name, c("United States", "United Kingdom", "MyCustomEconomy"))
  expect_equal(result$economy_id, c("USA", "GBR", "MCE"))
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

test_that("aggregate detection and reporting works", {
  test_df <- tibble::tribble(
    ~economy,
    "East Asia & Pacific",
    "Euro area",
    "High income"
  )
  
  expect_message(
    standardize_economy(test_df, name_col = economy),
    "classified as aggregates"
  )
  
  silent_result <- standardize_economy(test_df, name_col = economy, show_aggregates = FALSE)
  expect_equal(silent_result$economy_type, rep("Aggregate", 3))
})

test_that("output column selection works", {
  test_df <- tibble::tribble(~economy, "Germany")
  
  minimal_result <- standardize_economy(test_df, name_col = economy, output_cols = "name")
  expect_named(minimal_result, c("economy_name"))
  
  full_result <- standardize_economy(test_df, name_col = economy, output_cols = c("name", "id", "type", "iso3c", "iso2c"))
  expect_named(full_result, c("economy_name", "economy_id", "economy_type", "iso3c", "iso2c"))
})

test_that("error handling works correctly", {
  expect_error(standardize_economy("not a dataframe", name_col = economy), "must be a data frame")
  
  test_df <- tibble::tribble(~wrong_col, "USA")
  expect_error(standardize_economy(test_df, name_col = economy), "not found in data")
})

test_that("ambiguous matches trigger warnings", {
  test_df <- tibble::tribble(
    ~economy,
    "Congo",  # Matches both Congo Dem. Rep. and Congo Rep.
    "Guinea"  # Matches Guinea and Guinea-Bissau
  )
  
  expect_warning(
    standardize_economy(test_df, name_col = economy),
    "Ambiguous match"
  )
  
  silent_result <- suppressWarnings(
    standardize_economy(test_df, name_col = economy, warn_ambiguous = FALSE)
  )
  expect_equal(nrow(silent_result), 2)
})
