test_that("learners are objects with a print method", {
  expect_s3_class(lrn_lm(), "softcats_learner")
  expect_output(print(lrn_lm(degree = 2)), "lm \\(degree 2\\)")
  expect_error(lrn_lm(degree = 0), "positive integer")
  expect_error(lrn_custom(1, 2), "functions")
})

test_that("lrn_lm handles factor controls and new data", {
  x <- data.frame(a = c(1, 2, 3, 4, 5, 6),
                  f = factor(c("u", "v", "u", "v", "w", "w")))
  y <- c(1, 2, 3, 5, 4, 6)
  l <- lrn_lm(degree = 2)
  m <- l$fit(x, y, rep(1, 6))
  p <- l$predict(m, x[1:2, ])
  expect_length(p, 2L)
  expect_true(all(is.finite(p)))
})

test_that("separate learners for the outcome and the scores are used", {
  d <- sim_softcats(n = 800, K = 2, seed = 31)
  f <- soft_lm(y ~ x1 + x2, probs = d$prob_B, data = d,
               learner = list(m = lrn_lm(degree = 2), r = lrn_lm()), seed = 1)
  expect_identical(f$learner$m$name, "lm (degree 2)")
  expect_identical(f$learner$r$name, "lm")
  expect_output(print(f), "lm \\(degree 2\\) \\(outcome\\), lm \\(scores\\)")
})

test_that("a custom learner can be plugged in", {
  d <- sim_softcats(n = 800, K = 2, seed = 32)
  ols <- lrn_custom(
    fit = function(x, y, w) {
      stats::lm.wfit(cbind(1, as.matrix(x)), y, w)$coefficients
    },
    predict = function(model, newdata) {
      drop(cbind(1, as.matrix(newdata)) %*% model)
    },
    name = "ols"
  )
  f1 <- soft_lm(y ~ x1 + x2, probs = d$prob_B, data = d, learner = ols,
                seed = 2)
  f2 <- soft_lm(y ~ x1 + x2, probs = d$prob_B, data = d, learner = lrn_lm(),
                seed = 2)
  expect_equal(coef(f1), coef(f2))
})

test_that("a learner returning the wrong number of predictions is caught", {
  d <- sim_softcats(n = 400, K = 2, seed = 33)
  broken <- lrn_custom(fit = function(x, y, w) mean(y),
                       predict = function(model, newdata) model,
                       name = "broken")
  expect_error(soft_lm(y ~ x1, probs = d$prob_B, data = d, learner = broken),
               "returned")
})

test_that("the ranger learner (default) fits", {
  d <- sim_softcats(n = 1000, K = 2, nonlinear = TRUE, seed = 34)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = d$prob_B, data = d,
               learner = lrn_ranger(num.trees = 100), seed = 4)
  expect_true(is.finite(coef(f)))
  expect_identical(f$learner$m$name, "ranger")
  f2 <- soft_lm(y ~ x1 + x2 + x3, probs = d$prob_B, data = d,
                learner = lrn_ranger(num.trees = 100), seed = 4)
  expect_identical(coef(f), coef(f2))
})

test_that("the glmnet learner fits", {
  skip_if_not_installed("glmnet")
  d <- sim_softcats(n = 800, K = 3, seed = 35)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C, data = d,
               learner = lrn_glmnet(degree = 2), seed = 5)
  expect_true(all(is.finite(coef(f))))
  f1 <- soft_lm(y ~ x1, probs = d$prob_B + d$prob_C, data = d,
                learner = lrn_glmnet(degree = 1), seed = 5)
  expect_true(is.finite(coef(f1)))
})
