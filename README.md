
<!-- README.md is generated from README.Rmd. Please edit that file. -->

# softcats

<div class="pkgdown-hide">
<img src="man/figures/logo.png" align="right" height="139"
     alt="softcats logo" />
</div>

<!-- badges: start -->

[![R-CMD-check](https://github.com/mtkurbucz/softcats/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mtkurbucz/softcats/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Regression on predicted categories with calibrated class probabilities.

Many analyses need the association between an outcome and a group that
is not recorded: an ethnic group inferred from names and places, a cell
type assigned by an annotation model, a household type predicted from
administrative data. A classifier gives each observation the probability
of each group. The usual next step, assigning the most likely group or
thresholding the probabilities and regressing on the labels, distorts
the estimate (for two groups it typically attenuates it) and can give
confidence intervals whose coverage is far below the nominal level.

softcats estimates the group differences from the calibrated
probabilities themselves. It partials the controls out of the outcome
and the probabilities with cross-fitted machine learning, solves a
Neyman-orthogonal moment equation, and reports robust standard errors,
with survey weights and clustered designs supported. Diagnostics check
the conditions the estimate needs.

## Installation

``` r
# From CRAN
install.packages("softcats")

# Development version from GitHub
# install.packages("pak")
pak::pak("mtkurbucz/softcats")
```

softcats requires R 4.1 or later and the packages generics and ranger.

## Example

Simulated data with three groups, `A` (the reference), `B` and `C`,
whose true effects are 1 and -0.5:

``` r
library(softcats)

d <- sim_softcats(n = 3000, K = 3, seed = 1)

fit <- soft_lm(y ~ x1 + x2 + x3,
               probs = c("prob_A", "prob_B", "prob_C"),
               data = d, seed = 1)
fit
#> Regression on predicted categories (calibrated soft labels)
#> 
#> Call:
#> soft_lm(formula = y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B", 
#>     "prob_C"), data = d, seed = 1)
#> 
#> Difference from reference category 'A':
#>   Estimate Std. Error   2.5 %  97.5 %
#> B   0.9430     0.1142  0.7192  1.1670
#> C  -0.4701     0.1106 -0.6868 -0.2534
#> 
#> Observations: 3000   Cross-fitting: 5 folds, 1 split
#> Learner: ranger
```

Regressions on the most likely labels attenuate the effect of `B`, and
their intervals miss the true value:

``` r
hard <- compare_hard(fit)
hard$estimates[, c("method", "term", "estimate", "conf.low", "conf.high")]
#>                method term   estimate   conf.low  conf.high
#> 1                soft    B  0.9429893  0.7191530  1.1668257
#> 2                soft    C -0.4700981 -0.6867982 -0.2533981
#> 3 hard (cross-fitted)    B  0.4419844  0.3085271  0.5754416
#> 4 hard (cross-fitted)    C -0.4918450 -0.6198170 -0.3638731
#> 5          hard (OLS)    B  0.4902066  0.3603631  0.6200501
#> 6          hard (OLS)    C -0.4887371 -0.6157639 -0.3617103
```

The diagnostics run on the subsample in which the group is observed:

``` r
soft_check(fit, labelled = d[d$labelled, ], group = "group", extra = ~ z)
#> softcats diagnostic report
#> 
#> [ok]      Information beyond the controls
#>           smallest share not explained by the controls: 0.906
#> [ok]      Direct effects of classifier features
#>           Wald p = 0.162 on 1 df
#> [ok]      Calibration given the controls
#>           smallest Holm-adjusted p = 0.243; largest gap beyond noise = 0.00112
#> [ok]      Sensitivity to calibration drift
#>           delta = 0.00112; smallest robustness value 0.0789 (interval: 0.0425)
```

The vignette, [Regression on Predicted Categories with
softcats](https://mtkurbucz.github.io/softcats/articles/softcats.html)
(`vignette("softcats")` in R), walks through the method, the diagnostics
and recalibration.

## Functions

| Function | Purpose |
|----|----|
| `soft_lm()` | Group differences from class probabilities |
| `lrn_ranger()`, `lrn_lm()`, `lrn_glmnet()`, `lrn_custom()` | Learners for the nuisance functions |
| `score_spectrum()` | Information in the probabilities beyond the controls |
| `calibration_check()` | Calibration, and calibration given the controls, on labelled data |
| `recalibrate()` | Recalibration on labelled data, checked out of fold |
| `exclusion_test()` | Direct effects of classifier features on the outcome |
| `drift_sensitivity()` | Bias bound under calibration error and robustness values |
| `compare_hard()` | Distortion and implied coverage of regressions on predicted labels |
| `kappa_curve()` | Attenuation across confidence thresholds (two groups) |
| `soft_check()` | All diagnostics in one graded report |
| `sim_softcats()` | Simulated data with known effects |

Fits have methods for `print()`, `summary()`, `coef()`, `vcov()`,
`confint()`, `nobs()`, `residuals()`, `fitted()`, `formula()`,
`update()` and `plot()`, and `tidy()` and `glance()`, so they work with
broom, modelsummary and `lmtest::coeftest()`.

## Assumptions

The estimand is the partial association between the group and the
outcome given the controls, not a causal effect. It is identified when

1.  the probabilities are calibrated given the controls (stronger than
    the marginal calibration of Platt scaling or isotonic regression);
2.  the classifier uses features beyond the controls, so that no linear
    combination of the non-reference probabilities is a function of the
    controls;
3.  those extra features affect the outcome only through the group.

`calibration_check()`, `score_spectrum()` and `exclusion_test()` check
these conditions. `recalibrate()` repairs the first on labelled data,
and `drift_sensitivity()` shows how much miscalibration the conclusion
can tolerate.

## Citation

If you use softcats in a publication, please cite the methods papers and
the package (`citation("softcats")` gives the same entries):

- Kurbucz, M. T. (2026). Coarsening latent-class probabilities:
  Directional distortion and coverage loss. *arXiv preprint*.
  [doi:10.48550/arXiv.2608.11784](https://doi.org/10.48550/arXiv.2608.11784)
- Kurbucz, M. T. (2026). When to trust static confidence thresholding:
  Calibration diagnostics for pseudo-labelled regression.
  *Knowledge-Based Systems*, forthcoming. Earlier version:
  [doi:10.48550/arXiv.2605.12780](https://doi.org/10.48550/arXiv.2605.12780)
- Kurbucz, M. T. (2026). *softcats: Regression on predicted categories
  with calibrated probabilities*. R package version 1.0.0.

<details><summary>BibTeX</summary>

``` bibtex
@Misc{kurbucz2026coarsening,
  title = {Coarsening Latent-Class Probabilities: Directional Distortion and Coverage Loss},
  author = {Marcell T. Kurbucz},
  year = {2026},
  note = {arXiv preprint arXiv:2608.11784},
  doi = {10.48550/arXiv.2608.11784},
}

@Article{kurbucz2026thresholding,
  title = {When to Trust Static Confidence Thresholding: Calibration Diagnostics for Pseudo-Labelled Regression},
  author = {Marcell T. Kurbucz},
  journal = {Knowledge-Based Systems},
  year = {2026},
  note = {Forthcoming. An earlier version is available as arXiv:2605.12780},
  url = {https://arxiv.org/abs/2605.12780},
}

@Manual{kurbucz2026softcats,
  title = {softcats: Regression on Predicted Categories with Calibrated Probabilities},
  author = {Marcell T. Kurbucz},
  year = {2026},
  note = {R package version 1.0.0},
}
```

</details>

## Funding

Development of softcats was supported by the Economic and Social
Research Council \[grant number UKRI5718\].

## License

GPL (\>= 3)
