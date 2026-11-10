# Changelog

## softcats 1.0.0

- First CRAN release.
- [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
  estimates the effects of a latent categorical group from calibrated
  class probabilities, with cross-fitted nuisance functions, repeated
  sample splitting, weights and cluster-robust standard errors.
- Learners:
  [`lrn_ranger()`](https://mtkurbucz.github.io/softcats/reference/learners.md)
  (default),
  [`lrn_lm()`](https://mtkurbucz.github.io/softcats/reference/learners.md),
  [`lrn_glmnet()`](https://mtkurbucz.github.io/softcats/reference/learners.md)
  and
  [`lrn_custom()`](https://mtkurbucz.github.io/softcats/reference/learners.md),
  with separate learners for the outcome and the score regressions.
- Diagnostics:
  [`score_spectrum()`](https://mtkurbucz.github.io/softcats/reference/score_spectrum.md),
  [`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md),
  [`exclusion_test()`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md),
  [`drift_sensitivity()`](https://mtkurbucz.github.io/softcats/reference/drift_sensitivity.md),
  [`compare_hard()`](https://mtkurbucz.github.io/softcats/reference/compare_hard.md),
  [`kappa_curve()`](https://mtkurbucz.github.io/softcats/reference/kappa_curve.md)
  and the combined report
  [`soft_check()`](https://mtkurbucz.github.io/softcats/reference/soft_check.md).
- [`recalibrate()`](https://mtkurbucz.github.io/softcats/reference/recalibrate.md)
  recalibrates the class probabilities on labelled data, checks the
  recalibrated probabilities out of fold and recomputes the estimate;
  its [`predict()`](https://rdrr.io/r/stats/predict.html) method
  recalibrates other data.
- Methods for [`print()`](https://rdrr.io/r/base/print.html),
  [`summary()`](https://rdrr.io/r/base/summary.html),
  [`coef()`](https://rdrr.io/r/stats/coef.html),
  [`vcov()`](https://rdrr.io/r/stats/vcov.html),
  [`confint()`](https://rdrr.io/r/stats/confint.html),
  [`nobs()`](https://rdrr.io/r/stats/nobs.html),
  [`formula()`](https://rdrr.io/r/stats/formula.html),
  [`residuals()`](https://rdrr.io/r/stats/residuals.html),
  [`fitted()`](https://rdrr.io/r/stats/fitted.values.html) and
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html), and for the
  [`tidy()`](https://generics.r-lib.org/reference/tidy.html) and
  [`glance()`](https://generics.r-lib.org/reference/glance.html)
  generics used by broom and modelsummary.
- [`sim_softcats()`](https://mtkurbucz.github.io/softcats/reference/sim_softcats.md)
  simulates data with calibrated probabilities and known effects.
