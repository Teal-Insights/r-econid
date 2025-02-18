#' List economy patterns
#'
#' This function returns a tibble containing regular expression patterns for
#' identifying economic indicators.
#'
#' @return A data frame with the following columns:
#' \describe{
#'   \item{economy_name}{Economy name}
#'   \item{economy_regex}{Regular expression pattern for matching economy names}
#'   \item{iso2c}{ISO 3166-1 alpha-2 code}
#'   \item{iso3c}{ISO 3166-1 alpha-3 code}
#' }
#'
#' @examples
#' patterns <- list_economy_patterns()
#'
#' @export
#' @keywords internal
list_economy_patterns <- function() {
  get0("economy_patterns", envir = asNamespace("econid"))
}
