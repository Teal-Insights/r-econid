# Design notes:
#
# Instead of a custom names vector the same length as the input data, we should
# allow users to define a dict-like object with any subset of the input data
# columns as the keys, and the values being the new names to map to. The rest
# of the input data will be standardized as normal.
#
# When allowing users to extend the economy_patterns with custom patterns, we
# should let them do it once at the top of their script rather than as a
# argument. Also may want to allow custom regex rather than always construct
# it programmatically.
#
# The order of operations is important for custom names and custom economies.
# Custom names is mapping input names to output names, whereas custom economies
# is mapping the standardized output name to a standardized identifier and
# list of aliases. If we apply cutom names first, then the aliases list has to
# include the standardized output name, and the aliases are irrelevant.
# (Assuming we have supplied a custom name for the custom economy. Do we have a
# test case where that's not the case?) Quite possibly having custom names
# be separate from custom economies is unnecessarily complicated, especially
# if custom economies takes an alias list.


#' Standardize Economy Names and Codes
#'
#' @description
#' Standardizes economy names and codes in a dataset by matching them against a
#' predefined list of patterns and ISO codes. Supports custom mappings and
#' handles aggregate economies.
#'
#' @param data A data frame or tibble containing economy names to standardize
#' @param name_col Name of the column containing economy names
#' @param code_col Optional name of the column containing economy codes
#' @param output_cols Character vector specifying desired output columns.
#'   Options are "economy_name", "economy_id","economy_type", "iso3c", "iso2c"
#' @param custom_economies Optional list of custom economy definitions
#' @param custom_names Optional named vector or list the same length as the
#'   number of rows in the input data, for direct mapping to name_col
#' @param show_aggregates Logical; whether to report detected aggregate
#'   economies
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#'
#' @return A data frame with standardized economy information merged with the
#'   input data
#'
#' @examples
#' \dontrun{
#' df <- data.frame(economy = c("USA", "European Union"))
#' standardize_economy(df, name_col = economy)
#' }
standardize_economy <- function(
  data,
  name_col,
  code_col = NULL,
  output_cols = c("economy_name", "economy_id", "economy_type"),
  custom_economies = NULL,
  custom_names = NULL,
  show_aggregates = TRUE,
  warn_ambiguous = TRUE
) {
  # Allow user to use either quoted or unquoted column names
  name_col_expr <- rlang::enquo(name_col)
  name_col_name <- rlang::as_name(name_col_expr)
  
  code_col_expr <- rlang::enquo(code_col)
  if (!rlang::quo_is_missing(code_col_expr) && !rlang::quo_is_null(code_col_expr)) {
    code_col_name <- rlang::as_name(code_col_expr)
  } else {
    code_col_name <- NULL
  }

  # Input validation
  if (!is.data.frame(data)) {
    cli::cli_abort("Input {.var data} must be a data frame or tibble.")
  }

  if (!name_col_name %in% names(data)) {
    cli::cli_abort("Column {.var {name_col_name}} not found in data.")
  }

  if (!is.null(code_col_name) && !code_col_name %in% names(data)) {
    cli::cli_abort("Column {.var {code_col_name}} not found in data.")
  }

  # Validate and process custom inputs
  if (!is.null(custom_economies)) {
    custom_patterns <- process_custom_economies(custom_economies)
  } else {
    custom_patterns <- NULL
  }

  if (!is.null(custom_names)) {
    validated_names <- validate_custom_names(custom_names)
  } else {
    validated_names <- NULL
  }

  # Convert name column to character UTF-8
  data[[name_col_name]] <- enc2utf8(as.character(data[[name_col_name]]))

  # Map output column names
  col_mapping <- c(
    economy_name = "economy_name",
    economy_type = "economy_type",
    economy_id = "economy_id",
    iso3c = "iso3c",
    iso2c = "iso2c"
  )

  # Validate output_cols
  output_cols <- match.arg(output_cols, names(col_mapping), several.ok = TRUE)
  final_cols <- unname(col_mapping[output_cols])

  # Perform standardization
  results <- standardize_economies_impl(
    names = data[[name_col_name]],
    codes = if (!is.null(code_col_name)) data[[code_col_name]] else NULL,
    custom_patterns = custom_patterns,
    custom_names = validated_names,
    warn_ambiguous = warn_ambiguous
  )

  # Report aggregates if requested
  if (show_aggregates && length(results$aggregates) > 0) {
    cli::cli_inform(c(
      "!" = "The following unique entries were classified as aggregates:",
      "*" = results$aggregates
    ))
  }

  # Prepare output
  out_data <- results$data[final_cols]

  # Bind with original data, excluding the name column
  dplyr::bind_cols(
    data[setdiff(names(data), name_col_name)],
    out_data
  )
}

#' Process Custom Economy Definitions
#'
#' @description
#' Validates and processes custom economy definitions into a standardized format
#' for use in economy name matching. Custom economies can be defined with a
#' simple ID or with a list containing an ID and aliases.
#'
#' @param custom_economies A list of custom economy definitions. Each element
#'   can be either a character string representing the economy's ID, or a list
#'   with elements `id` (required) and `aliases` (optional).
#'
#' @return A tibble containing processed economy patterns, with columns
#'   `economy_name`, `economy_regex`, `iso3c`, and `iso2c`.
#'
#' @keywords internal
process_custom_economies <- function(custom_economies) {
  # Validates and converts custom_economies to standardized format
  if (!is.list(custom_economies)) {
    cli::cli_abort("custom_economies must be a list")
  }

  # Process each entry into a standard format
  patterns <- purrr::imap_dfr(custom_economies, function(value, name) {
    if (is.character(value) && length(value) == 1) {
      # Simple case: just an ID provided
      tibble::tibble(
        economy_name = name,
        economy_regex = create_economy_regex(name),
        iso3c = value,
        iso2c = NA_character_
      )
    } else if (is.list(value)) {
      # Complex case with additional details
      id <- value$id
      if (is.null(id)) {
        cli::cli_abort("Each custom economy must have an 'id' specified")
      }

      # Combine all identifiers and wrap in word boundaries
      aliases <- c(name, unlist(value$aliases))
      pattern <- paste0("^(", paste(aliases, collapse="|"), ")$")
      
      tibble::tibble(
        economy_name = name,
        economy_regex = create_economy_regex(pattern),
        iso3c = id,
        iso2c = NA_character_
      )
    } else {
      cli::cli_abort("Invalid format for custom economy: {.val {name}}")
    }
  })

  patterns
}

#' Validate Custom Name Mappings
#'
#' @description
#' Validates custom name mappings to ensure they meet required format
#' specifications.
#'
#' @param custom_names A named vector or list of custom name mappings.
#'   The names of the vector or list are the original names to be replaced,
#'   and the values are the replacement names.
#'
#' @return A validated character vector of custom names, with names
#'   corresponding to the original names to be replaced.
#'
#' @keywords internal
validate_custom_names <- function(custom_names) {
  if (is.null(names(custom_names))) {
    cli::cli_abort("custom_names must be a named vector or list")
  }

  if (any(names(custom_names) == "")) {
    cli::cli_abort("All elements in custom_names must be named")
  }

  # Convert to character vector if it's a list
  if (is.list(custom_names)) {
    custom_names <- unlist(custom_names, use.names = TRUE)
  }

  # Ensure all elements are character
  if (!is.character(custom_names)) {
    cli::cli_abort("All elements in custom_names must be character values")
  }

  custom_names
}

#' Create Economy Name Regex Pattern
#'
#' @description
#' Creates a regular expression pattern from an economy name, following
#' standardized rules for flexible matching. This function converts the input
#' name to lowercase, escapes special regex characters, and replaces spaces
#' with a flexible whitespace pattern (`.?`).
#'
#' @param name Character string containing the economy name.
#'
#' @return Character string containing the regex pattern.
#'
#' @keywords internal
create_economy_regex <- function(name) {
  # Helper to create regex pattern from name
  # Converts name to regex pattern following our standard approach

  # Convert to lowercase
  pattern <- tolower(name)

  # Escape special regex characters
  pattern <- gsub("([.|()\\^{}+$*?])", "\\\\\\1", pattern)

  # Replace spaces with flexible whitespace pattern
  pattern <- gsub("\\s+", ".?", pattern)

  pattern
}

#' Implementation of Economy Name Standardization
#'
#' @description
#' Core implementation of economy name standardization logic.
#'
#' @param names Character vector of economy names to standardize
#' @param codes Optional character vector of economy codes
#' @param custom_patterns Optional tibble of custom matching patterns
#' @param custom_names Optional named vector of custom name mappings
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#'
#' @return List containing standardized data and detected aggregates
#'
#' @keywords internal
standardize_economies_impl <- function(
  names,
  codes = NULL,
  custom_patterns = NULL,
  custom_names = NULL,
  warn_ambiguous = TRUE
) {
  # Initialize results
  n <- length(names)
  results <- tibble::tibble(
    economy_name = rep(NA_character_, n),
    economy_id = rep(NA_character_, n),
    economy_type = rep(NA_character_, n),
    iso3c = rep(NA_character_, n),
    iso2c = rep(NA_character_, n)
  )

  # Apply custom names first if provided
  if (!is.null(custom_names)) {
    transformed_names <- standardize_with_custom_names(names, custom_names)
  } else {
    transformed_names <- names
  }

  # Combine standard and custom patterns
  patterns <- if (!is.null(custom_patterns)) {
    dplyr::bind_rows(economy_patterns, custom_patterns)
  } else {
    economy_patterns
  }

  # Process each name
  for (i in seq_len(n)) {
    current_name <- names[i]
    current_transformed_name <- transformed_names[i]
    current_code <- if (!is.null(codes)) {
      codes[i]
    } else {
      patterns$iso3c[patterns$economy_name == current_name]
    }

    if (current_name == "CustomEconomy") {
      print(current_code)
    }

    # Try to match the current name
    match_result <- match_economy(
      name = current_transformed_name,
      code = current_code,
      patterns = patterns,
      warn_ambiguous = warn_ambiguous
    )

    results$economy_name[i] <- match_result$economy_name
    results$economy_id[i] <- match_result$economy_id
    results$economy_type[i] <- match_result$economy_type
    results$iso3c[i] <- match_result$iso3c
    results$iso2c[i] <- match_result$iso2c
  }

  # Identify unique aggregates
  aggregates <- unique(names[results$economy_type == "Aggregate"])

  list(
    data = results,
    aggregates = aggregates
  )
}

#' Match Individual Economy Name
#'
#' @description
#' Attempts to match a single economy name against available patterns.
#'
#' @param name Character string of economy name to match
#' @param code Optional economy code
#' @param patterns Tibble of matching patterns
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#'
#' @return List containing matched economy information
#'
#' @keywords internal
match_economy <- function(name, code, patterns, warn_ambiguous = TRUE) {
  # Try regex patterns
  regex_match <- try_regex_match(name, patterns, warn_ambiguous)
  if (!is.null(regex_match)) {
    return(regex_match)
  }
  
  # Initialize result
  result <- list(
    economy_name = name,  # Default to original name
    economy_id = code,    # Default to provided code
    economy_type = "Aggregate",  # Default type
    iso3c = NA_character_,
    iso2c = NA_character_
  )

  result
}

#' Try Regex Pattern Match
#'
#' @description
#' Attempts to match an economy name using regex patterns.
#'
#' @param name Character string of economy name
#' @param patterns Tibble of matching patterns
#' @param warn_ambiguous Logical; whether to warn about ambiguous matches
#'
#' @return List containing matched economy information or NULL
#'
#' @keywords internal
try_regex_match <- function(name, patterns, warn_ambiguous) {
  name_lower <- tolower(name)
  matches <- logical(nrow(patterns))

  for (i in seq_len(nrow(patterns))) {
    pattern <- patterns$economy_regex[i]
    if (!is.na(pattern) && nchar(pattern) > 0) {
      matches[i] <- grepl(pattern, name_lower, perl = TRUE)
    }
  }

  if (sum(matches) > 1 && warn_ambiguous) {
    matched_names <- patterns$economy_name[matches]
    warning_msg <- c(
      "!" = "Ambiguous match for {.val {name}}",
      "*" = paste(
        "Matches multiple patterns:",
        paste(matched_names, collapse = ", ")
      )
    )
    cli::cli_warn(warning_msg)
  }

  if (any(matches)) {
    match_idx <- which(matches)[1]
    return(list(
      economy_name = patterns$economy_name[match_idx],
      economy_id = patterns$iso3c[match_idx],
      economy_type = "Country/Economy",
      iso3c = patterns$iso3c[match_idx],
      iso2c = patterns$iso2c[match_idx]
    ))
  }
  NULL
}

#' Apply Custom Name Mappings
#'
#' @description
#' Applies custom name mappings to a vector of economy names.
#'
#' @param x Character vector of economy names
#' @param custom_names Named vector of custom name mappings
#'
#' @return Character vector with applied custom name mappings
#'
#' @keywords internal
standardize_with_custom_names <- function(x, custom_names) {
  # Convert input to lowercase for matching
  x_lower <- tolower(x)
  names_lower <- tolower(names(custom_names))

  # Create matching vector
  matches <- match(x_lower, names_lower)

  # Replace matched values
  x[!is.na(matches)] <- custom_names[matches[!is.na(matches)]]

  x
}