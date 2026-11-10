# Package index

## Estimation

- [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
  : Regression on Predicted Categories with Calibrated Class
  Probabilities
- [`coef(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`vcov(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`nobs(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`formula(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`residuals(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`fitted(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`confint(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`print(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`summary(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`print(`*`<summary.softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`tidy(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`glance(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  [`plot(`*`<softcats>`*`)`](https://mtkurbucz.github.io/softcats/reference/softcats-methods.md)
  : Methods for softcats Fits

## Learners

- [`lrn_ranger()`](https://mtkurbucz.github.io/softcats/reference/learners.md)
  [`lrn_lm()`](https://mtkurbucz.github.io/softcats/reference/learners.md)
  [`lrn_glmnet()`](https://mtkurbucz.github.io/softcats/reference/learners.md)
  [`lrn_custom()`](https://mtkurbucz.github.io/softcats/reference/learners.md)
  [`print(`*`<softcats_learner>`*`)`](https://mtkurbucz.github.io/softcats/reference/learners.md)
  : Nuisance Learners

## Diagnostics

- [`score_spectrum()`](https://mtkurbucz.github.io/softcats/reference/score_spectrum.md)
  [`print(`*`<softcats_spectrum>`*`)`](https://mtkurbucz.github.io/softcats/reference/score_spectrum.md)
  : Information in the Scores Beyond the Controls
- [`calibration_check()`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
  [`print(`*`<softcats_calibration>`*`)`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
  [`plot(`*`<softcats_calibration>`*`)`](https://mtkurbucz.github.io/softcats/reference/calibration_check.md)
  : Check Conditional Calibration on Labelled Data
- [`exclusion_test()`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md)
  [`print(`*`<softcats_exclusion>`*`)`](https://mtkurbucz.github.io/softcats/reference/exclusion_test.md)
  : Test Whether Classifier Features Affect the Outcome Directly
- [`drift_sensitivity()`](https://mtkurbucz.github.io/softcats/reference/drift_sensitivity.md)
  [`print(`*`<softcats_sensitivity>`*`)`](https://mtkurbucz.github.io/softcats/reference/drift_sensitivity.md)
  : Sensitivity of the Estimate to Calibration Error
- [`soft_check()`](https://mtkurbucz.github.io/softcats/reference/soft_check.md)
  [`print(`*`<softcats_check>`*`)`](https://mtkurbucz.github.io/softcats/reference/soft_check.md)
  : Diagnostic Report for a softcats Fit

## Recalibration

- [`recalibrate()`](https://mtkurbucz.github.io/softcats/reference/recalibrate.md)
  [`print(`*`<softcats_recalibration>`*`)`](https://mtkurbucz.github.io/softcats/reference/recalibrate.md)
  [`predict(`*`<softcats_recalibration>`*`)`](https://mtkurbucz.github.io/softcats/reference/recalibrate.md)
  : Recalibrate the Class Probabilities on Labelled Data

## Predicted labels

- [`compare_hard()`](https://mtkurbucz.github.io/softcats/reference/compare_hard.md)
  [`print(`*`<softcats_hard>`*`)`](https://mtkurbucz.github.io/softcats/reference/compare_hard.md)
  : Compare with Regressions on Predicted Labels
- [`kappa_curve()`](https://mtkurbucz.github.io/softcats/reference/kappa_curve.md)
  [`print(`*`<softcats_kappa>`*`)`](https://mtkurbucz.github.io/softcats/reference/kappa_curve.md)
  [`plot(`*`<softcats_kappa>`*`)`](https://mtkurbucz.github.io/softcats/reference/kappa_curve.md)
  : Attenuation of Hard Labels Across Confidence Thresholds

## Simulation

- [`sim_softcats()`](https://mtkurbucz.github.io/softcats/reference/sim_softcats.md)
  : Simulate Data with Calibrated Class Probabilities
