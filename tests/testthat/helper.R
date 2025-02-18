local_clean_econid_patterns <- function(env = parent.frame()) {
  # Capture the old custom table so we can restore it after the test
  old <- .econid_env$custom_economy_patterns

  # Re-initialize to an empty tibble at the start of this test
  .econid_env$custom_economy_patterns <- tibble::tibble(
    economy_id    = character(),
    economy_name  = character(),
    iso3c         = character(),
    iso2c         = character(),
    economy_type  = character(),
    economy_regex = character()
  )

  # Use withr::defer() so that when the current test_that() finishes,
  # we restore the old data (if you want to restore it).
  withr::defer({
    .econid_env$custom_economy_patterns <- old
  }, envir = env)
}
