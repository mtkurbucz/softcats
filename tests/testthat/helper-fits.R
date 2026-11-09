# Helper Functions -------------------------------------------------------------

fit_k3 <- function(n = 2000, seed = 1, ...) {
  d <- sim_softcats(n = n, K = 3, seed = seed)
  fit <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B", "prob_C"),
                 data = d, learner = lrn_lm(degree = 3), seed = seed, ...)
  list(data = d, fit = fit)
}

# ------------------------------------------------------------------------------

fit_k2 <- function(n = 2000, seed = 2, ...) {
  d <- sim_softcats(n = n, K = 2, seed = seed)
  fit <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B"), data = d,
                 learner = lrn_lm(degree = 3), seed = seed, ...)
  list(data = d, fit = fit)
}
