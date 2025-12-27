# Standardize Entity Identifiers

Standardizes entity identifiers (e.g., name, ISO code) in an economic
data frame by matching them against a predefined list of regex patterns
to add columns containing standardized identifiers to the data frame.

## Usage

``` r
standardize_entity(
  data,
  ...,
  output_cols = c("entity_id", "entity_name", "entity_type"),
  prefix = NULL,
  fill_mapping = NULL,
  default_entity_type = NA_character_,
  warn_ambiguous = TRUE,
  overwrite = TRUE,
  warn_overwrite = TRUE,
  .before = NULL
)
```

## Arguments

- data:

  A data frame or tibble containing entity identifiers to standardize

- ...:

  Columns containing entity names and/or IDs. These can be specified
  using unquoted column names (e.g., `entity_name`, `entity_id`) or
  quoted column names (e.g., `"entity_name"`, `"entity_id"`). Must
  specify at least one column. If two columns are specified, the first
  is assumed to be the entity name and the second is assumed to be the
  entity ID.

- output_cols:

  Character vector specifying desired output columns. Options are
  "entity_id", "entity_name", "entity_type", "iso3c", "iso2c". Defaults
  to c("entity_id", "entity_name", "entity_type").

- prefix:

  Optional character string to prefix the output column names. Useful
  when standardizing multiple entities in the same dataset (e.g.,
  "country", "counterpart"). If provided, output columns will be named
  prefix_entity_id, prefix_entity_name, etc. (with an underscore
  automatically inserted between the prefix and the column name).

- fill_mapping:

  Named character vector specifying how to fill missing values when no
  entity match is found. Names should be output column names (without
  prefix), and values should be input column names (from `...`). For
  example, `c(entity_id = "country_code", entity_name = "country_name")`
  will fill missing entity_id values with values from the country_code
  column and missing entity_name values with values from the
  country_name column.

- default_entity_type:

  Character or NA; the default entity type to use for entities that do
  not match any of the patterns. Options are "economy", "organization",
  "aggregate", "other", or NA_character\_. Defaults to NA_character\_.
  This argument is only used when "entity_type" is included in
  output_cols.

- warn_ambiguous:

  Logical; whether to warn about ambiguous matches

- overwrite:

  Logical; whether to overwrite existing entity\_\* columns

- warn_overwrite:

  Logical; whether to warn when overwriting existing entity\_\* columns.
  Defaults to TRUE.

- .before:

  Column name or position to insert the standardized columns before. If
  NULL (default), columns are inserted at the beginning of the
  dataframe. Can be a character vector specifying the column name or a
  numeric value specifying the column index. If the specified column is
  not found in the data, an error is thrown.

## Value

A data frame with standardized entity information merged with the input
data. The standardized columns are placed directly to the left of the
first target column.

## Examples

``` r
# Standardize entity names and IDs in a data frame
test_df <- tibble::tribble(
  ~entity,         ~code,
  "United States",  "USA",
  "united.states",  NA,
  "us",             "US",
  "EU",             NA,
  "NotACountry",    NA
)

standardize_entity(test_df, entity, code)
#> # A tibble: 5 × 5
#>   entity_id entity_name   entity_type entity        code 
#>   <chr>     <chr>         <chr>       <chr>         <chr>
#> 1 USA       United States economy     United States USA  
#> 2 USA       United States economy     united.states NA   
#> 3 USA       United States economy     us            US   
#> 4 NA        NA            NA          EU            NA   
#> 5 NA        NA            NA          NotACountry   NA   

# Standardize with fill_mapping for unmatched entities
standardize_entity(
  test_df,
  entity, code,
  fill_mapping = c(entity_id = "code", entity_name = "entity")
)
#> # A tibble: 5 × 5
#>   entity_id entity_name   entity_type entity        code 
#>   <chr>     <chr>         <chr>       <chr>         <chr>
#> 1 USA       United States economy     United States USA  
#> 2 USA       United States economy     united.states NA   
#> 3 USA       United States economy     us            US   
#> 4 NA        EU            NA          EU            NA   
#> 5 NA        NotACountry   NA          NotACountry   NA   

# Standardize multiple entities in sequence with a prefix
df <- data.frame(
  country_name = c("United States", "France"),
  counterpart_name = c("China", "Germany")
)
df |>
  standardize_entity(
    country_name
  ) |>
  standardize_entity(
    counterpart_name,
    prefix = "counterpart"
  )
#>   counterpart_entity_id counterpart_entity_name counterpart_entity_type
#> 1                   CHN                   China                 economy
#> 2                   DEU                 Germany                 economy
#>   entity_id   entity_name entity_type  country_name counterpart_name
#> 1       USA United States     economy United States            China
#> 2       FRA        France     economy        France          Germany
```
