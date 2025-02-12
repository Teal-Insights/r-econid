# Design notes:
#
# When allowing users to extend the economy_patterns with custom patterns, we
# should let them do it once at the top of their script rather than as a
# argument. Also may want to allow custom regex rather than always construct
# it programmatically.

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
