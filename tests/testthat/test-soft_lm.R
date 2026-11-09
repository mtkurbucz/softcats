test_that("the estimator recovers the true effects (two categories)", {
  d <- sim_softcats(n = 6000, K = 2, seed = 21)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B, data = d,
               learner = lrn_lm(degree = 3), seed = 21)
  se <- sqrt(diag(vcov(f)))
  expect_lt(abs(coef(f) - attr(d, "tau")), 4 * se)
})

test_that("the estimator recovers the true effects (three categories)", {
  d <- sim_softcats(n = 6000, K = 3, seed = 22)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C, data = d,
               learner = lrn_lm(degree = 3), seed = 22)
  se <- sqrt(diag(vcov(f)))
  expect_true(all(abs(coef(f) - attr(d, "tau")) < 4 * se))
})

test_that("the estimate solves the moment equation with the stored nuisances", {
  f <- fit_k3()$fit
  r <- f$reps[[1]]
  tau <- drop(solve(crossprod(r$a), crossprod(r$a, r$R)))
  expect_equal(unname(coef(f)), unname(tau))
  psi <- r$a * drop(r$R - r$a %*% tau)
  Jinv <- solve(crossprod(r$a))
  expect_equal(unname(vcov(f)), unname(Jinv %*% crossprod(psi) %*% Jinv))
})

test_that("constant weights leave the estimate unchanged", {
  d <- sim_softcats(n = 1500, K = 3, seed = 23)
  args <- list(formula = y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C,
               data = d, learner = lrn_lm(degree = 2), seed = 3)
  f0 <- do.call(soft_lm, args)
  f1 <- do.call(soft_lm, c(args, list(weights = rep(2.5, nrow(d)))))
  expect_equal(coef(f0), coef(f1))
  expect_equal(vcov(f0), vcov(f1))
  expect_true(f1$weighted)
})

test_that("weights given as a column name or formula are equivalent", {
  d <- sim_softcats(n = 1000, K = 2, seed = 24)
  d$w <- 0.5 + 1.5 * (seq_len(nrow(d)) %% 7) / 6
  args <- list(formula = y ~ x1 + x2, probs = d$prob_B, data = d,
               learner = lrn_lm(), seed = 4)
  fa <- do.call(soft_lm, c(args, list(weights = d$w)))
  fb <- do.call(soft_lm, c(args, list(weights = "w")))
  fc <- do.call(soft_lm, c(args, list(weights = ~ w)))
  expect_equal(coef(fa), coef(fb))
  expect_equal(coef(fa), coef(fc))
})

test_that("singleton clusters give the HC0 variance times G/(G - 1)", {
  d <- sim_softcats(n = 1000, K = 2, seed = 25)
  d$id <- seq_len(nrow(d))
  args <- list(formula = y ~ x1 + x2 + x3, probs = d$prob_B, data = d,
               learner = lrn_lm(), seed = 5)
  f0 <- do.call(soft_lm, args)
  # With singleton clusters the fold assignment draws the same folds
  f1 <- do.call(soft_lm, c(args, list(cluster = "id")))
  expect_equal(coef(f0), coef(f1))
  expect_equal(unname(vcov(f1)), unname(vcov(f0)) * 1000 / 999)
  expect_equal(f1$n_clusters, 1000L)
})

test_that("folds keep clusters together", {
  d <- sim_softcats(n = 1200, K = 2, seed = 26)
  d$cl <- rep(seq_len(120), each = 10)
  f <- soft_lm(y ~ x1, probs = d$prob_B, data = d, cluster = ~ cl,
               learner = lrn_lm(), seed = 6)
  folds_per_cluster <- tapply(f$reps[[1]]$folds, d$cl,
                              function(v) length(unique(v)))
  expect_true(all(folds_per_cluster == 1L))
})

test_that("the seed makes results reproducible and leaves the RNG untouched", {
  d <- sim_softcats(n = 800, K = 2, seed = 27)
  set.seed(99)
  before <- .Random.seed
  f1 <- soft_lm(y ~ x1 + x2, probs = d$prob_B, data = d, learner = lrn_lm(),
                seed = 7)
  expect_identical(.Random.seed, before)
  f2 <- soft_lm(y ~ x1 + x2, probs = d$prob_B, data = d, learner = lrn_lm(),
                seed = 7)
  expect_identical(coef(f1), coef(f2))
})

test_that("repeated cross-fitting averages estimates and adds their spread", {
  f <- fit_k2(n = 1000, n_rep = 3)$fit
  taus <- vapply(f$reps, `[[`, numeric(1), "tau")
  expect_equal(unname(coef(f)), mean(taus))
  v_within <- mean(vapply(f$reps, function(r) r$vcov[1, 1], numeric(1)))
  expect_equal(unname(vcov(f)[1, 1]), v_within + mean((taus - mean(taus))^2))
})

test_that("a model without controls is allowed", {
  d <- sim_softcats(n = 800, K = 2, seed = 28)
  f <- soft_lm(y ~ 1, probs = d$prob_B, data = d, learner = lrn_lm(), seed = 8)
  expect_length(coef(f), 1L)
  expect_true(is.finite(coef(f)))
})

test_that("scores that are a function of the controls trigger a warning", {
  d <- sim_softcats(n = 1500, K = 2, seed = 29)
  # A score that is, up to tiny noise, a linear function of the controls
  p <- 0.5 + 0.05 * d$x1 - 0.03 * d$x2 + 1e-4 * sin(seq_len(nrow(d)))
  expect_warning(
    soft_lm(y ~ x1 + x2, probs = p, data = d, learner = lrn_lm(), seed = 9),
    "information beyond the controls"
  )
})
