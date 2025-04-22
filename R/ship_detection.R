library(sf)
library(terra)
library(raster)

mask_to_water <- function(raster, water_shapefile_path) {
  # Load water shapefile
  water_sf <- st_read(water_shapefile_path)

  # Reproject to match raster CRS if needed
  if (st_crs(water_sf)$epsg != crs(raster, proj=TRUE)) {
    message("Reprojecting water shapefile to match raster CRS...")
    water_sf <- st_transform(water_sf, crs(raster))
  }

  # Convert to terra vector
  water_vect <- vect(water_sf)

  # Crop and mask the raster
  cropped_raster <- crop(raster, water_vect)
  masked_raster <- mask(cropped_raster, water_vect)

  plot(masked_raster, main = "Masked to Water Area Only")

  return(masked_raster)
}

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
  # Convert logical raster to numeric: 1 for TRUE, NA for FALSE
  filtered_num <- classify(filtered_clusters, rcl = matrix(c(0, NA, 1, 1), ncol = 2, byrow = TRUE))

  # Now apply patches on proper values
  clumped <- patches(filtered_num, directions = 8)

  # Count how many unique clump IDs exist (exclude NA)
  ship_ids <- unique(na.omit(values(clumped)))
  ship_count <- length(ship_ids)

  # Plot result
  plot(clumped, main = paste("Detected Ships (Total:", ship_count, ")"))

  return(list(count = ship_count, clumps = clumped))
}

get_ship_bounding_boxes <- function(clumps_raster) {
  # Convert to polygons and keep only valid clumps
  clump_polygons <- as.polygons(clumps_raster, dissolve = TRUE, na.rm = TRUE)

  # Remove NA or 0 values
  clump_polygons <- clump_polygons[!is.na(clump_polygons$patches), ]
  clump_polygons <- clump_polygons[clump_polygons$patches != 0, ]

  # Create bounding boxes from each polygon
  bounding_boxes <- lapply(1:nrow(clump_polygons), function(i) {
    b <- ext(clump_polygons[i, ])
    bb_poly <- as.polygons(b)
    values(bb_poly) <- data.frame(id = clump_polygons$patches[i])
    return(bb_poly)
  })

  # Combine all bounding boxes into one vector
  bbox_vect <- do.call(rbind, bounding_boxes)

  # Ensure CRS is set correctly
  crs(bbox_vect) <- crs(clumps_raster)

  # Plot
  plot(clumps_raster, main = "Detected Ships with Bounding Boxes")
  plot(bbox_vect, border = "red", add = TRUE, lwd = 2)

  return(bbox_vect)
}



###################

sentinel_raster <- rast("C:/Users/cleme/Desktop/radar_files/suez_cropped_package_use/package_basis_subset_TC_vh_intensity.tif")
plot(sentinel_raster)

# Step 0: mask to water area
sentinel_raster_masked <- mask_to_water(sentinel_raster, "C:/Users/cleme/Eagle/active_remote_sensing/water_bodies/iho/iho.shp")

# Step 1: detect bright pixels
ship_pixels <- detect_ships(sentinel_raster_masked)

# Step 2: cluster them
ship_clusters <- cluster_bright_pixels(ship_pixels, window_size = 51)

# Step 3: filter based on size
filtered_ships <- filter_clusters(ship_clusters, min_cluster_size = 40)

table(values(ship_results$clumps), useNA = "no")

# Step 4: Count ships
ship_results <- count_ships(filtered_ships)
clumped <- ship_results$clumps
clumps_raster <- ship_results$clumps

# Step 5: Bounding boxes:
ship_boxes <- get_ship_bounding_boxes(clumps_raster)










print(crs(ship_boxes))
print(crs(clumped))
ship_boxes <- project(ship_boxes, crs(clumped))

crs(ship_boxes) <- crs(clumped)
ship_boxes <- project(ship_boxes, crs(clumped))
plot(clumped, main = "Ships with Bounding Boxes")
plot(ship_boxes, border = "red", lwd = 2, add = TRUE)


print(ext(clumped))
print(ext(ship_boxes))

unique(values(clumps_raster))

clumps_raster <- ship_results$clumps
unique(values(clumps_raster))
print(ext(clumps_raster))

