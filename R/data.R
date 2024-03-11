#' Excerpts from English novels
#' 
#' @name novels
#' @docType data
#' @usage data(novels)
#' @description A dataset of text from English novels by Jane Austen, George Eliot, 
#' and Elizabeth Gaskell.
#' @format A dataframe with 21 rows and 3 variables.
#' @source Novel excerpts obtained from Project Gutenberg full texts in the
#'   public domain in the USA. \url{http://gutenberg.org}
#' @keywords datasets
"novels"

#' Novel excerpts in quanteda dfm object
#' 
#' @name novels_dfm
#' @docType data
#' @usage data(novels_dfm)
#' @description A dataset of text from English novels by Jane Austen, George Eliot, 
#' and Elizabeth Gaskell. It has been tokenized and processed as a document-feature
#' matrix in quanteda.
#' @format A quanteda \code{dfm} with a document variable titled "author".
#' @source Novel excerpts obtained from Project Gutenberg full texts in the
#'   public domain in the USA. \url{http://gutenberg.org}
#' @keywords datasets
"novels_dfm"

#' SOTU speech data
#' 
#' @name sotu
#' @docType data
#' @usage data(sotu)
#' @description A dataset of U.S. presidential State of the Union speeches from 
#' 1974-present
#' @format A dataframe with 46 rows and 5 variables.
#' @source Speeches obtained from the R \code{sotu} package.
#' @keywords datasets
"sotu"

