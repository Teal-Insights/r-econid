#' Add a custom economy pattern
#'
#' This function allows users to extend the default economy patterns with a
#' custom entry.
#'
#' Custom economy patterns can be added at the top of a script (or
#' interactively) and will be appended to the built-in patterns when using
#' \code{list_economy_patterns()}. This makes it possible for users to register
#' alternative names (aliases) for economies that might appear in their economic
#' datasets.
#'
#' @param economy_id A unique identifier for the economy.
#' @param economy_name The standard (canonical) name of the economy.
#' @param economy_type A character string describing the type of economy (e.g.,
#'   "country", "region").
#' @param aliases An optional character vector of alternative names identifying
#'   the economy. If provided, these are automatically combined (using the pipe
#'   operator, "|") with \code{economy_name} and \code{economy_id} to construct
#'   a regular expression pattern.
#' @param economy_regex An optional custom regular expression pattern. If
#'   supplied, it overrides the regex automatically constructed from
#'   \code{aliases}.
#'
#' @return \code{NULL}. As a side effect of the function, the custom pattern is
#'   stored in an internal tibble for the current session.
#'
#' @details The custom economy patterns are kept separately and are appended to
#'   the default patterns when retrieving the economy_patterns via
#'   \code{list_economy_patterns()}. The custom patterns will only persist
#'   for the length of the R session.
#'
#' @examples
#' \dontrun{
#'   add_economy_pattern("EU", "European Union", aliases = c("Europe"))
#'   patterns <- list_economy_patterns()
#' }
#'
#' @export
add_economy_pattern <- function(
  economy_id,
  economy_name,
  economy_type,
  aliases = NULL,
  economy_regex = NULL
) {
  # If no custom regex is supplied, build one from aliases (or default to
  # "economy_id|economy_name")
  if (is.null(economy_regex)) {
    if (is.null(aliases) || length(aliases) == 0) {
      aliases <- c(economy_id, economy_name)
    } else {
      aliases <- c(economy_id, economy_name, aliases)
    }
    # Construct regex by joining provided aliases with the pipe operator
    economy_regex <- create_economy_regex(aliases)
  }

  # Create a new tibble row with the provided details.
  # Coerce economy_id to character to match the type in the stored tibble.
  new_pattern <- tibble::tibble(
    economy_id   = as.character(economy_id),
    economy_name = economy_name,
    iso3c        = NA_character_,
    iso2c        = NA_character_,
    economy_type = economy_type,
    economy_regex = economy_regex
  )

  # Ensure the custom patterns object exists in the environment.
  if (!exists("custom_economy_patterns", envir = .econid_env)) {
    .econid_env$custom_economy_patterns <- tibble::tibble(
      economy_id    = character(),
      economy_name  = character(),
      iso3c         = character(),
      iso2c         = character(),
      economy_type  = character(),
      economy_regex = character()
    )
  }

  # Retrieve, update, and reassign
  current_custom <- .econid_env$custom_economy_patterns
  updated_custom <- dplyr::bind_rows(current_custom, new_pattern)
  .econid_env$custom_economy_patterns <- updated_custom

  invisible(NULL)
}
