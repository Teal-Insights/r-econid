

<a href="https://teal-insights.github.io/r-econid"><img src="man/figures/logo.png" align="right" height="40" alt="r-econid website" /></a>

# econid

<!-- badges: start -->

[![R-CMD-check](https://github.com/Teal-Insights/r-econid/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Teal-Insights/r-econid/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Overview

The `econid` R package is a foundational building block of the
[econdataverse](https://econdataverse.org) family of packages aimed at
helping economists and financial professionals work with sovereign-level
economic data. The package is aimed at domain experts in economics and
finance who need to analyze and join data across multiple sources, but
who aren’t necessarily R programming experts.

## Motivation

Economic and financial datasets present unique challenges when working
with country-level data:

1.  **Mixed Entity Types**

Datasets often combine different types of entities in the same “country”
column:

-   Countries and sovereign states
-   Territories and administrative regions (e.g., Puerto Rico, Hong
    Kong)
-   Geographic or economic aggregates (e.g., “Sub-Saharan Africa”, “Low
    Income Countries”)
-   International institutions (e.g., “World Bank”, “IMF”)

1.  **Inconsistent Naming**

The same entity might appear in various formats:

-   Different codes (ISO-2, ISO-3, numeric codes)
-   Various name formats (e.g., “United States”, “US”, “U.S.A.”)
-   Historical names or non-English variants

1.  **Complex Analysis Needs**

Researchers often need to:

-   Compare individual countries with regional aggregates (e.g., Nigeria
    vs. Sub-Saharan Africa)
-   Join data across datasets with different naming conventions
-   Handle ambiguous cases (e.g., “Congo” could refer to multiple
    countries)
-   Work with specialized entities not in standard ISO lists

`econid` addresses these challenges through:

-   Robust name standardization with clear entity type identification
-   Flexible customization options for special cases
-   Warning systems for missing or ambiguous matches
-   Tools for fuzzy searching, filtering, and joining across datasets

## Design Philosophy

The design philosophy of the package follows [tidyverse
principles](https://www.tidyverse.org/principles/) and the [tidy tools
manifesto](https://www.tidyverse.org/manifesto/). We strive to practice
human-centered design, with clear documentation and examples and
graceful handling of edge cases. We invite you to submit suggestions for
improvements and extensions on the package’s [Github
Issues](https://github.com/Teal-Insights/r-econid/issues) page.

We have designed the package to handle only the most common entities
financial and economic professionals might encounter in a dataset (249
in total), not to handle every edge case. However, the package allows
users to extend the standardization list with custom entities to
flexibly accommodate any unconventional use case.

## Installation

Until the package is published on CRAN, you can install it from GitHub
using the `remotes` package.

``` r
remotes::install_github("Teal-Insights/r-econid")
```

Then, load the package in your R session or Quarto or RMarkdown
notebook:

``` r
library(econid)
```

## Usage

### Program flow

<figure class=''>

<img src="README_files\figure-markdown_strict\mermaid-figure-1.png"
style="width:12.35in;height:17.01in" />

</figure>

### The `standardize_economy()` function

The core function in the package is `standardize_economy()`, which takes
the following arguments:

-   A tibble containing unstandardized country names
-   The name of the column containing these names
-   An optional column containing codes (particularly useful for
    aggregates)
-   Optional `custom_data` for adding new entities
-   Optional `name_aliases` for common variants

The function returns:

-   `economy_name`: standardized name
-   `economy_id`: iso3c code for countries, custom ID for aggregates
-   `economy_type`: distinguishes between “Country/Economy” and
    “Aggregate”

### Extending the standardization list with custom entities

The `standardize_economy()` function allows users to extend the
standardization list with custom entities. This is particularly useful
for:

-   Small territories not in standard ISO lists
-   Newly independent states
-   Special administrative regions
-   Custom aggregate entities specific to a project

Here is an example of how to extend the standardization list with a
custom entity:

``` r
custom_data <- tibble::tibble(
  country.name.en = "Kosovo",
  country.name.en.regex = "kosovo",
  iso3c = "XKX",
  iso2c = "XK"
)

standardize_economy(
  data = data,
  col = "country.name.en",
  custom_data = custom_data
)
```

### Adding name aliases

The `standardize_economy()` function allows users to add name aliases
for common variants of entity names. This is useful for:

-   Common abbreviations or alternate names
-   Historical names
-   Non-English names that appear in datasets

The `name_aliases` argument should be a named vector directly mapping
non-standard names to standard ones. Here is an example of how to add
name aliases:

``` r
name_aliases <- c(
  "the states" = "United States",
  "republic of korea" = "South Korea",
  "holland" = "Netherlands"
)

standardize_economy(
  data = data,
  col = "country.name.en",
  name_aliases = name_aliases
)
```

## Roadmap

-   Users should be able to extend the list
-   Users should be able to add the standardized columns to any table
-   Maybe a fuzzy join function
-   And a fuzzy filter function
