dotenv::load_dot_env()

parse_deepseek_response <- function(response) {
  # Remove "```json" and "```"
  clean_text <- gsub("```\\s*json\\s*\\{", "{", response)
  clean_text <- gsub("\\s*```\\s*$", "", clean_text)

  tryCatch({
    # Parse the JSON into a list structure
    parsed <- jsonlite::fromJSON(clean_text, simplifyVector = TRUE)

    # Assert that the parsed result is a list of strings
    # Handle both cases: direct array or object with "variants" key
    if (is.character(parsed)) {
      # Direct array case
      variants <- parsed
    } else if (
      is.list(parsed) &&
        "variants" %in% names(parsed) &&
        is.character(parsed$variants)
    ) {
      # Object with variants key case
      variants <- parsed$variants
    } else {
      cli::cli_warn("Invalid response format, returning empty vector")
      return(character(0))
    }

    variants
  }, error = function(e) {
    cli::cli_warn(
      c("Failed to parse DeepSeek response, returning empty vector",
        i = "Original response: {response}",
        x = "Error: {conditionMessage(e)}")
    )
    character(0)
  })
}

get_variant_names <- function(economy_name, iso3c, iso2c) {
  # Prompt DeepSeek to return a JSON array of the variant names
  prompt <- paste0(
    "Return a JSON array of the variant names for a given economy. ",
    "You will be given the economy name, ISO3 code, and ISO2 code. ",
    "Variants should include all names for the nation that might appear in ",
    "standard economic data sets from institutions like the World Bank, ",
    "IMF, etc. dating back to the mid-20th century. The goal is to generate ",
    "test cases for a regex pattern matching function used for table joins ",
    "across datasets. You should include a name only if there's a more or less ",
    "one-to-one mapping between the variant name and the input name. ",
    "That is, you should not return The United Provinces of the Río de la ",
    "Plata for Argentina or Transcaucasian Democratic Federative Republic for ",
    "Armenia, because those historical nations encompassed several modern ",
    "states. Similarly, do not return \"Colony of Queensland\" for Australia, ",
    "because that historical colony encompassed only a small part of the ",
    "modern country.\n",
    "Example: given the input:\n",
    "\"Afghanistan\", \"AFG\", \"AF\"\n",
    "the output might be:\n",
    "[\"Republic of Afghanistan\", \"Islamic Emirate of Afghanistan\", ",
    "\"First Islamic Emirate of Afghanistan\", \"Afghanistan\", ",
    "\"Kingdom of Afghanistan\", \"Islamic Republic of Afghanistan\", ",
    "\"Islamic State of Afghanistan\"]\n",
    "IMPORTANT: Return the JSON array only, without any extra or explanatory ",
    "text. The output should include only square brackets enclosing a ",
    "comma-separated list of double-quoted strings."
  )

  # Send the prompt to DeepSeek
  chat <- ellmer::chat_vllm(
    base_url = "https://api.deepseek.com/v1/",
    system_prompt = prompt,
    turns = NULL,
    model = "deepseek-chat",
    api_key = Sys.getenv("DEEPSEEK_API_KEY"),
    api_args = list(response_format = list(type = "json_object")),
    echo = "none"
  )

  deepseek_result <- chat$chat(paste0(
    "Input: \"", economy_name, "\", \"", iso3c, "\", \"", iso2c, "\"."
  ))

  parsed_result <- parse_deepseek_response(deepseek_result)

  parsed_result
}

# Create a lookup table of existing variant names
existing_variants <- test_cases |>
  dplyr::select(economy_name, variant_names) |>
  dplyr::filter(lengths(variant_names) > 0)

# test_cases generation with option to update all or just missing
get_test_cases <- function(update_all = FALSE) {
  purrr::pmap_dfr(
    economy_patterns,
    function(economy_name, economy_regex, iso3c, iso2c) {
      # Check if we already have variants for this economy
      if (!update_all && economy_name %in% existing_variants$economy_name) {
        # Use existing variants
        existing_row <- existing_variants |>
          dplyr::filter(economy_name == !!economy_name)
        return(tibble::tibble(
          economy_name = economy_name,
          variant_names = existing_row$variant_names
        ))
      }
      
      # Make API request for new economies or when update_all is TRUE
      variant_names <- get_variant_names(economy_name, iso3c, iso2c)
      tibble::tibble(
        economy_name = economy_name,
        variant_names = list(variant_names)
      )
    }
  )
}

# Generate test cases (change to test_cases(TRUE) to update all)
test_cases <- get_test_cases(update_all = FALSE)

# Manual fixup
test_cases$variant_names[[which(test_cases$economy_name == "Argentina")]] <- 
  test_cases$variant_names[[which(test_cases$economy_name == "Argentina")]][
    test_cases$variant_names[[which(test_cases$economy_name == "Argentina")]] != "United Provinces of South America"
  ]

test_cases$variant_names[[which(test_cases$economy_name == "Armenia")]] <- 
  test_cases$variant_names[[which(test_cases$economy_name == "Armenia")]][
    test_cases$variant_names[[which(test_cases$economy_name == "Armenia")]] != "Transcaucasian Socialist Federative Soviet Republic"
  ]

test_cases$variant_names[[which(test_cases$economy_name == "Australia")]] <- 
  test_cases$variant_names[[which(test_cases$economy_name == "Australia")]][
    !test_cases$variant_names[[which(test_cases$economy_name == "Australia")]] %in% c(
      "Colony of Queensland",
      "Colony of New South Wales",
      "Colony of Victoria",
      "Colony of Tasmania",
      "Colony of New Zealand"
    )
  ]

test_cases$variant_names[[which(test_cases$economy_name == "China")]] <- 
  test_cases$variant_names[[which(test_cases$economy_name == "China")]][
    !test_cases$variant_names[[which(test_cases$economy_name == "China")]] %in% c(
      "Republic of China",
      "ROC"
    )
  ]

test_cases$variant_names[[which(test_cases$economy_name == "Colombia")]] <- 
  test_cases$variant_names[[which(test_cases$economy_name == "Colombia")]][
    !grepl("Granad", test_cases$variant_names[[which(test_cases$economy_name == "Colombia")]])
  ]

test_cases$variant_names[[which(test_cases$economy_name == "Czechia")]] <- 
  test_cases$variant_names[[which(test_cases$economy_name == "Czechia")]][
    !grepl("Czechoslovak|Federative|Socialist", test_cases$variant_names[[which(test_cases$economy_name == "Czechia")]])
  ]

test_cases$variant_names[[which(test_cases$economy_name == "Egypt")]] <- 
  test_cases$variant_names[[which(test_cases$economy_name == "Egypt")]][
    test_cases$variant_names[[which(test_cases$economy_name == "Egypt")]] != "United Arab Republic"
  ]

test_cases$variant_names[[which(test_cases$economy_name == "Ethiopia")]] <- 
  test_cases$variant_names[[which(test_cases$economy_name == "Ethiopia")]][
    test_cases$variant_names[[which(test_cases$economy_name == "Ethiopia")]] != "Derg"
  ]


usethis::use_data(test_cases, overwrite = TRUE)
