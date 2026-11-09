test_that("the map is fitted by maximum likelihood", {
  dat <- with_seed(1, {
    n <- 600
    Z <- cbind(1, matrix(stats::rnorm(n * 3), n))
    off <- matrix(stats::rnorm(n), n)
    eta <- drop(off + Z %*% c(0.2, 0.5, -0.3, 0.1))
    list(Z = Z, off = off, y = stats::rbinom(n, 1, stats::plogis(eta)),
         g3 = sample(c("A", "B", "C"), n, replace = TRUE),
         off3 = matrix(stats::rnorm(2 * n), n), w = stats::runif(n, 0.5, 2))
  })

  # Two categories: the binomial logit of glm()
  Y2 <- cbind(A = 1 - dat$y, B = dat$y)
  fm <- fit_multinom(dat$Z, Y2, dat$off, dat$w)
  gl <- suppressWarnings(stats::glm.fit(dat$Z, dat$y, weights = dat$w,
                                        offset = drop(dat$off),
                                        family = stats::binomial()))
  expect_true(fm$converged)
  expect_equal(unname(drop(fm$coefficients)), unname(gl$coefficients),
               tolerance = 1e-8)

  # Three categories: the score equations hold at the solution
  Y3 <- one_hot(dat$g3, c("A", "B", "C"))
  fm3 <- fit_multinom(dat$Z, Y3, dat$off3, dat$w)
  P3 <- map_probs(dat$Z, dat$off3, fm3$coefficients)
  score <- crossprod(dat$Z, dat$w * (Y3[, -1L] - P3[, -1L]))
  expect_true(fm3$converged)
  expect_lt(max(abs(score)), 1e-6)

  # A collinear column gets zero coefficients and leaves the fit unchanged
  fmc <- fit_multinom(cbind(dat$Z, 2 * dat$Z[, 2L]), Y3, dat$off3, dat$w)
  expect_equal(unname(fmc$coefficients[5L, ]), c(0, 0))
  expect_equal(fmc$loglik, fm3$loglik)
})

test_that("zero coefficients leave the probabilities unchanged", {
  d <- sim_softcats(n = 300, K = 3, seed = 81)
  P <- validate_probs(as.matrix(d[, c("prob_A", "prob_B", "prob_C")]))
  Xd <- as.matrix(d[, c("x1", "x2", "x3")])
  f <- map_features(P, Xd, map_scaling(P, Xd), TRUE)
  expect_identical(ncol(f$Z), 1L + 2L + 3L + 6L)
  P0 <- map_probs(f$Z, f$offset, matrix(0, ncol(f$Z), 2L))
  expect_lt(max(abs(P0 - P)), 1e-5)
})

test_that("recalibration repairs overconfident probabilities", {
  d <- sim_softcats(n = 6000, K = 3, labelled_share = 0.25, seed = 5)
  P <- as.matrix(d[, c("prob_A", "prob_B", "prob_C")])
  d[, c("q_A", "q_B", "q_C")] <- P^3 / rowSums(P^3)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = c("q_A", "q_B", "q_C"), data = d,
               learner = lrn_lm(degree = 3), seed = 5)
  lab <- d[d$labelled, ]
  rc <- recalibrate(f, labelled = lab, group = "group")
  expect_s3_class(rc, "softcats_recalibration")

  # The miscalibration does not depend on the controls, so only the
  # overall test detects it; recalibration removes it out of fold
  t0 <- rc$calibration$original$table
  t1 <- rc$calibration$recalibrated$table
  expect_lt(max(t0$p_overall_holm), 1e-4)
  expect_gt(min(t0$p_conditional_holm), 0.05)
  expect_gt(min(t1$p_overall_holm), 0.01)

  # The recalibrated estimates recover the true effects
  e <- rc$estimates
  tau <- unname(attr(d, "tau"))
  before <- e$estimate[e$probabilities == "original"]
  after <- e$estimate[e$probabilities == "recalibrated"]
  se <- e$std.error[e$probabilities == "recalibrated"]
  expect_true(all(abs(after - tau) < 2 * se))
  expect_lt(abs(after[1L] - tau[1L]), abs(before[1L] - tau[1L]) / 4)

  # soft_check() grades this miscalibration as a problem
  chk <- soft_check(f, labelled = lab, group = "group")
  st <- stats::setNames(chk$summary$status, chk$summary$check)
  expect_identical(st[["Calibration given the controls"]], "problem")
})

test_that("recalibration repairs miscalibration given the controls", {
  d <- sim_softcats(n = 6000, K = 2, miscalibration = 1.5,
                    labelled_share = 0.25, seed = 2)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B"), data = d,
               learner = lrn_lm(degree = 3), seed = 2)
  rc <- recalibrate(f, labelled = d[d$labelled, ], group = "group")
  c0 <- rc$calibration$original
  c1 <- rc$calibration$recalibrated
  expect_lt(c0$table$p_conditional_holm, 1e-4)
  expect_gt(c1$table$p_conditional_holm, 0.05)
  expect_lt(c1$delta_hat, c0$delta_hat)
  expect_identical(rc$nobs_labelled, sum(d$labelled))
  expect_identical(dim(rc$probs_labelled), c(sum(d$labelled), 2L))
})

test_that("calibrated probabilities change little", {
  x <- fit_k3(n = 4000)
  d <- x$data
  rc <- recalibrate(x$fit, labelled = d[d$labelled, ], group = "group")
  expect_lt(mean(abs(rc$probs - x$fit$data$probs)), 0.05)
  e <- rc$estimates
  shift <- e$estimate[e$probabilities == "recalibrated"] - coef(x$fit)
  expect_true(all(abs(shift) < sqrt(diag(vcov(x$fit)))))
  expect_equal(e$estimate[e$probabilities == "original"],
               unname(coef(x$fit)))
})

test_that("predict() and update() reproduce the recalibrated estimate", {
  d <- sim_softcats(n = 3000, K = 3, miscalibration = 1,
                    labelled_share = 0.3, seed = 82)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B", "prob_C"),
               data = d, reference = "B", learner = lrn_lm(degree = 3),
               seed = 82)
  rc <- recalibrate(f, labelled = d[d$labelled, ], group = "group")
  pr <- predict(rc, d)
  expect_identical(colnames(pr), c("A", "B", "C"))
  expect_equal(unname(rowSums(pr)), rep(1, nrow(d)))
  expect_equal(unname(pr[, f$categories]), unname(rc$probs))

  # The same folds and learner give the estimate of recalibrate()
  d[, c("r_A", "r_B", "r_C")] <- pr
  up <- update(f, probs = c("r_A", "r_B", "r_C"))
  e <- rc$estimates[rc$estimates$probabilities == "recalibrated", ]
  expect_identical(up$reference, "B")
  expect_equal(unname(coef(up)), e$estimate, tolerance = 1e-8)
  expect_equal(unname(sqrt(diag(vcov(up)))), e$std.error, tolerance = 1e-8)
})

test_that("factor controls, matrix terms and missing values are handled", {
  d <- sim_softcats(n = 3000, K = 2, miscalibration = 1,
                    labelled_share = 0.3, seed = 83)
  d$region <- factor(c("north", "south", "east")[1L + (d$x2 > 0) +
                                                   (d$x3 > 1)])
  f <- soft_lm(y ~ x1 + region + poly(x3, 2), probs = c("prob_A", "prob_B"),
               data = d, learner = lrn_lm(degree = 2), seed = 83)

  # A level missing from the labelled sample and a row with missing values
  lab <- d[d$labelled & d$region != "east", ]
  lab[1L, c("prob_A", "prob_B")] <- NA
  rc <- recalibrate(f, labelled = lab, group = "group")
  expect_identical(rc$nobs_labelled, nrow(lab) - 1L)
  expect_identical(rc$n_par, 10L)

  new <- d[1:5, ]
  new$x1[2L] <- NA
  new$region[3L] <- "east"
  pr <- predict(rc, new)
  expect_true(all(is.na(pr[2L, ])))
  expect_false(anyNA(pr[-2L, ]))
  expect_equal(unname(pr[c(1L, 4L, 5L), ]),
               unname(rc$probs[c(1L, 4L, 5L), ]))
})

test_that("binary vectors, 0/1 labels, weights and fits without controls", {
  b <- sim_softcats(n = 3000, K = 2, miscalibration = 1,
                    labelled_share = 0.3, seed = 84)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = b$prob_B, data = b,
               learner = lrn_lm(degree = 3), seed = 84)
  lab <- b[b$labelled, ]
  expect_error(recalibrate(f, lab, group = as.integer(lab$group == "B")),
               "Supply `probs`")
  rc <- recalibrate(f, lab, group = as.integer(lab$group == "B"),
                    probs = lab$prob_B)
  rcw <- recalibrate(f, lab, group = lab$group == "B", probs = lab$prob_B,
                     weights = rep(1, nrow(lab)))
  expect_equal(rcw$estimates, rc$estimates)
  expect_error(predict(rc, b), "Supply `probs`")
  pr <- predict(rc, b, probs = b$prob_B)
  expect_identical(colnames(pr), c("0", "1"))
  expect_equal(unname(pr), unname(rc$probs))

  # Without interactions the map has fewer parameters
  rc0 <- recalibrate(f, lab, group = lab$group == "B", probs = lab$prob_B,
                     interactions = FALSE)
  expect_identical(rc0$n_par, 5L)
  expect_output(print(rc0), "on the log-odds and the controls")

  # Without controls the map uses the log-odds only
  f1 <- soft_lm(y ~ 1, probs = c("prob_A", "prob_B"), data = b,
                learner = lrn_lm(), seed = 84)
  rc1 <- recalibrate(f1, lab, group = "group")
  expect_identical(rc1$n_par, 2L)
  expect_false(rc1$calibration$original$has_controls)
  expect_equal(unname(predict(rc1, b)), unname(rc1$probs))
})

test_that("the folds of the labelled sample are reproducible", {
  x <- fit_k2(n = 3000)
  lab <- x$data[x$data$labelled, ]
  r1 <- recalibrate(x$fit, lab, "group")
  r2 <- recalibrate(x$fit, lab, "group")
  expect_identical(r1$probs_labelled, r2$probs_labelled)
  set.seed(99)
  s <- .Random.seed
  r3 <- recalibrate(x$fit, lab, "group", seed = 7)
  expect_identical(.Random.seed, s)
  expect_false(identical(r3$probs_labelled, r1$probs_labelled))
  expect_identical(r3$probs, r1$probs)
})

test_that("invalid inputs give informative errors", {
  x <- fit_k3()
  d <- x$data
  lab <- d[d$labelled, ]
  expect_error(recalibrate(stats::lm(y ~ x1, d), lab, "group"),
               "softcats fit")
  expect_error(recalibrate(x$fit, as.list(lab), "group"), "data frame")
  expect_error(recalibrate(x$fit, lab), "`group` is needed")
  expect_error(recalibrate(x$fit, lab, "group", folds = 1), "at least 2")
  expect_error(recalibrate(x$fit, lab, "group", level = 2), "between 0")
  expect_error(recalibrate(x$fit, lab, "group", interactions = NA),
               "TRUE or FALSE")
  expect_error(recalibrate(x$fit, lab, "group",
                           probs = c("prob_A", "prob_B")),
               "differ from those of the fit")
  expect_error(recalibrate(x$fit, lab[lab$group != "C", ], "group"),
               "do not occur")
  lab2 <- lab
  lab2$x1 <- as.character(lab2$x1 > 0)
  expect_error(recalibrate(x$fit, lab2, "group"), "do not match")
  w <- capture_warnings(recalibrate(x$fit, lab[1:150, ], "group"))
  expect_true(any(grepl("small for a map", w)))
  rc <- recalibrate(x$fit, lab, "group")
  expect_error(predict(rc, as.matrix(d)), "data frame")
})

test_that("the print method reports the comparison", {
  d <- sim_softcats(n = 4000, K = 3, labelled_share = 0.3, seed = 85)
  P <- as.matrix(d[, c("prob_A", "prob_B", "prob_C")])
  d[, c("q_A", "q_B", "q_C")] <- P^5 / rowSums(P^5)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = c("q_A", "q_B", "q_C"), data = d,
               learner = lrn_lm(degree = 3), seed = 85)
  rc <- recalibrate(f, labelled = d[d$labelled, ], group = "group")
  out <- capture_output(expect_invisible(print(rc)))
  expect_match(out, "Recalibration of the class probabilities")
  expect_match(out, "recalibrated out of fold, 5 folds")
  expect_match(out, "eigenvalue 2 of E\\[aa'\\]")
  expect_match(out, "can amplify the bias")
  expect_match(out, "treat the map as known")
  expect_true(all(nchar(strsplit(out, "\n")[[1L]]) <= 80L))
})

test_that("with random forests the refit replays the random draws of the fit", {
  d <- sim_softcats(n = 1500, K = 3, miscalibration = 1,
                    labelled_share = 0.3, seed = 86)
  f <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B", "prob_C"),
               data = d, learner = lrn_ranger(num.trees = 50), seed = 86)

  # Scores equal to the probabilities reproduce the fit exactly
  same <- crossfit_scores(f, f$data$probs[, -1L, drop = FALSE],
                          replay = TRUE)
  expect_equal(same$tau, unname(coef(f)), tolerance = 1e-12)
  expect_equal(unname(same$vcov), unname(vcov(f)), tolerance = 1e-12)

  # A refit with the recalibrated probabilities gives the same estimate
  rc <- recalibrate(f, labelled = d[d$labelled, ], group = "group")
  d[, c("r_A", "r_B", "r_C")] <- predict(rc, d)
  up <- update(f, probs = c("r_A", "r_B", "r_C"))
  e <- rc$estimates[rc$estimates$probabilities == "recalibrated", ]
  expect_equal(unname(coef(up)), e$estimate, tolerance = 1e-10)

  # Replaying leaves the random number generator of the session unchanged
  f0 <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B", "prob_C"),
                data = d, learner = lrn_ranger(num.trees = 50))
  set.seed(5)
  s <- .Random.seed
  recalibrate(f0, labelled = d[d$labelled, ], group = "group", seed = 1)
  expect_identical(.Random.seed, s)
})
