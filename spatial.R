library(readr)
library(dplyr)
library(ggplot2)
library(sf)
library(spdep)
library(spatialreg)
library(igraph)
library(spatialprobit)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

sink("logs/spatial.log")

data <- read_csv("data/willhaben_woom_bikes_sample_no_outlier.csv")

data$WoomCategory_i <- as.factor(data$WoomCategory_i)
data$Cond_i <- as.factor(data$Cond_i)
data$Color_i <- as.factor(data$Color_i)
data$Dealer_i <- as.factor(data$Dealer_i)
data$Last_48_hours_i <- as.factor(data$Last_48_hours_i)
data$hasPsychologicalPricing_i <- as.factor(data$hasPsychologicalPricing_i)

data <- data %>%
  mutate(latitude = as.numeric(latitude),
         longitude = as.numeric(longitude))

data_sf <- st_as_sf(data, coords = c("longitude", "latitude"), crs = 4326)

shapefile <- st_read("data/Austria_shapefile/at_10km.shp")

# Save Spatial Distribution Plot
p1 <- ggplot() +
  geom_sf(data = shapefile, fill = "white", color = "lightgray") +
  geom_sf(data = data_sf, aes(color = hasPsychologicalPricing_i), size = 2) +
  theme_minimal() +
  labs(title = "Spatial Distribution of Psychological Pricing by Grid Cell")

ggsave("spatial_distribution.png", plot = p1, width = 1920/100, height = 1080/100, dpi = 100)

# Nearest Neighbors Plot
coords <- st_coordinates(data_sf)
knn <- knearneigh(coords, k = 1)
knn_weights <- knn2nb(knn)
weights_list <- nb2listw(knn_weights)

edges <- data.frame(
  x = numeric(),
  y = numeric(),
  xend = numeric(),
  yend = numeric()
)

for (i in 1:length(knn$nn)) {
  nn_indices <- knn$nn[[i]]
  for (nn_index in nn_indices) {
    edges <- rbind(edges, data.frame(
      x = coords[i, 1],
      y = coords[i, 2],
      xend = coords[nn_index, 1],
      yend = coords[nn_index, 2]
    ))
  }
}

p2 <- ggplot() +
  geom_point(data = data, aes(x = longitude, y = latitude), color = "red", size = 3) +
  geom_segment(data = edges, aes(x = x, y = y, xend = xend, yend = yend), color = "blue") +
  theme_minimal() +
  labs(title = "Nearest Neighbors Visualization", x = "Longitude", y = "Latitude")

ggsave("nearest_neighbors.png", plot = p2, width = 1920/100, height = 1080/100, dpi = 100)

data_sf$hasPsychologicalPricing_i_num <- as.numeric(data_sf$hasPsychologicalPricing_i)


# Moran's I Test
moran.test(data_sf$hasPsychologicalPricing_i_num, weights_list)
# High-High at 10%-level, low value

moran.test(data_sf$log_price, weights_list)
# Not significant.

sink()


# Moran's I Test by each Category
