#' Economy Patterns
#'
#' A dataset containing patterns for matching economy names.
#' This dataset is accessible through \link{list_economy_patterns}.
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{economy_id}{Unique identifier for the economy}
#'   \item{economy_name}{Economy name}
#'   \item{iso3c}{ISO 3166-1 alpha-3 code}
#'   \item{iso2c}{ISO 3166-1 alpha-2 code}
#'   \item{economy_type}{Type of economy (e.g., "country")}
#'   \item{economy_regex}{Regular expression pattern for matching economy names}
#' }
#' @source Data manually prepared by Teal L. Emery
"economy_patterns"
