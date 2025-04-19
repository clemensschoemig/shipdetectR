library(terra)
library(raster)

detect_ships <- function(raster) {
  # Step 1: Calculate global mean and SD correctly
  stats <- global(raster, fun = c("mean", "sd"), na.rm = TRUE)
  threshold_value <- stats$mean + 1.5 * stats$sd
  print(paste("Threshold value:", round(threshold_value, 4)))

  # Step 2: Identify pixels above threshold
  bright_pixels <- raster > threshold_value

  # Step 3: Plot binary result
  plot(bright_pixels, main = "Potential ship pixels (above threshold)", col = c("black", "red"))

  # Return binary raster for next steps
  return(bright_pixels)
}

cluster_bright_pixels <- function(bright_pixels, window_size = 51) {
  # Ensure odd window size
  if (window_size %% 2 == 0) {
    window_size <- window_size + 1
  }

  # Convert logical raster to numeric (TRUE = 1, FALSE = 0)
  bright_pixels_num <- app(bright_pixels, fun = function(x) as.numeric(x))

  # Create the moving window matrix
  w <- matrix(1, nrow = window_size, ncol = window_size)

  # Use focal to count bright pixels in neighborhood
  local_count <- focal(bright_pixels_num, w, fun = sum, na.rm = TRUE)

  # Plot the cluster map
  plot(local_count, main = paste0("Local bright pixel count (", window_size, "x", window_size, ")"))

  return(local_count)
}

filter_clusters <- function(local_count, min_cluster_size = 100) {
  # Create binary mask of potential ship clusters
  filtered_clusters <- local_count >= min_cluster_size

  # Plot result
  plot(filtered_clusters, main = paste("Filtered Clusters (>", min_cluster_size, "bright pixels)"),
       col = c("black", "red"))

  return(filtered_clusters)
}

count_ships <- function(filtered_clusters) {
  # Group connected pixels (4-directional or 8-directional — here we use 8)
  clumped <- patches(filtered_clusters, directions = 8)

  # Count number of unique ship-like objects (exclude NA / background)
  ship_ids <- unique(na.omit(values(clumped)))
  ship_count <- length(ship_ids)

  # Print and plot
  print(paste("Detected ships:", ship_count))
  plot(clumped, main = paste("Detected Ships (Total:", ship_count, ")"))

  return(list(count = ship_count, clumps = clumped))
}


###################

raster <- rast("C:/Users/cleme/Desktop/radar_files/suez_cropped_package_use/package_basis_subset_TC_vh_intensity.tif")
plot(raster)


# Step 1: detect bright pixels
ship_pixels <- detect_ships(raster)

# Step 2: cluster them
ship_clusters <- cluster_bright_pixels(ship_pixels, window_size = 51)

# Step 3: filter based on size
filtered_ships <- filter_clusters(ship_clusters, min_cluster_size = 40)

# Step 4: Count ships
ship_results <- count_ships(filtered_ships)


# plot(detected)
# print(ship_counter(detected))
