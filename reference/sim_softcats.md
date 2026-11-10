# Simulate Data with Calibrated Class Probabilities

Generates data that satisfy the assumptions of
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md),
with options to break them. It is used in the examples, the tests and
the vignette.

## Usage

``` r
sim_softcats(
  n = 2000L,
  K = 2L,
  tau = NULL,
  n_controls = 3L,
  concentration = 5,
  z_effect = 1.5,
  direct_effect = 0,
  miscalibration = 0,
  nonlinear = FALSE,
  labelled_share = 0.2,
  seed = NULL
)
```

## Arguments

- n:

  \[optional\] (integer) Number of observations (default: `2000`).

- K:

  \[optional\] (integer) Number of categories (default: `2`).

- tau:

  \[optional\] (numeric) Effects of categories 2 to `K` relative to
  category 1. `NULL` uses the first `K - 1` values of
  `c(1, -0.5, 0.75, -0.25, 0.5)`, recycled (default: `NULL`).

- n_controls:

  \[optional\] (integer) Number of controls (default: `3`).

- concentration:

  \[optional\] (numeric) Dirichlet concentration; smaller values give
  more dispersed probabilities and more information beyond the controls
  (default: `5`).

- z_effect:

  \[optional\] (numeric) Effect of \\Z\\ on the class probabilities
  (default: `1.5`).

- direct_effect:

  \[optional\] (numeric) Direct effect of \\Z\\ on the outcome (default:
  `0`).

- miscalibration:

  \[optional\] (numeric) Strength of the conditional miscalibration of
  the returned probabilities (default: `0`).

- nonlinear:

  \[optional\] (logical) If `TRUE`, the outcome regression and the class
  probabilities are non-linear in the controls (default: `FALSE`).

- labelled_share:

  \[optional\] (numeric) Share of observations flagged in column
  `labelled`, for use as a labelled sample (default: `0.2`).

- seed:

  \[optional\] (integer) Seed. The random number generator state of the
  session is restored afterwards (default: `NULL`).

## Value

A data frame with the outcome `y`, controls `x1`, `x2`, ..., the
classifier feature `z`, the latent group `group` (a factor with levels
`A`, `B`, ...), probabilities `prob_A`, `prob_B`, ... and a logical
`labelled`. Attributes: `tau` (the true effects), `m_true` (the true
\\E\[Y \mid X\]\\) and `r_true` (the true \\E\[p \mid X\]\\ of the
calibrated probabilities), computed by Gauss-Hermite quadrature over
\\Z\\.

## Details

The controls \\X\\ are independent standard normal variables, and \\Z\\
is a standard normal classifier feature that is not a control. Class
probabilities are drawn as \\p \sim \mathrm{Dirichlet}(c\\ \pi(X, Z))\\,
where \\\pi\\ is a multinomial logit in \\X\\ and \\Z\\ and \\c\\ is
`concentration`. The group is drawn from \\p\\, so the probabilities are
calibrated given \\X\\ by construction. The outcome is \\Y = \mu(X) +
\sum_k \tau_k 1\\G = k\\ + \theta Z + \varepsilon\\ with \\\varepsilon
\sim N(0, 1)\\ and \\\theta\\ = `direct_effect`.

With `miscalibration` different from zero, the returned probabilities
are distorted: the logit of the second category is shifted by
`miscalibration * x1`, so they are no longer calibrated given \\X\\.
With `direct_effect` different from zero, \\Z\\ affects the outcome
directly and the exclusion restriction fails.

## Examples

``` r
# Example: Three categories with the true effects
d <- sim_softcats(n = 500, K = 3, seed = 11)
head(d)
#>           y          x1         x2         x3          z group      prob_A
#> 1 1.7535164 -0.59103110  0.9451401 -0.4016787  0.3351174     B 0.229619153
#> 2 0.8110990  0.02659437 -1.3432396 -0.3709327 -1.0826478     B 0.208120303
#> 3 0.3410374 -1.51655310  0.4122123 -0.4251462  1.8231983     B 0.163679508
#> 4 0.2725487 -1.36265335  0.9327749  0.4411515 -0.3771681     C 0.242014817
#> 5 1.1389610  1.17848916 -0.9253432 -0.6727504  1.1349793     B 0.005320046
#> 6 0.8966980 -0.93415132  0.6121816  0.4166941  1.1497207     B 0.491427906
#>       prob_B       prob_C labelled
#> 1 0.63377479 1.366061e-01    FALSE
#> 2 0.09084370 7.010360e-01    FALSE
#> 3 0.76920542 6.711507e-02    FALSE
#> 4 0.03044459 7.275406e-01    FALSE
#> 5 0.99461500 6.495057e-05    FALSE
#> 6 0.50321618 5.355917e-03     TRUE
attr(d, "tau")
#>    B    C 
#>  1.0 -0.5 
```
