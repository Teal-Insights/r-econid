% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/standardize_entity.R
\name{standardize_entity}
\alias{standardize_entity}
\title{Standardize Entity Identifiers}
\usage{
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
}
\arguments{
\item{data}{A data frame or tibble containing entity identifiers to
standardize}

\item{...}{Columns containing entity names and/or IDs. These can be
specified using unquoted column names (e.g., \code{entity_name}, \code{entity_id})
or quoted column names (e.g., \code{"entity_name"}, \code{"entity_id"}).  Must
specify at least one column. If two columns are specified, the first is
assumed to be the entity name and the second is assumed to be the entity
ID.}

\item{output_cols}{Character vector specifying desired output columns.
Options are "entity_id", "entity_name", "entity_type", "iso3c", "iso2c".
Defaults to c("entity_id", "entity_name", "entity_type").}

\item{prefix}{Optional character string to prefix the output column names.
Useful when standardizing multiple entities in the same dataset (e.g.,
"country", "counterpart"). If provided, output columns will be named
prefix_entity_id, prefix_entity_name, etc. (with an underscore
automatically inserted between the prefix and the column name).}

\item{fill_mapping}{Named character vector specifying how to fill missing
values when no entity match is found. Names should be output column names
(without prefix), and values should be input column names (from \code{...}).
For example, \code{c(entity_id = "country_code", entity_name = "country_name")}
will fill missing entity_id values with values from the country_code column
and missing entity_name values with values from the country_name column.}

\item{default_entity_type}{Character; the default entity type to use for
entities that do not match any of the patterns. Options are "economy",
"organization", "aggregate", or "other". If this argument is not supplied,
the default value will be NA_character_. Argument will be ignored if
output_cols do not include "entity_type".}

\item{warn_ambiguous}{Logical; whether to warn about ambiguous matches}

\item{overwrite}{Logical; whether to overwrite existing entity_* columns}

\item{warn_overwrite}{Logical; whether to warn when overwriting existing
entity_* columns. Defaults to TRUE.}

\item{.before}{Column name or position to insert the standardized columns
before. Defaults to the first target column. Can be a character vector
specifying the column name or a numeric value specifying the column index.
If the specified column is not found in the data, an error is thrown.}
}
\value{
A data frame with standardized entity information merged with the
input data. The standardized columns are placed directly to the left of the
first target column.
}
\description{
Standardizes entity identifiers (e.g., name, ISO code) in an economic data
frame by matching them against a predefined list of regex patterns to add
columns containing standardized identifiers to the data frame.
}
\examples{
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

# Standardize with fill_mapping for unmatched entities
standardize_entity(
  test_df,
  entity, code,
  fill_mapping = c(entity_id = "code", entity_name = "entity")
)

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

}
