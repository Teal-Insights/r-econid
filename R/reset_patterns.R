#' Reset custom entity patterns
#'
#' This function resets all custom entity patterns that have been added
#' during the current R session.
#'
#' @return Invisibly returns NULL.
#'
#' @examples
#' \dontrun{
#'   add_entity_pattern("EU", "European Union", "economy")
#'   reset_custom_entity_patterns()  # Clears the custom pattern
#' }
#'
#' @export
reset_custom_entity_patterns <- function() {
  options(econid.custom_entity_patterns = tibble::tibble(
    entity_id    = character(),
    entity_name  = character(),
    iso3c        = character(),
    iso2c        = character(),
    entity_type  = character(),
    entity_regex = character()
  ))
  invisible(NULL)
}
