test_that("Wald intervals with the true nuisances have nominal coverage", {
  skip_on_cran()
  covered <- vapply(seq_len(200), function(s) {
    d <- sim_softcats(n = 1000, K = 2, seed = 1000 + s)
    Pq <- as.matrix(d$prob_B)
    est <- estimate_moment(d$y, Pq, rep(1, nrow(d)), attr(d, "m_true"),
                           attr(d, "r_true")[, 2, drop = FALSE])
    se <- sqrt(est$vcov[1, 1])
    abs(est$tau - attr(d, "tau")) < stats::qnorm(0.975) * se
  }, logical(1))
  expect_gt(mean(covered), 0.90)
  expect_lt(mean(covered), 0.99)
})

test_that("cross-fitted estimates are approximately unbiased", {
  skip_on_cran()
  est <- vapply(seq_len(40), function(s) {
    d <- sim_softcats(n = 1500, K = 2, seed = 2000 + s)
    f <- soft_lm(y ~ x1 + x2 + x3, probs = d$prob_B, data = d,
                 learner = lrn_lm(degree = 3), seed = s)
    c(coef(f), sqrt(vcov(f)[1, 1]))
  }, numeric(2))
  bias <- mean(est[1, ]) - 1
  expect_lt(abs(bias), 3 * stats::sd(est[1, ]) / sqrt(ncol(est)) + 0.02)
  expect_lt(abs(mean(est[2, ]) / stats::sd(est[1, ]) - 1), 0.35)
})
