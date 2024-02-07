
if(Sys.info()["user"]=="christianbaehr") {setwd("/Users/christianbaehr/Documents/GitHub/stylest2_project/stylest2_project/data")}

rm(list = ls())

library(quanteda)
library(stylest)

source("../R/stylest2_select_vocab.R")
source("../R/stylest2_fit.R")
source("../R/stylest2_predict.R")

################################################################################


## test functions with novels excerpts data

load("novels_excerpts.RData")

## pre processing for stylest2
novels_excerpts$text <- gsub("--|- | -|—", " - ", novels_excerpts$text)
novels_excerpts_tok <- tokens(novels_excerpts$text)
docvars(novels_excerpts_tok)["author"] <- novels_excerpts$author
novels_excerpts_dfm <- dfm(novels_excerpts_tok)


##### stylest_select_vocab #####

num <- sample(1:1000, 1)

set.seed(num)
MOD1CV <- stylest_select_vocab(x=novels_excerpts$text, speaker = novels_excerpts$author)
MOD1CV$miss_pct

set.seed(num)
MOD2CV <- stylest2_select_vocab(dfm=novels_excerpts_dfm)
MOD2CV$cv_missrate_results

all.equal(MOD1CV$miss_pct, MOD2CV$cv_missrate_results)


##### stylest_fit #####


## fit stylest
MOD1 <- stylest_fit(x = novels_excerpts$text, 
                            speaker = novels_excerpts$author,
                            smooth = 0.5,
                            terms = NULL,
                            term_weights = NULL)

## fit stylest2
MOD2 <- stylest2_fit(dfm=novels_excerpts_dfm)

## TEST 1: check the rates from fit() function are equal
MOD1$rate[ , colnames(MOD1$rate) == "the"]
MOD2$rate[ , colnames(MOD2$rate) == "the"]

MOD1$rate[ , colnames(MOD1$rate) == "little"]
MOD2$rate[ , colnames(MOD2$rate) == "little"]
## equivalent


##### stylest_predict #####


## check the predicted probabilites from predict() function

MOD1PRED <- stylest_predict(model = MOD1, text = novels_excerpts$text)
MOD2PRED <- stylest2_predict(dfm=novels_excerpts_dfm, model = MOD2,
                             speaker_odds = T, term_influence = T)

## predicted author of the text
all.equal(as.character(MOD1PRED$predicted), as.character(MOD2PRED$posterior$predicted))
## log probability of predicted authorship
all.equal( unname(as.matrix(MOD1PRED$log_probs)), unname(as.matrix(MOD2PRED$posterior$log_probs)) )
## equivalent


##### stylest_odds #####


MOD1ODDS <- stylest_odds(model = MOD1, text = novels_excerpts$text, speaker = novels_excerpts$author)

## average log odds
all.equal(MOD1ODDS$log_odds_avg, unname(MOD2PRED$speaker_odds$log_odds_mean))
## standard error of log odds
all.equal(MOD1ODDS$log_odds_se, unname(MOD2PRED$speaker_odds$log_odds_se))
## equivalent


##### stylest_term_influence #####


MOD1INF <- stylest_term_influence(model = MOD1, text = novels_excerpts$text, speaker = novels_excerpts$author)

## mean influence
all.equal(MOD1INF$infl_avg[order(MOD1INF$term)], MOD2PRED$term_influence[[1]]$mean_influence[order(MOD2PRED$term_influence[[1]]$features)])
## max influence
all.equal(MOD1INF$infl_max[order(MOD1INF$term)], MOD2PRED$term_influence[[1]]$max_influence[order(MOD2PRED$term_influence[[1]]$features)])
## equivalent



################################################################################


## test functions with SOTU speeches data

load("sotu_speeches.RData")

## pre processing for stylest2
sotu_speeches$text <- gsub("--|- | -|—", " - ", sotu_speeches$sotu_text)
sotu_speeches_tok <- tokens(sotu_speeches$text)
docvars(sotu_speeches_tok)["author"] <- sotu_speeches$president
sotu_speeches_dfm <- dfm(sotu_speeches_tok)



##### stylest_select_vocab #####


num <- sample(1:1000, 1)

set.seed(num)
MOD1CV <- stylest_select_vocab(x=sotu_speeches$text, speaker = sotu_speeches$president)
MOD1CV$miss_pct

set.seed(num)
MOD2CV <- stylest2_select_vocab(dfm=sotu_speeches_dfm)
MOD2CV$cv_missrate_results

all.equal(MOD1CV$miss_pct, MOD2CV$cv_missrate_results)



##### stylest_fit #####


## fit stylest
MOD1 <- stylest_fit(x = sotu_speeches$text, 
                    speaker = sotu_speeches$president,
                    smooth = 0.5,
                    terms = NULL,
                    term_weights = NULL)

## fit stylest2
MOD2 <- stylest2_fit(dfm=sotu_speeches_dfm)

## TEST 1: check the rates from fit() function are equal
MOD1$rate[ , colnames(MOD1$rate) == "the"]
MOD2$rate[ , colnames(MOD2$rate) == "the"]

MOD1$rate[ , colnames(MOD1$rate) == "little"]
MOD2$rate[ , colnames(MOD2$rate) == "little"]
## equivalent



##### stylest_predict #####


## check the predicted probabilites from predict() function

MOD1PRED <- stylest_predict(model = MOD1, text = sotu_speeches$text)
MOD2PRED <- stylest2_predict(dfm=sotu_speeches_dfm, model = MOD2,
                             speaker_odds = T, term_influence = T)

## predicted author of the text
all.equal(as.character(MOD1PRED$predicted), as.character(MOD2PRED$posterior$predicted))
## log probability of predicted authorship
all.equal( unname(as.matrix(MOD1PRED$log_probs)), unname(as.matrix(MOD2PRED$posterior$log_probs)) )
## equivalent



##### stylest_odds #####


MOD1ODDS <- stylest_odds(model = MOD1, text = sotu_speeches$text, speaker = sotu_speeches$president)

## average log odds
all.equal(MOD1ODDS$log_odds_avg, unname(MOD2PRED$speaker_odds$log_odds_mean))
## standard error of log odds
all.equal(MOD1ODDS$log_odds_se, unname(MOD2PRED$speaker_odds$log_odds_se))
## equivalent



##### stylest_term_influence #####


MOD1INF <- stylest_term_influence(model = MOD1, text = sotu_speeches$text, speaker = sotu_speeches$president)

## mean influence
all.equal(MOD1INF$infl_avg[order(MOD1INF$term)], MOD2PRED$term_influence[[1]]$mean_influence[order(MOD2PRED$term_influence[[1]]$features)])
## max influence
all.equal(MOD1INF$infl_max[order(MOD1INF$term)], MOD2PRED$term_influence[[1]]$max_influence[order(MOD2PRED$term_influence[[1]]$features)])
## equivalent





