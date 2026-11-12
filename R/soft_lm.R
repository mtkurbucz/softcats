# Main Function ----------------------------------------------------------------

#' Regression on Predicted Categories with Calibrated Class Probabilities
#'
#' Estimates the partial association between a latent categorical group and
#' an outcome when the group is not observed, but a classifier supplies
#' calibrated class probabilities for every observation. It replaces the
#' common practice of regressing the outcome on the predicted label (argmax
#' or a confidence threshold), which distorts the estimate (for a binary
#' group it typically attenuates it) and can give confidence intervals whose
#' coverage is far below the nominal level.
#' @param formula [mandatory] (formula) A two-sided formula
#'   \code{outcome ~ controls}. The right-hand side lists the controls; their
#'   functional form is left to the learner. Matrix-valued terms such as
#'   \code{poly(x, 2)} enter as one control per column. Use
#'   \code{outcome ~ 1} for no controls.
#' @param probs [mandatory] (matrix, data.frame, character, formula or
#'   numeric) Class probabilities, one column per category and rows summing
#'   to one: a matrix or data frame, a character vector of column names in
#'   \code{data}, a one-sided formula such as \code{~ p_a + p_b + p_c}, or,
#'   for a binary group, a numeric vector of probabilities of the second
#'   category, in which case the categories are named \code{"0"} and
#'   \code{"1"}. A prefix shared by all column names (such as \code{prob_}
#'   or \code{.pred_}) is removed to obtain category labels.
#' @param data [mandatory] (data.frame) A data frame containing the outcome
#'   and the controls.
#' @param reference [optional] (character or integer) The reference category,
#'   by name or position (default: \code{1}, the first column of
#'   \code{probs}).
#' @param learner [optional] (softcats_learner or list) A learner (see
#'   \code{\link{learners}}) used for both nuisances, or a list
#'   \code{list(m = , r = )} with separate learners for the outcome
#'   regression and the score regressions (default: \code{lrn_ranger()}).
#' @param folds [optional] (integer) Number of cross-fitting folds, at least
#'   two (default: \code{5}).
#' @param n_rep [optional] (integer) Number of repetitions of cross-fitting
#'   with new fold splits (default: \code{1}).
#' @param weights [optional] (numeric, character or formula) Non-negative
#'   observation weights, for example survey weights: a numeric vector, a
#'   column name of \code{data} or a one-sided formula (default:
#'   \code{NULL}).
#' @param cluster [optional] (vector, character or formula) Cluster
#'   identifier for cluster-robust standard errors: a vector, a column name of
#'   \code{data} or a one-sided formula (default: \code{NULL}).
#' @param seed [optional] (integer) Seed for the fold splits and stochastic
#'   learners. The random number generator state of the session is restored
#'   afterwards (default: \code{NULL}).
#' @section Model:
#' For a latent group \eqn{G} with categories \eqn{1, \dots, K} (category 1
#' is the reference) and class probabilities, or scores, \eqn{p}, the target
#' is \eqn{\tau} in the partially linear model
#' \deqn{E[Y \mid G, X] = \mu(X) + \sum_{k = 2}^{K} \tau_k 1\{G = k\},}
#' where \eqn{\mu} is unrestricted. The probabilities must be calibrated
#' conditionally on the controls, \eqn{E[1\{G = k\} \mid p, X] =
#' p_k}. Under this condition and the exclusion condition
#' \eqn{E[Y \mid G, p, X] = E[Y \mid G, X]} (see Requirements), with
#' \eqn{a = p - E[p \mid X]} (reference column removed) and
#' \eqn{m(X) = E[Y \mid X]},
#' \deqn{E[a\,(Y - m(X))] = E[a a^\top]\,\tau ,}
#' so \eqn{\tau} is identified from the unlabelled data whenever the scores
#' vary beyond what the controls explain, that is, whenever \eqn{E[a
#' a^\top]} is non-singular. For two categories, \eqn{E[a a^\top]} is the
#' residual score variance \eqn{V^* = E[\mathrm{Var}(p \mid X)]}.
#' @section Estimation and inference:
#' The nuisances \eqn{m(X)} and \eqn{E[p_k \mid X]} are estimated by
#' cross-fitting with the chosen learner. The estimator solves the sample
#' version of the moment equation above, whose estimating function is
#' Neyman-orthogonal in both nuisances. This is the partialling-out
#' estimator of Robinson (1988), with cross-fitted nuisance estimates and
#' the probabilities as regressors. Without weights or clusters, the
#' estimate is asymptotically normal with variance
#' \eqn{M^{-1} E[u^2 a a^\top] M^{-1} / n}, \eqn{M = E[a a^\top]} and
#' \eqn{u = Y - m(X) - a^\top\tau}, when both nuisance estimates are
#' consistent, their errors satisfy
#' \eqn{\|\hat m - m\|_2 \|\hat r - r\|_2 + \|\hat r - r\|_2^2 =
#' o_P(n^{-1/2})} and further regularity conditions hold (Chernozhukov et
#' al. 2018; Kurbucz 2026, arXiv:2608.11784). Standard errors are sandwich
#' estimates,
#' heteroskedasticity-robust (HC0) by default and cluster-robust (CR1, with
#' the factor \eqn{G / (G - 1)} for \eqn{G} clusters) when \code{cluster}
#' is supplied. With \code{cluster}, folds are formed from
#' whole clusters. With \code{n_rep > 1}, cross-fitting is repeated with new
#' fold splits; estimates are averaged and the variance includes the spread
#' across splits. With random forests, several splits (for example
#' \code{n_rep = 5}) are advisable, because in simulations the variance from
#' a single split understates the variability of the estimate.
#' @section Requirements:
#' The classifier must use information beyond the controls (classifier
#' features that are not in \code{formula}), otherwise the scores are a
#' function of the controls and the effect is not identified;
#' \code{\link{score_spectrum}()} reports how much information is left. These
#' extra features must not affect the outcome directly;
#' \code{\link{exclusion_test}()} checks this on labelled data. Conditional
#' calibration can be checked with \code{\link{calibration_check}()} and
#' repaired on labelled data with \code{\link{recalibrate}()}, and
#' \code{\link{drift_sensitivity}()} bounds the bias from calibration error.
#' The estimand is a partial association, not a causal effect.
#' @return An object of class \code{softcats}, with methods for
#'   \code{\link{print}()}, \code{\link{summary}()}, \code{\link{coef}()},
#'   \code{\link{vcov}()}, \code{\link{confint}()}, \code{\link{nobs}()},
#'   \code{\link{residuals}()}, \code{\link{fitted}()},
#'   \code{\link{formula}()}, \code{\link{plot}()},
#'   \code{\link[generics:tidy]{generics::tidy()}} and
#'   \code{\link[generics:glance]{generics::glance()}}. It works with
#'   \code{\link{update}()}, \pkg{broom}, \pkg{modelsummary} and
#'   \code{lmtest::coeftest()}.
#' @references
#' Kurbucz, M. T. (2026). Coarsening latent-class probabilities: Directional
#' distortion and coverage loss. arXiv preprint.
#' \doi{10.48550/arXiv.2608.11784}
#'
#' Kurbucz, M. T. (2026). When to trust confidence thresholding:
#' Calibration diagnostics for pseudo-labelled regression. arXiv preprint.
#' \doi{10.48550/arXiv.2605.12780}
#'
#' Chernozhukov, V., Chetverikov, D., Demirer, M., Duflo, E., Hansen, C.,
#' Newey, W. and Robins, J. (2018). Double/debiased machine learning for
#' treatment and structural parameters. \emph{The Econometrics Journal},
#' 21(1), C1--C68. \doi{10.1111/ectj.12097}
#'
#' Robinson, P. M. (1988). Root-N-consistent semiparametric regression.
#' \emph{Econometrica}, 56(4), 931--954. \doi{10.2307/1912705}
#' @seealso \code{\link{compare_hard}()} for the cost of using predicted
#'   labels instead, \code{\link{soft_check}()} for a one-page diagnostic
#'   report.
#' @export
#' @examples
#' # Example: Three categories, probabilities given as column names
#' d <- sim_softcats(n = 2000, K = 3, seed = 1)
#' fit <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B", "prob_C"),
#'                data = d, learner = lrn_lm(degree = 3), seed = 1)
#' fit
#' summary(fit)
#' confint(fit)
#' attr(d, "tau")
#'
#' # Example: Binary group, probability of the second category as a vector
#' b <- sim_softcats(n = 2000, K = 2, seed = 2)
#' soft_lm(y ~ x1 + x2 + x3, probs = b$prob_B, data = b,
#'         learner = lrn_lm(degree = 3), seed = 2)
#' @importFrom stats complete.cases
#'
soft_lm <- function(formula, probs, data, reference = 1L,
                    learner = lrn_ranger(), folds = 5L, n_rep = 1L,
                    weights = NULL, cluster = NULL, seed = NULL) {

  # Validate the arguments that do not depend on the data
  cl <- match.call()
  if (missing(data) || !is.data.frame(data)) {
    stop_input("`data` must be a data frame.")
  }
  if (!inherits(formula, "formula") || length(formula) != 3L) {
    stop_input(paste0("`formula` must be a two-sided formula such as ",
                      "`y ~ x1 + x2`."))
  }
  folds <- as.integer(folds)
  n_rep <- as.integer(n_rep)
  if (length(folds) != 1L || is.na(folds) || folds < 2L) {
    stop_input("`folds` must be an integer of at least 2.")
  }
  if (length(n_rep) != 1L || is.na(n_rep) || n_rep < 1L) {
    stop_input("`n_rep` must be a positive integer.")
  }
  learners <- resolve_learner(learner)

  # Resolve the outcome, controls, probabilities, weights and clusters
  n_all <- nrow(data)
  cf <- controls_frame(formula, data)
  pr <- resolve_probs(probs, data, n_all)
  w_all <- resolve_vector(weights, data, n_all, "weights")
  cl_all <- resolve_vector(cluster, data, n_all, "cluster")

  # The probabilities must not enter the model as controls
  prob_cols <- switch(pr$spec, names = pr$raw, formula = all.vars(pr$raw),
                      character())
  overlap <- intersect(prob_cols,
                       union(names(cf$x), all.vars(formula[[3L]])))
  if (length(overlap)) {
    stop_input(paste0("The probability columns %s are also among the ",
                      "controls. Remove them from `formula`."),
               paste(overlap, collapse = ", "))
  }

  # Keep complete observations and record the dropped rows
  ok <- !is.na(cf$y) & complete.cases(pr$mat)
  if (ncol(cf$x)) ok <- ok & complete.cases(cf$x)
  if (!is.null(w_all)) ok <- ok & !is.na(w_all)
  if (!is.null(cl_all)) ok <- ok & !is.na(cl_all)
  na_action <- NULL
  if (any(!ok)) {
    na_action <- which(!ok)
    names(na_action) <- rownames(data)[!ok]
    class(na_action) <- "omit"
  }
  n <- sum(ok)
  if (n < 2L * folds) {
    stop_input("Too few complete observations (%d) for %d folds.", n, folds)
  }

  # Prepare the outcome, controls, weights and clusters of the complete rows
  y <- cf$y[ok]
  if (is.logical(y)) y <- as.numeric(y)
  if (!is.numeric(y)) stop_input("The outcome must be numeric.")
  x <- cf$x[ok, , drop = FALSE]
  rownames(x) <- NULL
  w <- if (is.null(w_all)) rep(1, n) else as.numeric(w_all[ok])
  if (any(!is.finite(w)) || any(w < 0) || sum(w) <= 0) {
    stop_input("`weights` must be finite, non-negative and not all zero.")
  }
  clus <- if (is.null(cl_all)) NULL else cl_all[ok]
  if (!is.null(clus) && length(unique(clus)) < folds) {
    stop_input("`cluster` has fewer clusters (%d) than `folds` (%d).",
               length(unique(clus)), folds)
  }

  # Put the reference category first and drop it from the scores
  P <- validate_probs(order_reference(pr$mat[ok, , drop = FALSE], reference))
  categories <- colnames(P)
  Pq <- P[, -1L, drop = FALSE]
  q <- ncol(Pq)

  # Cross-fit the nuisances and solve the moment equation in each split
  reps <- with_seed(seed, lapply(seq_len(n_rep), function(s) {
    fold_id <- make_folds(n, folds, clus)
    nu <- crossfit_nuisances(y, Pq, x, w, fold_id, learners)
    est <- estimate_moment(y, Pq, w, nu$m_hat, nu$r_hat, clus)
    c(est, list(folds = fold_id, r_states = nu$r_states))
  }))

  # Average over splits; the variance includes the spread across splits
  taus <- vapply(reps, function(r) r$tau, numeric(q))
  taus <- matrix(taus, nrow = q)
  tau <- rowMeans(taus)
  V <- Reduce(`+`, lapply(seq_len(n_rep), function(s) {
    d <- taus[, s] - tau
    reps[[s]]$vcov + tcrossprod(d)
  })) / n_rep
  terms_ <- categories[-1L]
  names(tau) <- terms_
  dimnames(V) <- list(terms_, terms_)

  # Measure the information in the scores beyond the controls
  M <- Reduce(`+`, lapply(reps, `[[`, "M")) / n_rep
  dimnames(M) <- list(terms_, terms_)
  spectrum <- compute_spectrum(M, weighted_cov(Pq, w))
  if (spectrum$min_share < 0.01) {
    warning(sprintf(paste0(
      "The scores carry almost no information beyond the controls ",
      "(smallest residual share %.3g). The estimate is not reliable; ",
      "the classifier needs features that are not among the controls."),
      spectrum$min_share), call. = FALSE)
  }

  # Average the residuals of the moment equation over splits
  resid <- Reduce(`+`, lapply(reps, function(r) {
    drop(r$R - r$a %*% tau)
  })) / n_rep

  fit <- structure(list(
    coefficients = tau,
    vcov = V,
    call = cl,
    formula = formula,
    terms = cf$terms,
    categories = categories,
    reference = categories[1L],
    nobs = n,
    weighted = !is.null(w_all),
    weights = w,
    cluster = clus,
    n_clusters = if (is.null(clus)) NA_integer_ else length(unique(clus)),
    folds = folds,
    n_rep = n_rep,
    learner = learners,
    spectrum = spectrum,
    reps = reps,
    data = list(y = y, x = x, probs = P),
    probs_spec = pr$spec,
    probs_arg = if (pr$spec %in% c("names", "formula")) pr$raw else NULL,
    residuals = resid,
    na.action = na_action,
    seed = seed
  ), class = "softcats")

  return(fit)
}

# Internal Functions -----------------------------------------------------------

#' Assign Observations to Cross-Fitting Folds
#'
#' Draws balanced random folds. Whole clusters stay in one fold.
#' @param n [mandatory] (integer) Number of observations.
#' @param folds [mandatory] (integer) Number of folds.
#' @param cluster [optional] (vector) Cluster identifier (default:
#'   \code{NULL}).
#' @return An integer vector of fold indices of length \code{n}.
#' @keywords internal
#'
make_folds <- function(n, folds, cluster = NULL) {

  if (is.null(cluster)) {
    return(sample(rep_len(seq_len(folds), n)))
  }

  # Draw folds for the clusters and map them to the observations
  u <- unique(cluster)
  fu <- sample(rep_len(seq_len(folds), length(u)))

  return(fu[match(cluster, u)])
}

# ------------------------------------------------------------------------------

#' Cross-Fit the Nuisance Functions
#'
#' Estimates the outcome regression \eqn{m(X)} and the score regressions
#' \eqn{r_k(X)} out of fold.
#' @param y [mandatory] (numeric) Outcome.
#' @param Pq [mandatory] (matrix) Class probabilities without the reference
#'   column.
#' @param x [mandatory] (data.frame) Controls.
#' @param w [mandatory] (numeric) Observation weights.
#' @param fold_id [mandatory] (integer) Fold index of each observation.
#' @param learners [mandatory] (list) Learners \code{m} and \code{r}.
#' @return A list with the out-of-fold predictions \code{m_hat} (vector) and
#'   \code{r_hat} (matrix), and \code{r_states}, the state of the random
#'   number generator before each score regression (by fold, then column).
#' @keywords internal
#'
crossfit_nuisances <- function(y, Pq, x, w, fold_id, learners) {

  n <- length(y)
  q <- ncol(Pq)
  m_hat <- numeric(n)
  r_hat <- matrix(0, n, q)
  ks <- sort(unique(fold_id))
  r_states <- vector("list", length(ks) * q)

  # Fit on all folds but one and predict the remaining fold
  for (i in seq_along(ks)) {
    test <- which(fold_id == ks[i])
    train <- which(fold_id != ks[i])
    m_hat[test] <- fit_predict(learners$m, x, y, w, train, test)
    for (j in seq_len(q)) {
      r_states[(i - 1L) * q + j] <- list(rng_state())
      r_hat[test, j] <- fit_predict(learners$r, x, Pq[, j], w, train, test)
    }
  }

  return(list(m_hat = m_hat, r_hat = r_hat, r_states = r_states))
}

# ------------------------------------------------------------------------------

#' Solve the Orthogonal Moment Equation
#'
#' Solves \eqn{\sum_i w_i a_i (R_i - a_i^\top \tau) = 0} for \eqn{\tau},
#' where \eqn{a = p - \hat r(X)} and \eqn{R = Y - \hat m(X)}, and computes the
#' sandwich covariance.
#' @param y [mandatory] (numeric) Outcome.
#' @param Pq [mandatory] (matrix) Class probabilities without the reference
#'   column.
#' @param w [mandatory] (numeric) Observation weights.
#' @param m_hat [mandatory] (numeric) Predictions of \eqn{E[Y \mid X]}.
#' @param r_hat [mandatory] (matrix) Predictions of \eqn{E[p \mid X]}.
#' @param cluster [optional] (vector) Cluster identifier (default:
#'   \code{NULL}).
#' @return A list with the estimate \code{tau}, its covariance \code{vcov},
#'   the residualised scores \code{a} and outcome \code{R}, the nuisance
#'   predictions and the normalised Jacobian \code{M}.
#' @keywords internal
#'
estimate_moment <- function(y, Pq, w, m_hat, r_hat, cluster = NULL) {

  # Residualise the scores and the outcome
  a <- Pq - r_hat
  R <- y - m_hat

  # Weighted Jacobian of the moment equation
  aw <- a * w
  J <- crossprod(aw, a)
  if (rcond(J) < 1e-12) {
    stop_input(paste0("The residualised scores are (nearly) collinear: the ",
                      "scores carry no usable information beyond the ",
                      "controls."))
  }

  # Solve for tau and compute the per-observation scores
  tau <- drop(solve(J, crossprod(aw, R)))
  psi <- aw * drop(R - a %*% tau)

  return(list(tau = tau, vcov = sandwich_vcov(psi, J, cluster), a = a, R = R,
              m_hat = m_hat, r_hat = r_hat, M = J / sum(w)))
}

# ------------------------------------------------------------------------------

#' Eigen-Decomposition of the Score Information
#'
#' Computes the eigenvalues and eigenvectors of \eqn{M = E[a a^\top]} and
#' the canonical shares, the eigenvalues of \eqn{C^{-1/2} M C^{-1/2}} with
#' \eqn{C} the covariance of the scores.
#' @param M [mandatory] (matrix) Normalised Jacobian \eqn{E[a a^\top]}.
#' @param C [mandatory] (matrix) Weighted covariance of the scores.
#' @return A list with \code{values}, \code{vectors}, \code{shares},
#'   \code{min_share}, \code{condition}, \code{M} and \code{score_cov}.
#' @keywords internal
#'
compute_spectrum <- function(M, C) {

  q <- ncol(M)
  ev <- eigen(M, symmetric = TRUE)

  # Canonical shares relative to the covariance of the scores
  shares <- tryCatch({
    L <- chol(C)
    Linv <- backsolve(L, diag(q))
    eigen(t(Linv) %*% M %*% Linv, symmetric = TRUE, only.values = TRUE)$values
  }, error = function(e) rep(NA_real_, q))

  vec <- ev$vectors
  dimnames(vec) <- list(colnames(M), paste0("dir", seq_len(q)))

  return(list(
    values = ev$values,
    vectors = vec,
    shares = shares,
    min_share = suppressWarnings(min(shares, na.rm = TRUE)),
    condition = if (min(ev$values) > 0) {
      max(ev$values) / min(ev$values)
    } else {
      Inf
    },
    M = M,
    score_cov = C
  ))
}
