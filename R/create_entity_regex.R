#' Create entity Name Regex Pattern
#'
#' @description
#' Creates a regular expression pattern from one or more entity names,
#' following standardized rules for flexible matching. The function converts
#' each input name to lowercase, escapes special regex characters, and replaces
#' spaces with a flexible whitespace pattern (`.?`). The individual patterns
#' are then joined with the pipe operator (`|`) to produce a regex that matches
#' any of the supplied names.
#'
#' @param names A character vector of entity names.
#'
#' @return A character string containing the combined regex pattern.
#'
#' @keywords internal
create_entity_regex <- function(names) {
  if (!is.character(names)) {
    cli::cli_abort("`names` must be a character vector.")
  }

  # Process each name individually
  patterns <- vapply(names, function(name) {
    # Convert to lowercase
    pattern <- tolower(name)

    # Escape special regex characters
    pattern <- gsub("([.|()\\^{}+$*?])", "\\\\\\1", pattern)

    # Replace spaces with flexible whitespace pattern
    pattern <- gsub("\\s+", ".?", pattern)

    pattern
  }, FUN.VALUE = character(1))

  # Join individual patterns with pipe to create an "or" regex pattern
  combined_pattern <- paste(patterns, collapse = "|")
  combined_pattern
}
