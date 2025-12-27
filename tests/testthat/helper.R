local_clean_econid_patterns <- function(env = parent.frame()) {
  # Capture the old custom patterns so we can restore them after the test
  old <- getOption("econid.custom_entity_patterns")

  # Re-initialize to an empty tibble at the start of this test
  options(
    econid.custom_entity_patterns = tibble::tibble(
      entity_id = character(),
      entity_name = character(),
      iso3c = character(),
      iso2c = character(),
      entity_type = character(),
      entity_regex = character()
    )
  )

  # Use withr::defer() to restore the old data when the test finishes
  rlang::is_installed("withr")
  withr::defer(
    {
      options(econid.custom_entity_patterns = old)
    },
    envir = env
  )
}
