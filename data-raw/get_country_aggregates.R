## code to prepare `country_aggregates` dataset goes here
## TODO: Construct the dataset anew rather than downloading it
## TODO: Move continent mapping here from country_codes.R

# Download the CSV from the specified URL and save to a temporary file
url <- paste0("https://raw.githubusercontent.com/t-emery/sais-susfin_data/",
              "refs/heads/main/datasets/imf_wb_country_groups.csv")
temp_file <- tempfile(fileext = ".csv")
download.file(url, destfile = temp_file)

# Read the downloaded CSV file
country_aggregates <- read.csv(temp_file, fileEncoding = "UTF-8")

# Clean up the temporary file
unlink(temp_file)

# Set encoding for character columns to UTF-8
char_cols <- sapply(country_aggregates, is.character)
country_aggregates[char_cols] <- lapply(
  country_aggregates[char_cols],
  function(col) {
    Encoding(col) <- "UTF-8"
    col
  }
)

# Save the dataset to an .rda file for export using usethis::use_data
usethis::use_data(country_aggregates, overwrite = TRUE, internal = TRUE)
