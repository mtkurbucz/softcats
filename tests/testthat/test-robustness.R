test_that("factor levels missing from a training fold are handled", {
  d <- sim_softcats(n = 1000, K = 2, seed = 61)
  d$f <- factor(c(rep("a", 499), rep("b", 500), "rare"))
  f1 <- soft_lm(y ~ x1 + f, probs = d$prob_B, data = d, learner = lrn_lm(),
                seed = 1)
  f2 <- soft_lm(y ~ f, probs = d$prob_B, data = d, learner = lrn_lm(),
                seed = 1)
  expect_true(is.finite(coef(f1)))
  expect_true(is.finite(coef(f2)))
  skip_if_not_installed("glmnet")
  f3 <- soft_lm(y ~ x1 + f, probs = d$prob_B, data = d,
                learner = lrn_glmnet(), seed = 1)
  expect_true(is.finite(coef(f3)))
})

test_that("the dummy coding keeps rows and matches model.matrix", {
  x <- data.frame(a = c(1, 2, 3, 4), f = factor(c("u", "v", "w", "v")))
  dm <- design_matrix(x, 1L)
  mm <- stats::model.matrix(~ f + a, data = x)[, -1L]
  expect_equal(unname(dm), unname(mm))
  expect_identical(colnames(dm), colnames(mm))
  xlev <- list(f = c("u", "v"))
  new <- data.frame(a = c(1, 2, 3), f = c("u", "zz", NA))
  dn <- design_matrix(new, 1L, xlev)
  expect_identical(nrow(dn), 3L)
  expect_identical(unname(dn[, "fv"]), c(0, 0, NA))
})

test_that("calibration_check drops rows with missing factor controls", {
  d <- sim_softcats(n = 3000, K = 2, seed = 62)
  lab <- d[d$labelled, ]
  lab$f <- factor(rep(c("u", "v"), length.out = nrow(lab)))
  lab$f[1:3] <- NA
  cc <- calibration_check(c("prob_A", "prob_B"), "group", data = lab,
                          controls = ~ x1 + f)
  expect_identical(cc$nobs, nrow(lab) - 3L)
})

test_that("matrix-valued terms enter as separate controls", {
  d <- sim_softcats(n = 1000, K = 2, seed = 63)
  f_rf <- soft_lm(y ~ poly(x1, 2) + x2, probs = d$prob_B, data = d,
                  learner = lrn_ranger(num.trees = 50), seed = 1)
  f_lm <- soft_lm(y ~ poly(x1, 2) + x2, probs = d$prob_B, data = d,
                  learner = lrn_lm(), seed = 1)
  expect_true(is.finite(coef(f_rf)))
  expect_identical(ncol(f_lm$data$x), 3L)
})

test_that("common input mistakes give clear errors", {
  d <- sim_softcats(n = 500, K = 2, seed = 64)
  expect_error(soft_lm(y ~ x1, probs = d$prob_B, data = d, weights = "wt",
                       learner = lrn_lm()),
               "Column 'wt' given in `weights` not found")
  expect_error(soft_lm(y ~ x1, probs = c("prob_A", "prob_B"), data = d,
                       reference = c("A", "B"), learner = lrn_lm()),
               "single category")
  expect_error(soft_lm(y ~ ., probs = c("prob_A", "prob_B"),
                       data = d[, c("y", "x1", "prob_A", "prob_B")],
                       learner = lrn_lm()),
               "also among the controls")
  expect_error(calibration_check(c("prob_A", "prob_B"), "group", data = d,
                                 weights = rep(-1, nrow(d))),
               "non-negative")
  expect_error(exclusion_test(y ~ x1, "group", ~ z, data = d,
                              weights = rep(-1, nrow(d))),
               "non-negative")
  expect_error(lrn_ranger(seed = 1), "cannot be passed")
  skip_if_not_installed("glmnet")
  expect_error(lrn_glmnet(degree = 0), "positive integer")
  expect_error(lrn_glmnet(weights = 1), "cannot be passed")
})

test_that("diagnostics print rounded values and p-values in text form", {
  d <- sim_softcats(n = 2000, K = 2, direct_effect = 0.5, seed = 65)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = d$prob_B, data = d,
               learner = lrn_lm(degree = 3), seed = 1)
  kc <- kappa_curve(f, thresholds = c(0.5, 0.7))
  expect_output(print(kc), "share_positive")
  e <- exclusion_test(y ~ x1 + x2 + x3, "group", ~ z, data = d)
  expect_output(print(e), "p < 1e-04")
  expect_identical(p_text(c(0.5, 1e-6)), c("p = 0.5", "p < 1e-04"))
})
