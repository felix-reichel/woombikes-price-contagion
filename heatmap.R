
library(dplyr)
library(ggplot2)
library(reshape2)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

bikes <- read.csv(
  "data/willhaben_woom_bikes_sample_no_outlier.csv", 
  stringsAsFactors = TRUE)


bikes_selected <- bikes[, colnames(bikes)]
numeric_cols <- sapply(bikes_selected, is.numeric)
cor_data <- cor(bikes_selected[, numeric_cols])
cor_data_melted <- melt(cor_data)
cor_data_melted <-
cor_data_melted[!(cor_data_melted$Var1 == "zip_code" | cor_data_melted$Var2 == "zip_code"), ]



### PRODUCE A CORRELATION HEATMAP ###
png("heatmap.png", width = 1920, height = 1080, res = 120)

ggplot(cor_data_melted, aes(Var2, Var1, fill = value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1, 1), space = "Lab",
                       name = "Correlation") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, vjust = 1, size = 10, hjust = 1)) +
  coord_fixed()

dev.off()

