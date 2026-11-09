test_that("sim_softcats returns calibrated probabilities and the truth", {
  d <- sim_softcats(n = 20000, K = 3, seed = 51)
  probs <- c("prob_A", "prob_B", "prob_C")
  expect_s3_class(d, "data.frame")
  expect_true(all(c("y", "x1", "x2", "x3", "z", "group", probs,
                    "labelled") %in% names(d)))
  expect_equal(unname(rowSums(d[, probs])), rep(1, 20000))
  expect_identical(levels(d$group), c("A", "B", "C"))
  expect_named(attr(d, "tau"), c("B", "C"))
  # Calibration: frequency of each category matches its mean probability
  freq <- as.numeric(table(d$group)) / nrow(d)
  expect_equal(freq, unname(colMeans(d[, probs])), tolerance = 0.03)
  # The true E[p | X] matches the probabilities on average
  expect_equal(unname(colMeans(attr(d, "r_true"))),
               unname(colMeans(d[, probs])), tolerance = 0.02)
})

test_that("sim_softcats validates its arguments and restores the RNG", {
  expect_error(sim_softcats(K = 1), "at least 2")
  expect_error(sim_softcats(K = 3, tau = 1), "length")
  set.seed(5)
  before <- .Random.seed
  sim_softcats(n = 50, seed = 1)
  expect_identical(.Random.seed, before)
  expect_identical(sim_softcats(n = 50, seed = 3),
                   sim_softcats(n = 50, seed = 3))
})

test_that("the Gauss-Hermite rule integrates normal moments", {
  gh <- gauss_hermite(20)
  expect_equal(sum(gh$weights), 1)
  expect_equal(sum(gh$weights * gh$nodes^2), 1)
  expect_equal(sum(gh$weights * gh$nodes^4), 3)
})
