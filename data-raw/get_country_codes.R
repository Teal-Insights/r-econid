## code to prepare `country_codes` dataset goes here
## TODO: Construct the dataset anew rather than downloading CSV

# Download the CSV from the specified URL and save to a temporary file
url <- paste0("https://raw.githubusercontent.com/t-emery/wbhelpr/",
              "refs/heads/master/data-raw/wb_countrycode.csv")
temp_file <- tempfile(fileext = ".csv")
download.file(url, destfile = temp_file)

# Read the downloaded CSV file
country_codes <- read.csv(temp_file, fileEncoding = "UTF-8")

# Clean up the temporary file
unlink(temp_file)

# Set encoding for character columns to UTF-8
char_cols <- sapply(country_codes, is.character)
country_codes[char_cols] <- lapply(country_codes[char_cols], function(col) {
  Encoding(col) <- "UTF-8"
  col
})

# Save the dataset to an .rda file for export using usethis::use_data
usethis::use_data(country_codes, overwrite = TRUE, internal = TRUE)
