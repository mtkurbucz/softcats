# Recalibrate the Class Probabilities on Labelled Data

[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
requires the class probabilities to be calibrated given the controls.
When
[`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
rejects this, a sample in which the group is observed can be used to
recalibrate them. `recalibrate()` estimates the recalibration map
\\E\[1\\G = k\\ \mid p, X\]\\ on the labelled sample, checks the
recalibrated probabilities out of fold, and recomputes the estimate of
the fit with them. It implements the recalibration experiment of Kurbucz
(2026, arXiv:2608.11784), which also helps to tell which condition of
the estimator fails.

## Usage

``` r
recalibrate(
  object,
  labelled,
  group,
  probs = NULL,
  interactions = TRUE,
  folds = 5L,
  weights = NULL,
  level = 0.95,
  seed = NULL
)

# S3 method for class 'softcats_recalibration'
print(x, digits = 3L, ...)

# S3 method for class 'softcats_recalibration'
predict(object, newdata, probs = NULL, ...)
```

## Arguments

- object:

  \[mandatory\] (softcats or softcats_recalibration) A fit returned by
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md);
  for [`predict()`](https://rdrr.io/r/stats/predict.html), the result of
  `recalibrate()`.

- labelled:

  \[mandatory\] (data.frame) Labelled observations with the controls of
  the fit, the probabilities and the observed group.

- group:

  \[mandatory\] (vector or character) Observed category labels in
  `labelled`: a column name or a vector. Labels must match the category
  names of the fit; for a fit with a numeric probability vector use 0/1
  or `FALSE`/`TRUE`.

- probs:

  \[optional\] (matrix, data.frame, character, formula or numeric)
  Probabilities for the labelled observations, or for `newdata` in
  [`predict()`](https://rdrr.io/r/stats/predict.html), in any form
  accepted by
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).
  `NULL` reuses the `probs` specification of the fit, or of the labelled
  sample in [`predict()`](https://rdrr.io/r/stats/predict.html), which
  works when it was given as column names or a formula (default:
  `NULL`).

- interactions:

  \[optional\] (logical) Whether the map includes the products of the
  log-odds and the controls (default: `TRUE`).

- folds:

  \[optional\] (integer) Number of folds of the labelled sample for the
  out-of-fold check, at least two (default: `5`).

- weights:

  \[optional\] (numeric, character or formula) Weights of the labelled
  observations: a vector, a column name of `labelled` or a one-sided
  formula (default: `NULL`).

- level:

  \[optional\] (numeric) Confidence level of the intervals (default:
  `0.95`).

- seed:

  \[optional\] (integer) Seed for the folds of the labelled sample.
  `NULL` uses the seed of the fit (default: `NULL`).

- x:

  \[mandatory\] (softcats_recalibration) Result of `recalibrate()`.

- digits:

  \[optional\] (integer) Number of significant digits to print (default:
  `3`).

- ...:

  \[optional\] Not used.

- newdata:

  \[mandatory\] (data.frame) Data with the controls and the
  probabilities to recalibrate.

## Value

`recalibrate()` returns an object of class `softcats_recalibration`: a
list with `estimates` (a data frame with columns `probabilities`,
`term`, `estimate`, `std.error`, `conf.low` and `conf.high`),
`calibration` (the results of
[`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
on the labelled sample, `original` and `recalibrated` out of fold),
`spectrum` (the score spectra of the estimation sample, `original` and
`recalibrated`, as returned by
[`score_spectrum()`](https://mtkurbucz.github.io/softcats/reference/score_spectrum.md)),
`probs` (the recalibrated probabilities of the estimation sample,
reference category first), `probs_labelled` (the out-of-fold
recalibrated probabilities of the complete labelled observations), `map`
(the fitted map) and `nobs_labelled`.
[`predict()`](https://rdrr.io/r/stats/predict.html) returns a matrix of
recalibrated probabilities with one row per row of `newdata`, `NA` where
an input is missing, and the columns in the order of `probs`. The print
method returns `x` invisibly.

## Details

The map is a multinomial logistic regression of the observed group on
the log-odds of the probabilities against the reference category, the
controls and, with `interactions = TRUE`, the products of the log-odds
and the controls. It is fitted by maximum likelihood with the log-odds
as an offset, so that zero coefficients leave the probabilities
unchanged. For two categories and without controls, the map is the
logistic recalibration model of Cox (1958). Factor controls enter as
dummies, and a level that does not occur in the labelled sample is
treated as the first level. Columns that are collinear in the labelled
sample are dropped. With few labelled observations, or when the
miscalibration does not depend on the controls, `interactions = FALSE`
gives a map with fewer parameters.

The function proceeds in three steps.

1.  The labelled sample is split into `folds` folds; two folds give the
    split-half design of Kurbucz (2026). Each fold is recalibrated by
    the map fitted on the other folds, and
    [`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
    is run on the original and on these out-of-fold probabilities, so
    that the check does not reuse the observations that fitted the map.
    The maps of the folds are fitted on fewer observations than the
    final map, so the check is somewhat conservative.

2.  The map fitted on the whole labelled sample recalibrates the
    probabilities of the estimation sample.

3.  The estimate is recomputed with the recalibrated probabilities,
    using the folds, the outcome residuals and the learner of the fit.
    Only the regressions of the probabilities on the controls are
    refitted, and each starts from the state of the random number
    generator before the corresponding regression of the fit, so a
    stochastic learner such as
    [`lrn_ranger()`](https://mtkurbucz.github.io/softcats/reference/learners.md)
    draws the same random numbers. The two estimates thus differ only
    through the recalibration, and
    [`update()`](https://rdrr.io/r/stats/update.html) with the
    probabilities from
    [`predict()`](https://rdrr.io/r/stats/predict.html) and the seed of
    the fit gives the same estimate.

Recalibration targets calibration given the controls, not the exclusion
condition. If the classifier features affect the outcome directly,
\\E\[Y \mid G, p, X\] = \mu(X) + \tau^\top g + d(p, X)\\, the estimate
converges to \\\tau + M^{-1} E\[a\\d\]\\ with \\M = E\[a a^\top\]\\. A
map that moves the probabilities towards their conditional mean given
the controls shrinks \\M\\ and can amplify this bias. The function
therefore reports the eigenvalues of \\M\\ and the smallest canonical
share before and after recalibration, and the print method notes when
recalibration halves the smallest eigenvalue or more. Read together with
[`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
and
[`exclusion_test()`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md),
the change in the estimate indicates which condition fails.

The standard errors after recalibration treat the map as known. They do
not include its estimation error and can therefore be too small,
especially when the labelled sample is small compared with the
estimation sample. The function warns when the labelled sample has fewer
than ten observations per parameter of the map.

[`predict()`](https://rdrr.io/r/stats/predict.html) applies the map
fitted on the whole labelled sample to other data, for example to refit
the model with [`update()`](https://rdrr.io/r/stats/update.html).

## References

Kurbucz, M. T. (2026). Coarsening latent-class probabilities:
Directional distortion and coverage loss. arXiv preprint.
[doi:10.48550/arXiv.2608.11784](https://doi.org/10.48550/arXiv.2608.11784)

Cox, D. R. (1958). Two further applications of a model for binary
regression. *Biometrika*, 45(3–4), 562–565.
[doi:10.1093/biomet/45.3-4.562](https://doi.org/10.1093/biomet/45.3-4.562)

## See also

[`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
for the calibration tests,
[`exclusion_test()`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md)
for direct effects of the classifier features.

## Examples

``` r
# Example: Probabilities miscalibrated given the first control
d <- sim_softcats(n = 3000, K = 2, miscalibration = 1.5,
                  labelled_share = 0.3, seed = 8)
fit <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B"), data = d,
               learner = lrn_lm(degree = 3), seed = 8)
rc <- recalibrate(fit, labelled = d[d$labelled, ], group = "group")
rc
#> Recalibration of the class probabilities on 919 labelled observations
#> Map: multinomial logit with 8 parameters on the log-odds, the controls and
#> their products
#> 
#> Calibration on the labelled sample (recalibrated out of fold, 5 folds):
#>  probabilities category    ECE overall p conditional p net of noise
#>       original        B 0.1010    <1e-04        <1e-04       0.0826
#>   recalibrated        B 0.0243     0.906         0.999       0.0000
#> 
#> Information beyond the controls (estimation sample):
#>                      original recalibrated
#> eigenvalue of E[aa']   0.0736       0.0935
#> smallest share         0.5180       0.8600
#> 
#> Estimates (difference from reference category 'A'):
#>  probabilities term estimate std.error conf.low conf.high
#>       original    B    1.040    0.0697     0.90      1.17
#>   recalibrated    B    0.971    0.0622     0.85      1.09
#> 
#> Standard errors after recalibration treat the map as known.
attr(d, "tau")
#> B 
#> 1 

# Example: Refit with the recalibrated probabilities of all observations
d[, c("rprob_A", "rprob_B")] <- predict(rc, d)
update(fit, probs = c("rprob_A", "rprob_B"))
#> Regression on predicted categories (calibrated soft labels)
#> 
#> Call:
#> soft_lm(formula = y ~ x1 + x2 + x3, probs = c("rprob_A", "rprob_B"), 
#>     data = d, learner = lrn_lm(degree = 3), seed = 8)
#> 
#> Difference from reference category 'A':
#>   Estimate Std. Error  2.5 % 97.5 %
#> B   0.9715    0.06216 0.8496  1.093
#> 
#> Observations: 3000   Cross-fitting: 5 folds, 1 split
#> Learner: lm (degree 3)
```
