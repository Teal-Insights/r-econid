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
#' add_entity_pattern(
#'   "ASN",
#'   "Association of Southeast Asian Nations",
#'   "economy",
#'   aliases = c("ASEAN")
#' )
#' patterns <- list_entity_patterns()
#' print(patterns[patterns$entity_id == "ASN", ])
#'
#'
#' @export
add_entity_pattern <- function(
  entity_id,
  entity_name,
  entity_type,
  aliases = NULL,
  entity_regex = NULL
) {
  # Validate entity_type is one of the allowed values
  valid_types <- c("economy", "organization", "aggregate", "other")
  if (!entity_type %in% valid_types) {
    cli::cli_abort(
      paste(
        entity_type,
        "is not a valid entity type. Must be one of:",
        paste(valid_types, collapse = ", ")
      )
    )
  }

  # Get current custom patterns from options
  custom_patterns <- getOption("econid.custom_entity_patterns")

  # Validate that the entity_id is not already in the patterns
  if (entity_id %in% list_entity_patterns()$entity_id) {
    cli::cli_abort(
      paste(
        "The entity_id", as.character(entity_id),
        "already exists in the custom patterns.",
        "Please use a unique identifier."
      )
    )
  }

  # If no custom regex is supplied, build one from aliases
  if (is.null(entity_regex)) {
    if (is.null(aliases) || length(aliases) == 0) {
      aliases <- c(entity_id, entity_name)
    } else {
      aliases <- c(entity_id, entity_name, aliases)
    }
    # Construct regex by joining provided aliases with the pipe operator
    entity_regex <- create_entity_regex(aliases)
  }

  # Create a new tibble row with the provided details
  new_pattern <- tibble::tibble(
    entity_id   = as.character(entity_id),
    entity_name = entity_name,
    iso3c       = NA_character_,
    iso2c       = NA_character_,
    entity_type = entity_type,
    entity_regex = entity_regex
  )

  # Update the custom patterns option
  updated_custom <- dplyr::bind_rows(custom_patterns, new_pattern)
  options(econid.custom_entity_patterns = updated_custom)

  invisible(NULL)
}
