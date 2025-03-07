# Install dotenv if not already present
if (!requireNamespace("dotenv", quietly = TRUE)) {
  install.packages("dotenv")
}

# Set API endpoint url
url <- "https://rest-countries10.p.rapidapi.com/countries"

# Load environment variables
dotenv::load_dot_env(".env")

# Check if X-RAPIDAPI-KEY is set and stop if not
if (Sys.getenv("X-RAPIDAPI-KEY") == "") {
  cli::cli_abort("X-RAPIDAPI-KEY is not set")
}

# Set headers
headers <- c(
  "X-RapidAPI-Key" = Sys.getenv("X-RAPIDAPI-KEY"),
  "X-RapidAPI-Host" = "rest-countries10.p.rapidapi.com"
)

# Make request to get json data
response <- httr2::request(url) |>
  httr2::req_headers(!!!headers) |>
  httr2::req_perform()

# Get json data from response
json_data <- response |>
  httr2::resp_body_json()

# Convert json data to tibble
iso_codes <- json_data |>
  sapply(function(x) {
    tibble::tibble(
      alpha2code = x$code$aplha2code,
      alpha3code = x$code$alpha3code,
      numericcode = x$code$numericcode,
      shortname = x$name$shortname,
      shortnamelowercase = x$name$shortnamelowercase,
      fullname = x$name$fullname,
    )
  }) |>
  dplyr::bind_rows()

# Fill missing fullname with shortnamelowercase
iso_codes <- iso_codes |>
  dplyr::mutate(
    fullname = ifelse(is.na(fullname), shortnamelowercase, fullname)
  )

# save to data-raw/.csv/iso_codes.csv
write.csv(
  iso_codes,
  file.path("data-raw", ".csv", "iso_codes.csv"),
  row.names = FALSE
)
