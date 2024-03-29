% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/stylest2_predict.R
\name{speaker_odds}
\alias{speaker_odds}
\title{Internal stylest2 function to predict log odds of speakership across texts.}
\usage{
speaker_odds(log_weights, pred_docs_dfm, pred_docs_ntoken, speakers)
}
\arguments{
\item{log_weights}{The logged author-level term weights from a stylest2 model.}

\item{pred_docs_dfm}{A document-feature matrix for the texts to be predicted.}

\item{pred_docs_ntoken}{A vector, the number of tokens in each prediction
document.}

\item{speakers}{The speaker labels for \code{pred_docs_dfm} rows.}
}
\description{
Internal stylest2 function to predict log odds of speakership across texts.
}
\keyword{internal}
