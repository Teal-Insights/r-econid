#' Standardized Country and Aggregate Mappings to IMF and World Bank Areas
#'
#' A dataset containing geographic groupings mapped to area names used by the
#' IMF and World Bank.
#'
#' @format A data frame with 2587 rows and 3 columns:
#' \describe{
#'   \item{country_name}{Standardized country name}
#'   \item{country_group}{Standardized aggregate name}
#'   \item{group_type}{Either "IMF" or "World Bank"}
#' }
# nolint start
#' @source \url{https://github.com/t-emery/sais-susfin_data/blob/main/datasets/imf_wb_country_groups.csv}
# nolint end
#' @export
"country_aggregates"

#' Country Data with ISO Codes and World Bank Information
#'
#' A dataset containing country information, including ISO codes and World Bank
#' status.
#'
#' @format A data frame with columns:
#' \describe{
#'   \item{country}{Country name}
#'   \item{is_wb_country}{Logical indicating if the country is recognized by the
#'      World Bank}
#'   \item{wb_name}{World Bank name for the country}
#'   \item{cldr_short_en}{CLDR short name for the country}
#'   \item{iso2c}{ISO 3166-1 alpha-2 code}
#'   \item{iso3c}{ISO 3166-1 alpha-3 code}
#'   \item{iso3n}{ISO 3166-1 numeric code}
#'   \item{imf}{IMF code}
#'   \item{continent}{Continent name}
#'   \item{country_name_en_regex}{Standardized country name}
#' }
# nolint start
#' @source \url{https://github.com/t-emery/wbhelpr/blob/master/data-raw/wb_countrycode.csv}
# nolint end
#' @export
"country_codes"

#' World Bank Geographic Entities
#'
#' A dataset containing countries, regions, and other geographic entities from
#' the World Bank's WDI API, enriched with data from other World Bank sources.
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{geography_iso3}{ISO 3166-1 alpha-3 code}
#'   \item{geography_iso2}{ISO 3166-1 alpha-2 code}
#'   \item{geography_name}{Standardized name of the geographic entity}
#'   \item{geography_type}{Type of the geography: "Country" or "Region"}
#' }
#' @source World Bank World Development Indicators API
#' @export
"geographies"

#' World Bank Counterparts
#'
#' A dataset containing counterpart entities from the World Bank's IDS API.
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{counterpart_id}{Unique identifier for the counterpart}
#'   \item{counterpart_name}{Name of the counterpart entity}
#'   \item{geography_iso3}{ISO 3166-1 alpha-3 code, where available}
#'   \item{geography_iso2}{ISO 3166-1 alpha-2 code, where available}
#'   \item{geography_type}{Type of geographic entity (e.g., "Country",
#'         "Region", "Institution")}
#'   \item{counterpart_type}{Classification of the counterpart (e.g.,
#'         "Country", "Global MDBs", "Global IFIs")}
#' }
#' @source World Bank International Debt Statistics API
#' @export
"counterparts"

#' Economy Patterns
#'
#' A dataset containing patterns for matching economy names.
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{economy_name}{Economy name}
#'   \item{economy_regex}{Regular expression pattern for matching economy names}
#'   \item{iso2c}{ISO 3166-1 alpha-2 code}
#'   \item{iso3c}{ISO 3166-1 alpha-3 code}
#' }
#' @source Data manually prepared by Teal L. Emery
#' @export
"economy_patterns"

#' Economy Patterns Test Cases
#'
#' A dataset containing test cases for the economy patterns.
#'
#' @format A data frame with the following columns:
#' \describe{
#'   \item{economy_name}{Economy name}
#'   \item{variant_names}{List of variant names}
#' }
#' @source DeepSeek-V3 API
#' @keywords internal
"test_cases"
