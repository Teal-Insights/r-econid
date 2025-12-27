# List entity patterns

This function returns a tibble containing regular expression patterns
for identifying economic indicators. It combines the patterns from the
built-in `entity_patterns` dataset with any custom patterns stored in
the `.econid_env` environment.

## Usage

``` r
list_entity_patterns()
```

## Value

A data frame with the following columns:

- entity_id:

  entity id

- entity_name:

  entity name

- iso2c:

  ISO 3166-1 alpha-2 code

- iso3c:

  ISO 3166-1 alpha-3 code

- entity_type:

  entity type

- entity_regex:

  Regular expression pattern for matching entity names

## Examples

``` r
patterns <- list_entity_patterns()
```
