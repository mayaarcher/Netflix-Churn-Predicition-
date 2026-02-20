install.packages(c("glmnet", "caret", "car", "corrplot", "ggplot2", "MASS", "stats"))
library(caret)
library(car)      
library(corrplot) 
library(glmnet) 
library(stats)
library(ggplot2)
library(MASS)

# 1 DATA PREPARATION

netflix <- read.csv("netflix_customer_churn.csv")

# exploring the data
# no of rows
nrow(netflix)
# no of columns
ncol(netflix)
# variable names
names(netflix)
# data structure
str(netflix)
# data summary
summary(netflix)

# 2 DATA CLEANING

# remove customer_id (not predictive)
netflix_clean <- netflix[, !names(netflix) %in% "customer_id"]

# create new variable avg_watch_time_per_person
netflix_clean$avg_watch_time_per_person <-
  netflix_clean$avg_watch_time_per_day /
  as.numeric(as.character(netflix_clean$number_of_profiles))

summary(netflix_clean)

# show the 5 largest values 
head(sort(netflix_clean$avg_watch_time_per_person, decreasing = TRUE), 5)

# remove value that is above 16hr 
netflix_clean <- subset(netflix_clean, avg_watch_time_per_person <= 16)
netflix_clean$avg_watch_time_per_day <- NULL

# no variables remaining after removing cust id
ncol(netflix_clean)

# check for missing values
missing_counts <- colSums(is.na(netflix_clean))
missing_counts # no missing value detected

# convert categorical variables to factors
netflix_clean$gender <- as.factor(netflix_clean$gender)
netflix_clean$subscription_type <- as.factor(netflix_clean$subscription_type)
netflix_clean$region <- as.factor(netflix_clean$region)
netflix_clean$device <- as.factor(netflix_clean$device)
netflix_clean$payment_method <- as.factor(netflix_clean$payment_method)
netflix_clean$favorite_genre <- as.factor(netflix_clean$favorite_genre)
netflix_clean$number_of_profiles <- as.factor(netflix_clean$number_of_profiles)

# 3 TRAIN/TEST SPLIT (80/20) + CROSS-VALIDATION SETUP

library(caret)
set.seed(100) 

# train/test split using caret
train_idx <- createDataPartition(netflix_clean$churned, p = 0.8, list = FALSE)
train_data <- netflix_clean[train_idx, ]
test_data <- netflix_clean[-train_idx, ]

# no of training set observations
nrow(train_data)
# no of test set observations
nrow(test_data)

# churn distribution in training set
table(train_data$churned)

# churn distribution in test set
table(test_data$churned)

# cross-validation setup for model validation
fitControl <- trainControl(
  method = "repeatedcv",
  number = 10,
  repeats = 3,
  classProbs = TRUE,
  summaryFunction = twoClassSummary,
  savePredictions = "final"
)

# check correlation in training set (continuous variables only)
continuous_vars <- c("age", "watch_hours", "last_login_days", "avg_watch_time_per_person")
cor_matrix <- cor(train_data[, continuous_vars], use = "complete.obs")

# correlation matrix 
round(cor_matrix, 3)

# 4 ASSUMPTIONS TESTING

# ASSUMPTION 1: Binary Outcome
unique_values <- unique(netflix_clean$churned)
print(unique_values)
# because the value is 1 and 0 it is binary 

# ASSUMPTION 2: Independence of Observations
# ASSUMED: Each customer is independent (unique customer_id removed)
# data collection should ensure no repeated measurements per customer

# ASSUMPTION 3: Multicollinearity Check (VIF Test)

# test with all variables to detect multicollinearity
model_with_fee <- glm(churned ~ ., data = train_data, family = "binomial")
vif(model_with_fee) # error because of alias

# check for aliased coefficients
alias(model_with_fee)

# we found that model fee has a multicolinearity with subcription type
# VIF test without monthly_fee
library(car)
model_no_fee <- glm(churned ~ . - monthly_fee, data = train_data, family = "binomial")
vif_values <- vif(model_no_fee)
vif_values

# ASSUMPTION 4: Sample Size Check
# use the 700i + 500 threshold from the literature

# ASSUMPTION 5: Influential Outliers Check -> we found another outlier test that aligns more with our data
cooks_d <- cooks.distance(model_no_fee)
cutoff <- 0.5 # Standard cutoff
influential_points <- which(cooks_d > cutoff)

# Plot Cook's distance
plot(cooks_d, main = "Cook's Distance - Outlier Detection",
     ylab = "Cook's Distance", xlab = "Observation Index", pch = 16)
abline(h = cutoff, col = "red", lty = 2, lwd = 2)
legend("topright", legend = paste("Cutoff =", round(cutoff, 4)), 
       col = "red", lty = 2, bty = "n")

# ASSUMPTION 6: LINEARITY OF LOG ODDS (SIMPLIFIED VERSION)
# elogit function
elogit <- function(x, y, nbins = 10, use_equal_width = FALSE) {
  # remove NAs and keep alignment
  ok <- is.finite(x) & !is.na(y)
  x <- x[ok]; y <- y[ok]
  
  if (length(x) < 10) return(NULL)  # not enough data to bin
  
  if (use_equal_width) {
    # equal-width bins
    rng <- range(x, na.rm = TRUE)
    br  <- pretty(rng, n = nbins)
  } else {
    # equal-count (quantile) bins
    br <- quantile(x, probs = seq(0, 1, length.out = nbins + 1), na.rm = TRUE)
  }
  
  br <- unique(br)                         # ensure unique breaks
  if (length(br) < 3) return(NULL)         # need at least 2 bins
  
  cutx <- cut(x, breaks = br, include.lowest = TRUE)
  p    <- tapply(y, cutx, mean)  
  mid  <- tapply(x, cutx, mean)
  
  # handle edge cases where p is 0 or 1
  eps <- 0.001
  p <- pmax(eps, pmin(1-eps, p))  # Bound p between eps and 1-eps
  
  el  <- log(p / (1 - p))  # logit transformation
  
  # return only non-NA values
  valid <- !is.na(el) & !is.na(mid)
  data.frame(xmid = as.numeric(mid[valid]), elogit = as.numeric(el[valid]))
}

# linearity of the log-odds plots
# only check the continuous variables WITHOUT transformation

# define numeric variables to check (NO LOG TRANSFORMATION)
num_vars <- c("age", "watch_hours", "last_login_days", "avg_watch_time_per_person")

# make sure variables exist in the dataset
num_vars <- intersect(num_vars, names(train_data))

# create the plots in a 2x2 grid
par(mfrow = c(2, 2), mar = c(4, 4, 3, 1))
for (v in num_vars) {
  if (!is.numeric(train_data$churned)) {
    stop("churned must be numeric (0/1) for linearity check")
  }
  eg <- elogit(train_data[[v]], train_data$churned, nbins = 10)
  if (is.null(eg) || nrow(eg) < 3) {
    plot(0, 0, type = "n", axes = FALSE, xlab = "", ylab = "",
         main = paste("Logit ~", v, "\n(insufficient data)"))
    next
  }
  
  # create the plot
  plot(eg$xmid, eg$elogit, pch = 16, cex = 1.2,
       xlab = v, ylab = "Empirical logit", 
       main = paste("Logit ~", v),
       ylim = range(eg$elogit, na.rm = TRUE) * c(0.9, 1.1))
  
  # add smoothed line (lowess)
  if (nrow(eg) >= 4) {
    lines(lowess(eg$xmid, eg$elogit, f = 0.75), col = "blue", lwd = 2)
  }
  
  # add linear fit
  if (nrow(eg) >= 3) {
    abline(lm(elogit ~ xmid, data = eg), lty = 2, col = "red")
  }
  
  # add grid for better readability
  grid(col = "gray90")
  
  # add legend
  if (nrow(eg) >= 4) {
    legend("topright", legend = c("Smoothed", "Linear"), 
           col = c("blue", "red"), lty = c(1, 2), lwd = c(2, 1),
           bty = "n", cex = 0.8)
  }
}
par(mfrow = c(1, 1))

# 5 LOGISTIC REGRESSION MODEL

# fit model without monthly_fee (due to multicollinearity)
model_logistic <- glm(churned ~ . - monthly_fee, data = train_data, family = "binomial")

summary(model_logistic)

# create coefficient interpretation table
model_summary <- summary(model_logistic)
coefficients_df <- data.frame(
  Variable = rownames(model_summary$coefficients),
  Estimate = model_summary$coefficients[, "Estimate"],
  Std_Error = model_summary$coefficients[, "Std. Error"],
  P_Value = model_summary$coefficients[, "Pr(>|z|)"],
  Odds_Ratio = exp(model_summary$coefficients[, "Estimate"]),
  Significant = ifelse(model_summary$coefficients[, "Pr(>|z|)"] < 0.001, "***",
                       ifelse(model_summary$coefficients[, "Pr(>|z|)"] < 0.01, "**",
                              ifelse(model_summary$coefficients[, "Pr(>|z|)"] < 0.05, "*", "")))
)

coefficients_df

# make predictions on test set
pred_logistic_prob <- predict(model_logistic, test_data, type = "response")
pred_logistic_binary <- ifelse(pred_logistic_prob > 0.5, 1, 0)

# calculate performance
accuracy_logistic <- mean(pred_logistic_binary == test_data$churned)
error_rate_logistic <- 1 - accuracy_logistic

# confusion Matrix
conf_logistic <- table(Predicted = pred_logistic_binary, Actual = test_data$churned)
print(conf_logistic)

# 6 PENALIZED REGRESSION MODELS

# prepare data for glmnet (needs numeric target and design matrix)
X_train <- model.matrix(churned ~ . - monthly_fee, data = train_data)[, -1]
X_test <- model.matrix(churned ~ . - monthly_fee, data = test_data)[, -1]
y_train <- train_data$churned
y_test <- test_data$churned

# no of observarions
nrow(X_train)
# no of predictors
ncol(X_train)

library(glmnet)

# RIDGE REGRESSION (alpha = 0)
ridge_cv <- cv.glmnet(X_train, y_train, family = "binomial", alpha = 0, nfolds = 10)
lambda_ridge <- ridge_cv$lambda.min
ridge_model <- glmnet(X_train, y_train, family = "binomial", alpha = 0, lambda = lambda_ridge)

# ridge predictions
pred_ridge_prob <- predict(ridge_model, X_test, s = lambda_ridge, type = "response")
pred_ridge_binary <- ifelse(pred_ridge_prob > 0.5, 1, 0)
accuracy_ridge <- mean(pred_ridge_binary == y_test)

# LASSO REGRESSION (alpha = 1)
lasso_cv <- cv.glmnet(X_train, y_train, family = "binomial", alpha = 1, nfolds = 10)
lambda_lasso <- lasso_cv$lambda.min
lasso_model <- glmnet(X_train, y_train, family = "binomial", alpha = 1, lambda = lambda_lasso)

# lasso coefficients (automatic variable selection)
lasso_coef <- coef(lasso_model, s = lambda_lasso)
lasso_coef_df <- data.frame(
  Variable = rownames(lasso_coef),
  Coefficient = as.vector(lasso_coef)
)
lasso_coef_df <- lasso_coef_df[lasso_coef_df$Coefficient != 0, ]

# lasso selected variable
lasso_coef_df

# lasso predictions
pred_lasso_prob <- predict(lasso_model, X_test, s = lambda_lasso, type = "response")
pred_lasso_binary <- ifelse(pred_lasso_prob > 0.5, 1, 0)
accuracy_lasso <- mean(pred_lasso_binary == y_test)


# ELASTIC NET REGRESSION (alpha = 0.5)
elastic_cv <- cv.glmnet(X_train, y_train, family = "binomial", alpha = 0.5, nfolds = 10)
lambda_elastic <- elastic_cv$lambda.min
elastic_model <- glmnet(X_train, y_train, family = "binomial", alpha = 0.5, lambda = lambda_elastic)


# elastic Net predictions
pred_elastic_prob <- predict(elastic_model, X_test, s = lambda_elastic, type = "response")
pred_elastic_binary <- ifelse(pred_elastic_prob > 0.5, 1, 0)
accuracy_elastic <- mean(pred_elastic_binary == y_test)

# 7 MODEL COMPARISON 

# performance comparison table
comparison_table <- data.frame(
  Model = c("Logistic", "Ridge", "Lasso", "Elastic Net"),
  Test_Accuracy = round(c(accuracy_logistic, accuracy_ridge, accuracy_lasso, accuracy_elastic), 4),
  Error_Rate = round(c(error_rate_logistic, 1-accuracy_ridge, 1-accuracy_lasso, 1-accuracy_elastic), 4),
  Variables_Used = c(
    length(coef(model_logistic)) - 1,
    ncol(X_train),
    nrow(lasso_coef_df) - 1,
    sum(coef(elastic_model, s = lambda_elastic) != 0) - 1
  )
)

# model performance comparison
comparison_table

