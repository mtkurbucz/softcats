test_that("standard methods return consistent objects", {
  f <- fit_k3()$fit
  expect_s3_class(f, "softcats")
  expect_named(coef(f), c("B", "C"))
  expect_equal(dim(vcov(f)), c(2L, 2L))
  expect_identical(rownames(vcov(f)), c("B", "C"))
  ci <- confint(f)
  expect_equal(dim(ci), c(2L, 2L))
  expect_identical(colnames(ci), c("2.5 %", "97.5 %"))
  expect_true(all(ci[, 1] < coef(f) & coef(f) < ci[, 2]))
  se_c <- sqrt(vcov(f)["C", "C"])
  expect_equal(confint(f, "C", level = 0.9)[1, ],
               coef(f)[["C"]] + c(-1, 1) * stats::qnorm(0.95) * se_c,
               ignore_attr = TRUE)
  expect_error(confint(f, "Z"), "Unknown")
  expect_identical(nobs(f), 2000L)
  expect_equal(formula(f), y ~ x1 + x2 + x3, ignore_formula_env = TRUE)
  expect_length(residuals(f), 2000L)
  expect_equal(fitted(f) + residuals(f), f$data$y)
})

test_that("print and summary run and report the key quantities", {
  f <- fit_k3()$fit
  expect_output(print(f), "reference category 'A'")
  s <- summary(f)
  expect_s3_class(s, "summary.softcats")
  expect_identical(colnames(s$coefficients),
                   c("Estimate", "Std. Error", "z value", "Pr(>|z|)"))
  expect_output(print(s), "Score information beyond the controls")
  expect_output(print(s), "HC0")
})

test_that("tidy() and glance() follow broom conventions", {
  f <- fit_k3()$fit
  td <- tidy(f)
  expect_identical(names(td),
                   c("term", "estimate", "std.error", "statistic", "p.value"))
  expect_equal(td$estimate, unname(coef(f)))
  td_ci <- tidy(f, conf.int = TRUE, conf.level = 0.9)
  expect_equal(td_ci$conf.low, unname(confint(f, level = 0.9)[, 1]))
  gl <- glance(f)
  expect_identical(nrow(gl), 1L)
  expect_identical(gl$nobs, 2000L)
})

test_that("fits work with broom, lmtest and modelsummary", {
  f <- fit_k3()$fit
  skip_if_not_installed("broom")
  expect_equal(broom::tidy(f)$estimate, unname(coef(f)))
  skip_if_not_installed("lmtest")
  ct <- lmtest::coeftest(f)
  expect_equal(unname(ct[, "Std. Error"]), unname(sqrt(diag(vcov(f)))))
  expect_equal(unname(ct[, 3]), tidy(f)$statistic)
  skip_if_not_installed("modelsummary")
  out <- modelsummary::modelsummary(list(soft = f), output = "data.frame")
  expect_true(all(c("B", "C") %in% out$term))
})

test_that("update() refits with changed arguments", {
  d <- sim_softcats(n = 800, K = 2, seed = 2)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B"), data = d,
               learner = lrn_lm(), seed = 2)
  f2 <- update(f, folds = 3)
  expect_identical(f2$folds, 3L)
  expect_s3_class(f2, "softcats")
})

test_that("plot methods draw without error", {
  f <- fit_k3()$fit
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  expect_silent(plot(f))
  expect_silent(plot(f, which = "spectrum"))
})
