
setwd("/Users/christianbaehr/Documents/GitHub/stylest2/R/")

library(stylest)
library(quanteda)
library(quanteda.corpora)

source("stylest2_select_vocab.R")
source("stylest2_fit.R")
source("stylest2_predict.R")

load("../data/novels_excerpts.RData")
novels$id <- 1:nrow(novels)

novelst <- tokens(novels$text)
novelsd <- dfm(novelst)
docvars(novelsd)["author"] <- novels$author

## fit stylest model over all SOTU observations. 
s1_fit <- stylest_fit(x = novels$text, 
                      speaker = novels$author)

## fit stylest2 model
s2_fit <- stylest2_fit(dfm=novelsd)

s1_pred <- stylest_predict(model = s1_fit, 
                           text = novels$text)

s2_pred <- stylest2_predict(dfm=novelsd, model = s2_fit, speaker_odds = T, 
                            term_influence = T)

cat(sum(s1_pred$predicted==s2_pred$posterior$predicted) / length(s1_pred$predicted) * 100,
    "% prediction agreement \n" , sep = "")













