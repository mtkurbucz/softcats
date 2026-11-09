test_that("all forms of `probs` give the same estimate", {
  d <- sim_softcats(n = 800, K = 2, seed = 11)
  args <- list(formula = y ~ x1 + x2 + x3, data = d, learner = lrn_lm(),
               seed = 1)
  f_names <- do.call(soft_lm, c(args, list(probs = c("prob_A", "prob_B"))))
  f_form <- do.call(soft_lm, c(args, list(probs = ~ prob_A + prob_B)))
  p_mat <- as.matrix(d[, c("prob_A", "prob_B")])
  f_mat <- do.call(soft_lm, c(args, list(probs = p_mat)))
  f_vec <- do.call(soft_lm, c(args, list(probs = d$prob_B)))
  f_df <- do.call(soft_lm, c(args, list(probs = d[, c("prob_A", "prob_B")])))
  expect_equal(unname(coef(f_names)), unname(coef(f_form)))
  expect_equal(unname(coef(f_names)), unname(coef(f_df)))
  expect_equal(unname(coef(f_names)), unname(coef(f_mat)))
  expect_equal(unname(coef(f_names)), unname(coef(f_vec)))
  expect_identical(names(coef(f_names)), "B")
  expect_identical(f_names$reference, "A")
  expect_identical(names(coef(f_vec)), "1")
})

test_that("the reference category can be chosen by name or position", {
  d <- sim_softcats(n = 800, K = 3, seed = 12)
  f1 <- soft_lm(y ~ x1, probs = ~ prob_A + prob_B + prob_C, data = d,
                reference = "B", learner = lrn_lm(), seed = 1)
  f2 <- soft_lm(y ~ x1, probs = ~ prob_A + prob_B + prob_C, data = d,
                reference = 2, learner = lrn_lm(), seed = 1)
  expect_identical(f1$reference, "B")
  expect_equal(coef(f1), coef(f2))
  expect_identical(names(coef(f1)), c("A", "C"))
  expect_error(soft_lm(y ~ x1, probs = ~ prob_A + prob_B, data = d,
                       reference = "Z", learner = lrn_lm()),
               "not found")
})

test_that("invalid inputs give informative errors", {
  d <- sim_softcats(n = 400, K = 2, seed = 13)
  bad <- d
  bad$prob_B <- bad$prob_B * 0.5
  expect_error(soft_lm(y ~ x1, probs = c("prob_A", "prob_B"), data = bad,
                       learner = lrn_lm()), "sum to one")
  expect_error(soft_lm(y ~ x1, probs = c("prob_A", "nope"), data = d),
               "not found")
  expect_error(soft_lm(y ~ x1, probs = d$prob_B[-1], data = d),
               "one row per observation")
  expect_error(soft_lm(y ~ x1, probs = d$prob_B, data = d, folds = 1),
               "at least 2")
  expect_error(soft_lm(y ~ x1, probs = d$prob_B, data = d, weights = -d$x1,
                       learner = lrn_lm()), "non-negative")
  expect_error(soft_lm(~ x1, probs = d$prob_B, data = d), "two-sided")
  expect_error(soft_lm(y ~ x1, probs = d$prob_B, data = as.list(d)),
               "data frame")
  expect_error(soft_lm(y ~ x1, probs = d$prob_B, data = d, learner = "lm"),
               "learner")
  expect_error(soft_lm(y ~ x1, probs = d$prob_B, data = d,
                       cluster = rep(1:3, length.out = 400), folds = 5,
                       learner = lrn_lm()),
               "fewer clusters")
})

test_that("rows with missing values are dropped and recorded", {
  d <- sim_softcats(n = 600, K = 2, seed = 14)
  d$x1[1:5] <- NA
  d$prob_B[6] <- NA
  d$prob_A[6] <- NA
  f <- soft_lm(y ~ x1 + x2, probs = c("prob_A", "prob_B"), data = d,
               learner = lrn_lm(), seed = 1)
  expect_equal(nobs(f), 594L)
  expect_length(f$na.action, 6L)
  expect_s3_class(f$na.action, "omit")
})

test_that("a shared prefix of the probability columns is removed", {
  strip <- strip_common_prefix
  expect_identical(strip(c("prob_A", "prob_B")), c("A", "B"))
  expect_identical(strip(c(".pred_x", ".pred_y")), c("x", "y"))
  expect_identical(strip(c("pa", "pb")), c("pa", "pb"))
})
