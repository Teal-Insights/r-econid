# Create entity Name Regex Pattern

Creates a regular expression pattern from one or more entity names,
following standardized rules for flexible matching. The function
converts each input name to lowercase, escapes special regex characters,
and replaces spaces with a flexible whitespace pattern (`.?`). The
individual patterns are then joined with the pipe operator (`|`) to
produce a regex that matches any of the supplied names.

## Usage

``` r
create_entity_regex(names)
```

## Arguments

- names:

  A character vector of entity names.

## Value

A character string containing the combined regex pattern.
