library(readr)
library(dplyr)
library(ggplot2)
library(lmtest)
library(sandwich)
library(car)
library(MASS)
library(stargazer)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

sink("logs/statInference.log")

#data <- read_csv("data/willhaben_woom_bikes_sample.csv")
data <- read_csv("data/willhaben_woom_bikes_sample_no_outlier.csv")
spec(data)


hist(as.numeric(data$WoomCategory_i))
plot(as.factor(data$Cond_i))
plot(as.factor(data$Color_i))
hist(as.numeric(data$Dealer_i))
hist(as.numeric(data$Last_48_hours_i))
hist(as.numeric(data$hasPsychologicalPricing_i))
hist(as.numeric(data$logistic_costs))

hist(data$AnzahlSameSizeRadius0To10_i)
hist(data$AnzahlSameSizeRadius10To30_i)
hist(data$AnzahlSameSizeRadius30To60_i)

### Stepwise AIC Best MLR Model
data <- data %>% 
  mutate(
    size = as.factor(WoomCategory_i),
    color = as.factor(Color_i),
    condition = as.factor(Cond_i)
  )


initial_model <- lm(log_price ~ size + condition + color + Dealer_i + Last_48_hours_i 
                                 + hasPsychologicalPricing_i + Uebergabeart_i + logistic_costs
                    +AnzahlSameSizeRadius0To10_i 
                    + AnzahlSameSizeRadius10To30_i+
                      AnzahlSameSizeRadius30To60_i, 
                    data = data)

vif(initial_model)  # Check for multicollinearity

model <- initial_model
coeftest(model, vcov = vcovHC(model, type = "HC0")) # Huber-White
summary(model)


# Stepwise Regression for model selection
stepwise_model <- stepAIC(initial_model, direction = "both")

final_model <- stepwise_model
coeftest_final <- coeftest(final_model, vcov = vcovHC(final_model, type = "HC0")) # Huber-White
summary(final_model)

# diagnostics
par(mfrow = c(2, 2))
plot(final_model)



### SLR Bivariate Models ###
bivariate_models <- list()
predictor_vars <- c("size", "condition", "Dealer_i", "Last_48_hours_i", 
                    "hasPsychologicalPricing_i", "color",
                    "AnzahlSameSizeRadius0To10_i", "AnzahlSameSizeRadius10To30_i",
                    "AnzahlSameSizeRadius30To60_i", "Uebergabeart_i", "logistic_costs")

for (var in predictor_vars) {
  formula <- paste("log_price ~", var)
  bivariate_models[[var]] <- lm(formula = formula, data = data)
}
for (var in predictor_vars) {
  print(summary(bivariate_models[[var]]))
}
bivariate_metrics <- data.frame(
  Predictor = predictor_vars,
  R_squared = sapply(bivariate_models, function(model) summary(model)$r.squared),
  Adj_R_squared = sapply(bivariate_models, function(model) summary(model)$adj.r.squared)
)
print(bivariate_metrics)


### MLR Models ### 

mlr_model <- lm(price_parsed ~ 
                  size 
                + condition 
                + Dealer_i
                + Last_48_hours_i 
                + hasPsychologicalPricing_i
                + AnzahlSameSizeRadius0To10_i
                + AnzahlSameSizeRadius10To30_i
                + AnzahlSameSizeRadius30To60_i,
                data = data)

coeftest(mlr_model, vcov = vcovHC(mlr_model, type = "const"))
coeftest_mlr <- coeftest(mlr_model, vcov = vcovHC(mlr_model, type = "HC0")) # Huber-White
summary(mlr_model)


mlr_model_2 <- lm(price_parsed ~ 
                  size 
                + condition 
                + Dealer_i
                + Last_48_hours_i 
                + hasPsychologicalPricing_i
                + logistic_costs,
                data = data)
coeftest(mlr_model_2, vcov = vcovHC(mlr_model, type = "const"))
coeftest_mlr2 <- coeftest(mlr_model_2, vcov = vcovHC(mlr_model_2, type = "HC0")) # Huber-White


summary(mlr_model_2)


### MLR with interaction terms for hasPsychologicalPricing_i x Var ###
interaction_formula <- as.formula(
  "log_price ~ hasPsychologicalPricing_i * (size + condition + color + Dealer_i + Last_48_hours_i + hasPsychologicalPricing_i + Uebergabeart_i+ AnzahlSameSizeRadius0To10_i + AnzahlSameSizeRadius10To30_i + AnzahlSameSizeRadius30To60_i)"
)

interaction_model <- lm(interaction_formula, data = data)
coeftest_interaction_model <- coeftest(interaction_model, vcov = vcovHC(interaction_model, type = "HC1"))
summary(interaction_model)





sink()

### Output tables ###
sink("tex/final_model_output_table_1.tex")
stargazer(final_model, type = "latex", 
          se = list(coeftest_final[, 2]), 
          p = list(coeftest_final[, 4]), 
          title = "Stepwise Regression Model", 
          label = "tab:stepwise_model",
          star.cutoffs = c(0.10, 0.05, 0.01),
          add.lines = list(
            c("Observations", 254),
            c("R-squared", round(summary(final_model)$r.squared, 3)),
            c("Adjusted R-squared", round(summary(final_model)$adj.r.squared, 3)),
            c("Note", "t-statistics based on Huber-White standard errors.")
          ),
          style = "qje",
          notes.align = "l",
          notes.append = TRUE,
          notes = "t-statistics are calculated using Huber-White robust standard errors. Significance levels: *p \\le 0.1; **p \\le 0.05; ***p \\le 0.01."
)
sink()


sink("tex/mlr_model_output_table_1.tex")
stargazer(mlr_model, type = "latex", 
          se = list(coeftest_mlr[, 2]), 
          p = list(coeftest_mlr[, 4]), 
          title = "Multiple Linear Regression Model", 
          label = "tab:mlr_model",
          star.cutoffs = c(0.10, 0.05, 0.01),
          add.lines = list(
            c("Observations", 254),
            c("R-squared", round(summary(mlr_model)$r.squared, 3)),
            c("Adjusted R-squared", round(summary(mlr_model)$adj.r.squared, 3)),
            c("Note", "t-statistics based on Huber-White standard errors.")
          ),
          style = "qje",
          notes.align = "l",
          notes.append = TRUE,
          notes = "t-statistics are calculated using Huber-White robust standard errors. Significance levels: *p \\le 0.1; **p \\le 0.05; ***p \\le 0.01.",
          table.placement = "H",
          keep.stat = c("n", "rsq", "adj.rsq")
)
sink()

sink("tex/mlr_model_2_output_table_1.tex")
stargazer(mlr_model_2, type = "latex", 
          se = list(coeftest_mlr2[, 2]), 
          p = list(coeftest_mlr2[, 4]), 
          title = "Multiple Linear Regression Model with Logistic Costs", 
          label = "tab:mlr_model_2",
          star.cutoffs = c(0.10, 0.05, 0.01),
          add.lines = list(
            c("Observations", 254),
            c("R-squared", round(summary(mlr_model_2)$r.squared, 3)),
            c("Adjusted R-squared", round(summary(mlr_model_2)$adj.r.squared, 3)),
            c("Note", "t-statistics based on Huber-White standard errors.")
          ),
          style = "qje",
          notes.align = "l",
          notes.append = TRUE,
          notes = "t-statistics are calculated using Huber-White robust standard errors. Significance levels: *p \\le 0.1; **p \\le 0.05; ***p \\le 0.01.",
          table.placement = "H",
          keep.stat = c("n", "rsq", "adj.rsq")
)
sink()
