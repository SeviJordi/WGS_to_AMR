#!/usr/bin/env/Rscript
# Jordi Sevilla Fortuny

# Load libraries
library(xgboost)
library(tidyverse)
library(vroom)

# log function
log <- function(str){
  sprintf("Rscript - %s | %s", Sys.time(), str)
}
# read args
args <- commandArgs(trailingOnly = TRUE)
atbs        <- readLines(args[1])
data_dir    <- args[2]
temp_dir    <- args[3]
output_file <- args[4]

# thresholds
thresholds <- list()
for (line in readLines(sprintf("%s/thresholds.tsv", data_dir))){
    atb <- strsplit(line, "\t")[[1]][1]
    th  <- strsplit(line, "\t")[[1]][2]
    thresholds[[atb]] <- as.numeric(th)
}

# create output table
output_table <- data.frame(
    "Sample" = character(),
    "Atb" = character(),
    "Prob_resistance" = numeric(),
    "Prediction" = character()
    )

# predict
for (atb in atbs){
    model <- sprintf("%s/%s.rds", data_dir, atb) %>%
        readRDS()
    data <- sprintf("%s/matrix_%s.txt", temp_dir, atb) %>%
        vroom()
    
    prediction <- predict(
        model,
        xgb.DMatrix(data = data.matrix(data[-1]))
        )
    
    for (x in 1:nrow(data)){
        output_table <- add_row(
            output_table,
            Sample = data$ID[x],
            Atb = atb,
            Prob_resistance = prediction[x],
            Prediction = ifelse(prediction[x] > thresholds[[atb]], "R", "S")
            )
    }
}

# Write output
output_table %>%
    pivot_wider(names_from = Atb, values_from = c(Prob_resistance, Prediction)) %>%
    write.csv(output_file, row.names = FALSE)

sprintf("Rscript - %s | Finished", Sys.time())
