% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ship_detection.R
\name{detect_ships}
\alias{detect_ships}
\title{Detect Bright Ship Pixels}
\usage{
detect_ships(raster)
}
\arguments{
\item{raster}{A SpatRaster (masked to water).}
}
\value{
A logical SpatRaster with TRUE for potential ship pixels.
}
\description{
Identifies radar image pixels significantly brighter than the sea background using a threshold.
}
