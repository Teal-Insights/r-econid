#' Entity Patterns
#'
#' A dataset containing patterns for matching entity names.
#' This dataset is accessible through \link{list_entity_patterns}.
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{entity_id}{Unique identifier for the entity}
#'   \item{entity_name}{entity name}
#'   \item{iso3c}{ISO 3166-1 alpha-3 code}
#'   \item{iso2c}{ISO 3166-1 alpha-2 code}
#'   \item{entity_type}{Type of entity ("economy", "organization", "aggregate",
#'     or "other")}
#'   \item{entity_regex}{Regular expression pattern for matching entity names}
#' }
#' @source Data manually prepared by Teal L. Emery
"entity_patterns"
