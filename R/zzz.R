# zzz.R

# This will be a private environment where you store your session-specific data
.econid_env <- new.env(parent = emptyenv())

.onLoad <- function(libname, pkgname) {
  # You can optionally initialize the custom patterns tibble here
  .econid_env$custom_economy_patterns <- tibble::tibble(
    economy_id    = character(),
    economy_name  = character(),
    iso3c         = character(),
    iso2c         = character(),
    economy_type  = character(),
    economy_regex = character()
  )
}
