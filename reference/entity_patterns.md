# Entity Patterns

A dataset containing patterns for matching entity names. This dataset is
accessible through
[list_entity_patterns](https://teal-insights.github.io/r-econid/reference/list_entity_patterns.md).

## Usage

``` r
entity_patterns
```

## Format

A data frame with the following columns:

- entity_id:

  Unique identifier for the entity

- entity_name:

  entity name

- iso3c:

  ISO 3166-1 alpha-3 code

- iso2c:

  ISO 3166-1 alpha-2 code

- entity_type:

  Type of entity ("economy", "organization", "aggregate", or "other")

- entity_regex:

  Regular expression pattern for matching entity names

## Source

Data manually prepared by Teal L. Emery
