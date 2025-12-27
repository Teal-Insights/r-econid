# Add a custom entity pattern

This function allows users to extend the default entity patterns with a
custom entry.

## Usage

``` r
add_entity_pattern(
  entity_id,
  entity_name,
  entity_type,
  aliases = NULL,
  entity_regex = NULL
)
```

## Arguments

- entity_id:

  A unique identifier for the entity.

- entity_name:

  The standard (canonical) name of the entity.

- entity_type:

  A character string describing the type of entity ("economy",
  "organization", "aggregate", or "other").

- aliases:

  An optional character vector of alternative names identifying the
  entity. If provided, these are automatically combined (using the pipe
  operator, "\|") with `entity_name` and `entity_id` to construct a
  regular expression pattern.

- entity_regex:

  An optional custom regular expression pattern. If supplied, it
  overrides the regex automatically constructed from `aliases`.

## Value

`NULL`. As a side effect of the function, the custom pattern is stored
in an internal tibble for the current session.

## Details

Custom entity patterns can be added at the top of a script (or
interactively) and will be appended to the built-in patterns when using
[`list_entity_patterns()`](https://teal-insights.github.io/r-econid/reference/list_entity_patterns.md).
This makes it possible for users to register alternative names (aliases)
for entities that might appear in their economic datasets.

The custom entity patterns are kept separately and are appended to the
default patterns when retrieving the entity_patterns via
[`list_entity_patterns()`](https://teal-insights.github.io/r-econid/reference/list_entity_patterns.md).
The custom patterns will only persist for the length of the R session.

## Examples

``` r
add_entity_pattern(
  "ASN",
  "Association of Southeast Asian Nations",
  "economy",
  aliases = c("ASEAN")
)
patterns <- list_entity_patterns()
print(patterns[patterns$entity_id == "ASN", ])
#> # A tibble: 1 × 6
#>   entity_id entity_name                     iso3c iso2c entity_type entity_regex
#>   <chr>     <chr>                           <chr> <chr> <chr>       <chr>       
#> 1 ASN       Association of Southeast Asian… NA    NA    economy     asn|associa…

```
