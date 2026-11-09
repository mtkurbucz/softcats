# softcats 1.0.0

* First CRAN release.
* `soft_lm()` estimates the effects of a latent categorical group from
  calibrated class probabilities, with cross-fitted nuisance functions,
  repeated sample splitting, weights and cluster-robust standard errors.
* Learners: `lrn_ranger()` (default), `lrn_lm()`, `lrn_glmnet()` and
  `lrn_custom()`, with separate learners for the outcome and the score
  regressions.
* Diagnostics: `score_spectrum()`, `calibration_check()`, `exclusion_test()`,
  `drift_sensitivity()`, `compare_hard()`, `kappa_curve()` and the combined
  report `soft_check()`.
* `recalibrate()` recalibrates the class probabilities on labelled data,
  checks the recalibrated probabilities out of fold and recomputes the
  estimate; its `predict()` method recalibrates other data.
* Methods for `print()`, `summary()`, `coef()`, `vcov()`, `confint()`,
  `nobs()`, `formula()`, `residuals()`, `fitted()` and `plot()`, and for the
  `tidy()` and `glance()` generics used by broom and modelsummary.
* `sim_softcats()` simulates data with calibrated probabilities and known
  effects.
