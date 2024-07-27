library(glmnet)
library(readr)

data <- read_csv("data/willhaben_woom_bikes_sample.csv")


data_numeric <- data[, sapply(data, is.numeric)]
data_numeric <- data_numeric[, !names(data_numeric) %in% 
                               c("price_parsed", "latitude", "longitude", 
                                 "zip_code", "last_modified_unix", "zip_code_result", 
                                 "obs_id")]

data_numeric <- na.omit(data_numeric)

# Create X and y
X <- model.matrix(log_price ~ . - 1, data = data_numeric)  # Exclude intercept
y <- data_numeric$log_price

dim(X)
length(y)

cvfit <- cv.glmnet(X, y, alpha = 1)

best_lambda <- cvfit$lambda.min
print(best_lambda)

plot(cvfit, main = "Lasso Path")


lasso_coefs <- coef(cvfit, s = best_lambda)
print(lasso_coefs)


