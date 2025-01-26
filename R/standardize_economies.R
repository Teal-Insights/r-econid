# Design suggestion: instead of name_col and code_col, have a single match_on
# column that takes an ordered vector of column names in the priority order to
# match on. Indicate in roxygen2 documentation that we recommend iso3c first
# if available, name second, and that iso2c is also supported.
#
# We need to handle the case where the `economy_*` columns already exist in the
# data.
#
# We need to enforce that economy_id output codes are unique, including when
# the user defines a custom economy and when we copy the code column value over
# to the economy_id column.

# Define valid output columns
valid_cols <- c(
  "economy_name", "economy_type", "economy_id", "iso3c", "iso2c"
)

#' Standardize Economy Names and Codes
#'
#' @description
#' Standardizes economy names and codes in a dataset by matching them against a
#' predefined list of patterns and ISO codes. Handles aggregate economies.
#'
#' @param data A data frame or tibble containing economy names to standardize
#' @param name_col Name of the column containing economy names
#' @param code_col Optional name of the column containing economy codes
#' @param output_cols Character vector specifying desired output columns.
#'   Options are "economy_name", "economy_id", "economy_type", "iso3c", "iso2c"
#' @param default_economy_type Character; the default economy type to use if not
#'   specified in the data. Options are "country", "institution", or
#'   "aggregate". Defaults to NA. Will be ignored if output_cols do not
#'   include "economy_type".
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#'
#' @return A data frame with standardized economy information merged with the
#'   input data
#'
#' @examples
#' \dontrun{
#' df <- data.frame(economy = c("United States", "China"))
#' standardize_economy(df, name_col = economy)
#' }
standardize_economy <- function(
  data,
  name_col,
  code_col = NULL,
  output_cols = c("economy_id", "economy_name", "economy_type"),
  default_economy_type = NA_character_,
  warn_ambiguous = TRUE
) {
  # Allow user to use either quoted or unquoted column names
  name_col_expr <- rlang::enquo(name_col)
  name_col_name <- rlang::as_name(name_col_expr)

  code_col_expr <- rlang::enquo(code_col)
  if (
    !rlang::quo_is_missing(code_col_expr) &&
      !rlang::quo_is_null(code_col_expr)
  ) {
    code_col_name <- rlang::as_name(code_col_expr)
  } else {
    code_col_name <- NULL
  }

  # Validate inputs
  final_cols <- validate_economy_inputs(
    data,
    name_col_name,
    code_col_name,
    output_cols
  )

  # Convert name column to character UTF-8
  data[[name_col_name]] <- enc2utf8(as.character(data[[name_col_name]]))

  # Use regex match to add a column of economy_ids to the data
  data <- data |>
    dplyr::mutate(economy_id = match_economy_ids(
      names = data[[name_col_name]],
      codes = if (!is.null(code_col_name)) data[[code_col_name]] else NULL,
      warn_ambiguous = warn_ambiguous
    ))

  # Join economy_patterns to the input data
  results <- dplyr::left_join(
    data,
    list_economy_patterns(),
    by = c(economy_id = "economy_id")
  )

  # Drop any valid_cols not in the final_cols
  difference <- setdiff(valid_cols, final_cols)
  results <- results[, !(names(results) %in% difference)]

  # Replace any NA values in economy_name with the value in name_col
  if ("economy_name" %in% final_cols) {
    results$economy_name[
      is.na(results$economy_name)
    ] <- data[[name_col_name]][
      is.na(results$economy_name)
    ]
  }

  # Replace any NA values in economy_id with the value in code_col
  if (!is.null(code_col_name) && "economy_id" %in% final_cols) {
    results$economy_id[
      is.na(results$economy_id)
    ] <- data[[code_col_name]][
      is.na(results$economy_id)
    ]
  }

  # Replace any NA values in economy_type with the default_economy_type
  if ("economy_type" %in% final_cols) {
    results$economy_type[
      is.na(results$economy_type)
    ] <- default_economy_type
  }

  results
}

#' Validate inputs for economy standardization
#'
#' @description
#' Validates the input data frame and column names for economy standardization.
#'
#' @param data A data frame or tibble to validate
#' @param name_col_name Name of the column containing economy names
#' @param code_col_name Optional name of the column containing economy codes
#' @param output_cols Character vector of requested output columns
#'
#' @return List containing validated output_cols and final_cols
#'
#' @keywords internal
validate_economy_inputs <- function(
  data,
  name_col_name,
  code_col_name,
  output_cols
) {
  # Validate data frame
  if (!is.data.frame(data)) {
    cli::cli_abort("Input {.var data} must be a data frame or tibble.")
  }

  # Validate column names
  if (!name_col_name %in% names(data)) {
    cli::cli_abort("Column {.var {name_col_name}} not found in data.")
  }

  if (!is.null(code_col_name) && !code_col_name %in% names(data)) {
    cli::cli_abort("Column {.var {code_col_name}} not found in data.")
  }

  # Validate output_cols
  invalid_cols <- setdiff(output_cols, valid_cols)
  if (length(invalid_cols) > 0) {
    cli::cli_abort("Invalid output columns: {.val {invalid_cols}}")
  }

  output_cols
}

#' Match Economy Ids
#'
#' @description
#' Given vectors of names and codes, match them against a list of patterns and
#' return a vector of economy ids.
#'
#' @param names Character vector of economy names to standardize
#' @param codes Optional character vector of economy codes
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#'
#' @return A vector of economy ids
#'
#' @keywords internal
match_economy_ids <- function(
  names,
  codes = NULL,
  warn_ambiguous = TRUE
) {
  # Initialize results
  results <- c()

  # Process each name
  for (i in seq_along(names)) {
    current_name <- names[i]
    current_code <- if (!is.null(codes)) {
      codes[i]
    } else {
      NULL
    }

    # Try to match the current code (if provided)
    if (!is.null(current_code)) {
      code_match_results <- try_regex_match(current_code)
    } else {
      code_match_results <- c()
    }

    # Try to match the current name
    name_match_results <- try_regex_match(current_name)

    # Take the union of the two match results
    match_results <- unique(c(code_match_results, name_match_results))

    # Warn if there are multiple matches
    if (warn_ambiguous && length(match_results) > 1) {
      cli::cli_warn(c(
        "!" = "Ambiguous match for {.val {current_name}}",
        "*" = paste(
          "Matches multiple patterns:",
          paste(match_results, collapse = ", ")
        )
      ))
    }

    # Add the first match result to the results vector
    results <- append(results, match_results[1])
  }

  results
}

#' Try Regex Pattern Match
#'
#' @description
#' Attempts to match a string and return matching economy_id(s) using regex
#' patterns from economy_patterns.
#'
#' @param name Character string of economy name or code
#'
#' @return Character vector of economy_ids
#'
#' @keywords internal
try_regex_match <- function(name) {
  patterns <- list_economy_patterns()

  grepl_mask <- function(pattern, x) {
    grepl(pattern, x, ignore.case = TRUE, perl = TRUE)
  }

  # Get a boolean vector of which regex patterns match the name
  matches_case_insensitive <- vapply(
    patterns$economy_regex,
    grepl_mask,
    x = name,
    FUN.VALUE = logical(1)
  )

  # Return the economy_ids of the patterns that match the name
  patterns$economy_id[
    matches_case_insensitive
  ]
}