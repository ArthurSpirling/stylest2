#' Cross-validation based term selection
#'
#' K-fold cross validation to determine the optimal cutoff on the term frequency 
#' distribution under which to drop terms.
#' 
#' @export
#' 
#' @param dfm a quanteda \code{dfm} object. 
#' @param smoothing the smoothing parameter value for smoothing the dfm. Should 
#' be a numeric scalar, default to 0.5.
#' @param cutoffs a numeric vector of cutoff candidates.
#' @param nfold number of folds for the cross-validation
#' @param terms If not \code{NULL}, terms to be used in the model. If \code{NULL}, 
#' use all terms.
#' @param term_weights Named vector of distances (or any weights) per term in the 
#' vocab. Names should correspond to the term.
#' @param fill Should missing values in term weights be filled? Defaults to FALSE.
#' @param fill_weight Numeric value to fill in as weight for any term which does 
#' not have a weight specified in \code{term_weights}.
#' @return List of: best cutoff percent with the best speaker classification
#'   rate; cutoff percentages that were tested; matrix of the mean percentage of
#'   incorrectly identified speakers for each cutoff percent and fold; and the
#'   number of folds for cross-validation.
#' 
stylest2_select_vocab <- function(dfm, smoothing=0.5, cutoffs=c(50, 60, 70, 80, 90, 99), 
                                  nfold=5, terms=NULL, term_weights=NULL, fill=FALSE,
                                  fill_weight=NULL) {
  
  ## check that `dfm` is of acceptable class and, if so, does it have the correct
  ## columns?
  if(!inherits(dfm, 'dfm')) {
    
    stop('`dfm` object must be of class "dfm".')
    
  }
  
  if(smoothing<0 | !is.numeric(smoothing)) {
    stop('Smoothing value must be numeric and non-negative.')
  }
  
  ## extract authors from input data
  if( !'author' %in% names(quanteda::docvars(dfm)) ) {
    stop('Need to supply a docvar in `dfm` with text authorship with name "author".')
  } else {
    author_loc <- as.character(quanteda::docvars(dfm)['author'][,1])
  }
  
  if(length(author_loc) < 2) {
    stop('Should be at least two authors in the corpus.')
  }
  if(any(is.na(author_loc))) {
    stop('Detected missingness in the authorship variable. Documents with missing authorship should be omitted from the corpus.')
  }
  
  ## if there are any docvars that dont contain "author"
  if( any(colnames(quanteda::docvars(dfm)) != 'author') ) {
    warning('Additional docvars detected other than authorship. These will be ignored.')
  }
  
  ## reorder documents prior distributing folds
  ndoc <- nrow(dfm)

  ## assign rows to folds
  test_fold <- sample(rep(1:nfold, ceiling(ndoc / nfold)), ndoc)
  
  ## empty matrix to store missrate for each fold, cutoff
  missrate <- matrix(NA, nrow = nfold, ncol = length(cutoffs))
  colnames(missrate) <- paste0(cutoffs, "%")
  rownames(missrate) <- 1:nfold
  
  for(i in 1:nfold) {
    
    ## allocate all folds except i to training set, i to test set
    test_set <- (test_fold == i)
    train_set <- !test_set
    X_test <- dfm[test_set, ]
    X_train <- dfm[train_set, ]
    
    ## temporary dfm -- utility object to help retrieve terms with frequency >(cutoff/100)
    temp <- dfm(X_train)
    
    for(j in 1:length(cutoffs)) {
      
      ## select only the terms above the (j/100)th quantile of frequency
      keep_terms <- colnames( quanteda::dfm_trim(temp, min_termfreq = (cutoffs[j]/100), termfreq_type = c("quantile")) )
      
      ## keep only the candidate terms
      #X_train_sub <- tokens_select(X_train, pattern=keep_terms)
      X_train_sub <- quanteda::dfm_select(X_train, pattern = keep_terms)
      
      ## fit the model to the terms above cutoff
      fit <- stylest2_fit(dfm=X_train_sub, smoothing=smoothing, terms=terms,
                          term_weights=term_weights, fill=fill, fill_weight=fill_weight)
      
      ## predict authors for the hold-out fold
      prediction <- stylest2_predict(model=fit, dfm=X_test)
      
      ## calculate miss rate -- the percent of hold-out texts for which we get authorship
      ## wrong
      missrate[i, j] <- 100 * mean(prediction$posterior$predicted != author_loc[test_set]) 
    }
    
  }
  
  ## collapse to the mean of missrates across folds
  avg_missrate <- apply(missrate, 2, mean)
  
  ## retrieve the highest performing cutoff rate in terms of minimizing average misses
  bestrate <- names(avg_missrate)[which.min(avg_missrate)]
  
  return(
    list(cutoff_pct_best = bestrate,
         cutoff_candidates = cutoffs,
         cv_missrate_results = missrate,
         nfold = nfold)
  )
  
}

#' Select terms above frequency cutoff
#'
#' A function to select terms for inclusion in a stylest2 model, based on a document-feature
#' matrix of texts to predict and a specified cutoff.
#' 
#' @export
#' 
#' @param dfm a quanteda \code{dfm} object. 
#' @param cutoff a single numeric value - the quantile of term frequency under which
#' to drop terms.
#' @return A character vector of terms falling above the term frequency cutoff.
#' 
stylest2_terms <- function(dfm, cutoff) {
  
  if(!'author' %in% names(quanteda::docvars(dfm)) ) {
    stop('Need to supply a docvar in `dfm` with text authorship with name "author".')
  } else {
    author_loc <- as.character(quanteda::docvars(dfm)['author'][,1])
  }
  
  if(length(author_loc) < 2) {
    stop("Should be at least two authors in the corpus.")
  }
  if(any(duplicated(author_loc))) {
    stop("Detected multiple instances of the same author. The corpus must be collapsed to the author-level before passing to stylest2.")
  }
  if(any(is.na(author_loc))) {
    stop("Detected missingness in the authorship variable. Documents with missing authorship should be omitted from the corpus.")
  }
  
  ## select the terms that are above the (cutoff/100) quantile of term frequency
  keep_terms <- colnames( quanteda::dfm_trim(dfm, min_termfreq = (cutoff/100), termfreq_type = c('quantile')) )
  
  ## return a vector of terms
  return(keep_terms)
  
}