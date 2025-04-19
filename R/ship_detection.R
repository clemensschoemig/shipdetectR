library(terra)
library(raster)


detect_ships <- function(raster,
                        window_size = 51,
                        min_cluster_size = 100,
                        max_cluster_size = 400) {
  # Ensure window size is odd
  window_size <- ifelse(window_size %% 2 == 0, window_size + 1, window_size)

  # Auto threshold: pixels that are significantly brighter than the sea
  stats <- global(raster, fun = c("mean", "sd"), na.rm = TRUE)
  threshold_value <- stats["mean"] + 1.5 * stats["sd"]

  # Binary mask of bright pixels
  bright_pixels <- raster > threshold_value

  # Convert logical SpatRaster to numeric (1 = TRUE, 0 = FALSE)
  bright_pixels_num <- app(bright_pixels, fun = function(x) as.numeric(x))

  # Local pixel count in a moving window
  w <- matrix(1, nrow = window_size, ncol = window_size)
  local_count <- focal(bright_pixels_num, w, fun = sum, na.rm = TRUE)

  # Filter: keep regions with enough bright pixels
  filtered_objects <- local_count >= min_cluster_size

  # Label connected regions
  ship_clusters <- clumps(filtered_objects)

  # Filter by max cluster size (number of pixels)
  cluster_sizes <- freq(ship_clusters)
  valid_ids <- cluster_sizes[cluster_sizes[,2] <= max_cluster_size, 1]
  ship_mask <- ship_clusters
  ship_mask[!(ship_mask %in% valid_ids)] <- NA

  return(ship_mask)
}

# Ship Counter
ship_counter <- function(ship_mask) {
  unique_ships <- unique(values(ship_mask, na.rm = TRUE))
  return(length(unique_ships))
}

# Example:
raster <- rast("C:/Users/cleme/Desktop/radar_files/suez_cropped_package_use/package_basis_subset_TC_vh_intensity.tif")
plot(raster)
detected <- detect_ships(raster)
# plot(detected)
# print(ship_counter(detected))
