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
#' @param fill_mapping Named character vector specifying how to fill missing
#'   values when no entity match is found. Names should be output column names
#'   (without prefix), and values should be input column names (from `...`).
#'   For example, `c(entity_id = "country_code", entity_name = "country_name")`
#'   will fill missing entity_id values with values from the country_code column
#'   and missing entity_name values with values from the country_name column.
#' @param default_entity_type Character; the default entity type to use for
#'   entities that do not match any of the patterns. Options are "economy",
#'   "organization", "aggregate", or "other". If this argument is not supplied,
#'   the default value will be NA_character_. Argument will be ignored if
#'   output_cols do not include "entity_type".
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#' @param overwrite Logical; whether to overwrite existing entity_* columns
#' @param warn_overwrite Logical; whether to warn when overwriting existing
#'   entity_* columns. Defaults to TRUE.
#' @param .before Column name or position to insert the standardized columns
#'   before. Defaults to the first target column. Can be a character vector
#'   specifying the column name or a numeric value specifying the column index.
#'   If the specified column is not found in the data, an error is thrown.
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

  # Rename entity_patterns column names by adding prefix if provided
  entity_patterns <- list_entity_patterns()
  if (!is.null(prefix)) {
    names(entity_patterns) <- paste(prefix, names(entity_patterns), sep = "_")
  }

  # Use regex match to map entities to patterns
  entity_mapping <- match_entities_with_patterns(
    data = data,
    target_cols = target_cols_names,
    patterns = entity_patterns,
    warn_ambiguous = warn_ambiguous
  )

  # Select only the prefixed output columns and original data columns
  entity_mapping <- entity_mapping |>
    dplyr::select(
      dplyr::all_of(prefixed_output_cols),
      dplyr::all_of(names(data))
    )

  # Join entity_mapping to the input data
  results <- dplyr::left_join(
    data,
    entity_mapping,
    by = target_cols_names
  )

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

      # Only apply mapping if output column exists
      if (prefixed_output %in% names(results)) {
        # Fill NA values in the output column with values from the input column
        # but only for rows with no matches
        results[no_match_mask, prefixed_output] <- results[
          no_match_mask, input_col
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
        results[[prefixed_entity_type]], default_entity_type
      )
    }
  }

  # Reorder columns
  if (!rlang::quo_is_null(rlang::enquo(.before))) {
    results <- results |>
      dplyr::relocate(
        dplyr::any_of(prefixed_output_cols), .before = {{ .before }}
      )
  } else {
    results <- results |>
      dplyr::relocate(
        dplyr::any_of(prefixed_output_cols), .before = 1
      )
  }

  # Check for ambiguous matches (multiple matches for the same entity_id) and
  # warn that we will keep only the first match
  if (warn_ambiguous) {
    # Get groups of target values with multiple entity ID matches
    ambiguous_targets <- results |>
      dplyr::group_by(!!rlang::sym(target_cols_names[1])) |>
      dplyr::summarize(
        entity_ids = list(unique(!!rlang::sym(names(entity_patterns)[1]))),
        count = dplyr::n()
      ) |>
      dplyr::filter(count > 1) # nolint

    # Warn for each ambiguous match
    if (nrow(ambiguous_targets) > 0) {
      for (i in seq_len(nrow(ambiguous_targets))) {
        cli::cli_warn(c(
          "!" = paste(
            "Ambiguous match for",
            ambiguous_targets[[target_cols_names[1]]][i],
            "Matches multiple entity IDs:",
            paste(ambiguous_targets$entity_ids[[i]], collapse = ", "),
            "\nThe output will contain duplicate rows."
          )
        ))
      }
    }
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
    if (!is.character(fill_mapping) || is.null(names(fill_mapping)) ||
          any(names(fill_mapping) == "")) {
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

#' Match entities with patterns using fuzzyjoin
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
  # Get the column names for entity_regex and entity_id in the patterns data
  # frame
  entity_regex_col <- names(patterns)[6]
  entity_id_col <- names(patterns)[1]

  # If data frame is empty, return empty result with correct structure
  if (nrow(data) == 0) {
    return(
      patterns |>
        dplyr::slice(0) |>
        dplyr::bind_cols(data)
    )
  }

  # Initialize a tibble to hold unmatched unique combinations of target columns
  unmatched_entities <- data |>
    dplyr::distinct(dplyr::across(dplyr::all_of(target_cols))) |>
    dplyr::select(dplyr::all_of(target_cols)) |>
    dplyr::mutate(row_id = seq_len(dplyr::n()))

  # Initialize a tibble to hold the matched entities with corresponding
  # entity_patterns columns
  col_names <- c(names(patterns), target_cols)
  matched_entities <- tibble::tibble(
    !!!setNames(purrr::map(col_names, ~ c()), col_names), row_id = integer()
  )

  # Perform multiple passes of fuzzy matching, one for each target column
  for (col in target_cols) {
    # Skip if the column has all NA values
    if (all(is.na(unmatched_entities[[col]]))) {
      next
    }

    # Perform regex join on the current column for unmatched rows
    matched_pass <- fuzzyjoin::regex_inner_join(
      unmatched_entities,
      patterns,
      by = setNames(entity_regex_col, col),
      ignore_case = TRUE
    )

    # Find which row IDs were successfully matched
    matched_ids <- matched_pass |>
      dplyr::pull(row_id) |> # nolint
      unique()

    # Update unmatched_entities by removing matched rows
    unmatched_entities <- unmatched_entities |>
      dplyr::anti_join(dplyr::tibble(row_id = matched_ids), by = "row_id")

    # Combine non-NA matched_pass rows with previous matches
    matched_entities <- dplyr::bind_rows(
      matched_entities,
      matched_pass |>
        dplyr::filter(!is.na(!!rlang::sym(entity_id_col)))
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
    dplyr::select(-row_id) # nolint

  # Check for ambiguous matches (multiple matches for the same entity_id) and
  # warn that we will keep only the first match
  if (warn_ambiguous) {
    # Get groups of target values with multiple entity ID matches
    ambiguous_targets <- result |>
      dplyr::group_by(!!rlang::sym(target_cols[1])) |>
      dplyr::filter(!is.na(!!rlang::sym(entity_id_col))) |>
      dplyr::summarize(
        entity_ids = list(unique(!!rlang::sym(entity_id_col))),
        count = length(unique(!!rlang::sym(entity_id_col))),
        .groups = "drop"
      ) |>
      dplyr::filter(count > 1)

    # Warn for each ambiguous match
    if (nrow(ambiguous_targets) > 0) {
      for (i in seq_len(nrow(ambiguous_targets))) {
        original_value <- ambiguous_targets[[target_cols[1]]][i]
        matching_ids <- paste(ambiguous_targets$entity_ids[[i]], collapse = ", ")
        cli::cli_warn(c(
          "!" = "Ambiguous match for {.val {original_value}}",
          "*" = paste(
            "Matches multiple entity IDs:", matching_ids,
            "\nThe output will contain duplicate rows."
          )
        ))
      }
    }
  }

  result
}
