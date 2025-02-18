#' List entity patterns
#'
#' This function returns a tibble containing regular expression patterns for
#' identifying economic indicators. It combines the patterns from the built-in
#' \code{entity_patterns} dataset with any custom patterns stored in the
#' \code{.econid_env} environment.
#'
#' @return A data frame with the following columns:
#' \describe{
#'   \item{entity_name}{entity name}
#'   \item{entity_regex}{Regular expression pattern for matching entity names}
#'   \item{iso2c}{ISO 3166-1 alpha-2 code}
#'   \item{iso3c}{ISO 3166-1 alpha-3 code}
#' }
#'
#' @examples
#' patterns <- list_entity_patterns()
#'
#' @export
#' @keywords internal
list_entity_patterns <- function() {
  builtin <- get0("entity_patterns", envir = asNamespace("econid"))
  custom  <- get("custom_entity_patterns", envir = .econid_env)
  dplyr::bind_rows(builtin, custom)
}
