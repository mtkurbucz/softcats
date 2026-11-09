test_that("score_spectrum reports shares and directions", {
  f <- fit_k3()$fit
  s <- score_spectrum(f)
  expect_s3_class(s, "softcats_spectrum")
  expect_length(s$shares, 2L)
  expect_true(all(s$shares > 0 & s$shares <= 1.05))
  expect_equal(s$condition, max(s$values) / min(s$values))
  expect_output(print(s), "Weakest direction")
})

test_that("compare_hard shows the distortion caused by predicted labels", {
  f <- fit_k2(n = 4000)$fit
  h <- compare_hard(f)
  expect_s3_class(h, "softcats_hard")
  est <- h$estimates
  expect_identical(unique(est$method),
                   c("soft", "hard (cross-fitted)", "hard (OLS)"))
  kappa <- h$distortion[1, 1]
  expect_gt(kappa, 0)
  expect_lt(kappa, 1)
  hard <- est$estimate[est$method == "hard (cross-fitted)"]
  expect_equal(hard, kappa * coef(f)[[1]], tolerance = 0.25)
  expect_output(print(h), "Attenuation factor")
  # For two categories the retention coefficient is the attenuation factor
  expect_equal(unname(h$retention), kappa)
  # A large bias relative to the standard error drives coverage towards zero
  expect_true(all(h$coverage$coverage >= 0 & h$coverage$coverage <= 1))
  expect_lt(h$coverage$coverage, 0.05)
  nu <- h$coverage$implied_bias / h$coverage$std.error_hard
  z <- stats::qnorm(0.975)
  expect_equal(h$coverage$coverage,
               stats::pnorm(z - nu) - stats::pnorm(-z - nu))
  h3 <- compare_hard(fit_k3()$fit)
  expect_equal(dim(h3$distortion), c(2L, 2L))
  expect_length(h3$retention, 2L)
  V <- fit_k3()$fit$spectrum$vectors
  expect_equal(unname(h3$retention),
               unname(diag(t(V) %*% h3$distortion %*% V)))
  expect_output(print(h3), "Retention")
  expect_error(compare_hard(fit_k3()$fit, rule = "threshold"),
               "two categories")
})

test_that("compare_hard is reproducible for a fit with a seed", {
  d <- sim_softcats(n = 600, K = 3, seed = 21)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C, data = d,
               learner = lrn_ranger(num.trees = 50), seed = 21)
  h1 <- compare_hard(f)
  # Advance the session generator between the two calls
  stats::runif(1)
  h2 <- compare_hard(f)
  expect_identical(h1$estimates, h2$estimates)
  expect_identical(h1$distortion, h2$distortion)
})

test_that("kappa_curve gives one row per threshold", {
  f <- fit_k2(n = 3000)$fit
  kc <- kappa_curve(f, thresholds = c(0.5, 0.7, 0.9, 1))
  expect_s3_class(kc, "softcats_kappa")
  expect_identical(nrow(kc), 4L)
  expect_true(all(kc$kappa[1:3] > 0 & kc$kappa[1:3] < 1))
  # No probability exceeds 1, so the label does not vary
  expect_identical(kc$share_positive[4], 0)
  expect_true(is.na(kc$kappa[4]))
  expect_error(kappa_curve(fit_k3()$fit), "two categories")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_silent(plot(kc))
})

test_that("calibration_check separates calibrated and miscalibrated scores", {
  good <- sim_softcats(n = 6000, K = 2, seed = 41)
  bad <- sim_softcats(n = 6000, K = 2, miscalibration = 1, seed = 41)
  cg <- calibration_check(c("prob_A", "prob_B"), "group", data = good,
                          controls = ~ x1 + x2 + x3)
  cb <- calibration_check(c("prob_A", "prob_B"), "group", data = bad,
                          controls = ~ x1 + x2 + x3)
  expect_s3_class(cg, "softcats_calibration")
  expect_gt(cg$table$p_conditional_holm, 0.001)
  expect_lt(cb$table$p_conditional_holm, 1e-6)
  expect_lt(cg$delta_hat, cb$delta_hat)
  expect_output(print(cb), "miscalibrated given the controls")
  c3 <- calibration_check(~ prob_A + prob_B + prob_C, "group",
                          data = sim_softcats(n = 2000, K = 3, seed = 42),
                          by = "labelled")
  expect_identical(nrow(c3$table), 3L)
  expect_identical(c3$delta_source, "subgroups")
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_silent(plot(c3))
})

test_that("calibration_check accepts a binary vector and 0/1 labels", {
  d <- sim_softcats(n = 2000, K = 2, seed = 43)
  cc <- calibration_check(d$prob_B, as.integer(d$group == "B"),
                          controls = d[, c("x1", "x2")])
  expect_identical(cc$table$category, "1")
})

test_that("exclusion_test detects a direct effect of the classifier feature", {
  ok <- sim_softcats(n = 4000, K = 2, seed = 44)
  bad <- sim_softcats(n = 4000, K = 2, direct_effect = 0.4, seed = 44)
  e0 <- exclusion_test(y ~ x1 + x2 + x3, "group", ~ z, data = ok)
  e1 <- exclusion_test(y ~ x1 + x2 + x3, "group", "z", data = bad)
  expect_s3_class(e0, "softcats_exclusion")
  expect_gt(e0$p.value, 0.001)
  expect_lt(e1$p.value, 1e-6)
  expect_output(print(e1), "exclusion restriction")
  ec <- exclusion_test(y ~ x1, "group", ~ z,
                       data = transform(bad, cl = rep(1:400, each = 10)),
                       cluster = "cl")
  expect_identical(ec$vcov_type, "CR1")
})

test_that("drift_sensitivity matches the closed form for two categories", {
  f <- fit_k2()$fit
  ds <- drift_sensitivity(f, delta = 0.01)
  r <- f$reps[[1]]
  vstar <- f$reps[[1]]$M[1, 1]
  expect_equal(ds$bias_per_delta,
               abs(coef(f)[[1]]) * mean(abs(r$a)) / vstar)
  expect_equal(ds$rv, abs(ds$estimate) / ds$bias_per_delta)
  expect_equal(ds$bound, 0.01 * ds$bias_per_delta)
  expect_true(all(ds$conf.low < ds$estimate & ds$estimate < ds$conf.high))
  expect_error(drift_sensitivity(f, delta = -1), "non-negative")
  expect_output(print(ds), "Sensitivity to calibration drift")
  expect_output(print(ds), "rv_ci: drift at which the widened interval")
})

test_that("soft_check grades the checks", {
  d <- sim_softcats(n = 4000, K = 2, seed = 45)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B"), data = d,
               learner = lrn_lm(degree = 3), seed = 5)
  chk <- soft_check(f, labelled = d[d$labelled, ], group = "group",
                    extra = ~ z)
  expect_s3_class(chk, "softcats_check")
  expect_identical(nrow(chk$summary), 4L)
  expect_true(all(chk$summary$status %in% c("ok", "warning", "problem")))
  expect_identical(chk$summary$status[1], "ok")
  expect_output(print(chk), "diagnostic report")

  bad <- sim_softcats(n = 6000, K = 2, miscalibration = 1.5,
                      direct_effect = 0.5, labelled_share = 0.5, seed = 46)
  fb <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B"), data = bad,
                learner = lrn_lm(degree = 3), seed = 6)
  cb <- soft_check(fb, labelled = bad[bad$labelled, ], group = "group",
                   extra = ~ z)
  st <- stats::setNames(cb$summary$status, cb$summary$check)
  expect_identical(st[["Direct effects of classifier features"]], "problem")
  expect_identical(st[["Calibration given the controls"]], "problem")

  only <- soft_check(f)
  expect_identical(nrow(only$summary), 1L)
  expect_output(print(only), "need labelled data")
  fm <- soft_lm(y ~ x1, probs = as.matrix(d[, c("prob_A", "prob_B")]),
                data = d, learner = lrn_lm(), seed = 1)
  expect_error(soft_check(fm, labelled = d, group = "group"),
               "Supply `probs`")
})
