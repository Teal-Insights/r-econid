# Define valid output columns
valid_cols <- c(
  "entity_id", "entity_name", "entity_type", "iso3c", "iso2c"
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
#' @param default_entity_type Character; the default entity type to use for
#'   entities that do not match any of the patterns. Options are "economy",
#'   "organization", "aggregate", or "other". If this argument is not supplied,
#'   the default value will be NA_character_. Argument will be ignored if
#'   output_cols do not include "entity_type".
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#' @param overwrite Logical; whether to overwrite existing entity_* columns
#' @param warn_overwrite Logical; whether to warn when overwriting existing
#'   entity_* columns. Defaults to TRUE.
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
  default_entity_type = NA_character_,
  warn_ambiguous = TRUE,
  overwrite = TRUE,
  warn_overwrite = TRUE
) {
  # Gather the columns from ...
  target_cols_syms <- rlang::ensyms(...)

  # Turn syms into strings
  target_cols_names <- purrr::map_chr(target_cols_syms, rlang::as_name)

  # Validate inputs
  final_cols <- validate_entity_inputs(
    data,
    target_cols_names,
    output_cols,
    prefix
  )

  # Apply prefix to output column names if provided
  prefixed_output_cols <- output_cols
  if (!is.null(prefix)) {
    prefixed_output_cols <- paste(prefix, output_cols, sep = "_")
  }

  # Check for existing entity columns
  existing_cols <- intersect(names(data), prefixed_output_cols)
  if (length(existing_cols) > 0) {
    # Ignore warn_overwrite if overwrite is FALSE
    if (overwrite && warn_overwrite) {
      cli::cli_warn(
        "Overwriting existing entity columns: {.val {existing_cols}}"
      )
    }
  }

  # Remove existing entity columns if overwrite is TRUE
  if (overwrite && length(existing_cols) > 0) {
    data <- data[, setdiff(names(data), existing_cols), drop = FALSE]
  }

  # Convert all target columns to character UTF-8
  for (col in target_cols_names) {
    data[[col]] <- enc2utf8(as.character(data[[col]]))
  }

  # Use regex match to add a column of entity_ids to the data
  data <- data |>
    dplyr::mutate(entity_id = match_entity_ids_multi(
      data = data,
      target_cols = target_cols_names,
      warn_ambiguous = warn_ambiguous
    ))

  # Rename entity_patterns column names by adding prefix if provided
  entity_patterns <- list_entity_patterns()
  if (!is.null(prefix)) {
    names(entity_patterns) <- paste(prefix, names(entity_patterns), sep = "_")
  }

  # Join entity_patterns to the input data
  results <- dplyr::left_join(
    data,
    entity_patterns,
    by = c(entity_id = "entity_id")
  )

  # Drop any prefixed valid_cols not in the final_cols
  prefixed_valid_cols <- paste(prefix, valid_cols, sep = "_")
  difference <- setdiff(c(prefixed_valid_cols, "entity_regex"), final_cols)
  results <- results[, !(names(results) %in% difference)]

  # Replace any NA values in entity_name with the value in the first target
  # column
  if ("entity_name" %in% output_cols) {
    results$entity_name[
      is.na(results$entity_name)
    ] <- data[[target_cols_names[1]]][
      is.na(results$entity_name)
    ]
  }

  # Replace any NA values in entity_type with the default_entity_type
  if ("entity_type" %in% output_cols) {
    results$entity_type[
      is.na(results$entity_type)
    ] <- default_entity_type
  }

  # Determine the position of the first target column
  first_target_col_pos <- which(names(results) == target_cols_names[1])

  # Get all column names except the output columns and the first target column
  other_cols <- setdiff(names(results), c(final_cols, target_cols_names[1]))

  # Split other columns into those before and after the first target column
  cols_before <- other_cols[
    other_cols %in% names(results)[1:(first_target_col_pos - 1)]
  ]
  cols_after <- setdiff(other_cols, cols_before)

  # Reorder columns
  results <- results |>
    dplyr::select(
      dplyr::all_of(cols_before),
      dplyr::all_of(final_cols),
      dplyr::all_of(target_cols_names),
      dplyr::all_of(cols_after)
    )

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
#'
#' @return Character vector of validated output columns
#'
#' @keywords internal
validate_entity_inputs <- function(
  data,
  target_cols_names,
  output_cols,
  prefix
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

  # Validate output_cols against prefixed valid_cols
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

#' Match entity IDs using multiple columns
#'
#' @description
#' Given a data frame and a vector of column names, match the values in those
#' columns against a list of patterns and return a vector of entity ids. The
#' function tries each column in sequence, prioritizing matches from earlier
#' columns.
#'
#' @param data A data frame containing the columns to match
#' @param target_cols Character vector of column names to match
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#'
#' @return A vector of entity ids
#'
#' @keywords internal
match_entity_ids_multi <- function(
  data,
  target_cols,
  warn_ambiguous = TRUE
) {
  # Initialize results vector with NAs
  n_rows <- nrow(data)
  results <- rep(NA_character_, n_rows)

  # Process each row
  for (i in seq_len(n_rows)) {
    # Try each target column in sequence
    for (col in target_cols) {
      current_value <- data[[col]][i]

      # Skip NA or empty values
      if (is.na(current_value) || current_value == "") {
        next
      }

      # Try to match the current value
      match_results <- try_regex_match(current_value)

      # If we found matches
      if (length(match_results) > 0) {
        # Warn if there are multiple matches
        if (warn_ambiguous && length(match_results) > 1) {
          cli::cli_warn(c(
            "!" = "Ambiguous match for {.val {current_value}}",
            "*" = paste(
              "Matches multiple patterns:",
              paste(match_results, collapse = ", ")
            )
          ))
        }

        # Store the first match and break out of the column loop
        results[i] <- match_results[1]
        break
      }
    }
  }

  results
}
