#!/usr/bin/env/Rscript
# Jordi Sevilla Fortuny

# Load libraries
library(xgboost)
library(tidyverse)
library(vroom)

# Constants
FOSFO_TH = 0.38
AMI_TH = 0.054
PIP_TH = 0.39

# log function
log <- function(str){
  sprintf("Rscript - %s | %s", Sys.time(), str)
}
# read args
args <- commandArgs(trailingOnly = TRUE)
fosfo_model <- args[1]
fosfo_data <-  args[2]
ami_model <-   args[3]
ami_data <-    args[4]
pip_model <-   args[5]
pip_data <-    args[6]
output_file <- args[7]

# create output table
output_table <- data.frame(
    "Sample" = character(),
    "Atb" = character(),
    "Prob_resistance" = numeric(),
    "Prediction" = character()
    )

# Fosfomycin prediction
fosfo_model <- readRDS(fosfo_model)
fosfo_data <- vroom::vroom(fosfo_data)

fosfo_prediction <- predict(
    fosfo_model,
    xgb.DMatrix(data = data.matrix(fosfo_data[-1]))
    )



for (x in 1:nrow(fosfo_data)){    

    output_table <- add_row(
        output_table,
        Sample = fosfo_data$ID[x],
        Atb = "Fosfomycin",
        Prob_resistance = fosfo_prediction[x],
        Prediction = ifelse(fosfo_prediction[x] > FOSFO_TH, "R", "S")
        )

}


# Amikacin prediction
ami_model <- readRDS(ami_model)
ami_data <- vroom::vroom(ami_data)

ami_prediction <- predict(
    ami_model,
    xgb.DMatrix(data = data.matrix(ami_data[-1]))
    )

for (x in 1:nrow(ami_data)){    

    output_table <- add_row(
        output_table,
        Sample = ami_data$ID[x],
        Atb = "Amikacin",
        Prob_resistance = ami_prediction[x],
        Prediction = ifelse(ami_prediction[x] > AMI_TH, "R", "S")
        )
}

# Piperacillin prediction
pip_model <- readRDS(pip_model)
pip_data <- vroom::vroom(pip_data)

pip_prediction <- predict(
    pip_model,
    xgb.DMatrix(data = data.matrix(pip_data[-1]))
    )

for (x in 1:nrow(pip_data)){    

    output_table <- add_row(
        output_table,
        Sample = pip_data$ID[x],
        Atb = "Piperacillin",
        Prob_resistance = pip_prediction[x],
        Prediction = ifelse(pip_prediction[x] > PIP_TH, "R", "S")
        )
}


# Write output
write.csv(output_table, output_file, row.names = FALSE)

sprintf("Rscript - %s | Finished", Sys.time())
