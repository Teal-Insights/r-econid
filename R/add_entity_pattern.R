#' Add a custom entity pattern
#'
#' This function allows users to extend the default entity patterns with a
#' custom entry.
#'
#' Custom entity patterns can be added at the top of a script (or
#' interactively) and will be appended to the built-in patterns when using
#' \code{list_entity_patterns()}. This makes it possible for users to register
#' alternative names (aliases) for entities that might appear in their economic
#' datasets.
#'
#' @param entity_id A unique identifier for the entity.
#' @param entity_name The standard (canonical) name of the entity.
#' @param entity_type A character string describing the type of entity
#'   ("economy", "organization", "aggregate", or "other").
#' @param aliases An optional character vector of alternative names identifying
#'   the entity. If provided, these are automatically combined (using the pipe
#'   operator, "|") with \code{entity_name} and \code{entity_id} to construct
#'   a regular expression pattern.
#' @param entity_regex An optional custom regular expression pattern. If
#'   supplied, it overrides the regex automatically constructed from
#'   \code{aliases}.
#'
#' @return \code{NULL}. As a side effect of the function, the custom pattern is
#'   stored in an internal tibble for the current session.
#'
#' @details The custom entity patterns are kept separately and are appended to
#'   the default patterns when retrieving the entity_patterns via
#'   \code{list_entity_patterns()}. The custom patterns will only persist
#'   for the length of the R session.
#'
#' @examples
#' \dontrun{
#'   add_entity_pattern(
#'     "EU",
#'     "European Union",
#'     "economy",
#'     aliases = c("Europe")
#'   )
#'   patterns <- list_entity_patterns()
#' }
#'
#' @export
add_entity_pattern <- function(
  entity_id,
  entity_name,
  entity_type,
  aliases = NULL,
  entity_regex = NULL
) {
  # If no custom regex is supplied, build one from aliases (or default to
  # "entity_id|entity_name")
  if (is.null(entity_regex)) {
    if (is.null(aliases) || length(aliases) == 0) {
      aliases <- c(entity_id, entity_name)
    } else {
      aliases <- c(entity_id, entity_name, aliases)
    }
    # Construct regex by joining provided aliases with the pipe operator
    entity_regex <- create_entity_regex(aliases)
  }

  # Create a new tibble row with the provided details.
  # Coerce entity_id to character to match the type in the stored tibble.
  new_pattern <- tibble::tibble(
    entity_id   = as.character(entity_id),
    entity_name = entity_name,
    iso3c        = NA_character_,
    iso2c        = NA_character_,
    entity_type = entity_type,
    entity_regex = entity_regex
  )

  # Ensure the custom patterns object exists in the environment.
  if (!exists("custom_entity_patterns", envir = .econid_env)) {
    .econid_env$custom_entity_patterns <- tibble::tibble(
      entity_id    = character(),
      entity_name  = character(),
      iso3c         = character(),
      iso2c         = character(),
      entity_type  = character(),
      entity_regex = character()
    )
  }

  # Retrieve, update, and reassign
  current_custom <- .econid_env$custom_entity_patterns
  updated_custom <- dplyr::bind_rows(current_custom, new_pattern)
  .econid_env$custom_entity_patterns <- updated_custom

  invisible(NULL)
}
