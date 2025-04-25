library(devtools)
library(usethis)
library(terra)
library(sf)
library(raster)

#testing:
###################

#step by step:
#######

# Load the package
library(shipdetectR)

# Load internal test data
raster_path <- system.file("extdata", "package_basis_subset_TC_vh_intensity.tif", package = "shipdetectR")
shapefile_path <- system.file("extdata", "iho.shp", package = "shipdetectR")

# STEP 1: Load raster
r <- terra::rast(raster_path)
plot(r, main = "Raw SAR Raster")

# STEP 2: Mask to water
masked_raster <- mask_to_water(r, shapefile_path)

# STEP 3: Detect bright pixels (thresholding)
bright_pixels <- detect_ships(masked_raster)

# STEP 4: Cluster bright pixels
clusters <- cluster_bright_pixels(bright_pixels, window_size = 15)

# STEP 5: Filter out small clusters
filtered_clusters <- filter_clusters(clusters, min_cluster_size = 50)

# STEP 6: Count ships
ship_count_results <- count_ships(filtered_clusters)
clumps_raster <- ship_count_results$clumps
print(paste("Ships detected:", ship_count_results$count))

# STEP 7: Get bounding boxes
bounding_boxes <- get_ship_bounding_boxes(clumps_raster)

# STEP 8: Export centroids
centroids <- export_ship_points(bounding_boxes, output_path = tempfile(fileext = ".shp"))

# Optional: Show final result
plot(masked_raster, main = "Ship Detections with Points and Bounding-Boxes", type = "continuous", legend = FALSE)
plot(bounding_boxes, border = "red", add = TRUE, lwd = 2)
plot(centroids, col = "green", pch = 20, add = TRUE)

#######
#wrapper:

library(shipdetectR)

results <- detect_all_ships(
  raster_path = system.file("extdata", "package_basis_subset_TC_vh_intensity.tif", package = "shipdetectR"),
  water_shapefile_path = system.file("extdata", "iho.shp", package = "shipdetectR"),
  output_path = tempfile(fileext = ".shp"), # Temporary output
  #output_path = "C:/your_filepath/ship_centroids.shp", # OR: Save results permanently
  export = TRUE,
  plot_results = TRUE
)


