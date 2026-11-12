# Main Functions ---------------------------------------------------------------

#' Compare with Regressions on Predicted Labels
#'
#' Replacing the class probabilities by a predicted label (the most likely
#' class, or a confidence threshold) is a coarsening of the probabilities.
#' \code{compare_hard()} reports, next to the \code{\link{soft_lm}()}
#' estimate, two hard-label estimates on the same data, the distortion that
#' coarsening causes, and the coverage that hard-label confidence intervals
#' can be expected to have.
#' @param object [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()}.
#' @param rule [optional] (character) \code{"argmax"} assigns the most likely
#'   category; \code{"threshold"} (two categories only) assigns the
#'   non-reference category when its probability exceeds \code{threshold}
#'   (default: \code{"argmax"}).
#' @param threshold [optional] (numeric) Threshold for
#'   \code{rule = "threshold"} (default: \code{0.5}).
#' @param level [optional] (numeric) Confidence level for the intervals and
#'   the implied coverage (default: \code{0.95}).
#' @param x [mandatory] (softcats_hard) Result of \code{compare_hard()}.
#' @param digits [optional] (integer) Number of significant digits to print
#'   (default: \code{3}).
#' @param ... [optional] Not used.
#' @details The two hard-label estimates are:
#'   \itemize{
#'     \item \code{hard (OLS)}: least squares of the outcome on the label
#'       dummies and the controls entered linearly, with HC1 or, with
#'       clusters, CR1 standard errors as in \code{\link{exclusion_test}()}.
#'       This is the analysis most often run in practice.
#'     \item \code{hard (cross-fitted)}: the same estimator as
#'       \code{\link{soft_lm}()} with the label \eqn{h} in place of the
#'       probabilities, using the same learner, folds and standard errors.
#'       Under the assumptions of \code{\link{soft_lm}()} it converges to
#'       \eqn{A \tau}, where \eqn{A = E[a_h a_h^\top]^{-1} E[a_h a^\top]} is
#'       the coarsening (distortion) matrix, \eqn{a_h} the label after
#'       partialling out the controls and \eqn{a} the residualised
#'       probabilities. For two categories \eqn{A} is the attenuation factor
#'       \eqn{\kappa}.
#'   }
#'
#'   With more than two categories the distortion need not be uniform: the
#'   estimate for one category can also pick up the effects of the others, and
#'   the retention coefficients \eqn{s_j = v_j^\top A v_j} along the
#'   eigenvectors \eqn{v_j} of \eqn{E[a a^\top]} can differ across
#'   directions and need not lie in \eqn{[0, 1]}.
#'
#'   The implied coverage is an asymptotic approximation to the coverage of
#'   nominal Wald intervals for the cross-fitted hard-label estimate,
#'   \eqn{\Phi(z - \nu) - \Phi(-z - \nu)} with \eqn{\nu} the implied bias
#'   \eqn{(\hat A - I)\hat\tau} divided by the hard-label standard error.
#'   It is an estimate: it uses the soft-label estimate in place of the true
#'   effects.
#'
#'   The regressions of the labels on the controls use the folds, the learner
#'   and the seed of the fit, so repeated calls on a fit with a seed give the
#'   same results.
#' @return An object of class \code{softcats_hard}: a list with
#'   \code{estimates} (a data frame with columns \code{method}, \code{term},
#'   \code{estimate}, \code{std.error}, \code{conf.low}, \code{conf.high}),
#'   the estimated distortion matrix \code{distortion}, the retention
#'   coefficients \code{retention}, and \code{coverage}, a data frame with the
#'   implied bias of the cross-fitted hard-label estimate and the implied
#'   coverage of its intervals. The print method returns \code{x} invisibly.
#' @references
#' Kurbucz, M. T. (2026). Coarsening latent-class probabilities: Directional
#' distortion and coverage loss. arXiv preprint.
#' \doi{10.48550/arXiv.2608.11784}
#'
#' Kurbucz, M. T. (2026). When to trust confidence thresholding:
#' Calibration diagnostics for pseudo-labelled regression. arXiv preprint.
#' \doi{10.48550/arXiv.2605.12780}
#' @seealso \code{\link{kappa_curve}()} for the attenuation across
#'   thresholds.
#' @export
#' @examples
#' # Example: Most likely category with three categories
#' d <- sim_softcats(n = 2000, K = 3, seed = 5)
#' fit <- soft_lm(y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C,
#'                data = d, learner = lrn_lm(degree = 3), seed = 5)
#' compare_hard(fit)
#' @importFrom stats coef pnorm qnorm setNames vcov
#'
compare_hard <- function(object, rule = c("argmax", "threshold"),
                         threshold = 0.5, level = 0.95) {

  if (!inherits(object, "softcats")) {
    stop_input("`object` must be a softcats fit.")
  }
  rule <- match.arg(rule)
  P <- object$data$probs
  K <- ncol(P)

  # Predicted labels, coded as dummies without the reference category
  if (rule == "threshold") {
    if (K != 2L) {
      stop_input(paste0("`rule = \"threshold\"` needs two categories; ",
                        "use \"argmax\"."))
    }
    H <- matrix(as.numeric(P[, 2L] > threshold), ncol = 1L,
                dimnames = list(NULL, colnames(P)[2L]))
  } else {
    idx <- max.col(P, ties.method = "first")
    H <- one_hot(colnames(P)[idx], colnames(P))[, -1L, drop = FALSE]
  }
  if (any(colSums(H) == 0) || any(colSums(H) == nrow(H))) {
    stop_input(paste0("The predicted labels do not vary for every category, ",
                      "so the hard-label regressions are not defined."))
  }
  z <- qnorm(1 - (1 - level) / 2)
  tau <- coef(object)

  # Hard-label estimates
  hard <- crossfit_scores(object, H)
  ols <- hard_ols(object, H)

  make_rows <- function(method, est, se) {
    data.frame(method = method, term = names(tau), estimate = unname(est),
               std.error = unname(se), conf.low = unname(est - z * se),
               conf.high = unname(est + z * se), stringsAsFactors = FALSE)
  }
  est <- rbind(
    make_rows("soft", tau, sqrt(diag(vcov(object)))),
    make_rows("hard (cross-fitted)", hard$tau, sqrt(diag(hard$vcov))),
    make_rows("hard (OLS)", ols$tau, sqrt(diag(ols$vcov)))
  )

  # Distortion matrix and retention along the eigen-directions
  A <- hard$A
  dimnames(A) <- list(names(tau), names(tau))
  V <- object$spectrum$vectors
  retention <- setNames(diag(t(V) %*% A %*% V), colnames(V))

  # Implied bias and coverage of the hard-label intervals
  bias <- drop((A - diag(nrow(A))) %*% tau)
  se_h <- sqrt(diag(hard$vcov))
  nu <- bias / se_h
  coverage <- data.frame(
    term = names(tau), implied_bias = unname(bias),
    std.error_hard = unname(se_h),
    coverage = unname(pnorm(z - nu) - pnorm(-z - nu)),
    stringsAsFactors = FALSE
  )

  out <- structure(list(
    estimates = est,
    distortion = A,
    retention = retention,
    coverage = coverage,
    rule = rule,
    threshold = if (rule == "threshold") threshold else NULL,
    level = level,
    reference = object$reference
  ), class = "softcats_hard")

  return(out)
}

# ------------------------------------------------------------------------------

#' Attenuation of Hard Labels Across Confidence Thresholds
#'
#' For a binary group, \code{kappa_curve()} evaluates the attenuation factor
#' \eqn{\kappa(t) = E[\tilde a_t a] / E[\tilde a_t^2]} of the label
#' \eqn{1\{p > t\}}, where \eqn{p} is the probability of the non-reference
#' category, \eqn{\tilde a_t = 1\{p > t\} - E[1\{p > t\} \mid X]} and
#' \eqn{a = p - E[p \mid X]}, on a grid of thresholds \eqn{t}, together with the
#' cross-fitted hard-label estimate at each threshold. Under the assumptions
#' of \code{\link{soft_lm}()}, the hard estimate converges to
#' \eqn{\kappa(t)\,\tau}, so values of \eqn{\kappa} close to one mean that
#' thresholding at \eqn{t} loses little, and values well below one that it
#' attenuates the coefficient. As in \code{\link{compare_hard}()}, the label
#' regressions use the folds, the learner and the seed of the fit.
#' @param object [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()} with two categories.
#' @param thresholds [optional] (numeric) Thresholds at which to evaluate the
#'   curve (default: \code{seq(0.5, 0.95, by = 0.05)}).
#' @param level [optional] (numeric) Confidence level for the hard-label
#'   intervals (default: \code{0.95}).
#' @param x [mandatory] (softcats_kappa) Result of \code{kappa_curve()}.
#' @param digits [optional] (integer) Number of significant digits to print
#'   (default: \code{3}).
#' @param ... [optional] Not used.
#' @return A data frame of class \code{softcats_kappa} with columns
#'   \code{threshold}, \code{share_positive} (weighted share labelled as the
#'   non-reference category), \code{kappa}, \code{estimate_hard},
#'   \code{std.error_hard}, \code{conf.low}, \code{conf.high} and
#'   \code{estimate_soft}. Thresholds at which the label does not vary give
#'   \code{NA}. The print and plot methods return \code{x} invisibly.
#' @references
#' Kurbucz, M. T. (2026). When to trust confidence thresholding:
#' Calibration diagnostics for pseudo-labelled regression. arXiv preprint.
#' \doi{10.48550/arXiv.2605.12780}
#' @export
#' @examples
#' # Example: Attenuation at four thresholds for a binary group
#' d <- sim_softcats(n = 2000, K = 2, seed = 6)
#' fit <- soft_lm(y ~ x1 + x2 + x3, probs = d$prob_B, data = d,
#'                learner = lrn_lm(degree = 3), seed = 6)
#' kc <- kappa_curve(fit, thresholds = c(0.5, 0.6, 0.7, 0.8))
#' kc
#' plot(kc)
#' @importFrom stats coef qnorm
#'
kappa_curve <- function(object, thresholds = seq(0.5, 0.95, by = 0.05),
                        level = 0.95) {

  if (!inherits(object, "softcats")) {
    stop_input("`object` must be a softcats fit.")
  }
  P <- object$data$probs
  if (ncol(P) != 2L) {
    stop_input(paste0("kappa_curve() needs two categories; use ",
                      "compare_hard() for more."))
  }
  z <- qnorm(1 - (1 - level) / 2)
  w <- object$weights

  # Attenuation factor and hard-label estimate at each threshold
  rows <- lapply(thresholds, function(t) {
    H <- matrix(as.numeric(P[, 2L] > t), ncol = 1L)
    share <- sum(w * H) / sum(w)
    if (share <= 0 || share >= 1) {
      return(data.frame(threshold = t, share_positive = share,
                        kappa = NA_real_, estimate_hard = NA_real_,
                        std.error_hard = NA_real_, conf.low = NA_real_,
                        conf.high = NA_real_))
    }
    h <- crossfit_scores(object, H)
    se <- sqrt(h$vcov[1L, 1L])
    data.frame(threshold = t, share_positive = share, kappa = h$A[1L, 1L],
               estimate_hard = h$tau, std.error_hard = se,
               conf.low = h$tau - z * se, conf.high = h$tau + z * se)
  })

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out$estimate_soft <- unname(coef(object))

  return(structure(out, class = c("softcats_kappa", "data.frame")))
}

# Methods ----------------------------------------------------------------------

#' @rdname compare_hard
#' @export
#'
print.softcats_hard <- function(x, digits = 3L, ...) {

  lab <- if (x$rule == "argmax") {
    "most likely category"
  } else {
    sprintf("threshold %s", format(x$threshold))
  }
  cat("Soft probabilities versus predicted labels (", lab, ")\n", sep = "")
  cat("Difference from reference category '", x$reference, "'\n\n", sep = "")

  # Estimates
  e <- x$estimates
  e[, 3:6] <- lapply(e[, 3:6], signif, digits = digits)
  print(e, row.names = FALSE)

  # Distortion
  if (nrow(x$distortion) == 1L) {
    cat("\nAttenuation factor kappa: ", signif(x$distortion[1L, 1L], digits),
        "\n", sep = "")
  } else {
    cat("\nDistortion matrix A (the cross-fitted hard estimate converges to ",
        "A tau):\n", sep = "")
    print(signif(x$distortion, digits))
    cat("Retention along the eigen-directions of E[aa']:\n")
    print(signif(x$retention, digits))
  }

  # Implied bias and coverage
  cv <- x$coverage
  cv[, 2:4] <- lapply(cv[, 2:4], formatC, digits = digits, format = "g",
                      flag = "#")
  cat(sprintf(paste0("\nImplied bias and coverage of nominal %g%% ",
                     "hard-label intervals:\n"), 100 * x$level))
  print(cv, row.names = FALSE)

  invisible(x)
}

# ------------------------------------------------------------------------------

#' @rdname kappa_curve
#' @export
#'
print.softcats_kappa <- function(x, digits = 3L, ...) {

  show <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  num <- vapply(show, is.numeric, TRUE)
  show[num] <- lapply(show[num], signif, digits = digits)
  print(show, row.names = FALSE)

  invisible(x)
}

# ------------------------------------------------------------------------------

#' @rdname kappa_curve
#' @export
#' @importFrom graphics abline plot
#'
plot.softcats_kappa <- function(x, ...) {

  ok <- is.finite(x$kappa)
  plot(x$threshold[ok], x$kappa[ok], type = "b", pch = 19,
       ylim = range(c(0, 1, x$kappa[ok])),
       xlab = "Confidence threshold", ylab = "Attenuation factor kappa")
  abline(h = 1, lty = 2, col = "grey50")

  invisible(x)
}

# Internal Functions -----------------------------------------------------------

#' Cross-Fitted Estimator with Other Scores
#'
#' Computes the cross-fitted estimate with other scores in place of the
#' class probabilities, such as hard labels or recalibrated probabilities,
#' using the folds, the outcome residuals and the seed stored in the fit.
#' With \code{replay = TRUE}, each regression of a score on the controls
#' starts from the state of the random number generator before the
#' corresponding regression of the fit, so that a stochastic learner draws
#' the same random numbers and scores equal to the probabilities reproduce
#' the estimate of the fit.
#' @param object [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()}.
#' @param H [mandatory] (matrix) Scores without the reference category.
#' @param what [optional] (character) Name of the scores in error messages
#'   (default: \code{"hard labels"}).
#' @param replay [optional] (logical) Whether to replay the random number
#'   states of the fit; requires one score per probability column (default:
#'   \code{FALSE}).
#' @return A list with the estimate \code{tau}, its covariance \code{vcov},
#'   the distortion matrix \code{A} relative to the residualised
#'   probabilities of the fit and the normalised Jacobian \code{M}, averaged
#'   over splits.
#' @keywords internal
#'
crossfit_scores <- function(object, H, what = "hard labels",
                            replay = FALSE) {

  w <- object$weights
  x <- object$data$x
  clus <- object$cluster
  q <- ncol(H)

  # Replaying the states of the fit leaves the state of the session unchanged
  if (replay) {
    old <- rng_state()
    on.exit(set_rng_state(old), add = TRUE)
  }

  res <- with_seed(object$seed, lapply(object$reps, function(r) {

    # Residualise the scores with the folds of the soft fit
    h_hat <- matrix(0, nrow(H), q)
    ks <- sort(unique(r$folds))
    for (i in seq_along(ks)) {
      test <- which(r$folds == ks[i])
      train <- which(r$folds != ks[i])
      for (j in seq_len(q)) {
        if (replay) set_rng_state(r$r_states[[(i - 1L) * q + j]])
        h_hat[test, j] <- fit_predict(object$learner$r, x, H[, j], w,
                                      train, test)
      }
    }
    at <- H - h_hat

    # Solve the moment equation with these scores in place of the probabilities
    atw <- at * w
    J <- crossprod(atw, at)
    if (rcond(J) < 1e-12) {
      stop_input("The residualised %s are collinear.", what)
    }
    tau_h <- drop(solve(J, crossprod(atw, r$R)))
    psi <- atw * drop(r$R - at %*% tau_h)
    list(tau = tau_h, vcov = sandwich_vcov(psi, J, clus),
         A = solve(J, crossprod(atw, r$a)), M = J / sum(w))
  }))

  # Average over splits; the variance includes the spread across splits
  n_rep <- length(res)
  taus <- matrix(vapply(res, `[[`, numeric(q), "tau"), nrow = q)
  tau <- rowMeans(taus)
  V <- Reduce(`+`, lapply(seq_len(n_rep), function(s) {
    res[[s]]$vcov + tcrossprod(taus[, s] - tau)
  })) / n_rep
  A <- Reduce(`+`, lapply(res, `[[`, "A")) / n_rep
  M <- Reduce(`+`, lapply(res, `[[`, "M")) / n_rep

  return(list(tau = tau, vcov = V, A = A, M = M))
}

# ------------------------------------------------------------------------------

#' Least Squares on Predicted Labels
#'
#' Regresses the outcome on the label dummies and the controls entered
#' linearly, with robust (HC1) or cluster-robust (CR1) standard errors.
#' @param object [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()}.
#' @param H [mandatory] (matrix) Label dummies without the reference
#'   category.
#' @return A list with the label coefficients \code{tau} and their
#'   covariance \code{vcov}.
#' @keywords internal
#' @importFrom stats lm.wfit
#'
hard_ols <- function(object, H) {

  y <- object$data$y
  w <- object$weights
  X <- cbind(`(Intercept)` = 1, H, design_matrix(object$data$x, 1L))

  fit <- lm.wfit(X, y, w)
  if (fit$rank < ncol(X)) {
    stop_input("The label dummies are collinear with the controls.")
  }

  # Sandwich covariance with the small-sample correction
  u <- fit$residuals
  J <- crossprod(X * w, X)
  psi <- X * (w * u)
  n <- nrow(X)
  p <- ncol(X)
  V <- if (is.null(object$cluster)) {
    sandwich_vcov(psi, J) * n / (n - p)
  } else {
    sandwich_vcov(psi, J, object$cluster) * (n - 1) / (n - p)
  }

  idx <- 1L + seq_len(ncol(H))

  return(list(tau = fit$coefficients[idx], vcov = V[idx, idx, drop = FALSE]))
}
