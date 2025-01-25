#' Economy Patterns Data
#'
#' This dataset contains regular expression patterns for identifying economic indicators.
#' It is accessible through this function.
#'
#' @return A character vector containing regular expression patterns for economic indicators
#'
#' @examples
#' patterns <- list_economy_patterns()
#' 
#' @export
#' @keywords internal
list_economy_patterns <- function() {
  return(economy_patterns)
}