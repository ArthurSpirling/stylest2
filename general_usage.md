

# About `stylest2`

This vignette describes the usage of `stylest2` for estimating speaker (author) style distinctiveness.

### Installation

The dev version of `stylest2` on GitHub may be installed with:

```r
install.packages("devtools")
devtools::install_github("ArthurSpirling/stylest2")
```

### Load the package

`stylest2` is built to interface with `quanteda`. A `quanteda` `dfm` object is required to fit a model in `stylest2`, so we recommend installing `quanteda` as well. 

```r
library(stylest2)
library(quanteda)
```

# Example: Fitting a model to English novels

We will be using texts of the first lines of novels by Jane Austen, George Eliot, and Elizabeth Gaskell. Excerpts were obtained from the full texts of novels available on Project Gutenberg: http://gutenberg.org.

```r
data(novels)
```

```r
# show a snippet of the data
novels[c(1,4,8), ]
```

The data should be transformed into a `quanteda` `dfm` object. 

**It should also include a document variable (`docvar`) entitled "author".** This is the variable around which the corpus is grouped (and ultimately collapsed).

Here, we will use `novels$author`.

```r
novels_tok <- tokens(novels$text)
novels_dfm <- dfm(novels_tok)

unique(novels$author)
docvars(novels_dfm)["author"] <- novels$author

```

In many cases, one will want to do more elaborate preprocessing.  These decisions can be passed to the `tokens()` function prior to generating a document-feature matrix; see the `quanteda` package for more information about `tokens()`.  For example: 

```r

novels_tok <- tokens(novels$text, 
                     remove_punct = T,
                     remove_symbols = T,
                     remove_numbers = T,
                     remove_separators = T,
                     split_hyphens = T)
novels_dfm <- dfm(novels_tok)

unique(novels$author)
docvars(novels_dfm)["author"] <- novels$author

```

## Using `stylest2_select_vocab`

This function uses n-fold cross-validation to identify the set of terms that maximizes the model's rate of predicting the speakers of out-of-sample texts. For those unfamiliar with cross-validation, the technical details follow:

- The terms of the raw vocabulary are ordered by frequency.
- A subset of the raw vocabulary above a frequency percentile is selected; e.g. terms above the 50th percentile are those which occur more frequently than the median term in the raw vocabulary.
- The corpus is divided into n folds. 
- One of these folds is held out and the model is fit using the remaining n-1 folds. The model is then used to predict the speakers of texts in the held-out fold. (This step is repeated n times.)
- The mean prediction rate for models using this vocabulary (percentile) is calculated.

(Vocabulary selection is optional; the model can be fit using all the terms in the support of the corpus.)

Setting the seed before this step, to ensure reproducible runs, is recommended:

```r
set.seed(1234)
```

Below are examples of `stylest2_select_vocab` using the defaults and with custom parameters:

```r
vocab_with_defaults <- stylest2_select_vocab(dfm = novels_dfm)
```

```r
vocab_custom <- stylest2_select_vocab(dfm = novels_dfm, 
                                      smoothing = 1, 
                                      nfold = 10, 
                                      cutoffs = c(50, 75, 99))
```

Let's look inside the `vocab_with_defaults` object.

```r
# Percentile with best prediction rate
vocab_with_defaults$cutoff_pct_best

# Rate of INCORRECTLY predicted speakers of held-out texts
vocab_with_defaults$cv_missrate_results

# Data on the setup:

# Percentiles tested
vocab_with_defaults$cutoff_candidates

# Number of folds
vocab_with_defaults$nfold
```

## Fitting a model

### Using a percentile to select terms

With the best percentile identified as 90 percent, we can select the terms above that percentile to use in the model. Be sure to use the same `text_filter` here as in the previous step.

```r
terms_90 <- stylest2_terms(dfm = novels_dfm, cutoff = 90)
```
This will issue a warning reminding users that the texts are being grouped/collapsed by author. 

### Fitting the model: basic

Below, we fit the model using the terms above the 90th percentile, using the same `text_filter` as before, and leaving the smoothing value for term frequencies as the default `0.5`.

```r
mod <- stylest2_fit(dfm = novels_dfm, terms = terms_90)
```

This will also a issue the same warning about collapsing on author. The model contains detailed information about token usage by each of the authors (see `mod$rate`); exploring this is left as an exercise.

### Fitting the model: adding custom term weights

A new feature is the option to specify custom term weights, in the form of a dataframe. The intended use case is the mean cosine distance from the embedding representation of the word to all other words in the vocabulary, but the weights can be anything desired by the user. 

An example `term_weights` is shown below. When this argument is passed to `stylest_fit()`, the weights for terms in the model vocabulary will be extracted. Any term not included in `term_weights` will be assigned a default weight of 0.

```r
term_weights <- c(0.1,0.2,0.001)
names(term_weights) <- c("the", "and", "Floccinaucinihilipilification")

term_weights
```

Below is an example of fitting the model with `term_weights`:

```r
mod <- stylest2_fit(dfm = novels_dfm,  terms = terms_90, term_weights = term_weights)
```

The weights are stored in `mod$term_weights`.

## Using the model

By default, `stylest_predict()` returns the posterior probabilities of authorship for each prediction text.

```r
predictions <- stylest2_predict(dfm = novels_dfm, model = mod)
```

`stylest_predict()` can optionally return the log odds of authorship for each speaker over each text, as well as the average contribution of each term in the model to speaker distinctiveness.

```r
predictions <- stylest2_predict(dfm = novels_dfm, model = mod,
                                speaker_odds = TRUE, term_influence = TRUE)
```

We can examine the mean log odds that Jane Austen wrote _Pride and Prejudice_ (in-sample).

```r
# Pride and Prejudice -- we can just look up 'Pride' in the titles, and see it is novel 14.
# That is

grep("Pride", novels$title)

# and
novels$text[grep("Pride", novels$title)]

predictions$speaker_odds$log_odds_mean[14]

predictions$speaker_odds$log_odds_se[14]
```


The terms with the highest mean influence can be obtained:

```r
head(predictions$term_influence$features[order(predictions$term_influence$mean_influence, decreasing = TRUE)])
```

And the least influential terms:

```r
tail(predictions$term_influence$features[order(predictions$term_influence$mean_influence, decreasing = TRUE)])
```



### Predicting the speaker of a new text

In this example, the model is used to predict the speaker of a new text, in this case _Northanger Abbey_ by Jane Austen. 

Note that a `prior` may be specified, and may be useful for handling texts containing out-of-sample terms. Here, we do not specify a prior, so a uniform prior is used.

```r
na_text <- "No one who had ever seen Catherine Morland in her infancy would have supposed 
            her born to be an heroine. Her situation in life, the character of her father 
            and mother, her own person and disposition, were all equally against her. Her 
            father was a clergyman, without being neglected, or poor, and a very respectable 
            man, though his name was Richard—and he had never been handsome. He had a 
            considerable independence besides two good livings—and he was not in the least 
            addicted to locking up his daughters."

na_text_dfm <- dfm(tokens(na_text))

pred <- stylest2_predict(dfm = na_text_dfm, model = mod)
```

Viewing the result, and recovering the log probabilities calculated for each speaker, is simple:

```r
pred$posterior$predicted

pred$posterior$log_probs
```


## Issues

Please submit any bugs, error reports, etc. on GitHub at: https://github.com/ArthurSpirling/stylest2/issues.
