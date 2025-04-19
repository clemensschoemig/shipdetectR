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

###################

raster <- rast("C:/Users/cleme/Desktop/radar_files/suez_cropped_package_use/package_basis_subset_TC_vh_intensity.tif")
plot(raster)

ship_pixels <- detect_ships(raster)
ship_clusters <- cluster_bright_pixels(ship_pixels, window_size = 51)


# plot(detected)
# print(ship_counter(detected))
