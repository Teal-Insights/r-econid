# Install wbids if not installed
if (!requireNamespace("wbids", quietly = TRUE)) {
  install.packages("wbids")
}

# Try to load the cached data from data/wbids_data.rds
if (file.exists("bench/data/wbids_data.rds")) {
  data <- readRDS("bench/data/wbids_data.rds")
} else {
  # Download data from World Bank
  data <- wbids::ids_get(
    geographies = wbids::ids_list_geographies()$geography_id[1:60],
    series = c("DT.DOD.DPPG.CD"),
    counterparts = c("all"),
    start_year = 2015,
    end_year = 2020
  )
  # Save the data to data/wbids_data.rds
  saveRDS(data, "bench/data/wbids_data.rds")
}

# Benchmark the standardization
result <- bench::mark(
  econid::standardize_entity(
    data, geography_id, prefix = "country"
  ),
  iterations = 10,
)

# Print the result
print(result)

# Save the result
saveRDS(result, "bench/benchmark_standardize_economy.rds")