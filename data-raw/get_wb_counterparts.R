library(httr2)
library(jsonlite)
library(dplyr)
library(tidyr)
library(stringr)

# Fetch countries and regions from World Bank WDI API ----

url_wdi <- "https://api.worldbank.org/v2/countries?per_page=32500&format=json"

geographies_raw <- request(url_wdi) |>
  req_perform() |>
  resp_body_json()

aggregates <- geographies_raw[[2]] |>
  bind_rows() |>
  unnest(region) |>
  filter(region == "Aggregates") |>
  pull(id)

geographies_wdi <- geographies_raw[[2]] |>
  bind_rows() |>
  select(
    geography_iso3 = id,
    geography_iso2 = iso2Code,
    geography_name = name
  ) |>
  distinct() |>
  mutate(geography_type = if_else(
    geography_iso3 %in% aggregates, "aggregate", "economy"
  ))

# Fetch counterparts from World Bank International Debt Statistics API  ----

url_ids <- paste0(
  "https://api.worldbank.org/v2/sources/",
  "6/counterpart-area?per_page=32500&format=json"
)

counterparts_raw <- request(url_ids) |>
  req_perform() |>
  resp_body_json()

counterparts_ids <- counterparts_raw$source[[1]]$concept[[1]]$variable |>
  bind_rows() |>
  select(counterpart_id = id,
         counterpart_name = value) |>
  mutate(across(where(is.character), str_trim))

# Enrich counterparts with codes and types -------------------------------

# Used ChatGPT to create this tribble, but also checked for most countries
geographies_manual <- tribble(
  ~geography_name, ~geography_iso2, ~geography_iso3, ~geography_type,
  "African Dev. Bank", NA, NA, "organization",
  "African Export-Import Bank", NA, NA, "organization",
  "Anguilla", "AI", "AIA", "economy",
  "Antigua", "AG", "ATG", "economy",
  "Arab African International Bank", NA, NA, "organization",
  "Arab Bank for Economic Dev. in Africa (BADEA)", NA, NA, "organization",
  "Arab Fund for Economic & Social Development", NA, NA, "organization",
  "Arab Fund for Tech. Assist. to African Countries", NA, NA, "organization",
  "Arab International Bank", NA, NA, "organization",
  "Arab League", NA, NA, "organization",
  "Arab Monetary Fund", NA, NA, "organization",
  "Arab Towns Organization (ATO)", NA, NA, "organization",
  "Asian Dev. Bank", NA, NA, "organization",
  "Asian Infrastructure Investment Bank", NA, NA, "organization",
  "Bahamas", "BS", "BHS", "economy",
  "Bank for International Settlements (BIS)", NA, NA, "organization",
  "Bolivarian Alliance for the Americas (ALBA)", NA, NA, "organization",
  "Bondholders", NA, NA, "organization",
  "Bosnia-Herzegovina", "BA", "BIH", "economy",
  "Brunei", "BN", "BRN", "economy",
  "Caribbean Community (CARICOM)", NA, NA, "organization",
  "Caribbean Dev. Bank", NA, NA, "organization",
  "Center for Latin American Monetary Studies (CEMLA)", NA, NA, "organization",
  "Central American Bank for Econ. Integ. (CABEI)", NA, NA, "organization",
  "Central American Bank for Econ. Integration (BCIE)", NA, NA, "organization",
  "Central Bank of West African States (BCEAO)", NA, NA, "organization",
  "Colombo Plan", NA, NA, "organization",
  "Corporacion Andina de Fomento", NA, NA, "organization",
  "Cote D`Ivoire, Republic Of", "CI", "CIV", "economy",
  "Council of Europe", NA, NA, "organization",
  "Czechoslovakia", "CS", "CSK", "economy",
  "Dev. Bank of the Central African States (BDEAC)", NA, NA, "organization",
  "ECO Trade and Dev. Bank", NA, NA, "organization",
  "EUROFIMA", NA, NA, "organization",
  "East African Community", NA, NA, "organization",
  "Eastern & Southern African Trade & Dev. Bank (TDB)", NA, NA, "organization",
  "Econ. Comm. of the Great Lakes Countries (ECGLC)", NA, NA, "organization",
  "Economic Community of West African States (ECOWAS)", NA, NA, "organization",
  "Egypt", "EG", "EGY", "economy",
  "Entente Council", NA, NA, "organization",
  "Eurasian Development Bank", NA, NA, "organization",
  "European Bank for Reconstruction and Dev. (EBRD)", NA, NA, "organization",
  "European Coal and Steel Community (ECSC)", NA, NA, "organization",
  "European Development Fund (EDF)", NA, NA, "organization",
  "European Economic Community (EEC)", NA, NA, "organization",
  "European Free Trade Association (EFTA)", NA, NA, "organization",
  "European Investment Bank", NA, NA, "organization",
  "European Relief Fund", NA, NA, "organization",
  "European Social Fund (ESF)", NA, NA, "organization",
  "Fondo Latinoamericano de Reservas (FLAR)", NA, NA, "organization",
  "Food and Agriculture Organization (FAO)", NA, NA, "organization",
  "Foreign Trade Bank of Latin America (BLADEX)", NA, NA, "organization",
  "German Dem. Rep.", "DD", "DDR", "economy",
  "Germany, Fed. Rep. of", "DE", "DEU", "economy",
  "Global Environment Facility", NA, NA, "organization",
  "Guadeloupe", "GP", "GLP", "economy",
  "Hong Kong", "HK", "HKG", "economy",
  "Inter-American Dev. Bank", NA, NA, "organization",
  "International Bank for Economic Cooperation (IBEC)", NA, NA, "organization",
  "International Coffee Organization (ICO)", NA, NA, "organization",
  "International Finance Corporation", NA, NA, "organization",
  "International Fund for Agricultural Dev.", NA, NA, "organization",
  "International Investment Bank (IIB)", NA, NA, "organization",
  "International Labour Organization (ILO)", NA, NA, "organization",
  "International Monetary Fund", NA, NA, "organization",
  "Iran, Islamic Republic Of", "IR", "IRN", "economy",
  "Islamic Dev. Bank", NA, NA, "organization",
  "Islamic Solidarity Fund for Dev. (ISFD)", NA, NA, "organization",
  "Korea, D.P.R. of", "KP", "PRK", "economy",
  "Korea, Republic of", "KR", "KOR", "economy",
  "Lao People's Democratic Rep.", "LA", "LAO", "economy",
  "Latin Amer. Conf. of Saving & Credit Coop. (COLAC)", NA, NA, "organization",
  "Latin American Agribusiness Dev. Corp. (LAAD)", NA, NA, "organization",
  "Macao", "MO", "MAC", "economy",
  "Micronesia Fed Sts", "FM", "FSM", "economy",
  "Montreal Protocol Fund", NA, NA, "organization",
  "Multiple Lenders", NA, NA, "Other",
  "Neth. Antilles", "AN", "ANT", "economy",
  "New Caledonia (Fr.)", "NC", "NCL", "economy",
  "Nordic Development Fund", NA, NA, "organization",
  "Nordic Environment Finance Corporation (NEFCO)", NA, NA, "organization",
  "Nordic Investment Bank", NA, NA, "organization",
  "OPEC Fund for International Dev.", NA, NA, "organization",
  "Org. of Arab Petroleum Exporting Countries (OAPEC)", NA, NA, "organization",
  "Other Multiple Lenders", NA, NA, "Other",
  "Pacific Is. (Us)", NA, NA, "organization",
  "Plata Basin Financial Dev. Fund", NA, NA, "organization",
  "Reunion", "RE", "REU", "economy",
  "Sao Tome & Principe", "ST", "STP", "economy",
  "South Asian Development Fund (SADF)", NA, NA, "organization",
  "St. Kitts And Nevis", "KN", "KNA", "economy",
  "St. Vincent & The Grenadines", "VC", "VCT", "economy",
  "Surinam", "SR", "SUR", "economy",
  "Trinidad & Tobago", "TT", "TTO", "economy",
  "USSR", "SU", "SUN", "economy",
  "UN-Children's Fund (UNICEF)", NA, NA, "organization",
  "UN-Development Fund for Women (UNIFEM)", NA, NA, "organization",
  "UN-Development Programme (UNDP)", NA, NA, "organization",
  "UN-Educ., Scientific and Cultural Org. (UNESCO)", NA, NA, "organization",
  "UN-Environment Programme (UNEP)", NA, NA, "organization",
  "UN-Fund for Drug Abuse Control (UNFDAC)", NA, NA, "organization",
  "UN-Fund for Human Rights", NA, NA, "organization",
  "UN-General Assembly (UNGA)", NA, NA, "organization",
  "UN-High Commissioner for Refugees (UNHCR)", NA, NA, "organization",
  "UN-INSTRAW", NA, NA, "organization",
  "UN-Industrial Development Organization (UNIDO)", NA, NA, "organization",
  "UN-Office on Drugs and Crime (UNDCP)", NA, NA, "organization",
  "UN-Population Fund (UNFPA)", NA, NA, "organization",
  "UN-Regular Programme of Technical Assistance", NA, NA, "organization",
  "UN-Regular Programme of Technical Coop. (RPTC)", NA, NA, "organization",
  "UN-Relief and Works Agency (UNRWA)", NA, NA, "organization",
  "UN-UNETPSA", NA, NA, "organization",
  "UN-World Food Programme (WFP)", NA, NA, "organization",
  "UN-World Intellectual Property Organization", NA, NA, "organization",
  "UN-World Meteorological Organization", NA, NA, "organization",
  "Venezuela, Republic Bolivarian", "VE", "VEN", "economy",
  "Virgin Is.(US)", "VI", "VIR", "economy",
  "West African Development Bank - BOAD", NA, NA, "organization",
  "West African Monetary Union (UMOA)", NA, NA, "organization",
  "World Bank-IBRD", NA, NA, "organization",
  "World Bank-IDA", NA, NA, "organization",
  "World Bank-MIGA", NA, NA, "organization",
  "World Health Organization", NA, NA, "organization",
  "World Trade Organization", NA, NA, "organization",
  "Yemen, Republic Of", "YE", "YEM", "economy",
  "Yugoslavia", "YU", "YUG", "economy"
)

counterparts_ids_enriched <- counterparts_ids |>
  left_join(
    bind_rows(geographies_wdi, geographies_manual),
    join_by(counterpart_name == geography_name)
  )

# Some counterparts have better names from WDI (e.g. Germany)
counterparts_ids_cleaned <- counterparts_ids_enriched |>
  left_join(
    geographies_wdi, join_by(geography_iso2, geography_iso3, geography_type)
  ) |>
  mutate(counterpart_name = if_else(
    !is.na(geography_name), geography_name, counterpart_name
  )) |>
  select(-geography_name)

global_ifis <- c(
  "International Monetary Fund",
  "Bank for International Settlements (BIS)"
)

global_mdbs <- c(
  "World Bank-IDA",
  "World Bank-IBRD",
  "World Bank-MIGA",
  "International Finance Corporation",
  "International Fund for Agricultural Dev.",
  "European Bank for Reconstruction and Dev. (EBRD)",
  "African Dev. Bank",
  "Asian Dev. Bank",
  "Inter-American Dev. Bank",
  "Asian Infrastructure Investment Bank"
)

counterparts <- counterparts_ids_cleaned |>
  mutate(
    counterpart_type = case_when(
      counterpart_name %in% global_ifis ~ "Global IFIs",
      counterpart_name %in% global_mdbs ~ "Global MDBs",
      counterpart_name %in% c("Bondholders") ~ "Bondholders",
      counterpart_name %in% c("World") ~ "All Creditors",
      geography_type == "economy" ~ "economy",
      geography_type == "Region" ~ "Region",
      .default = "Other"
    )
  )


# Use processed counterparts to enrich geographies -----------------------

geographies <- geographies_wdi |>
  bind_rows(
    counterparts |>
      filter(!is.na(geography_iso3)) |>
      select(contains("geography"), geography_name = counterpart_name)
  ) |>
  distinct() |>
  arrange(geography_iso3)

# Save data --------------------------------------------------------------

usethis::use_data(
  geographies, counterparts,
  overwrite = TRUE, internal = TRUE
)
