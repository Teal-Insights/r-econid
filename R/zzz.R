# zzz.R

utils::globalVariables(c(".econid_env", "entity_patterns"))

# This will be a private environment where you store your session-specific data
.econid_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # You can optionally initialize the custom patterns tibble here
  .econid_env$custom_entity_patterns <- tibble::tibble(
    entity_id    = character(),
    entity_name  = character(),
    iso3c         = character(),
    iso2c         = character(),
    entity_type  = character(),
    entity_regex = character()
  )
}
