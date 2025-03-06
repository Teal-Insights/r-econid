
<a href="https://teal-insights.github.io/r-econid"><img src="man/figures/logo.png" align="right" height="40" alt="r-econid website" /></a>

# econid

<!-- badges: start -->

[![CRAN
status](https://www.r-pkg.org/badges/version/econid)](https://cran.r-project.org/package=econid)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/econid)](https://cran.r-project.org/package=econid)
[![R-CMD-check](https://github.com/Teal-Insights/r-econid/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/Teal-Insights/r-econid/actions/workflows/R-CMD-check.yaml)
[![Lint](https://github.com/Teal-Insights/r-econid/actions/workflows/lint.yaml/badge.svg)](https://github.com/Teal-Insights/r-econid/actions/workflows/lint.yaml)
[![Codecov test
coverage](https://codecov.io/gh/Teal-Insights/r-econid/graph/badge.svg)](https://app.codecov.io/gh/Teal-Insights/r-econid)
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

- Countries and sovereign states
- Territories and administrative regions (e.g., Puerto Rico, Hong Kong)
- Geographic or economic aggregates (e.g., “Sub-Saharan Africa”, “Low
  Income Countries”)
- International institutions (e.g., “World Bank”, “IMF”)

2.  **Inconsistent Naming**

The same entity might appear in various formats:

- Different codes (ISO-2, ISO-3, numeric codes)
- Various name formats (e.g., “United States”, “US”, “U.S.A.”)
- Historical names or non-English variants

3.  **Complex Analysis Needs**

Researchers often need to:

- Compare individual countries with regional aggregates (e.g., Nigeria
  vs. Sub-Saharan Africa)
- Join data across datasets with different naming conventions
- Handle ambiguous cases (e.g., “Congo” could refer to multiple
  countries)
- Work with specialized entities not in standard ISO lists

`econid` addresses these challenges through:

- Robust name standardization with clear entity type identification
- Flexible customization options for special cases
- Warning systems for missing or ambiguous matches
- Tools for fuzzy searching, filtering, and joining across datasets

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

Below is a high-level overview of how `econid` works in practice,
followed by a more detailed description of the main function and its
parameters. The examples and tests illustrate typical usage patterns.

Use these patterns to explore the package and integrate it into your
data cleaning workflows. For finer-grained operations (e.g., fuzzy
filter and search), keep an eye on the package for future enhancements.

### Package Summary

1.  **Input validation**  
    The package checks if your input dataset and specified columns
    exist. It also ensures you only request valid output columns (e.g.,
    `"entity_name"`, `"entity_id"`, `"entity_type"`, `"iso2c"`, and
    `"iso3c"`). Any invalid columns raise an error.

2.  **Name and code matching**  
    The function `standardize_entity()` looks in your dataset for names
    (and optionally codes) that might match an entity. It:

    - Converts the names to UTF-8 for consistent processing.
    - Calls internal functions to try matching each entry via
      case-insensitive regex patterns.
    - If multiple columns are provided, it attempts to match on each in
      sequence, prioritizing matches from earlier columns.
    - If multiple matches exist for a single row, a warning is raised
      (unless suppressed).

3.  **Merging standardized columns**  
    Once the function finds a match, it returns a new or augmented data
    frame with standardized columns (e.g., `"entity_id"`,
    `"entity_name"`, `"entity_type"`, etc.). You control exactly which
    standardized columns appear via the `output_cols` argument.

4.  **Handling missing and custom cases**

    - Custom entities can be added using `add_entity_pattern()` before
      standardization
    - When an entity cannot be matched, it shows `NA` in the
      standardized columns.
    - You can specify how to fill missing values using the
      `fill_mapping` parameter.
    - You can optionally specify a default entity type for unmatched
      entries (`default_entity_type`).
    - Warnings are issued for ambiguous matches if `warn_ambiguous` is
      `TRUE`.

### Workflow

<svg aria-roledescription="flowchart-v2" role="graphics-document document" style="overflow: hidden; max-width: 100%;" class="flowchart" xmlns="http://www.w3.org/2000/svg" width="100%" id="graph-div" height="100%" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events">
<g id="viewport-20250306205000857" class="svg-pan-zoom_viewport" transform="matrix(0.9643654823303223,0,0,0.9643654823303223,281.4239807128906,28.997379302978516)" style="transform: matrix(0.964366, 0, 0, 0.964366, 281.424, 28.9974);">
<style>#graph-div{font-family:"trebuchet ms",verdana,arial,sans-serif;font-size:16px;fill:#333;}#graph-div .error-icon{fill:#552222;}#graph-div .error-text{fill:#552222;stroke:#552222;}#graph-div .edge-thickness-normal{stroke-width:1px;}#graph-div .edge-thickness-thick{stroke-width:3.5px;}#graph-div .edge-pattern-solid{stroke-dasharray:0;}#graph-div .edge-thickness-invisible{stroke-width:0;fill:none;}#graph-div .edge-pattern-dashed{stroke-dasharray:3;}#graph-div .edge-pattern-dotted{stroke-dasharray:2;}#graph-div .marker{fill:#333333;stroke:#333333;}#graph-div .marker.cross{stroke:#333333;}#graph-div svg{font-family:"trebuchet ms",verdana,arial,sans-serif;font-size:16px;}#graph-div p{margin:0;}#graph-div .label{font-family:"trebuchet ms",verdana,arial,sans-serif;color:#333;}#graph-div .cluster-label text{fill:#333;}#graph-div .cluster-label span{color:#333;}#graph-div .cluster-label span p{background-color:transparent;}#graph-div .label text,#graph-div span{fill:#333;color:#333;}#graph-div .node rect,#graph-div .node circle,#graph-div .node ellipse,#graph-div .node polygon,#graph-div .node path{fill:#ECECFF;stroke:#9370DB;stroke-width:1px;}#graph-div .rough-node .label text,#graph-div .node .label text,#graph-div .image-shape .label,#graph-div .icon-shape .label{text-anchor:middle;}#graph-div .node .katex path{fill:#000;stroke:#000;stroke-width:1px;}#graph-div .rough-node .label,#graph-div .node .label,#graph-div .image-shape .label,#graph-div .icon-shape .label{text-align:center;}#graph-div .node.clickable{cursor:pointer;}#graph-div .root .anchor path{fill:#333333!important;stroke-width:0;stroke:#333333;}#graph-div .arrowheadPath{fill:#333333;}#graph-div .edgePath .path{stroke:#333333;stroke-width:2.0px;}#graph-div .flowchart-link{stroke:#333333;fill:none;}#graph-div .edgeLabel{background-color:rgba(232,232,232, 0.8);text-align:center;}#graph-div .edgeLabel p{background-color:rgba(232,232,232, 0.8);}#graph-div .edgeLabel rect{opacity:0.5;background-color:rgba(232,232,232, 0.8);fill:rgba(232,232,232, 0.8);}#graph-div .labelBkg{background-color:rgba(232, 232, 232, 0.5);}#graph-div .cluster rect{fill:#ffffde;stroke:#aaaa33;stroke-width:1px;}#graph-div .cluster text{fill:#333;}#graph-div .cluster span{color:#333;}#graph-div div.mermaidTooltip{position:absolute;text-align:center;max-width:200px;padding:2px;font-family:"trebuchet ms",verdana,arial,sans-serif;font-size:12px;background:hsl(80, 100%, 96.2745098039%);border:1px solid #aaaa33;border-radius:2px;pointer-events:none;z-index:100;}#graph-div .flowchartTitleText{text-anchor:middle;font-size:18px;fill:#333;}#graph-div rect.text{fill:none;stroke-width:0;}#graph-div .icon-shape,#graph-div .image-shape{background-color:rgba(232,232,232, 0.8);text-align:center;}#graph-div .icon-shape p,#graph-div .image-shape p{background-color:rgba(232,232,232, 0.8);padding:2px;}#graph-div .icon-shape rect,#graph-div .image-shape rect{opacity:0.5;background-color:rgba(232,232,232, 0.8);fill:rgba(232,232,232, 0.8);}#graph-div :root{--mermaid-font-family:"trebuchet ms",verdana,arial,sans-serif;}</style>
<g><marker orient="auto" markerHeight="8" markerWidth="8" markerUnits="userSpaceOnUse" refY="5" refX="5" viewBox="0 0 10 10" class="marker flowchart-v2" id="graph-div_flowchart-v2-pointEnd"><path style="stroke-width: 1px; stroke-dasharray: 1px, 0px;" class="arrowMarkerPath" d="M 0 0 L 10 5 L 0 10 z"></path></marker><marker orient="auto" markerHeight="8" markerWidth="8" markerUnits="userSpaceOnUse" refY="5" refX="4.5" viewBox="0 0 10 10" class="marker flowchart-v2" id="graph-div_flowchart-v2-pointStart"><path style="stroke-width: 1px; stroke-dasharray: 1px, 0px;" class="arrowMarkerPath" d="M 0 5 L 10 10 L 10 0 z"></path></marker><marker orient="auto" markerHeight="11" markerWidth="11" markerUnits="userSpaceOnUse" refY="5" refX="11" viewBox="0 0 10 10" class="marker flowchart-v2" id="graph-div_flowchart-v2-circleEnd"><circle style="stroke-width: 1px; stroke-dasharray: 1px, 0px;" class="arrowMarkerPath" r="5" cy="5" cx="5"></circle></marker><marker orient="auto" markerHeight="11" markerWidth="11" markerUnits="userSpaceOnUse" refY="5" refX="-1" viewBox="0 0 10 10" class="marker flowchart-v2" id="graph-div_flowchart-v2-circleStart"><circle style="stroke-width: 1px; stroke-dasharray: 1px, 0px;" class="arrowMarkerPath" r="5" cy="5" cx="5"></circle></marker><marker orient="auto" markerHeight="11" markerWidth="11" markerUnits="userSpaceOnUse" refY="5.2" refX="12" viewBox="0 0 11 11" class="marker cross flowchart-v2" id="graph-div_flowchart-v2-crossEnd"><path style="stroke-width: 2px; stroke-dasharray: 1px, 0px;" class="arrowMarkerPath" d="M 1,1 l 9,9 M 10,1 l -9,9"></path></marker><marker orient="auto" markerHeight="11" markerWidth="11" markerUnits="userSpaceOnUse" refY="5.2" refX="-1" viewBox="0 0 11 11" class="marker cross flowchart-v2" id="graph-div_flowchart-v2-crossStart"><path style="stroke-width: 2px; stroke-dasharray: 1px, 0px;" class="arrowMarkerPath" d="M 1,1 l 9,9 M 10,1 l -9,9"></path></marker><g class="root"><g class="clusters"></g><g class="edgePaths"><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_A_B_0" d="M225.612,86L225.612,90.167C225.612,94.333,225.612,102.667,225.612,110.333C225.612,118,225.612,125,225.612,128.5L225.612,132"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_B_C_1" d="M333.414,214L350.46,220.167C367.505,226.333,401.596,238.667,418.642,250.333C435.687,262,435.687,273,435.687,278.5L435.687,284"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_B_D_2" d="M186.972,214L180.862,220.167C174.752,226.333,162.532,238.667,156.422,257.5C150.313,276.333,150.313,301.667,150.313,325C150.313,348.333,150.313,369.667,155.798,384.121C161.283,398.576,172.253,406.151,177.738,409.939L183.223,413.727"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_B_D_3" d="M225.612,214L225.612,220.167C225.612,226.333,225.612,238.667,225.612,257.5C225.612,276.333,225.612,301.667,225.612,325C225.612,348.333,225.612,369.667,225.612,383.833C225.612,398,225.612,405,225.612,408.5L225.612,412"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_C_D_4" d="M435.687,366L435.687,370.167C435.687,374.333,435.687,382.667,419.502,390.84C403.316,399.013,370.944,407.026,354.759,411.032L338.573,415.039"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_D_E_5" d="M225.612,470L225.612,474.167C225.612,478.333,225.612,486.667,225.612,494.333C225.612,502,225.612,509,225.612,512.5L225.612,516"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_E_F_6" d="M180.653,598L173.545,604.167C166.436,610.333,152.218,622.667,145.109,634.333C138,646,138,657,138,662.5L138,668"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_E_G_7" d="M339.732,598L357.777,604.167C375.822,610.333,411.911,622.667,429.955,634.333C448,646,448,657,448,662.5L448,668"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_F_H_8" d="M138,750L138,754.167C138,758.333,138,766.667,143.166,774.607C148.331,782.547,158.662,790.094,163.828,793.867L168.994,797.641"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_G_H_9" d="M448,750L448,754.167C448,758.333,448,766.667,433.243,775.08C418.485,783.494,388.971,791.988,374.214,796.235L359.456,800.482"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_H_I_10" d="M225.612,878L225.612,882.167C225.612,886.333,225.612,894.667,225.612,902.333C225.612,910,225.612,917,225.612,920.5L225.612,924"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_I_J_11" d="M298.208,1030L306.986,1036.167C315.764,1042.333,333.319,1054.667,342.097,1066.333C350.875,1078,350.875,1089,350.875,1094.5L350.875,1100"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_I_K_12" d="M196.657,1030L193.156,1036.167C189.655,1042.333,182.652,1054.667,179.151,1073.5C175.65,1092.333,175.65,1117.667,175.65,1141C175.65,1164.333,175.65,1185.667,178.493,1199.975C181.335,1214.282,187.02,1221.565,189.863,1225.206L192.705,1228.847"></path><path marker-end="url(#graph-div_flowchart-v2-pointEnd)" style="" class="edge-thickness-normal edge-pattern-solid edge-thickness-normal edge-pattern-solid flowchart-link" id="L_J_K_13" d="M350.875,1182L350.875,1186.167C350.875,1190.333,350.875,1198.667,343.314,1206.697C335.752,1214.727,320.629,1222.453,313.068,1226.317L305.506,1230.18"></path></g><g class="edgeLabels"><g class="edgeLabel"><g transform="translate(0, 0)" class="label"><foreignObject height="0" width="0">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel"></span>

</div>

</foreignObject></g></g><g transform="translate(435.68749618530273, 251)" class="edgeLabel"><g transform="translate(-13.050003051757812, -12)" class="label"><foreignObject height="24" width="26.100006103515625">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel">
<p>
Yes
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(150.31250381469727, 327)" class="edgeLabel"><g transform="translate(-10.224998474121094, -12)" class="label"><foreignObject height="24" width="20.449996948242188">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel">
<p>
No
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(225.61249923706055, 327)" class="edgeLabel"><g transform="translate(-45.07499694824219, -12)" class="label"><foreignObject height="24" width="90.14999389648438">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel">
<p>
Yes, but skip
</p>
</span>

</div>

</foreignObject></g></g><g class="edgeLabel"><g transform="translate(0, 0)" class="label"><foreignObject height="0" width="0">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel"></span>

</div>

</foreignObject></g></g><g class="edgeLabel"><g transform="translate(0, 0)" class="label"><foreignObject height="0" width="0">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel"></span>

</div>

</foreignObject></g></g><g transform="translate(138, 635)" class="edgeLabel"><g transform="translate(-45.80833435058594, -12)" class="label"><foreignObject height="24" width="91.61666870117188">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel">
<p>
Leave as NA
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(448, 635)" class="edgeLabel"><g transform="translate(-89.80833435058594, -12)" class="label"><foreignObject height="24" width="179.61666870117188">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel">
<p>
Fill from existing columns
</p>
</span>

</div>

</foreignObject></g></g><g class="edgeLabel"><g transform="translate(0, 0)" class="label"><foreignObject height="0" width="0">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel"></span>

</div>

</foreignObject></g></g><g class="edgeLabel"><g transform="translate(0, 0)" class="label"><foreignObject height="0" width="0">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel"></span>

</div>

</foreignObject></g></g><g class="edgeLabel"><g transform="translate(0, 0)" class="label"><foreignObject height="0" width="0">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel"></span>

</div>

</foreignObject></g></g><g transform="translate(350.87499618530273, 1067)" class="edgeLabel"><g transform="translate(-13.050003051757812, -12)" class="label"><foreignObject height="24" width="26.100006103515625">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel">
<p>
Yes
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(175.64999771118164, 1143)" class="edgeLabel"><g transform="translate(-10.224998474121094, -12)" class="label"><foreignObject height="24" width="20.449996948242188">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel">
<p>
No
</p>
</span>

</div>

</foreignObject></g></g><g class="edgeLabel"><g transform="translate(0, 0)" class="label"><foreignObject height="0" width="0">

<div class="labelBkg" xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="edgeLabel"></span>

</div>

</foreignObject></g></g></g><g class="nodes"><g transform="translate(225.61249923706055, 47)" id="flowchart-A-84" class="node default"><rect height="78" width="260" y="-39" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -24)" style="" class="label"><rect></rect><foreignObject height="48" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
Start with data containing economic entities
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(225.61249923706055, 175)" id="flowchart-B-85" class="node default"><rect height="78" width="260" y="-39" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -24)" style="" class="label"><rect></rect><foreignObject height="48" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
Non-standard entities without ISO codes?
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(435.68749618530273, 327)" id="flowchart-C-87" class="node default"><rect height="78" width="260" y="-39" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -24)" style="" class="label"><rect></rect><foreignObject height="48" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
Add custom entity patterns with add_entity_pattern
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(225.61249923706055, 443)" id="flowchart-D-89" class="node default"><rect height="54" width="250.38333129882812" y="-27" x="-125.19166564941406" style="" class="basic label-container"></rect><g transform="translate(-95.19166564941406, -12)" style="" class="label"><rect></rect><foreignObject height="24" width="190.38333129882812">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table-cell; white-space: nowrap; line-height: 1.5; max-width: 200px; text-align: center;">

<span class="nodeLabel">
<p>
Proceed to standardization
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(225.61249923706055, 559)" id="flowchart-E-95" class="node default"><rect height="78" width="260" y="-39" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -24)" style="" class="label"><rect></rect><foreignObject height="48" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
How to handle unmatched entities?
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(138, 711)" id="flowchart-F-97" class="node default"><rect height="78" width="260" y="-39" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -24)" style="" class="label"><rect></rect><foreignObject height="48" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
Omit fill_mapping and default_entity_type args
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(448, 711)" id="flowchart-G-99" class="node default"><rect height="78" width="260" y="-39" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -24)" style="" class="label"><rect></rect><foreignObject height="48" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
Use fill_mapping and default_entity_type
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(225.61249923706055, 839)" id="flowchart-H-101" class="node default"><rect height="78" width="260" y="-39" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -24)" style="" class="label"><rect></rect><foreignObject height="48" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
Call standardize_entity with data and identifier columns
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(225.61249923706055, 979)" id="flowchart-I-105" class="node default"><rect height="102" width="260" y="-51" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -36)" style="" class="label"><rect></rect><foreignObject height="72" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
Additional column to standardize in same dataframe?
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(350.87499618530273, 1143)" id="flowchart-J-107" class="node default"><rect height="78" width="260" y="-39" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -24)" style="" class="label"><rect></rect><foreignObject height="48" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
Call standardize_entity again with prefix parameter
</p>
</span>

</div>

</foreignObject></g></g><g transform="translate(225.61249923706055, 1271)" id="flowchart-K-109" class="node default"><rect height="78" width="260" y="-39" x="-130" style="" class="basic label-container"></rect><g transform="translate(-100, -24)" style="" class="label"><rect></rect><foreignObject height="48" width="200">

<div xmlns="http://www.w3.org/1999/xhtml"
style="display: table; white-space: break-spaces; line-height: 1.5; max-width: 200px; text-align: center; width: 200px;">

<span class="nodeLabel">
<p>
Analysis-ready data with standardized entities
</p>
</span>

</div>

</foreignObject></g></g></g></g></g></g><defs>
<style id="svg-pan-zoom-controls-styles" type="text/css">.svg-pan-zoom-control { cursor: pointer; fill: black; fill-opacity: 0.333; } .svg-pan-zoom-control:hover { fill-opacity: 0.8; } .svg-pan-zoom-control-background { fill: white; fill-opacity: 0.5; } .svg-pan-zoom-control-background { fill-opacity: 0.8; }</style>
</defs><g id="svg-pan-zoom-controls" transform="translate(1834 428) scale(0.75)" class="svg-pan-zoom-control"><g id="svg-pan-zoom-zoom-in" transform="translate(30.5 5) scale(0.015)" class="svg-pan-zoom-control"><rect x="0" y="0" width="1500" height="1400" class="svg-pan-zoom-control-background"></rect><path d="M1280 576v128q0 26 -19 45t-45 19h-320v320q0 26 -19 45t-45 19h-128q-26 0 -45 -19t-19 -45v-320h-320q-26 0 -45 -19t-19 -45v-128q0 -26 19 -45t45 -19h320v-320q0 -26 19 -45t45 -19h128q26 0 45 19t19 45v320h320q26 0 45 19t19 45zM1536 1120v-960 q0 -119 -84.5 -203.5t-203.5 -84.5h-960q-119 0 -203.5 84.5t-84.5 203.5v960q0 119 84.5 203.5t203.5 84.5h960q119 0 203.5 -84.5t84.5 -203.5z" class="svg-pan-zoom-control-element"></path></g><g id="svg-pan-zoom-reset-pan-zoom" transform="translate(5 35) scale(0.4)" class="svg-pan-zoom-control"><rect x="2" y="2" width="182" height="58" class="svg-pan-zoom-control-background"></rect><path d="M33.051,20.632c-0.742-0.406-1.854-0.609-3.338-0.609h-7.969v9.281h7.769c1.543,0,2.701-0.188,3.473-0.562c1.365-0.656,2.048-1.953,2.048-3.891C35.032,22.757,34.372,21.351,33.051,20.632z" class="svg-pan-zoom-control-element"></path><path d="M170.231,0.5H15.847C7.102,0.5,0.5,5.708,0.5,11.84v38.861C0.5,56.833,7.102,61.5,15.847,61.5h154.384c8.745,0,15.269-4.667,15.269-10.798V11.84C185.5,5.708,178.976,0.5,170.231,0.5z M42.837,48.569h-7.969c-0.219-0.766-0.375-1.383-0.469-1.852c-0.188-0.969-0.289-1.961-0.305-2.977l-0.047-3.211c-0.03-2.203-0.41-3.672-1.142-4.406c-0.732-0.734-2.103-1.102-4.113-1.102h-7.05v13.547h-7.055V14.022h16.524c2.361,0.047,4.178,0.344,5.45,0.891c1.272,0.547,2.351,1.352,3.234,2.414c0.731,0.875,1.31,1.844,1.737,2.906s0.64,2.273,0.64,3.633c0,1.641-0.414,3.254-1.242,4.84s-2.195,2.707-4.102,3.363c1.594,0.641,2.723,1.551,3.387,2.73s0.996,2.98,0.996,5.402v2.32c0,1.578,0.063,2.648,0.19,3.211c0.19,0.891,0.635,1.547,1.333,1.969V48.569z M75.579,48.569h-26.18V14.022h25.336v6.117H56.454v7.336h16.781v6H56.454v8.883h19.125V48.569z M104.497,46.331c-2.44,2.086-5.887,3.129-10.34,3.129c-4.548,0-8.125-1.027-10.731-3.082s-3.909-4.879-3.909-8.473h6.891c0.224,1.578,0.662,2.758,1.316,3.539c1.196,1.422,3.246,2.133,6.15,2.133c1.739,0,3.151-0.188,4.236-0.562c2.058-0.719,3.087-2.055,3.087-4.008c0-1.141-0.504-2.023-1.512-2.648c-1.008-0.609-2.607-1.148-4.796-1.617l-3.74-0.82c-3.676-0.812-6.201-1.695-7.576-2.648c-2.328-1.594-3.492-4.086-3.492-7.477c0-3.094,1.139-5.664,3.417-7.711s5.623-3.07,10.036-3.07c3.685,0,6.829,0.965,9.431,2.895c2.602,1.93,3.966,4.73,4.093,8.402h-6.938c-0.128-2.078-1.057-3.555-2.787-4.43c-1.154-0.578-2.587-0.867-4.301-0.867c-1.907,0-3.428,0.375-4.565,1.125c-1.138,0.75-1.706,1.797-1.706,3.141c0,1.234,0.561,2.156,1.682,2.766c0.721,0.406,2.25,0.883,4.589,1.43l6.063,1.43c2.657,0.625,4.648,1.461,5.975,2.508c2.059,1.625,3.089,3.977,3.089,7.055C108.157,41.624,106.937,44.245,104.497,46.331z M139.61,48.569h-26.18V14.022h25.336v6.117h-18.281v7.336h16.781v6h-16.781v8.883h19.125V48.569z M170.337,20.14h-10.336v28.43h-7.266V20.14h-10.383v-6.117h27.984V20.14z" class="svg-pan-zoom-control-element"></path></g><g id="svg-pan-zoom-zoom-out" transform="translate(30.5 70) scale(0.015)" class="svg-pan-zoom-control"><rect x="0" y="0" width="1500" height="1400" class="svg-pan-zoom-control-background"></rect><path d="M1280 576v128q0 26 -19 45t-45 19h-896q-26 0 -45 -19t-19 -45v-128q0 -26 19 -45t45 -19h896q26 0 45 19t19 45zM1536 1120v-960q0 -119 -84.5 -203.5t-203.5 -84.5h-960q-119 0 -203.5 84.5t-84.5 203.5v960q0 119 84.5 203.5t203.5 84.5h960q119 0 203.5 -84.5 t84.5 -203.5z" class="svg-pan-zoom-control-element"></path></g></g>
</svg>

### `standardize_entity()` Function

``` r
# Basic example
df <- data.frame(
  entity = c("United States", "China", "NotACountry"),
  code = c("USA", "CHN", "ZZZ"),
  obs_value = c(1, 2, 3)
)

# Using with dplyr pipeline
library(dplyr)

df |>
  standardize_entity(entity, code) |>
  filter(!is.na(entity_id)) |>
  mutate(entity_category = case_when(
    entity_type == "economy" ~ "Country",
    TRUE ~ "Other"
  )) |>
  select(entity_name, entity_category, obs_value)
```

    ##     entity_name entity_category obs_value
    ## 1 United States         Country         1
    ## 2         China         Country         2

You can also use the function directly without a pipeline:

``` r
standardize_entity(
  data = df,
  entity, code,
  output_cols = c("entity_id", "entity_name", "entity_type"),
  fill_mapping = c(entity_name = "entity"),
  default_entity_type = NA_character_,
  warn_ambiguous = TRUE
)
```

    ##   entity_id   entity_name entity_type        entity code obs_value
    ## 1       USA United States     economy United States  USA         1
    ## 2       CHN         China     economy         China  CHN         2
    ## 3      <NA>   NotACountry        <NA>   NotACountry  ZZZ         3

#### Parameters

- **data**  
  A data frame (or tibble) containing the entities to be standardized.

- **…**  
  Columns containing entity names and/or IDs. These can be specified
  using unquoted column names (e.g., `entity_name`) or quoted column
  names (e.g., `"entity_name"`). Must specify at least one column. If
  multiple columns are specified, the function tries each in sequence,
  prioritizing matches from earlier columns.

- **output_cols** *(optional)*  
  A character vector of columns to include in the final output. Valid
  options:

  - `"entity_id"`  
  - `"entity_name"`  
  - `"entity_type"`  
  - `"iso3c"`  
  - `"iso2c"`

  Defaults to `c("entity_id", "entity_name", "entity_type")`.

- **prefix** *(optional)*  
  A character string to prefix the output column names. Useful when
  standardizing multiple entities in the same dataset (e.g., “country”,
  “counterpart”).

- **fill_mapping** *(optional)*  
  A named character vector specifying how to fill missing values when no
  entity match is found. Names should be output column names (without
  prefix), and values should be input column names (from `...`).

- **default_entity_type** *(optional)*  
  A character scalar (`"economy"`, `"organization"`, `"aggregate"`, or
  `"other"`) to assign as the entity type where no match is found. This
  value only applies if `"entity_type"` is requested in `output_cols`.
  The four valid values were selected to cover the most common economic
  use cases:

  - `"economy"`: A legal or quasi-legal jurisdiction such as a country
    or autonomous region (e.g., “United States”, “Democratic Autonomous
    Administration of North and East Syria”)
  - `"organization"`: An institution or organization such as a bank or
    international agency (e.g., “World Bank”, “IMF”)
  - `"aggregate"`: A geographic or economic aggregate such as a region
    or development group (e.g., “Sub-Saharan Africa”, “Low Income
    Countries”)
  - `"other"`: Anything that doesn’t fit into the other categories
    (e.g., “Elon Musk”, “The Moon”)

- **warn_ambiguous** *(optional)*  
  A logical indicating whether to warn if a single row in `data` can
  match more than one entity. Defaults to `TRUE`.

- **overwrite** *(optional)*  
  A logical indicating whether to overwrite existing entity columns.
  Defaults to `TRUE`.

- **warn_overwrite** *(optional)*  
  A logical indicating whether to warn when overwriting existing entity
  columns. Defaults to `TRUE`.

- **.before** *(optional)*  
  Column name or position to insert the standardized columns before. If
  NULL (default), columns are inserted at the beginning of the
  dataframe. Can be a character vector specifying the column name or a
  numeric value specifying the column index.

#### Returns

A data frame (or tibble) the same size as `data`, augmented with the
requested standardized columns.

### Working with Multiple Entities

The `standardize_entity()` function can be used to standardize multiple
entities in the same dataset by using the `prefix` parameter:

``` r
df <- data.frame(
  country_name = c("United States", "France"),
  counterpart_name = c("China", "Germany")
)

df |>
  standardize_entity(country_name) |>
  standardize_entity(counterpart_name, prefix = "counterpart")
```

    ##   counterpart_entity_id counterpart_entity_name counterpart_entity_type
    ## 1                   CHN                   China                 economy
    ## 2                   DEU                 Germany                 economy
    ##   entity_id   entity_name entity_type  country_name counterpart_name
    ## 1       USA United States     economy United States            China
    ## 2       FRA        France     economy        France          Germany

### `add_entity_pattern()` Function

The `add_entity_pattern()` function allows you to add custom entity
patterns to the package. This is useful if you need to standardize
entities that are not in the default list.

``` r
add_entity_pattern(
  "BJ-CITY",
  "Beijing City",
  entity_type = "economy",
  aliases = c("Beijing Municipality")
)

df_custom <- data.frame(entity = c("United States", "Beijing Municipality"))
result_custom <- standardize_entity(df_custom, entity)
print(result_custom)
```

    ##   entity_id   entity_name entity_type               entity
    ## 1       USA United States     economy        United States
    ## 2   BJ-CITY  Beijing City     economy Beijing Municipality

### `reset_custom_entity_patterns()` Function

The `reset_custom_entity_patterns()` function allows you to clear all
custom entity patterns that have been added during the current R
session. This is useful when you want to start fresh with only the
default entity patterns.

## Contributing

We welcome your feedback and contributions! Please submit suggestions
for improvements and extensions on the package’s [Github
Issues](https://github.com/Teal-Insights/r-econid/issues) page.
