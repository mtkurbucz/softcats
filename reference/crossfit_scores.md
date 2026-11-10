# Cross-Fitted Estimator with Other Scores

Computes the cross-fitted estimate with other scores in place of the
class probabilities, such as hard labels or recalibrated probabilities,
using the folds, the outcome residuals and the seed stored in the fit.
With `replay = TRUE`, each regression of a score on the controls starts
from the state of the random number generator before the corresponding
regression of the fit, so that a stochastic learner draws the same
random numbers and scores equal to the probabilities reproduce the
estimate of the fit.

## Usage

``` r
crossfit_scores(object, H, what = "hard labels", replay = FALSE)
```

## Arguments

- object:

  \[mandatory\] (softcats) A fit returned by
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).

- H:

  \[mandatory\] (matrix) Scores without the reference category.

- what:

  \[optional\] (character) Name of the scores in error messages
  (default: `"hard labels"`).

- replay:

  \[optional\] (logical) Whether to replay the random number states of
  the fit; requires one score per probability column (default: `FALSE`).

## Value

A list with the estimate `tau`, its covariance `vcov`, the distortion
matrix `A` relative to the residualised probabilities of the fit and the
normalised Jacobian `M`, averaged over splits.
