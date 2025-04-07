library(terra)
library(raster)


s1raster <- rast("C:/Users/cleme/Eagle/active_remote_sensing/suez_channel/gis_files/visualization_double_detect_georef.tif")

plot(s1raster)
getwd()
l1_s1raster<-s1raster[[1]]
plot(l1_s1raster)


s1_fullraster<- rast("C:/Users/cleme/Desktop/radar_files/S1A_IW_GRDH_1SDV_20210321T034449_20210321T034514_037091_045DD0_875A.SAFE/measurement/s1a-iw-grd-vh-20210321t034449-20210321t034514-037091-045dd0-002.tiff")
rectified_raster <- rectify(s1_fullraster, method="bilinear", aoi=NULL, snap=TRUE, filename="")
plot(rectified_raster)

global_waters<-vect("C:/Users/cleme/Eagle/active_remote_sensing/water_bodies/iho/iho.shp")
plot(global_waters)

#ensure crs matching
crs(rectified_raster)
crs(global_waters)
# If they do not match, reproject the polygon to match the raster:
#global_waters <- project(global_waters, rectified_raster)

#masking
masked_raster <- mask(rectified_raster, global_waters)

masked_cropped_raster <- mask(cropped_raster, global_waters)

plot(masked_raster)
lines(global_waters, col = "red")  # Overlay polygon boundary


#focal moving window ship/object detection

window_size <- 31
w <- matrix(1, nrow = window_size, ncol = window_size)
max_filter <- focal(masked_raster, w, fun = max, na.rm = TRUE)
plot(max_filter)
#mean_filter <- focal(l1_s1raster, w, fun = mean, na.rm = TRUE)
#plot(mean_filter)

detected_objects <- l1_s1raster > 150
plot(detected_objects, col = c("white", "red"))  # Red shows detected objects

window_size_count <- 91
w2 <- matrix(1, nrow = window_size_count, ncol = window_size)
object_count <- focal(detected_objects, w2, fun = sum, na.rm = TRUE)
plot(object_count)
threshold <- 300
filtered_objects <- object_count >= threshold
plot(filtered_objects)

# Group connected object pixels into clusters
clusters <- clump(max_filter)
# Get frequency table of cluster sizes
cluster_sizes <- freq(clusters)
# Define minimum size threshold (80x80 pixels = 6400)
size_threshold <- 400
# Find cluster IDs that meet the size requirement
large_clusters <- cluster_sizes$value[cluster_sizes$count >= size_threshold]
# Create a binary raster of large objects
filtered_clusters <- clusters %in% large_clusters
# Count how many clusters remain after filtering
num_objects <- length(large_clusters)
# Print the number of detected objects
print(paste("Number of detected objects:", num_objects))

