# zzz.R

utils::globalVariables(c("entity_patterns"))

.onLoad <- function(libname, pkgname) {
  # Set default option for custom entity patterns
  op <- options()
  default_options <- list(
    econid.custom_entity_patterns = tibble::tibble(
      entity_id    = character(),
      entity_name  = character(),
      iso3c        = character(),
      iso2c        = character(),
      entity_type  = character(),
      entity_regex = character()
    )
  )

  # Only set options that aren't already set
  toset <- !(names(default_options) %in% names(op))
  if (any(toset)) {
    options(default_options[toset])
  }
}
