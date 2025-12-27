# Match entities with patterns using regex matching

Given a data frame and a vector of target columns, perform regex
matching on the target columns until all entities are matched or we run
out of columns to match. Warn about ambiguous matches (duplicate
entity_id values). Return a data frame mapping the target columns to the
entity patterns.

## Usage

``` r
match_entities_with_patterns(
  data,
  target_cols,
  patterns,
  warn_ambiguous = TRUE
)
```

## Arguments

- data:

  A data frame containing the columns to match

- target_cols:

  Character vector of column names to match

- patterns:

  Data frame containing entity patterns; if NULL, uses
  list_entity_patterns()

- warn_ambiguous:

  Logical; whether to warn about ambiguous matches

## Value

A data frame with the unique combinations of the target columns mapped
to the entity patterns
