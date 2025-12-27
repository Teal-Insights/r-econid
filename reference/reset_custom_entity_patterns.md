# Reset custom entity patterns

This function resets all custom entity patterns that have been added
during the current R session.

## Usage

``` r
reset_custom_entity_patterns()
```

## Value

Invisibly returns NULL.

## Examples

``` r
add_entity_pattern("EU", "European Union", "economy")
reset_custom_entity_patterns()
patterns <- list_entity_patterns()
print(patterns[patterns$entity_id == "EU", ])
#> # A tibble: 0 × 6
#> # ℹ 6 variables: entity_id <chr>, entity_name <chr>, iso3c <chr>, iso2c <chr>,
#> #   entity_type <chr>, entity_regex <chr>
```
