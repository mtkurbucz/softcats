# Sensitivity of the Estimate to Calibration Error

Bounds the bias of the
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
estimate when the probabilities are miscalibrated given the controls by
at most \\\delta\\, and reports how much miscalibration the conclusion
can tolerate.

## Usage

``` r
drift_sensitivity(object, delta = NULL, level = 0.95)

# S3 method for class 'softcats_sensitivity'
print(x, digits = 3L, ...)
```

## Arguments

- object:

  \[mandatory\] (softcats) A fit returned by
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).

- delta:

  \[optional\] (numeric) Drift magnitude. If given, the bound and the
  intervals widened by the bound are added (default: `NULL`).

- level:

  \[optional\] (numeric) Confidence level (default: `0.95`).

- x:

  \[mandatory\] (softcats_sensitivity) Result of `drift_sensitivity()`.

- digits:

  \[optional\] (integer) Number of significant digits to print (default:
  `3`).

- ...:

  \[optional\] Not used.

## Value

A data frame of class `softcats_sensitivity` with columns `term`,
`estimate`, `std.error`, `bias_per_delta`, `rv`, `rv_ci` and, if `delta`
is given, `bound`, `conf.low` and `conf.high` (the confidence interval
widened by the bound on each side). The print method returns `x`
invisibly.

## Details

Suppose that the probabilities are miscalibrated given the controls,
\\E\[1\\G = k\\ \mid p, X\] = p_k + \eta_k(p, X)\\ with \\\|\eta_k\| \le
\delta\\ for every category. Then the estimator of
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
converges to \\\tau + M^{-1} E\[a \eta^\top\] \tau\\ with \\M = E\[a
a^\top\]\\, and the bias of coefficient \\k\\ is at most \$\$\delta \\
\\\tau\\\_1 \\ E\left\|(M^{-1} a)\_k\right\| .\$\$ For two categories
this is \\\|\tau\| \\ \delta \\ E\|a\| / V^\*\\. `drift_sensitivity()`
evaluates the factor multiplying \\\delta\\ (the bias per unit of
drift), using the estimate of \\\tau\\, and reports two robustness
values in the spirit of Cinelli and Hazlett (2020):

- `rv`: the drift \\\delta\\ at which the bound equals the absolute
  estimate. For two categories the bias is proportional to \\\tau\\, so
  a drift below `rv` cannot reverse the sign of the effect;

- `rv_ci`: the drift at which the bound equals the distance from zero to
  the end of the confidence interval nearest to zero, so that the
  interval widened by the bound includes zero.

The bound holds for every drift function within \\\pm\delta\\ and is
therefore conservative for any particular one. It is evaluated at the
estimate of \\\tau\\, so the widened interval summarises sensitivity and
is not a confidence interval with guaranteed coverage. A value of
\\\delta\\ can be taken from
[`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
(`delta_hat`).

## References

Kurbucz, M. T. (2026). Coarsening latent-class probabilities:
Directional distortion and coverage loss. arXiv preprint.
[doi:10.48550/arXiv.2608.11784](https://doi.org/10.48550/arXiv.2608.11784)

Cinelli, C. and Hazlett, C. (2020). Making sense of sensitivity:
Extending omitted variable bias. *Journal of the Royal Statistical
Society Series B*, 82(1), 39–67.
[doi:10.1111/rssb.12348](https://doi.org/10.1111/rssb.12348)

Kurbucz, M. T. (2026). When to trust static confidence thresholding:
Calibration diagnostics for pseudo-labelled regression. *Knowledge-Based
Systems*, forthcoming. Earlier version:
[doi:10.48550/arXiv.2605.12780](https://doi.org/10.48550/arXiv.2605.12780)

## Examples

``` r
# Example: Robustness values and the bound at a drift of 0.02
d <- sim_softcats(n = 2000, K = 2, seed = 9)
fit <- soft_lm(y ~ x1 + x2 + x3, probs = d$prob_B, data = d,
               learner = lrn_lm(degree = 3), seed = 9)
drift_sensitivity(fit)
#> Sensitivity to calibration drift |eta| <= delta
#> 
#>  term estimate std.error bias_per_delta    rv rv_ci
#>     1    0.874    0.0748           2.44 0.359 0.298
#> 
#> bias_per_delta: largest bias per unit of drift.
#> rv: drift at which the bound equals the estimate.
#> rv_ci: drift at which the widened interval reaches zero.
drift_sensitivity(fit, delta = 0.02)
#> Sensitivity to calibration drift |eta| <= delta
#> 
#>  term estimate std.error bias_per_delta    rv rv_ci  bound conf.low conf.high
#>     1    0.874    0.0748           2.44 0.359 0.298 0.0488    0.679      1.07
#> 
#> bias_per_delta: largest bias per unit of drift.
#> rv: drift at which the bound equals the estimate.
#> rv_ci: drift at which the widened interval reaches zero.
#> Intervals are 95% confidence intervals widened by the bound at delta = 0.02.
```
