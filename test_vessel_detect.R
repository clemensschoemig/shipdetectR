#test detect R:


###
#testing:
###################

##sentinel_raster <- rast("C:/Users/cleme/Desktop/radar_files/suez_cropped_package_use/package_basis_subset_TC_vh_intensity.tif")
#plot(sentinel_raster)

# Step 1: mask to water area
##sentinel_raster_masked <- mask_to_water(sentinel_raster, "C:/Users/cleme/Eagle/active_remote_sensing/water_bodies/iho/iho.shp")

# Step 2: detect bright pixels
##ship_pixels <- detect_ships(sentinel_raster_masked)

# Step 3: cluster them
##ship_clusters <- cluster_bright_pixels(ship_pixels, window_size = 15)

# Step 4: filter based on size
##filtered_ships <- filter_clusters(ship_clusters, min_cluster_size = 50)

#table(values(ship_results$clumps), useNA = "no")

# Step 5: Count ships
##ship_results <- count_ships(filtered_ships)
#clumped <- ship_results$clumps
##clumps_raster <- ship_results$clumps

# Step 6: Bounding boxes:
#crs(ship_boxes) <- crs(clumped)
#ship_boxes <- project(ship_boxes, crs(clumped))
##ship_boxes <- get_ship_bounding_boxes(clumps_raster)


#unique(values(clumps_raster))
#clumps_raster <- ship_results$clumps
#unique(values(clumps_raster))
#print(ext(clumps_raster))

# Step 7: export ship location points:
##ship_points <- export_ship_points(ship_boxes, "C:/Users/cleme/Desktop/radar_files/outout_ship_detections_coordinates/ship_centroids.shp")


################
#wrapper function
###############


results <- detect_all_ships(
  raster_path = "C:/Users/cleme/Desktop/radar_files/suez_cropped_package_use/package_basis_subset_TC_vh_intensity.tif",
  water_shapefile_path = "C:/Users/cleme/Eagle/active_remote_sensing/water_bodies/iho/iho.shp",
  output_path = "C:/Users/cleme/Desktop/radar_files/outout_ship_detections_coordinates/ship_centroids3.shp"
)
