
<!-- README.md is generated from README.Rmd. Please edit that file -->

# `stylest2` versus `stylest`

`stylest2` replaces `stylest` with a new design built to interface with
objects from the `quanteda` package.

Results obtained from `stylest2` might differ from `stylest` due to
differences in default text pre-processing across the `quanteda` and
`corpus` package. A user will obtain equivalent results across the two
packages if they feed equivalent document-feature matrices (dfm) to the
underlying model. The exact pre-processing steps required to ensure
equivalence of dfms will depend on the specifics of a user’s text data.

This vignette demonstrates the similar performance of `stylest2` and
`stylest` even under default pre-processing settings.

``` r
library(stylest2)
library(stylest)
library(quanteda)
#> Package version: 3.3.1
#> Unicode version: 14.0
#> ICU version: 71.1
#> Parallel computing: 8 of 8 threads used.
#> See https://quanteda.io for tutorials and examples.
```

# Loading data

`stylest2` functions accept text data in the form of `quanteda` `dfm`
objects. Users should begin by converting their text data to a `dfm`,
completing the desired pre-processing steps prior to using `stylest2`.
In this example, we convert an R `data.frame` object to a `dfm` with no
manual pre-processing.

``` r
data(novels)

novels_tok <- tokens(novels$text)

novels_dfm <- dfm(novels_tok)
```

We must also include a document-level variable in our `dfm` object
indicating authorship of the text.

``` r
docvars(novels_dfm)["author"] <- novels$author 
# it is necessary to name the authorship variable "author"
```

# Estimating models

We are now ready to estimate a `stylest2` model.

### Selecting an optimal vocabulary frequency cutoff

A first step in estimating the model is to determine which terms should
be included. By default, both packages include all terms from the dfm.
This might not be optimal if too many features result in model
overfitting. To resolve this, the package provides a function to select
the optimal set of terms using a cross-validation approach. The function
evaluates the models performance across different sets of terms. The
sets are determined by the frequency of term occurrence in the text.

``` r
set.seed(123)
(s2_cv <- stylest2_select_vocab(dfm = novels_dfm))
#> $cutoff_pct_best
#> [1] 80
#> 
#> $cutoff_candidates
#> [1] 50 60 70 80 90 99
#> 
#> $cv_missrate_results
#>   50% 60% 70% 80% 90% 99%
#> 1   0   0   0  50  50  75
#> 2  75  75  75  25  25  25
#> 3  75  75  75  50  50  50
#> 4  50  50  50  50  50 100
#> 5  60  60  60  60  60  80
#> 
#> $nfold
#> [1] 5

set.seed(123)
stylest_select_vocab(x = novels$text, speaker = novels$author)
#> $cutoff_pct_best
#> [1] 80
#> 
#> $cutoff_pcts
#> [1] 50 60 70 80 90 99
#> 
#> $miss_pct
#>      [,1] [,2] [,3] [,4] [,5] [,6]
#> [1,]   25   25   25   50   50   50
#> [2,]   75   75   75   25   25   50
#> [3,]   75   75   75   50   50   25
#> [4,]   50   50   50   50   50   50
#> [5,]   60   60   60   60   60   80
#> 
#> $nfold
#> [1] 5
#> 
#> attr(,"class")
#> [1] "stylest_select_vocab"
```

With the exception of the first fold, the rates of mis-attributed
authorship across cutoffs is quite consistent across the packages.

### Fitting a model

We are now ready to estimate a model.

``` r
terms <- c("sunset", "burden", "amusement")

s2_mod <- stylest2_fit(dfm = novels_dfm)
#> Warning in fit_term_usage(dfm = dfm, smoothing = smoothing, terms = terms, :
#> Detected multiple texts with the same author. Collapsing to author-level dfm
#> for stylest2_fit() function.
s2_mod$rate[ , terms]
#>                              features
#> docs                                sunset       burden    amusement
#>   Austen, Jane                0.0003316750 0.0003316750 0.0009950249
#>   Eliot, George               0.0012180268 0.0012180268 0.0004060089
#>   Gaskell, Elizabeth Cleghorn 0.0002424242 0.0002424242 0.0002424242

s1_mod <- stylest_fit(x = novels$text, speaker = novels$author)
s1_mod$rate[ , terms]
#>                                   sunset       burden    amusement
#> Austen, Jane                0.0003318951 0.0003318951 0.0009956854
#> Eliot, George               0.0011928429 0.0011928429 0.0003976143
#> Gaskell, Elizabeth Cleghorn 0.0002407898 0.0002407898 0.0002407898
```

The speaker rates for the selected terms are quite similar across the
texts, suggesting that pre-processing differences are not driving
significant differences across the two packages.

### Predicting authorship of new texts

``` r
s2_pred <- stylest2_predict(dfm = novels_dfm, model = s2_mod,
                            speaker_odds = TRUE, term_influence = TRUE)
s2_pred$posterior$log_probs[1:3 , ]
#> 3 x 3 Matrix of class "dgeMatrix"
#>       Austen, Jane Eliot, George Gaskell, Elizabeth Cleghorn
#> text1    -55.66133     -95.23924                     0.00000
#> text2    -62.19359       0.00000                   -62.25615
#> text3    -82.77107    -101.51593                     0.00000

s1_pred <- stylest_predict(model = s1_mod, text = novels$text)
s1_pred$log_prob[1:3 , ]
#> 3 x 3 Matrix of class "dgeMatrix"
#>      Austen, Jane Eliot, George Gaskell, Elizabeth Cleghorn
#> [1,]    -54.86742     -96.31594                     0.00000
#> [2,]    -60.86146       0.00000                   -61.83261
#> [3,]    -81.88056    -102.47517                     0.00000
```

We display the log odds of authorship over the first three prediction
texts. The two packages produce very similar results across all the
texts, and the predicted authorship is equivalent across packages for
all three texts.

``` r
s2_pred$posterior$predicted[1:3]
#> [1] "Gaskell, Elizabeth Cleghorn" "Eliot, George"              
#> [3] "Gaskell, Elizabeth Cleghorn"

s1_pred$predicted[1:3]
#> [1] Gaskell, Elizabeth Cleghorn Eliot, George              
#> [3] Gaskell, Elizabeth Cleghorn
#> Levels: Austen, Jane Eliot, George Gaskell, Elizabeth Cleghorn
```

### Evaluating speaker distinctiveness

We can also produce measures of average speaker distinctiveness across
predicted texts.

``` r
s2_pred$speaker_odds$log_odds_mean
#>     text1     text2     text3     text4     text5     text6     text7     text8 
#> 0.3618719 0.3805802 0.3863459 0.4804183 0.3901221 0.3610468 0.4728913 0.4471712 
#>     text9    text10    text11    text12    text13    text14    text15    text16 
#> 0.4073947 0.4080386 0.4914136 0.4087303 0.4288836 0.4301716 0.5136579 0.4457103 
#>    text17    text18    text19    text20    text21 
#> 0.5458026 0.3309383 0.3836957 0.3573008 0.3527845

s1_dnct <- stylest_odds(model = s1_mod, text = novels$text, speaker = novels$author)
s1_dnct$log_odds_avg
#>  [1] 0.3625500 0.3752112 0.3864900 0.4922300 0.3899163 0.3578583 0.4619084
#>  [8] 0.4542496 0.3939327 0.3997168 0.4967785 0.4074016 0.4296487 0.4368732
#> [15] 0.5668975 0.4512220 0.5484987 0.3318069 0.3840112 0.3596779 0.3694457
```

### Analyzing the influence of terms

Last, we can check for the influence of specific terms in attributing
authorship across the prediction texts.

``` r
s2_pred$term_influence[order(s2_pred$term_influence$features)[1:10] , ]
#>     features mean_influence max_influence
#> 989  _angina     0.05398389    0.16195168
#> 475   _them_     0.04274946    0.12824839
#> 767    _you_     0.04274946    0.12824839
#> 897    --and     0.05398389    0.16195168
#> 681    --but     0.01688978    0.05066935
#> 484      --i     0.02573146    0.06721438
#> 21         ,     1.24082283    2.27258759
#> 37         ;     0.58192468    0.85891738
#> 150        :     0.17606405    0.52819216
#> 585        !     0.39640294    1.18920882

s1_infl <- stylest_term_influence(model = s1_mod, text = novels$text, speaker = novels$author)
s1_infl[order(s1_infl$term)[1:10] , ]
#>         term   infl_avg  infl_max
#> 15   _angina 0.05332308 0.1599692
#> 16    _them_ 0.04328622 0.1298587
#> 17     _you_ 0.04328622 0.1298587
#> 7          - 1.46753879 3.9505432
#> 1041       — 0.11368028 0.3410408
#> 6          , 1.24468543 2.2996326
#> 13         ; 0.59030851 0.8766303
#> 12         : 0.17639488 0.5291846
#> 1          ! 0.39698189 1.1909457
#> 14         ? 0.21704085 0.4941007
```

This is where we see the greatest difference in results across the two
packages. Because the package deviates from in its default
pre-processing steps, the default document-feature matrix for a given
set of texts will also differ across the packages.

``` r
cmn_terms <- intersect(s2_pred$term_influence$features, s1_infl$term)
s2_pred$term_influence[match(cmn_terms[1:10], s2_pred$term_influence$features) , ]
#>    features mean_influence max_influence
#> 1        in     0.57659659     1.0890540
#> 2       the     2.36869453     4.5471811
#> 3    county     0.07945690     0.2182284
#> 4      town     0.11343216     0.3402965
#> 5        of     0.88195951     1.0838401
#> 6         a     0.46834902     0.8695090
#> 7   certain     0.09069133     0.2182284
#> 8     shire     0.05900552     0.1770166
#> 9     there     0.22003559     0.4781609
#> 10    lived     0.16849238     0.4840757

s1_infl[match(cmn_terms[1:10], s1_infl$term) , ]
#>        term   infl_avg  infl_max
#> 440      in 0.57821355 1.0974901
#> 901     the 2.30570953 4.4262521
#> 216  county 0.08024178 0.2189728
#> 934    town 0.11368028 0.3410408
#> 616      of 0.87781916 1.0744116
#> 18        a 0.51956798 0.9761457
#> 156 certain 0.09027864 0.2189728
#> 808   shire 0.05917094 0.1775128
#> 906   there 0.18203709 0.3756651
#> 515   lived 0.17001994 0.4889065
```

When we compare top terms that are common across the two models, we see
that the influence of these terms is very similar between `stylest` and `stylest2`.
