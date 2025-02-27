# Implementation Plan for Updating `standardize_entities` to `standardize_entity`

## Overview

We will rename the `standardize_entities` function to `standardize_entity` and modify its signature to better support standardizing multiple entities in a dataset. The key change is to replace the separate `name_col` and `code_col` parameters with a more flexible `target_cols` parameter that takes a vector of column names, and to add a `prefix` parameter to allow for standardizing multiple entities in the same dataset.

## Goals and Rationale

The current `standardize_entities()` function has several limitations that we aim to address:

1. **Limited column flexibility**: The current function only supports a single name column and a single code column. The new `target_cols` parameter will allow users to specify multiple identifier columns (name, code, abbreviation, etc.) for a single entity, providing greater flexibility. Since we're handling both `name_col` and `code_col` using a unified regex function, we can handle an arbitrary number of identifier columns. (For performance reasons, probably we only want to run the second column for cases where we got an ambiguous or NA match on the first column, and so on for each additional column. Could use recursion to cycle through the columns.)

2. **Multiple entities per row**: Many economic datasets contain multiple entities in the same row (e.g., a country and its counterpart lender). The current function cannot handle this case effectively, as it would overwrite the first entity's standardized columns with the second entity's. By:

   - Renaming the function to `standardize_entity()` to clarify it works on one entity at a time
   - Adding a `prefix` parameter to distinguish output columns for different entities
   - Allowing sequential function calls for multiple entities

   We enable users to standardize multiple entities in the same dataset without column name conflicts.

3. **Improved column placement**: Currently, standardized columns are added at the left side of the data frame. The new implementation will place them directly to the left of the first target column, making the relationship between original and standardized columns clearer.

### Tradeoffs

1. **API complexity vs. flexibility**: By splitting the function into a single-entity operation, we slightly increase the verbosity of code needed to standardize multiple entities (requiring multiple function calls). However, this tradeoff is worthwhile as it:

   - Simplifies the mental model (one function call = one entity standardization)
   - Avoids complex nested parameter structures that would be harder to understand and use
   - Follows the tidyverse principle of having functions do one thing well

2. **Backward compatibility**: Renaming the function will break existing code. We could maintain a backward-compatible wrapper, but this adds maintenance overhead. Given that the package is likely still in development (not yet on CRAN), a clean break is preferable.

## Implementation Steps

### 1. Create New Function Signature

```r
standardize_entity <- function(
  data,
  target_cols,
  output_cols = c("entity_id", "entity_name", "entity_type"),
  prefix = NULL,
  default_entity_type = NA_character_,
  warn_ambiguous = TRUE,
  overwrite = TRUE,
  warn_overwrite = TRUE
) {}
```

### 2. Update Parameter Documentation

Update the Roxygen documentation to reflect the new parameter structure:

- Replace `name_col` and `code_col` documentation with `target_cols` documentation
- Add documentation for the new `prefix` parameter
- Update examples to show the new usage pattern
- Update the function description to clarify that it standardizes a single entity

### 3. Modify Input Validation Logic

- Update `validate_entity_inputs()` to handle the new `target_cols` parameter
- Validate that `target_cols` is a character vector or a vector of symbols
- Check that all columns in `target_cols` exist in the data
- Validate the `prefix` parameter if provided

### 4. Update Column Prefixing Logic

- Maintain the function's existing use of `enquo` and `as_name` to handle column names that may be passed as symbols or quoted strings
- After defusion, add logic to prefix the output columns with the `prefix` parameter if provided
- Ensure that column name conflicts are properly handled with the `overwrite` parameter
- Update the warning messages to include the prefixed column names

### 5. Update Entity Matching Logic

- Modify `match_entity_ids()` to accept multiple target columns
- Update the matching logic to try each target column in sequence
- Prioritize matches from earlier columns in the `target_cols` vector
- Implement early return logic for performance optimization:
  - If a non-ambiguous match is found in an earlier column, skip checking subsequent columns
  - Only proceed to check additional columns if:
    - No match was found in the current column, or
    - Only ambiguous matches were found (if `warn_ambiguous = TRUE`)
- Refactor the matching logic to efficiently handle multiple columns

For implementing the sequential column matching with early returns, we have two main options: a loop or recursion. The loop-based approach is preferable for this use case because the loop is easier to understand for most R programmers, and R is not optimized for tail recursion, making loops generally more efficient. The loop approach also makes it easier to implement additional logic like warning about ambiguous matches and tracking which column provided the match.

### 6. Update Column Placement Logic

- Add logic to place the output columns directly to the left of the first target column
- This will make the output more intuitive when standardizing multiple entities

## Detailed Function Logic

### Input Processing

1. Process `target_cols` using `rlang::enquo()` and `rlang::as_name()` to handle both quoted and unquoted column names
2. If `prefix` is provided, create prefixed versions of the `output_cols`
3. Check for existing columns that would be overwritten, considering the prefix, and proceed based on the `overwrite` and `warn_overwrite` parameters

### Entity Matching

1. Convert all target columns to character UTF-8
2. For each row in the data:
   a. Use the `fuzzyjoin` package to join the `output_cols` from `entity_patterns` to the first target column
   b. For rows with ambiguous matches (duplicate rows) or NA matches, try to fill or filter by regex match on the next target column
   c. Repeat until there is a match or all target columns have been tried
   d. Warn about remaining ambiguous matches if `warn_ambiguous` is TRUE, and leave the duplicate rows in the output data frame
3. Use `select` to place the output columns directly to the left of the first target column

This approach should improve performance by avoiding the need to loop through the rows of the data frame multiple times as in the current implementation.

## Example Usage

```r
# Standardize a single entity
df |>
  standardize_entity(
    target_cols = c(country_name, country_code),
    output_cols = c("entity_id", "entity_name", "entity_type"),
    prefix = "country"
  )

# Standardize multiple entities in sequence
df |>
  standardize_entity(
    target_cols = c(country_name, country_code),
    output_cols = c("entity_id", "entity_name", "entity_type"),
    prefix = "country"
  ) |>
  standardize_entity(
    target_cols = c(counterpart_name, counterpart_code),
    output_cols = c("entity_id", "entity_name", "entity_type"),
    prefix = "counterpart"
  )
```

## Testing Strategy

1. Test basic functionality with a single target column
2. Test with multiple target columns
3. Test with and without a prefix
4. Test with different output column combinations
5. Test overwriting behavior
6. Test with ambiguous matches
7. Test with unmatched entities
8. Test with different default entity types
9. Test column placement logic
