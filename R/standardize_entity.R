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

    # Remove the temporary target columns, we now have the standardized versions
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
