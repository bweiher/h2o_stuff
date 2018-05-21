library(tidyverse)
library(h2o)

h2o.init()


# Use local data file or download from GitHub
docker_data_path <- "/home/h2o/data/automl/product_backorders.csv"
if (file.exists(docker_data_path)) {
  data_path <- docker_data_path
} else {
  data_path <- "https://github.com/h2oai/h2o-tutorials/raw/master/h2o-world-2017/automl/data/product_backorders.csv"
}


df <- read_csv(data_path) %>% 
  mutate_if(is.character,as.factor) %>% 
  mutate(lead_time = replace_na(lead_time, -99))
df %>% countp(went_on_backorder)

# Load data into H2O
df <- as.h2o(df)
h2o.describe(df)


y <- "went_on_backorder"
x <- setdiff(names(df), c(y, "sku"))

aml <- h2o.automl(y = y,
                  x = x,
                  training_frame = df,
                  max_models = 10,
                  seed = 1)

lb <- aml@leaderboard
lb


# Get model ids for all models in the AutoML Leaderboard
model_ids <- as.data.frame(aml@leaderboard$model_id)[,1]

# Get the "All Models" Stacked Ensemble model
se <- h2o.getModel(grep("StackedEnsemble_AllModels", model_ids, value = TRUE)[1])
# Get the Stacked Ensemble metalearner model
metalearner <- h2o.getModel(se@model$metalearner$name)

