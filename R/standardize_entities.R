# Define valid output columns
valid_cols <- c(
  "entity_id", "entity_name", "entity_type", "iso3c", "iso2c"
)

#' Standardize entity Names and Codes
#'
#' @description
#' Standardizes entity names and codes in a dataset by matching them against a
#' predefined list of patterns and ISO codes. Handles aggregate entities.
#'
#' @param data A data frame or tibble containing entity names to standardize
#' @param name_col Name of the column containing entity names
#' @param code_col Optional name of the column containing entity codes
#' @param output_cols Character vector specifying desired output columns.
#'   Options are "entity_name", "entity_id", "entity_type", "iso3c", "iso2c"
#' @param default_entity_type Character; the default entity type to use if not
#'   specified in the data. Options are "country", "institution", or
#'   "aggregate". Defaults to NA. Will be ignored if output_cols do not
#'   include "entity_type".
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#' @param overwrite Logical; whether to overwrite existing entity_* columns
#' @param warn_overwrite Logical; whether to warn when overwriting existing
#'   entity_* columns. Defaults to TRUE.
#'
#' @return A data frame with standardized entity information merged with the
#'   input data
#'
#' @examples
#' \dontrun{
#' df <- data.frame(entity = c("United States", "China"))
#' standardize_entity(df, name_col = entity)
#' }
#'
#' @export
standardize_entities <- function(
  data,
  name_col,
  code_col = NULL,
  output_cols = c("entity_id", "entity_name", "entity_type"),
  default_entity_type = NA_character_,
  warn_ambiguous = TRUE,
  overwrite = TRUE,
  warn_overwrite = TRUE
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

  # Check for existing entity columns
  existing_cols <- intersect(names(data), output_cols)
  if (length(existing_cols) > 0) {
    if (warn_overwrite) {
      cli::cli_warn(
        "Overwriting existing entity columns: {.val {existing_cols}}"
      )
    }
  }

  # Remove existing entity columns
  data <- data[, setdiff(names(data), existing_cols), drop = FALSE]

  # Validate inputs
  final_cols <- validate_entity_inputs(
    data,
    name_col_name,
    code_col_name,
    output_cols
  )

  # Convert name column to character UTF-8
  data[[name_col_name]] <- enc2utf8(as.character(data[[name_col_name]]))

  # Use regex match to add a column of entity_ids to the data
  data <- data |>
    dplyr::mutate(entity_id = match_entity_ids(
      names = data[[name_col_name]],
      codes = if (!is.null(code_col_name)) data[[code_col_name]] else NULL,
      warn_ambiguous = warn_ambiguous
    ))

  # Join entity_patterns to the input data
  results <- dplyr::left_join(
    data,
    list_entity_patterns(),
    by = c(entity_id = "entity_id")
  )

  # Drop any valid_cols not in the final_cols
  difference <- setdiff(c(valid_cols, "entity_regex"), final_cols)
  results <- results[, !(names(results) %in% difference)]

  # Replace any NA values in entity_name with the value in name_col
  if ("entity_name" %in% final_cols) {
    results$entity_name[
      is.na(results$entity_name)
    ] <- data[[name_col_name]][
      is.na(results$entity_name)
    ]
  }

  # Replace any NA values in entity_id with the value in code_col
  if (!is.null(code_col_name) && "entity_id" %in% final_cols) {
    results$entity_id[
      is.na(results$entity_id)
    ] <- data[[code_col_name]][
      is.na(results$entity_id)
    ]
  }

  # Replace any NA values in entity_type with the default_entity_type
  if ("entity_type" %in% final_cols) {
    results$entity_type[
      is.na(results$entity_type)
    ] <- default_entity_type
  }

  # Reorder the columns to match the output_cols order
  selected_cols <- c(output_cols, setdiff(names(results), output_cols))
  results <- results[, selected_cols]

  results
}

#' Validate inputs for entity standardization
#'
#' @description
#' Validates the input data frame and column names for entity standardization.
#'
#' @param data A data frame or tibble to validate
#' @param name_col_name Name of the column containing entity names
#' @param code_col_name Optional name of the column containing entity codes
#' @param output_cols Character vector of requested output columns
#'
#' @return List containing validated output_cols and final_cols
#'
#' @keywords internal
validate_entity_inputs <- function(
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

#' Match entity Ids
#'
#' @description
#' Given vectors of names and codes, match them against a list of patterns and
#' return a vector of entity ids.
#'
#' @param names Character vector of entity names to standardize
#' @param codes Optional character vector of entity codes
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#'
#' @return A vector of entity ids
#'
#' @keywords internal
match_entity_ids <- function(
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
#' Attempts to match a string and return matching entity_id(s) using regex
#' patterns from entity_patterns.
#'
#' @param name Character string of entity name or code
#'
#' @return Character vector of entity_ids
#'
#' @keywords internal
try_regex_match <- function(name) {
  patterns <- list_entity_patterns()

  grepl_mask <- function(pattern, x) {
    grepl(pattern, x, ignore.case = TRUE, perl = TRUE)
  }

  # Get a boolean vector of which regex patterns match the name
  matches_case_insensitive <- vapply(
    patterns$entity_regex,
    grepl_mask,
    x = name,
    FUN.VALUE = logical(1)
  )

  # Return the entity_ids of the patterns that match the name
  patterns$entity_id[
    matches_case_insensitive
  ]
}
