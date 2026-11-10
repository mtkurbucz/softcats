# softcats: Regression on Predicted Categories with Calibrated Probabilities

Many studies need the association between an outcome and a group that is
not observed directly, such as an ethnic group inferred from names and
places, a cell type assigned by an annotation model, or a household type
predicted from administrative records. A common practice is to assign
each observation its most likely category, or the category whose
probability exceeds a confidence threshold, and to use these labels in a
regression. This distorts the estimate (for a binary group it typically
attenuates it) and can give confidence intervals whose coverage is far
below the nominal level.

## Details

softcats keeps the categories soft.
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
estimates the effect from the calibrated class probabilities themselves,
with cross-fitted nuisance functions, a Neyman-orthogonal score and
robust (optionally weighted and clustered) standard errors. Diagnostics
report whether the estimate can be trusted:

- [`score_spectrum()`](https://mtkurbucz.github.io/softcats/reference/score_spectrum.md):
  how much information the probabilities carry beyond the controls;

- [`exclusion_test()`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md):
  whether the classifier features affect the outcome directly;

- [`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md):
  whether the probabilities are calibrated given the controls;

- [`recalibrate()`](https://mtkurbucz.github.io/softcats/reference/recalibrate.md):
  recalibration of the probabilities on labelled data, checked out of
  fold;

- [`drift_sensitivity()`](https://mtkurbucz.github.io/softcats/reference/drift_sensitivity.md):
  how much calibration error the conclusion can tolerate;

- [`compare_hard()`](https://mtkurbucz.github.io/softcats/reference/compare_hard.md)
  and
  [`kappa_curve()`](https://mtkurbucz.github.io/softcats/reference/kappa_curve.md):
  what predicted labels would have given instead;

- [`soft_check()`](https://mtkurbucz.github.io/softcats/reference/soft_check.md):
  all of the above in one report.

Fits work with the standard model methods of R and with broom,
modelsummary and
[`lmtest::coeftest()`](https://rdrr.io/pkg/lmtest/man/coeftest.html).

## References

Kurbucz, M. T. (2026). Coarsening latent-class probabilities:
Directional distortion and coverage loss. arXiv preprint.
[doi:10.48550/arXiv.2608.11784](https://doi.org/10.48550/arXiv.2608.11784)

Kurbucz, M. T. (2026). When to trust static confidence thresholding:
Calibration diagnostics for pseudo-labelled regression. *Knowledge-Based
Systems*, forthcoming. Earlier version:
[doi:10.48550/arXiv.2605.12780](https://doi.org/10.48550/arXiv.2605.12780)

## See also

Useful links:

- <https://github.com/mtkurbucz/softcats>

- <https://mtkurbucz.github.io/softcats/>

- Report bugs at <https://github.com/mtkurbucz/softcats/issues>

## Author

**Maintainer**: Marcell T. Kurbucz <m.kurbucz@ucl.ac.uk>
([ORCID](https://orcid.org/0000-0002-0121-6781)) \[copyright holder\]

Other contributors:

- Economic and Social Research Council (Grant UKRI5718) \[funder\]
