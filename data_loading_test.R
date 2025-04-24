library(shipdetectR)

# Get the internal raster and shapefile paths
raster_path <- system.file("extdata", "package_basis_subset_TC_vh_intensity.tif", package = "shipdetectR")
shapefile_path <- system.file("extdata", "iho.shp", package = "shipdetectR")

print(raster_path)
print(shapefile_path)

# Check that the files actually exist
stopifnot(file.exists(raster_path))
stopifnot(file.exists(shapefile_path))

# Run the wrapper with internal data
results <- detect_all_ships(
  raster_path = raster_path,
  water_shapefile_path = shapefile_path,
  output_path = tempfile(fileext = ".shp"),
  export = TRUE,
  plot_results = FALSE  # turn off plots for clean test
)

# Check that results are valid
stopifnot(is.list(results))
stopifnot("ship_count" %in% names(results))
stopifnot(results$ship_count > 0)

cat("✅ Internal data test passed! Ships detected:", results$ship_count, "\n")
