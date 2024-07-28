library(dplyr)
library(ggplot2)
library(gridExtra)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

bikes <- read.csv("data/willhaben_woom_bikes_sample_no_outlier.csv", stringsAsFactors = TRUE)

bikes_selected <- bikes[, colnames(bikes)]
numeric_cols <- sapply(bikes_selected, is.numeric)
numeric_data <- bikes_selected[, numeric_cols]
num_plots <- length(numeric_data)
plot_list <- list()
for (i in 1:num_plots) {
  p <- ggplot(numeric_data, aes_string(x = names(numeric_data)[i])) +
    geom_histogram(binwidth = 1, fill = "blue", color = "black") +
    theme_minimal() +
    labs(title = paste("Histogram of", names(numeric_data)[i]))
  plot_list[[i]] <- p
}

categorical_vars <- c("WoomCategory_i", "color", "condition")
for (var in categorical_vars) {
  if (!is.factor(bikes_selected[[var]])) {
    bikes_selected[[var]] <- as.factor(bikes_selected[[var]])
  }
  p <- ggplot(bikes_selected, aes_string(x = var)) +
    geom_bar(fill = "blue", color = "black") +
    theme_minimal() +
    labs(title = paste("Bar Plot of", var))
  plot_list[[length(plot_list) + 1]] <- p
}

png("histograms.png", width = 1920, height = 1080, res = 120)
grid.arrange(grobs = plot_list, ncol = 3)
dev.off()
