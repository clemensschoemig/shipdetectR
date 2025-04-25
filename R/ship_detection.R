#' @import terra
#' @import sf
#' @import raster
NULL

#' Mask Raster to Waterbody Shapefile
#'
#' Masks a SAR raster using a provided waterbody shapefile. Keeps only pixels inside water polygons.
#'
#' @param raster A SpatRaster from the terra package.
#' @param water_shapefile_path Character. Path to a shapefile (.shp) with waterbody polygons.
#'
#' @return A masked SpatRaster.
#' @export
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


#' Detect Bright Ship Pixels
#'
#' Identifies radar image pixels significantly brighter than the sea background using a threshold.
#'
#' @param raster A SpatRaster (masked to water).
#'
#' @return A logical SpatRaster with TRUE for potential ship pixels.
#' @export
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


#' Cluster Bright Pixels Locally
#'
#' Uses a moving window to count bright pixels in the neighborhood to find clusters.
#'
#' @param bright_pixels Logical SpatRaster from \code{detect_ships()}.
#' @param window_size Integer. Size of the moving window (must be odd).
#'
#' @return Numeric SpatRaster of local bright-pixel counts.
#' @export
cluster_bright_pixels <- function(bright_pixels, window_size = 15) {
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


#' Filter Pixel Clusters
#'
#' Filters out bright pixel clusters smaller than a given size threshold.
#'
#' @param local_count A numeric SpatRaster of local bright-pixel counts.
#' @param min_cluster_size Integer. Minimum cluster size.
#'
#' @return Logical SpatRaster with valid clusters.
#' @export
filter_clusters <- function(local_count, min_cluster_size = 50) {
  # Create binary mask of potential ship clusters
  filtered_clusters <- local_count >= min_cluster_size

  # Plot result
  plot(filtered_clusters, main = paste("Filtered Clusters (>", min_cluster_size, "bright pixels)"),
       col = c("black", "red"))

  return(filtered_clusters)
}


#' Count and Label Ship Clusters
#'
#' Labels connected bright pixel clusters and counts distinct ships.
#'
#' @param filtered_clusters Logical SpatRaster of valid clusters.
#'
#' @return A list with: \code{count} (integer) and \code{clumps} (labeled SpatRaster).
#' @export
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


#' Generate Bounding Boxes for Ships
#'
#' Converts labeled clusters to minimum bounding boxes around each detected ship.
#'
#' @param clumps_raster A labeled SpatRaster from \code{count_ships()}.
#'
#' @return A SpatVector of bounding box polygons.
#' @export
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


#' Export Ship Centroids as Shapefile
#'
#' Calculates centroids from bounding boxes and writes them to a shapefile.
#'
#' @param bbox_vect A SpatVector of ship bounding boxes.
#' @param output_path Character. Destination for shapefile.
#'
#' @return SpatVector of centroid points.
#' @export
export_ship_points <- function(bbox_vect, output_path = "detected_ships_points.shp") {
  # Calculate centroids of bounding boxes
  centroids <- centroids(bbox_vect)

  # Assign a CRS (if missing)
  if (is.na(crs(centroids))) {
    crs(centroids) <- crs(bbox_vect)
  }

  # Plot to verify
  plot(bbox_vect, border = "red", main = "Ship Bounding Boxes and Centroids")
  plot(centroids, col = "blue", pch = 20, add = TRUE)

  # Export to shapefile (can also use ".geojson" or ".gpkg")
  writeVector(centroids, output_path, filetype = "ESRI Shapefile", overwrite = TRUE)

  message("Exported ship centroids to: ", output_path)
  return(centroids)
}



#' Run Complete Ship Detection Pipeline
#'
#' Runs the full ship detection workflow: mask water, detect, cluster, filter, count, box, export.
#'
#' @param raster_path Character. Path to input SAR raster (.tif).
#' @param water_shapefile_path Character. Path to water shapefile (.shp).
#' @param output_path Character. Output path for shapefile.
#' @param window_size Integer. Moving window size (must be odd).
#' @param min_cluster_size Integer. Minimum bright pixels per cluster.
#' @param export Logical. Whether to export the results.
#' @param plot_results Logical. Whether to show plots.
#'
#' @return A list with all intermediate data and final ship count.
#' @export
detect_all_ships <- function(
    raster_path,
    water_shapefile_path,
    output_path = "detected_ships_points.shp",
    window_size = 15,
    min_cluster_size = 50,
    export = TRUE,
    plot_results = TRUE
) {
  # Step 1: Load input raster
  message("Loading raster...")
  raster <- rast(raster_path)

  # Step 2: Mask to water
  raster_masked <- mask_to_water(raster, water_shapefile_path)

  # Step 3: Detect bright pixels (ships)
  ship_pixels <- detect_ships(raster_masked)

  # Step 4: Cluster ship pixels
  ship_clusters <- cluster_bright_pixels(ship_pixels, window_size = window_size)

  # Step 5: Filter by cluster size
  filtered <- filter_clusters(ship_clusters, min_cluster_size = min_cluster_size)

  # Step 7: Count ships (clumps)
  ship_results <- count_ships(filtered)
  clumps_raster <- ship_results$clumps

  # Step 9: Get bounding boxes
  ship_boxes <- get_ship_bounding_boxes(clumps_raster)

  # Step 10: Export ship centroids
  if (export) {
    ship_points <- export_ship_points(ship_boxes, output_path)
  } else {
    # Still calculate for return
    ship_points <- centroids(ship_boxes)
    crs(ship_points) <- crs(ship_boxes)
  }

  # Optionally show a final overview plot
  if (plot_results) {
    plot(raster_masked, main = "Ship Detections with Points and Bounding-Boxes", type = "continuous", legend = FALSE)
    plot(ship_boxes, border = "red", add = TRUE, lwd = 2)
    plot(ship_points, col = "green", pch = 20, add = TRUE)
  }

  message("Ship detection complete. Ships found: ", ship_results$count)

  return(list(
    masked_raster = raster_masked,
    bright_pixels = ship_pixels,
    clusters = ship_clusters,
    filtered = filtered,
    clumps = clumps_raster,
    boxes = ship_boxes,
    points = ship_points,
    ship_count = ship_results$count
  ))
}

