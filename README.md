# shipdetectR

**shipdetectR** is an R package for detecting ships in Synthetic Aperture Radar (SAR) imagery using brightness thresholding, spatial clustering, and geometric bounding.
Supports Sentinel-1 data.
It uses shapefiles to mask land and isolate potential vessels on open water.
The given example data contains of Sentinel-1 data, on wich a terrain correction was applied before with SNAP Software.
---

## 📦 Installation

Install from GitHub:

```r
devtools::install_github("clemensschoemig/shipdetectR")
```

## How it works

The ship detection process performs the following steps:

1. Water Masking – Crops SAR raster to water areas using a shapefile.

2. Thresholding – Flags bright pixels above mean + 1.5 × SD as potential ship pixels.

3. Clustering – Groups neighboring bright pixels in a moving window.

4. Filtering – Removes clusters with fewer than N pixels.

5. Counting – Labels and counts each ship-like cluster.

6. Bounding Boxes – Generates rectangular bounding boxes around each ship.

7. Centroid Export – Exports ship center points as a shapefile.

Each step can also be executed by the main detect_all_ships() function or step by step by using the individual functions.

## Quick Start

The package includes a built-in example raster and waterbody shapefile. You can run the full detection pipeline like this:

```r
library(shipdetectR)

results <- detect_all_ships(
  raster_path = system.file("extdata", "package_basis_subset_TC_vh_intensity.tif", package = "shipdetectR"),
  water_shapefile_path = system.file("extdata", "iho.shp", package = "shipdetectR"),
  output_path = "your_output_path/ship_centroids.shp"
)

# # Use internal example data
# results <- detect_all_ships(
#   raster_path = system.file("extdata", "package_basis_subset_TC_vh_intensity.tif", package = "shipdetectR"),
#   water_shapefile_path = system.file("extdata", "iho.shp", package = "shipdetectR"),
#   output_path = tempfile(fileext = ".shp"),
#   export = TRUE,
#   plot_results = TRUE
# )

```

##Functions
Function	- Description
mask_to_water()	- Masks SAR raster using a waterbody shapefile
detect_ships()	- Detects bright pixels based on global intensity threshold
cluster_bright_pixels()	- Applies local pixel clustering using a window matrix
filter_clusters()	- Filters out clusters smaller than a set size
count_ships()	- Labels and counts ship clusters
get_ship_bounding_boxes()	- Builds bounding boxes around labeled ships
export_ship_points()	- Calculates and exports ship centroids to a shapefile
detect_all_ships()	- Complete detection pipeline combining all steps


##Sample Data
The package includes a Sentinel-1 test raster and a water mask for quick testing:
```
raster_path <- system.file("extdata", "package_basis_subset_TC_vh_intensity.tif", package = "shipdetectR")
shapefile_path <- system.file("extdata", "iho.shp", package = "shipdetectR")
```

## Author
Clemens Schömig
GitHub: @clemensschoemig
