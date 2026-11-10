# Compare with Regressions on Predicted Labels

Replacing the class probabilities by a predicted label (the most likely
class, or a confidence threshold) is a coarsening of the probabilities.
`compare_hard()` reports, next to the
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
estimate, two hard-label estimates on the same data, the distortion that
coarsening causes, and the coverage that hard-label confidence intervals
can be expected to have.

## Usage

``` r
compare_hard(
  object,
  rule = c("argmax", "threshold"),
  threshold = 0.5,
  level = 0.95
)

# S3 method for class 'softcats_hard'
print(x, digits = 3L, ...)
```

## Arguments

- object:

  \[mandatory\] (softcats) A fit returned by
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).

- rule:

  \[optional\] (character) `"argmax"` assigns the most likely category;
  `"threshold"` (two categories only) assigns the non-reference category
  when its probability exceeds `threshold` (default: `"argmax"`).

- threshold:

  \[optional\] (numeric) Threshold for `rule = "threshold"` (default:
  `0.5`).

- level:

  \[optional\] (numeric) Confidence level for the intervals and the
  implied coverage (default: `0.95`).

- x:

  \[mandatory\] (softcats_hard) Result of `compare_hard()`.

- digits:

  \[optional\] (integer) Number of significant digits to print (default:
  `3`).

- ...:

  \[optional\] Not used.

## Value

An object of class `softcats_hard`: a list with `estimates` (a data
frame with columns `method`, `term`, `estimate`, `std.error`,
`conf.low`, `conf.high`), the estimated distortion matrix `distortion`,
the retention coefficients `retention`, and `coverage`, a data frame
with the implied bias of the cross-fitted hard-label estimate and the
implied coverage of its intervals. The print method returns `x`
invisibly.

## Details

The two hard-label estimates are:

- `hard (OLS)`: least squares of the outcome on the label dummies and
  the controls entered linearly, with HC1 or, with clusters, CR1
  standard errors as in
  [`exclusion_test()`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md).
  This is the analysis most often run in practice.

- `hard (cross-fitted)`: the same estimator as
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
  with the label \\h\\ in place of the probabilities, using the same
  learner, folds and standard errors. Under the assumptions of
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
  it converges to \\A \tau\\, where \\A = E\[a_h a_h^\top\]^{-1} E\[a_h
  a^\top\]\\ is the coarsening (distortion) matrix, \\a_h\\ the label
  after partialling out the controls and \\a\\ the residualised
  probabilities. For two categories \\A\\ is the attenuation factor
  \\\kappa\\.

With more than two categories the distortion need not be uniform: the
estimate for one category can also pick up the effects of the others,
and the retention coefficients \\s_j = v_j^\top A v_j\\ along the
eigenvectors \\v_j\\ of \\E\[a a^\top\]\\ can differ across directions
and need not lie in \\\[0, 1\]\\.

The implied coverage is an asymptotic approximation to the coverage of
nominal Wald intervals for the cross-fitted hard-label estimate,
\\\Phi(z - \nu) - \Phi(-z - \nu)\\ with \\\nu\\ the implied bias \\(\hat
A - I)\hat\tau\\ divided by the hard-label standard error. It is an
estimate: it uses the soft-label estimate in place of the true effects.

The regressions of the labels on the controls use the folds, the learner
and the seed of the fit, so repeated calls on a fit with a seed give the
same results.

## References

Kurbucz, M. T. (2026). Coarsening latent-class probabilities:
Directional distortion and coverage loss. arXiv preprint.
[doi:10.48550/arXiv.2608.11784](https://doi.org/10.48550/arXiv.2608.11784)

Kurbucz, M. T. (2026). When to trust static confidence thresholding:
Calibration diagnostics for pseudo-labelled regression. *Knowledge-Based
Systems*, forthcoming. Earlier version:
[doi:10.48550/arXiv.2605.12780](https://doi.org/10.48550/arXiv.2605.12780)

## See also

[`kappa_curve()`](https://mtkurbucz.github.io/softcats/reference/kappa_curve.md)
for the attenuation across thresholds.

## Examples

``` r
# Example: Most likely category with three categories
d <- sim_softcats(n = 2000, K = 3, seed = 5)
fit <- soft_lm(y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C,
               data = d, learner = lrn_lm(degree = 3), seed = 5)
compare_hard(fit)
#> Soft probabilities versus predicted labels (most likely category)
#> Difference from reference category 'A'
#> 
#>               method term estimate std.error conf.low conf.high
#>                 soft    B    1.120    0.1410    0.846     1.400
#>                 soft    C   -0.459    0.1370   -0.727    -0.190
#>  hard (cross-fitted)    B    0.660    0.0812    0.501     0.819
#>  hard (cross-fitted)    C   -0.411    0.0801   -0.568    -0.254
#>           hard (OLS)    B    0.652    0.0815    0.492     0.812
#>           hard (OLS)    C   -0.416    0.0802   -0.573    -0.258
#> 
#> Distortion matrix A (the cross-fitted hard estimate converges to A tau):
#>        B      C
#> B  0.546 -0.134
#> C -0.119  0.536
#> Retention along the eigen-directions of E[aa']:
#>  dir1  dir2 
#> 0.667 0.415 
#> 
#> Implied bias and coverage of nominal 95% hard-label intervals:
#>  term implied_bias std.error_hard coverage
#>     B       -0.448         0.0812 0.000188
#>     C       0.0796         0.0801    0.832
```
