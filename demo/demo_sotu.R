
setwd("/Users/christianbaehr/Documents/GitHub/stylest2/R/")

library(stylest)
library(quanteda)
library(quanteda.corpora)

source("stylest2_select_vocab.R")
source("stylest2_fit.R")
source("stylest2_predict.R")


## load State of the Union speeches
## this is a corpus object with speech text a docvar for President name
load("../data/sotu_speeches.RData")

## convert corpus object to quanteda dfm
## Note: we do not include any pre-processing options. This is with the purpose
## to evaluate the natural performance of stylest2 relative to stylest on an 
## example dataset
sotu_dfm <- dfm(tokens(sotu))

## set authorship docvar name to "author"
docvars(sotu_dfm)["author"] <- docvars(sotu)["President"][[1]]


############################# stylest2_select_vocab ############################# 

## generate a random seed. Used by stylest2_select_vocab() to bin data into 
## random "folds" to perform k-fold cross-validation.
num <- sample(1:1000, 1)

set.seed(num)
s1_terms <- stylest_select_vocab(x=as.character(sotu), speaker = docvars(sotu)["President"][[1]])
s1_terms$miss_pct
## miss rate in test fold, across cutoff hyperparameter values

set.seed(num)
s2_terms <- stylest2_select_vocab(dfm=sotu_dfm)
s2_terms$cv_missrate_results
## miss rate in stylest2

## difference in miss rates across stylest and stylest2. Because the seed (and
## thus the allocation of observations to folds) is equivalent across both,
## any discrepancies are attributable to differences across package versions in 
## default text pre-processing behavior.
missrate_error <- as.numeric(s1_terms$miss_pct - s2_terms$cv_missrate_results)
hist(missrate_error, xlab = "Ppt. difference in miss rate")


################################# stylest2_fit #################################

## fit stylest model over all SOTU observations. 
s1_fit <- stylest_fit(x = as.character(sotu), 
                      speaker = docvars(sotu)["President"][[1]])

## fit stylest2 model
s2_fit <- stylest2_fit(dfm=sotu_dfm)

dim(s1_fit$rate)
dim(s2_fit$rate)

s1<- colnames(s1_fit$rate)
s2 <- colnames(s2_fit$rate)

s2[!(s2 %in% s1)]
s1[!(s1 %in% s2)]




## align feature names across packages model outputs for comparison of speaker rates
common_cols <- unique(c(colnames(s1_fit$rate)[colnames(s1_fit$rate) %in% colnames(s2_fit$rate)],
                        colnames(s2_fit$rate)[colnames(s2_fit$rate) %in% colnames(s1_fit$rate)]))

s1_fit_comp <- s1_fit$rate[ , common_cols] # align columns (features) for ease of comparison
s2_fit_comp <- s2_fit$rate[ , common_cols]

error <- as.numeric(s1_fit_comp - s2_fit_comp)

## histogram of differences in speaker-term rates across stylest and stylest2
hist(error)


############################### stylest2_predict ############################### 

## predict authorship for sample speeches, using the stylest model trained on 
## the same speeches
s1_pred <- stylest_predict(model = s1_fit, 
                           text = sotu)

## predict authorship using stylest2 model
s2_pred <- stylest2_predict(dfm=sotu_dfm, model = s2_fit, speaker_odds = T, 
                            term_influence = T)

sum((s1_pred$predicted == s2_pred$posterior$predicted)/length(s1_pred$predicted)) # prediction agreement rate

## matrix of stylest predicted log probabilities of authorship for each text
as.matrix(s1_pred$log_probs)
as.matrix(s2_pred$posterior$log_probs)

all.equal(rownames(s1_pred$log_probs), rownames(s2_pred$posterior$log_probs))
all.equal(colnames(s1_pred$log_probs), colnames(s2_pred$posterior$log_probs))

error <- as.numeric(s1_pred$log_probs - s2_pred$posterior$log_probs)

## histogram of differences in posterior log probabilities across stylest and stylest2
hist(error)

## stylest speaker odds
s1_odds <- stylest_odds(model = s1_fit,
                        text = sotu,
                        speaker = docvars(sotu)["President"][,1])

## average speaker odds in stylest vs stylest2
s1_odds$log_odds_avg
s2_pred$speaker_odds$log_odds_mean

## standard error of speaker odds in stylest vs stylest2
s1_odds$log_odds_se
s2_pred$speaker_odds$log_odds_se

## term influence of SOTU terms in stylest
s1_infl <- stylest_term_influence(model = s1_fit,
                                  text = sotu,
                                  speaker = docvars(sotu)["President"][,1])

## retrieve term influence scores for first ten terms
s1_infl[order(s1_infl$term)[1:10] , ]
s2_pred$term_influence[[1]][order(s2_pred$term_influence[[1]]$features)[1:10] , ]









