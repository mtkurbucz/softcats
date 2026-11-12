# Regression on Predicted Categories with Calibrated Class Probabilities

Estimates the partial association between a latent categorical group and
an outcome when the group is not observed, but a classifier supplies
calibrated class probabilities for every observation. It replaces the
common practice of regressing the outcome on the predicted label (argmax
or a confidence threshold), which distorts the estimate (for a binary
group it typically attenuates it) and can give confidence intervals
whose coverage is far below the nominal level.

## Usage

``` r
soft_lm(
  formula,
  probs,
  data,
  reference = 1L,
  learner = lrn_ranger(),
  folds = 5L,
  n_rep = 1L,
  weights = NULL,
  cluster = NULL,
  seed = NULL
)
```

## Arguments

- formula:

  \[mandatory\] (formula) A two-sided formula `outcome ~ controls`. The
  right-hand side lists the controls; their functional form is left to
  the learner. Matrix-valued terms such as `poly(x, 2)` enter as one
  control per column. Use `outcome ~ 1` for no controls.

- probs:

  \[mandatory\] (matrix, data.frame, character, formula or numeric)
  Class probabilities, one column per category and rows summing to one:
  a matrix or data frame, a character vector of column names in `data`,
  a one-sided formula such as `~ p_a + p_b + p_c`, or, for a binary
  group, a numeric vector of probabilities of the second category, in
  which case the categories are named `"0"` and `"1"`. A prefix shared
  by all column names (such as `prob_` or `.pred_`) is removed to obtain
  category labels.

- data:

  \[mandatory\] (data.frame) A data frame containing the outcome and the
  controls.

- reference:

  \[optional\] (character or integer) The reference category, by name or
  position (default: `1`, the first column of `probs`).

- learner:

  \[optional\] (softcats_learner or list) A learner (see
  [`learners`](https://mtkurbucz.github.io/softcats/reference/learners.md))
  used for both nuisances, or a list `list(m = , r = )` with separate
  learners for the outcome regression and the score regressions
  (default:
  [`lrn_ranger()`](https://mtkurbucz.github.io/softcats/reference/learners.md)).

- folds:

  \[optional\] (integer) Number of cross-fitting folds, at least two
  (default: `5`).

- n_rep:

  \[optional\] (integer) Number of repetitions of cross-fitting with new
  fold splits (default: `1`).

- weights:

  \[optional\] (numeric, character or formula) Non-negative observation
  weights, for example survey weights: a numeric vector, a column name
  of `data` or a one-sided formula (default: `NULL`).

- cluster:

  \[optional\] (vector, character or formula) Cluster identifier for
  cluster-robust standard errors: a vector, a column name of `data` or a
  one-sided formula (default: `NULL`).

- seed:

  \[optional\] (integer) Seed for the fold splits and stochastic
  learners. The random number generator state of the session is restored
  afterwards (default: `NULL`).

## Value

An object of class `softcats`, with methods for
[`print()`](https://rdrr.io/r/base/print.html),
[`summary()`](https://rdrr.io/r/base/summary.html),
[`coef()`](https://rdrr.io/r/stats/coef.html),
[`vcov()`](https://rdrr.io/r/stats/vcov.html),
[`confint()`](https://rdrr.io/r/stats/confint.html),
[`nobs()`](https://rdrr.io/r/stats/nobs.html),
[`residuals()`](https://rdrr.io/r/stats/residuals.html),
[`fitted()`](https://rdrr.io/r/stats/fitted.values.html),
[`formula()`](https://rdrr.io/r/stats/formula.html),
[`plot()`](https://rdrr.io/r/graphics/plot.default.html),
[`generics::tidy()`](https://generics.r-lib.org/reference/tidy.html) and
[`generics::glance()`](https://generics.r-lib.org/reference/glance.html).
It works with [`update()`](https://rdrr.io/r/stats/update.html), broom,
modelsummary and
[`lmtest::coeftest()`](https://rdrr.io/pkg/lmtest/man/coeftest.html).

## Model

For a latent group \\G\\ with categories \\1, \dots, K\\ (category 1 is
the reference) and class probabilities, or scores, \\p\\, the target is
\\\tau\\ in the partially linear model \$\$E\[Y \mid G, X\] = \mu(X) +
\sum\_{k = 2}^{K} \tau_k 1\\G = k\\,\$\$ where \\\mu\\ is unrestricted.
The probabilities must be calibrated conditionally on the controls,
\\E\[1\\G = k\\ \mid p, X\] = p_k\\. Under this condition and the
exclusion condition \\E\[Y \mid G, p, X\] = E\[Y \mid G, X\]\\ (see
Requirements), with \\a = p - E\[p \mid X\]\\ (reference column removed)
and \\m(X) = E\[Y \mid X\]\\, \$\$E\[a\\(Y - m(X))\] = E\[a
a^\top\]\\\tau ,\$\$ so \\\tau\\ is identified from the unlabelled data
whenever the scores vary beyond what the controls explain, that is,
whenever \\E\[a a^\top\]\\ is non-singular. For two categories, \\E\[a
a^\top\]\\ is the residual score variance \\V^\* = E\[\mathrm{Var}(p
\mid X)\]\\.

## Estimation and inference

The nuisances \\m(X)\\ and \\E\[p_k \mid X\]\\ are estimated by
cross-fitting with the chosen learner. The estimator solves the sample
version of the moment equation above, whose estimating function is
Neyman-orthogonal in both nuisances. This is the partialling-out
estimator of Robinson (1988), with cross-fitted nuisance estimates and
the probabilities as regressors. Without weights or clusters, the
estimate is asymptotically normal with variance \\M^{-1} E\[u^2 a
a^\top\] M^{-1} / n\\, \\M = E\[a a^\top\]\\ and \\u = Y - m(X) -
a^\top\tau\\, when both nuisance estimates are consistent, their errors
satisfy \\\\\hat m - m\\\_2 \\\hat r - r\\\_2 + \\\hat r - r\\\_2^2 =
o_P(n^{-1/2})\\ and further regularity conditions hold (Chernozhukov et
al. 2018; Kurbucz 2026, arXiv:2608.11784). Standard errors are sandwich
estimates, heteroskedasticity-robust (HC0) by default and cluster-robust
(CR1, with the factor \\G / (G - 1)\\ for \\G\\ clusters) when `cluster`
is supplied. With `cluster`, folds are formed from whole clusters. With
`n_rep > 1`, cross-fitting is repeated with new fold splits; estimates
are averaged and the variance includes the spread across splits. With
random forests, several splits (for example `n_rep = 5`) are advisable,
because in simulations the variance from a single split understates the
variability of the estimate.

## Requirements

The classifier must use information beyond the controls (classifier
features that are not in `formula`), otherwise the scores are a function
of the controls and the effect is not identified;
[`score_spectrum()`](https://mtkurbucz.github.io/softcats/reference/score_spectrum.md)
reports how much information is left. These extra features must not
affect the outcome directly;
[`exclusion_test()`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md)
checks this on labelled data. Conditional calibration can be checked
with
[`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
and repaired on labelled data with
[`recalibrate()`](https://mtkurbucz.github.io/softcats/reference/recalibrate.md),
and
[`drift_sensitivity()`](https://mtkurbucz.github.io/softcats/reference/drift_sensitivity.md)
bounds the bias from calibration error. The estimand is a partial
association, not a causal effect.

## References

Kurbucz, M. T. (2026). Coarsening latent-class probabilities:
Directional distortion and coverage loss. arXiv preprint.
[doi:10.48550/arXiv.2608.11784](https://doi.org/10.48550/arXiv.2608.11784)

Kurbucz, M. T. (2026). When to trust confidence thresholding:
Calibration diagnostics for pseudo-labelled regression. arXiv preprint.
[doi:10.48550/arXiv.2605.12780](https://doi.org/10.48550/arXiv.2605.12780)

Chernozhukov, V., Chetverikov, D., Demirer, M., Duflo, E., Hansen, C.,
Newey, W. and Robins, J. (2018). Double/debiased machine learning for
treatment and structural parameters. *The Econometrics Journal*, 21(1),
C1–C68. [doi:10.1111/ectj.12097](https://doi.org/10.1111/ectj.12097)

Robinson, P. M. (1988). Root-N-consistent semiparametric regression.
*Econometrica*, 56(4), 931–954.
[doi:10.2307/1912705](https://doi.org/10.2307/1912705)

## See also

[`compare_hard()`](https://mtkurbucz.github.io/softcats/reference/compare_hard.md)
for the cost of using predicted labels instead,
[`soft_check()`](https://mtkurbucz.github.io/softcats/reference/soft_check.md)
for a one-page diagnostic report.

## Examples

``` r
# Example: Three categories, probabilities given as column names
d <- sim_softcats(n = 2000, K = 3, seed = 1)
fit <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B", "prob_C"),
               data = d, learner = lrn_lm(degree = 3), seed = 1)
fit
#> Regression on predicted categories (calibrated soft labels)
#> 
#> Call:
#> soft_lm(formula = y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B", 
#>     "prob_C"), data = d, learner = lrn_lm(degree = 3), seed = 1)
#> 
#> Difference from reference category 'A':
#>   Estimate Std. Error   2.5 %  97.5 %
#> B   0.9715     0.1355  0.7059  1.2370
#> C  -0.6301     0.1362 -0.8971 -0.3632
#> 
#> Observations: 2000   Cross-fitting: 5 folds, 1 split
#> Learner: lm (degree 3)
summary(fit)
#> Regression on predicted categories (calibrated soft labels)
#> 
#> Call:
#> soft_lm(formula = y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B", 
#>     "prob_C"), data = d, learner = lrn_lm(degree = 3), seed = 1)
#> 
#> Reference category: A   Categories: A, B, C
#> Observations: 2000
#> Cross-fitting: 5 folds, 1 split   Learner: lm (degree 3)
#> Standard errors: heteroskedasticity-robust (HC0)
#> 
#>   Estimate Std. Error z value Pr(>|z|)    
#> B   0.9715     0.1355   7.169 7.55e-13 ***
#> C  -0.6301     0.1362  -4.627 3.71e-06 ***
#> ---
#> Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
#> 
#> Score information beyond the controls
#>   Share of score variance not explained by the controls: 0.956, 0.881
#>   Condition number of E[aa']: 11.7
confint(fit)
#>        2.5 %     97.5 %
#> B  0.7059052  1.2371067
#> C -0.8970609 -0.3632156
attr(d, "tau")
#>    B    C 
#>  1.0 -0.5 

# Example: Binary group, probability of the second category as a vector
b <- sim_softcats(n = 2000, K = 2, seed = 2)
soft_lm(y ~ x1 + x2 + x3, probs = b$prob_B, data = b,
        learner = lrn_lm(degree = 3), seed = 2)
#> Regression on predicted categories (calibrated soft labels)
#> 
#> Call:
#> soft_lm(formula = y ~ x1 + x2 + x3, probs = b$prob_B, data = b, 
#>     learner = lrn_lm(degree = 3), seed = 2)
#> 
#> Difference from reference category '0':
#>   Estimate Std. Error  2.5 % 97.5 %
#> 1    1.028    0.07601 0.8788  1.177
#> 
#> Observations: 2000   Cross-fitting: 5 folds, 1 split
#> Learner: lm (degree 3)
```
