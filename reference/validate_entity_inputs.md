# Validate inputs for entity standardization

Validates the input data frame and column names for entity
standardization.

## Usage

``` r
validate_entity_inputs(
  data,
  target_cols_names,
  output_cols,
  prefix,
  fill_mapping = NULL
)
```

## Arguments

- data:

  A data frame or tibble to validate

- target_cols_names:

  Character vector of column names containing entity identifiers

- output_cols:

  Character vector of requested output columns

- prefix:

  Optional character string to prefix the output column names

- fill_mapping:

  Named character vector specifying how to fill missing values

## Value

Invisible NULL
