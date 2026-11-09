test_that("the threshold rule at 0.5 equals the most likely category", {
  f <- fit_k2(n = 3000)$fit
  h_arg <- compare_hard(f)
  h_thr <- compare_hard(f, rule = "threshold", threshold = 0.5)
  expect_equal(h_thr$estimates, h_arg$estimates)
  expect_equal(h_thr$distortion, h_arg$distortion)
})

test_that("kappa at 0.5 equals the attenuation factor of compare_hard", {
  f <- fit_k2(n = 3000)$fit
  kc <- kappa_curve(f, thresholds = 0.5)
  h <- compare_hard(f)
  expect_equal(kc$kappa, h$distortion[1, 1])
  cf <- h$estimates$method == "hard (cross-fitted)"
  expect_equal(kc$estimate_hard, h$estimates$estimate[cf])
})

test_that("canonical shares do not depend on the reference category", {
  d <- sim_softcats(n = 2000, K = 3, seed = 71)
  args <- list(formula = y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C,
               data = d, learner = lrn_lm(degree = 2), seed = 7)
  s_a <- score_spectrum(do.call(soft_lm, args))
  s_c <- score_spectrum(do.call(soft_lm, c(args, list(reference = "C"))))
  expect_equal(s_a$shares, s_c$shares)
})

test_that("unit weights give the unweighted diagnostics", {
  d <- sim_softcats(n = 3000, K = 2, seed = 72)
  lab <- d[d$labelled, ]
  cc0 <- calibration_check(c("prob_A", "prob_B"), "group", data = lab,
                           controls = ~ x1 + x2)
  cc1 <- calibration_check(c("prob_A", "prob_B"), "group", data = lab,
                           controls = ~ x1 + x2, weights = rep(1, nrow(lab)))
  expect_equal(cc1$table, cc0$table)
  e0 <- exclusion_test(y ~ x1 + x2, "group", ~ z, data = lab)
  e1 <- exclusion_test(y ~ x1 + x2, "group", ~ z, data = lab,
                       weights = rep(1, nrow(lab)))
  expect_equal(e1$statistic, e0$statistic)
})

test_that("glance() agrees with the fit and the spectrum", {
  f <- fit_k3()$fit
  gl <- glance(f)
  expect_identical(gl$n.categories, 3L)
  expect_equal(gl$min.residual.share, score_spectrum(f)$min_share)
  expect_equal(gl$condition.number, score_spectrum(f)$condition)
})

test_that("soft_check grades a large drift as a problem", {
  f <- fit_k2()$fit
  chk <- soft_check(f, delta = 10)
  st <- stats::setNames(chk$summary$status, chk$summary$check)
  expect_identical(st[["Sensitivity to calibration drift"]], "problem")
})

test_that("miscalibration distorts the probabilities but not the groups", {
  d0 <- sim_softcats(n = 1000, K = 3, seed = 73)
  d1 <- sim_softcats(n = 1000, K = 3, miscalibration = 1, seed = 73)
  probs <- c("prob_A", "prob_B", "prob_C")
  expect_identical(d1$group, d0$group)
  expect_identical(d1$y, d0$y)
  expect_false(isTRUE(all.equal(d1$prob_B, d0$prob_B)))
  expect_equal(unname(rowSums(d1[, probs])), rep(1, 1000))
})
