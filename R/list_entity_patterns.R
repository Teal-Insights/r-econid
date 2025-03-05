#' List entity patterns
#'
#' This function returns a tibble containing regular expression patterns for
#' identifying economic indicators. It combines the patterns from the built-in
#' \code{entity_patterns} dataset with any custom patterns stored in the
#' \code{.econid_env} environment.
#'
#' @return A data frame with the following columns:
#' \describe{
#'   \item{entity_id}{entity id}
#'   \item{entity_name}{entity name}
#'   \item{iso2c}{ISO 3166-1 alpha-2 code}
#'   \item{iso3c}{ISO 3166-1 alpha-3 code}
#'   \item{entity_type}{entity type}
#'   \item{entity_regex}{Regular expression pattern for matching entity names}
#' }
#'
#' @examples
#' patterns <- list_entity_patterns()
#'
#' @export
#' @keywords internal
list_entity_patterns <- function() {
  # Get built-in patterns
  builtin <- entity_patterns

  # Create the .econid_env if it doesn't exist
  if (!exists(".econid_env", mode = "environment")) {
    .econid_env <- new.env(parent = emptyenv())
    assign(".econid_env", .econid_env, envir = .GlobalEnv)
  }

  # Check if custom_entity_patterns exists, create empty tibble if not
  if (!exists("custom_entity_patterns", envir = .econid_env)) {
    .econid_env$custom_entity_patterns <- tibble::tibble(
      entity_id    = character(),
      entity_name  = character(),
      iso3c        = character(),
      iso2c        = character(),
      entity_type  = character(),
      entity_regex = character()
    )
  }

  # Get custom patterns
  custom <- get("custom_entity_patterns", envir = .econid_env)

  # Combine built-in and custom patterns
  dplyr::bind_rows(builtin, custom)
}
