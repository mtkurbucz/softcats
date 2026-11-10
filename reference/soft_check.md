# Diagnostic Report for a softcats Fit

Collects the checks that decide whether a
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
estimate can be trusted, and grades each as `ok`, `warning` or
`problem`:

1.  **Information beyond the controls**
    ([`score_spectrum()`](https://mtkurbucz.github.io/softcats/reference/score_spectrum.md)):
    the smallest canonical share of score variance not explained by the
    controls.

2.  **Direct effects of classifier features**
    ([`exclusion_test()`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md)),
    if `extra` is given.

3.  **Calibration given the controls**
    ([`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)),
    if labelled data are given, graded by the overall test, which
    detects every departure from \\E\[1\\G = k\\ \mid p, X\] = p_k\\,
    whether or not it depends on the controls.

4.  **Sensitivity to calibration drift**
    ([`drift_sensitivity()`](https://mtkurbucz.github.io/softcats/reference/drift_sensitivity.md)),
    at the drift `delta` or, if it is not given, at the largest
    calibration gap beyond sampling noise found by the calibration
    check.

## Usage

``` r
soft_check(
  object,
  labelled = NULL,
  group = NULL,
  probs = NULL,
  extra = NULL,
  by = NULL,
  delta = NULL
)

# S3 method for class 'softcats_check'
print(x, ...)
```

## Arguments

- object:

  \[mandatory\] (softcats) A fit returned by
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).

- labelled:

  \[optional\] (data.frame) Labelled observations (default: `NULL`).

- group:

  \[optional\] (vector or character) Observed category labels in
  `labelled`: a column name or a vector. Required with `labelled`
  (default: `NULL`).

- probs:

  \[optional\] (matrix, data.frame, character, formula or numeric)
  Probabilities for the labelled observations. `NULL` reuses the `probs`
  specification of the fit, which works when it was given as column
  names or a formula (default: `NULL`).

- extra:

  \[optional\] (formula or character) Classifier features that are not
  controls, for the exclusion test: a one-sided formula or column names
  (default: `NULL`).

- by:

  \[optional\] (vector, character or formula) Grouping variable for
  subgroup calibration gaps (default: `NULL`).

- delta:

  \[optional\] (numeric) Drift magnitude for the sensitivity check
  (default: `NULL`).

- x:

  \[mandatory\] (softcats_check) Result of `soft_check()`.

- ...:

  \[optional\] Not used.

## Value

An object of class `softcats_check`: a list with `summary` (a data frame
with columns `check`, `status` and `detail`) and the component results
`spectrum`, `calibration`, `exclusion` and `sensitivity` (`NULL` when
not run). The print method returns `x` invisibly.

## Details

The first check needs only the fit. The others need a labelled sample in
which the group is observed, with the outcome, the controls and the
probabilities. These checks are unweighted and use standard errors that
are not cluster-robust; call
[`exclusion_test()`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md)
and
[`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
directly to use weights or clusters. The drift check is skipped when
`delta` is not given and the calibration check finds no cell large
enough to estimate the gap. When calibration fails,
[`recalibrate()`](https://mtkurbucz.github.io/softcats/reference/recalibrate.md)
recalibrates the probabilities on the labelled sample.

The grading thresholds are rules of thumb. Information: `problem` below
a share of 0.01, `warning` below 0.05. Exclusion and calibration:
`problem` below p = 0.001, `warning` below p = 0.05. Drift: `problem` if
`delta` reaches the robustness value `rv`, at which the bias bound
equals the estimate, and `warning` if it reaches `rv_ci`, at which the
widened interval includes zero.

## Examples

``` r
# Example: All checks on the labelled subsample
d <- sim_softcats(n = 3000, K = 2, seed = 10)
fit <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B"), data = d,
               learner = lrn_lm(degree = 3), seed = 10)
soft_check(fit, labelled = d[d$labelled, ], group = "group", extra = ~ z)
#> softcats diagnostic report
#> 
#> [ok]      Information beyond the controls
#>           smallest share not explained by the controls: 0.86
#> [ok]      Direct effects of classifier features
#>           Wald p = 0.681 on 1 df
#> [ok]      Calibration given the controls
#>           smallest Holm-adjusted p = 0.777; largest gap beyond noise = 0
#> [ok]      Sensitivity to calibration drift
#>           no gap beyond sampling noise; set `delta` to bound a given drift
```
