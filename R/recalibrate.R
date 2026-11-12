# Main Function ----------------------------------------------------------------

#' Recalibrate the Class Probabilities on Labelled Data
#'
#' \code{\link{soft_lm}()} requires the class probabilities to be calibrated
#' given the controls. When \code{\link{calibration_check}()} rejects this, a
#' sample in which the group is observed can be used to recalibrate them.
#' \code{recalibrate()} estimates the recalibration map
#' \eqn{E[1\{G = k\} \mid p, X]} on the labelled sample, checks the
#' recalibrated probabilities out of fold, and recomputes the estimate of the
#' fit with them. It implements the recalibration experiment of Kurbucz
#' (2026, arXiv:2608.11784), which also helps to tell which condition of the
#' estimator fails.
#' @param object [mandatory] (softcats or softcats_recalibration) A fit
#'   returned by \code{\link{soft_lm}()}; for \code{predict()}, the result of
#'   \code{recalibrate()}.
#' @param labelled [mandatory] (data.frame) Labelled observations with the
#'   controls of the fit, the probabilities and the observed group.
#' @param group [mandatory] (vector or character) Observed category labels in
#'   \code{labelled}: a column name or a vector. Labels must match the
#'   category names of the fit; for a fit with a numeric probability vector
#'   use 0/1 or \code{FALSE}/\code{TRUE}.
#' @param probs [optional] (matrix, data.frame, character, formula or
#'   numeric) Probabilities for the labelled observations, or for
#'   \code{newdata} in \code{predict()}, in any form accepted by
#'   \code{\link{soft_lm}()}. \code{NULL} reuses the \code{probs}
#'   specification of the fit, or of the labelled sample in
#'   \code{predict()}, which works when it was given as column names or a
#'   formula (default: \code{NULL}).
#' @param interactions [optional] (logical) Whether the map includes the
#'   products of the log-odds and the controls (default: \code{TRUE}).
#' @param folds [optional] (integer) Number of folds of the labelled sample
#'   for the out-of-fold check, at least two (default: \code{5}).
#' @param weights [optional] (numeric, character or formula) Weights of the
#'   labelled observations: a vector, a column name of \code{labelled} or a
#'   one-sided formula (default: \code{NULL}).
#' @param level [optional] (numeric) Confidence level of the intervals
#'   (default: \code{0.95}).
#' @param seed [optional] (integer) Seed for the folds of the labelled
#'   sample. \code{NULL} uses the seed of the fit (default: \code{NULL}).
#' @param x [mandatory] (softcats_recalibration) Result of
#'   \code{recalibrate()}.
#' @param newdata [mandatory] (data.frame) Data with the controls and the
#'   probabilities to recalibrate.
#' @param digits [optional] (integer) Number of significant digits to print
#'   (default: \code{3}).
#' @param ... [optional] Not used.
#' @details The map is a multinomial logistic regression of the observed
#'   group on the log-odds of the probabilities against the reference
#'   category, the controls and, with \code{interactions = TRUE}, the
#'   products of the log-odds and the controls. It is fitted by maximum
#'   likelihood with the log-odds as an offset, so that zero coefficients
#'   leave the probabilities unchanged. For two categories and without
#'   controls, the map is the logistic recalibration model of Cox (1958).
#'   Factor controls enter as dummies, and a level that does not occur in the
#'   labelled sample is treated as the first level. Columns that are
#'   collinear in the labelled sample are dropped. With few labelled
#'   observations, or when the miscalibration does not depend on the
#'   controls, \code{interactions = FALSE} gives a map with fewer
#'   parameters.
#'
#'   The function proceeds in three steps.
#'   \enumerate{
#'     \item The labelled sample is split into \code{folds} folds; two folds
#'       give the split-half design of Kurbucz (2026). Each fold is
#'       recalibrated by the map fitted on the other folds, and
#'       \code{\link{calibration_check}()} is run on the original and on these
#'       out-of-fold probabilities, so that the check does not reuse the
#'       observations that fitted the map. The maps of the folds are fitted
#'       on fewer observations than the final map, so the check is somewhat
#'       conservative.
#'     \item The map fitted on the whole labelled sample recalibrates the
#'       probabilities of the estimation sample.
#'     \item The estimate is recomputed with the recalibrated probabilities,
#'       using the folds, the outcome residuals and the learner of the fit.
#'       Only the regressions of the probabilities on the controls are
#'       refitted, and each starts from the state of the random number
#'       generator before the corresponding regression of the fit, so a
#'       stochastic learner such as \code{\link{lrn_ranger}()} draws the same
#'       random numbers. The two estimates thus differ only through the
#'       recalibration, and \code{\link{update}()} with the probabilities from
#'       \code{predict()} and the seed of the fit gives the same estimate.
#'   }
#'
#'   Recalibration targets calibration given the controls, not the
#'   exclusion condition. If the classifier features affect the outcome
#'   directly, \eqn{E[Y \mid G, p, X] = \mu(X) + \tau^\top g + d(p, X)}, the
#'   estimate converges to \eqn{\tau + M^{-1} E[a\,d]} with
#'   \eqn{M = E[a a^\top]}. A map that moves the probabilities towards their
#'   conditional mean given the controls shrinks \eqn{M} and can amplify
#'   this bias. The function therefore reports the eigenvalues of \eqn{M} and
#'   the smallest canonical share before and after recalibration, and the
#'   print method notes when recalibration halves the smallest eigenvalue or
#'   more. Read together with \code{\link{calibration_check}()} and
#'   \code{\link{exclusion_test}()}, the change in the estimate indicates
#'   which condition fails.
#'
#'   The standard errors after recalibration treat the map as known. They do
#'   not include its estimation error and can therefore be too small,
#'   especially when the labelled sample is small compared with the
#'   estimation sample. The function warns when the labelled sample has fewer
#'   than ten observations per parameter of the map.
#'
#'   \code{predict()} applies the map fitted on the whole labelled sample to
#'   other data, for example to refit the model with \code{\link{update}()}.
#' @return \code{recalibrate()} returns an object of class
#'   \code{softcats_recalibration}: a list with \code{estimates} (a data frame
#'   with columns \code{probabilities}, \code{term}, \code{estimate},
#'   \code{std.error}, \code{conf.low} and \code{conf.high}),
#'   \code{calibration} (the results of \code{\link{calibration_check}()} on
#'   the labelled sample, \code{original} and \code{recalibrated} out of
#'   fold), \code{spectrum} (the score spectra of the estimation sample,
#'   \code{original} and \code{recalibrated}, as returned by
#'   \code{\link{score_spectrum}()}), \code{probs} (the recalibrated
#'   probabilities of the estimation sample, reference category first),
#'   \code{probs_labelled} (the out-of-fold recalibrated probabilities of
#'   the complete labelled observations), \code{map} (the fitted map) and
#'   \code{nobs_labelled}. \code{predict()} returns a matrix of recalibrated
#'   probabilities with one row per row of \code{newdata}, \code{NA} where an
#'   input is missing, and the columns in the order of \code{probs}. The
#'   print method returns \code{x} invisibly.
#' @references
#' Kurbucz, M. T. (2026). Coarsening latent-class probabilities: Directional
#' distortion and coverage loss. arXiv preprint.
#' \doi{10.48550/arXiv.2608.11784}
#'
#' Cox, D. R. (1958). Two further applications of a model for binary
#' regression. \emph{Biometrika}, 45(3--4), 562--565.
#' \doi{10.1093/biomet/45.3-4.562}
#' @seealso \code{\link{calibration_check}()} for the calibration tests,
#'   \code{\link{exclusion_test}()} for direct effects of the classifier
#'   features.
#' @export
#' @examples
#' # Example: Probabilities miscalibrated given the first control
#' d <- sim_softcats(n = 3000, K = 2, miscalibration = 1.5,
#'                   labelled_share = 0.3, seed = 8)
#' fit <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B"), data = d,
#'                learner = lrn_lm(degree = 3), seed = 8)
#' rc <- recalibrate(fit, labelled = d[d$labelled, ], group = "group")
#' rc
#' attr(d, "tau")
#'
#' # Example: Refit with the recalibrated probabilities of all observations
#' d[, c("rprob_A", "rprob_B")] <- predict(rc, d)
#' update(fit, probs = c("rprob_A", "rprob_B"))
#' @importFrom stats coef complete.cases delete.response qnorm vcov
#'
recalibrate <- function(object, labelled, group, probs = NULL,
                        interactions = TRUE, folds = 5L, weights = NULL,
                        level = 0.95, seed = NULL) {

  # Validate the arguments
  if (!inherits(object, "softcats")) {
    stop_input("`object` must be a softcats fit.")
  }
  if (missing(labelled) || !is.data.frame(labelled)) {
    stop_input("`labelled` must be a data frame.")
  }
  if (missing(group) || is.null(group)) {
    stop_input("`group` is needed: a column name of `labelled` or a vector.")
  }
  if (!is.logical(interactions) || length(interactions) != 1L ||
      is.na(interactions)) {
    stop_input("`interactions` must be TRUE or FALSE.")
  }
  folds <- as.integer(folds)
  if (length(folds) != 1L || is.na(folds) || folds < 2L) {
    stop_input("`folds` must be an integer of at least 2.")
  }
  if (!is.numeric(level) || length(level) != 1L || is.na(level) ||
      level <= 0 || level >= 1) {
    stop_input("`level` must be a number between 0 and 1.")
  }
  probs <- probs %||% object$probs_arg
  if (is.null(probs)) {
    stop_input(paste0("Supply `probs` for the labelled data (the fit ",
                      "received the probabilities as a matrix or vector)."))
  }
  seed <- seed %||% object$seed

  # Resolve the probabilities, labels, weights and controls
  n <- nrow(labelled)
  cats <- object$categories
  pr <- resolve_probs(probs, labelled, n)
  P <- match_categories(pr$mat, cats)
  g <- resolve_vector(group, labelled, n, "group")
  if (is.logical(g)) g <- as.integer(g)
  w <- resolve_vector(weights, labelled, n, "weights") %||% rep(1, n)
  terms_x <- delete.response(object$terms)
  x <- model_controls(terms_x, labelled)
  xlev <- factor_levels(x)
  Xd <- design_matrix(x, 1L, xlev)
  Xd_fit <- design_matrix(object$data$x, 1L, xlev)
  if (!identical(colnames(Xd), colnames(Xd_fit))) {
    stop_input("The controls in `labelled` do not match those of the fit.")
  }

  # Keep complete observations
  ok <- complete.cases(P) & !is.na(g) & !is.na(w)
  if (ncol(Xd)) ok <- ok & complete.cases(Xd)
  n_ok <- sum(ok)
  if (n_ok < 2L * folds) {
    stop_input("Too few complete labelled observations (%d) for %d folds.",
               n_ok, folds)
  }
  P <- validate_probs(P[ok, , drop = FALSE])
  g <- g[ok]
  Y <- one_hot(g, cats)
  x <- x[ok, , drop = FALSE]
  Xd <- Xd[ok, , drop = FALSE]
  w <- as.numeric(w[ok])
  if (any(!is.finite(w)) || any(w < 0) || sum(w) <= 0) {
    stop_input("`weights` must be finite, non-negative and not all zero.")
  }
  absent <- cats[colSums(Y * w) == 0]
  if (length(absent)) {
    stop_input("Categories that do not occur in the labelled sample: %s.",
               paste(absent, collapse = ", "))
  }

  # Features of the map, standardised on the labelled sample
  scaling <- map_scaling(P, Xd)
  f <- map_features(P, Xd, scaling, interactions)
  n_par <- ncol(f$Z) * (length(cats) - 1L)
  if (n_ok < 10L * n_par) {
    warning(sprintf(paste0(
      "The labelled sample (%d observations) is small for a map with %d ",
      "parameters; consider `interactions = FALSE`."), n_ok, n_par),
      call. = FALSE)
  }

  # Recalibrate each fold of the labelled sample with the other folds
  fold_id <- with_seed(seed, make_folds(n_ok, folds))
  P_oof <- P
  converged <- TRUE
  for (k in seq_len(folds)) {
    test <- which(fold_id == k)
    train <- which(fold_id != k)
    if (any(colSums(Y[train, , drop = FALSE] * w[train]) == 0)) {
      stop_input(paste0("A category does not occur in every training fold ",
                        "of the labelled sample; use fewer folds."))
    }
    fit_k <- fit_multinom(f$Z[train, , drop = FALSE], Y[train, , drop = FALSE],
                          f$offset[train, , drop = FALSE], w[train])
    converged <- converged && fit_k$converged
    P_oof[test, ] <- map_probs(f$Z[test, , drop = FALSE],
                               f$offset[test, , drop = FALSE],
                               fit_k$coefficients)
  }
  rownames(P_oof) <- rownames(labelled)[ok]

  # Map fitted on the whole labelled sample
  fit_all <- fit_multinom(f$Z, Y, f$offset, w)
  converged <- converged && fit_all$converged
  if (!converged) {
    warning(paste0("The recalibration map did not converge; the ",
                   "recalibrated probabilities may be unreliable."),
            call. = FALSE)
  }

  # Calibration of the original and the out-of-fold probabilities
  ctrl <- if (ncol(x)) x else NULL
  cal0 <- calibration_check(probs = P, group = g, controls = ctrl,
                            weights = w)
  cal1 <- calibration_check(probs = P_oof, group = g, controls = ctrl,
                            weights = w)

  # Recalibrate the estimation sample and recompute the estimate
  f_fit <- map_features(object$data$probs, Xd_fit, scaling, interactions)
  P_fit <- map_probs(f_fit$Z, f_fit$offset, fit_all$coefficients)
  colnames(P_fit) <- cats
  re <- crossfit_scores(object, P_fit[, -1L, drop = FALSE],
                        "recalibrated probabilities", replay = TRUE)
  terms_ <- cats[-1L]
  dimnames(re$M) <- list(terms_, terms_)
  spec1 <- compute_spectrum(re$M, weighted_cov(P_fit[, -1L, drop = FALSE],
                                               object$weights))

  # Estimates with the original and the recalibrated probabilities
  z <- qnorm(1 - (1 - level) / 2)
  make_rows <- function(label, est, V) {
    se <- sqrt(diag(V))
    data.frame(probabilities = label, term = terms_, estimate = unname(est),
               std.error = unname(se), conf.low = unname(est - z * se),
               conf.high = unname(est + z * se), stringsAsFactors = FALSE)
  }
  est <- rbind(make_rows("original", coef(object), vcov(object)),
               make_rows("recalibrated", re$tau, re$vcov))

  spectrum <- lapply(list(original = object$spectrum, recalibrated = spec1),
                     structure, class = "softcats_spectrum",
                     reference = object$reference)

  map <- list(
    coefficients = fit_all$coefficients,
    categories = cats,
    terms = terms_x,
    probs_arg = if (pr$spec %in% c("names", "formula")) probs else NULL,
    xlev = xlev,
    design = colnames(Xd),
    scaling = scaling,
    interactions = interactions,
    loglik = fit_all$loglik,
    converged = fit_all$converged
  )

  out <- structure(list(
    estimates = est,
    calibration = list(original = cal0, recalibrated = cal1),
    spectrum = spectrum,
    probs = P_fit,
    probs_labelled = P_oof,
    map = map,
    nobs_labelled = n_ok,
    folds = folds,
    n_par = n_par,
    level = level,
    reference = object$reference
  ), class = "softcats_recalibration")

  return(out)
}

# Methods ----------------------------------------------------------------------

#' @rdname recalibrate
#' @export
#'
print.softcats_recalibration <- function(x, digits = 3L, ...) {

  has_controls <- x$calibration$original$has_controls
  cat("Recalibration of the class probabilities on ", x$nobs_labelled,
      " labelled observations\n", sep = "")
  cat("Map: multinomial logit with ", x$n_par, " parameters on the log-odds",
      if (has_controls && x$map$interactions) {
        ", the controls and\ntheir products"
      } else if (has_controls) {
        " and the controls"
      },
      "\n", sep = "")

  # Calibration on the labelled sample before and after recalibration
  t0 <- x$calibration$original$table
  t1 <- x$calibration$recalibrated$table
  show <- data.frame(
    probabilities = rep(c("original", "recalibrated"), c(nrow(t0), nrow(t1))),
    category = c(t0$category, t1$category),
    ECE = signif(c(t0$ece, t1$ece), digits),
    `overall p` = format_p(c(t0$p_overall_holm, t1$p_overall_holm)),
    check.names = FALSE, stringsAsFactors = FALSE
  )
  if (has_controls) {
    show$`conditional p` <- format_p(c(t0$p_conditional_holm,
                                       t1$p_conditional_holm))
  }
  show$`net of noise` <- signif(c(t0$max_gap_adj, t1$max_gap_adj), digits)
  cat("\nCalibration on the labelled sample (recalibrated out of fold, ",
      x$folds, " folds):\n", sep = "")
  print(show, row.names = FALSE)

  # Information beyond the controls before and after recalibration
  s0 <- x$spectrum$original
  s1 <- x$spectrum$recalibrated
  q <- length(s0$values)
  info <- data.frame(original = signif(c(s0$values, s0$min_share), digits),
                     recalibrated = signif(c(s1$values, s1$min_share),
                                           digits))
  rownames(info) <- c(if (q == 1L) "eigenvalue of E[aa']" else {
    paste("eigenvalue", seq_len(q), "of E[aa']")
  }, "smallest share")
  cat("\nInformation beyond the controls (estimation sample):\n")
  print(info)

  # Estimates with the original and the recalibrated probabilities
  e <- x$estimates
  e[, 3:6] <- lapply(e[, 3:6], signif, digits = digits)
  cat("\nEstimates (difference from reference category '", x$reference,
      "'):\n", sep = "")
  print(e, row.names = FALSE)

  # Notes on compression and remaining miscalibration
  ratio <- min(s1$values) / min(s0$values)
  if (is.finite(ratio) && ratio <= 0.5) {
    cat("\nRecalibration reduces the smallest eigenvalue of E[aa'] to ",
        format(signif(ratio, 2)), " of its\n",
        "original value. This can amplify the bias from a direct effect of ",
        "the\nclassifier features (see exclusion_test()).\n", sep = "")
  }
  if (any(t1$p_overall_holm < 0.05, na.rm = TRUE)) {
    cat("\nThe recalibrated probabilities still fail the calibration ",
        "check.\n", sep = "")
  }
  cat("\nStandard errors after recalibration treat the map as known.\n")

  invisible(x)
}

# ------------------------------------------------------------------------------

#' @rdname recalibrate
#' @export
#' @importFrom stats complete.cases predict
#'
predict.softcats_recalibration <- function(object, newdata, probs = NULL,
                                           ...) {

  if (missing(newdata) || !is.data.frame(newdata)) {
    stop_input("`newdata` must be a data frame.")
  }
  mp <- object$map
  probs <- probs %||% mp$probs_arg
  if (is.null(probs)) {
    stop_input(paste0("Supply `probs` for `newdata` (the labelled ",
                      "probabilities were given as a matrix or vector)."))
  }

  # Probabilities and controls of the new data
  n <- nrow(newdata)
  pr <- resolve_probs(probs, newdata, n)
  P <- match_categories(pr$mat, mp$categories)
  Xd <- design_matrix(model_controls(mp$terms, newdata), 1L, mp$xlev)
  if (!identical(colnames(Xd), mp$design)) {
    stop_input("The controls in `newdata` do not match those of the fit.")
  }

  # Recalibrate the complete rows; the others stay missing
  ok <- complete.cases(P)
  if (ncol(Xd)) ok <- ok & complete.cases(Xd)
  out <- matrix(NA_real_, n, length(mp$categories),
                dimnames = list(rownames(newdata), mp$categories))
  if (any(ok)) {
    f <- map_features(validate_probs(P[ok, , drop = FALSE]),
                      Xd[ok, , drop = FALSE], mp$scaling, mp$interactions)
    out[ok, ] <- map_probs(f$Z, f$offset, mp$coefficients)
  }

  return(out[, colnames(pr$mat), drop = FALSE])
}

# Internal Functions -----------------------------------------------------------

#' Match Probability Columns to the Categories of a Fit
#'
#' Checks that the probabilities have the categories of the fit and puts
#' their columns in the order of the fit.
#' @param mat [mandatory] (matrix) Class probabilities with named columns.
#' @param categories [mandatory] (character) Categories of the fit,
#'   reference first.
#' @return The matrix with its columns in the order of \code{categories}.
#' @keywords internal
#'
match_categories <- function(mat, categories) {

  if (ncol(mat) != length(categories) ||
      !setequal(colnames(mat), categories)) {
    stop_input(paste0("The categories of `probs` (%s) differ from those of ",
                      "the fit (%s)."),
               paste(colnames(mat), collapse = ", "),
               paste(categories, collapse = ", "))
  }

  return(mat[, categories, drop = FALSE])
}

# ------------------------------------------------------------------------------

#' Log-Odds Against the Reference Category
#'
#' Computes the log-odds of each category against the first, with the
#' probabilities bounded below by \code{1e-6}.
#' @param P [mandatory] (matrix) Class probabilities, reference first.
#' @return A matrix with one column per non-reference category.
#' @keywords internal
#'
log_odds <- function(P) {

  Pc <- pmax(P, 1e-6)

  return(log(Pc[, -1L, drop = FALSE]) - log(Pc[, 1L]))
}

# ------------------------------------------------------------------------------

#' Standardisation of the Map Features
#'
#' Records the means and standard deviations of the log-odds and of the
#' design of the controls in the labelled sample.
#' @param P [mandatory] (matrix) Class probabilities, reference first.
#' @param Xd [mandatory] (matrix) Design matrix of the controls.
#' @return A list with elements \code{L} and \code{X}, each holding
#'   \code{centre} and \code{scale}.
#' @keywords internal
#' @importFrom stats sd
#'
map_scaling <- function(P, Xd) {

  centre_scale <- function(m) {
    if (!ncol(m)) {
      return(list(centre = numeric(0), scale = numeric(0)))
    }
    s <- apply(m, 2L, sd)
    s[!is.finite(s) | s == 0] <- 1
    list(centre = colMeans(m), scale = s)
  }

  return(list(L = centre_scale(log_odds(P)), X = centre_scale(Xd)))
}

# ------------------------------------------------------------------------------

#' Features of the Recalibration Map
#'
#' Builds the regressors of the map (an intercept, the standardised
#' log-odds, the standardised controls and, optionally, their products) and
#' the offset (the log-odds).
#' @param P [mandatory] (matrix) Class probabilities, reference first.
#' @param Xd [mandatory] (matrix) Design matrix of the controls.
#' @param scaling [mandatory] (list) Result of \code{map_scaling()}.
#' @param interactions [mandatory] (logical) Whether to include the products
#'   of the log-odds and the controls.
#' @return A list with the regressors \code{Z} and the offset \code{offset}.
#' @keywords internal
#'
map_features <- function(P, Xd, scaling, interactions) {

  L <- log_odds(P)
  standardise <- function(m, s) {
    sweep(sweep(m, 2L, s$centre), 2L, s$scale, "/")
  }

  Ls <- standardise(L, scaling$L)
  colnames(Ls) <- paste0("logodds_", colnames(P)[-1L])
  Z <- cbind(`(Intercept)` = 1, Ls)

  # Controls and their products with the log-odds
  if (ncol(Xd)) {
    Xs <- standardise(Xd, scaling$X)
    Z <- cbind(Z, Xs)
    if (interactions) {
      prods <- lapply(seq_len(ncol(Ls)), function(j) {
        m <- Ls[, j] * Xs
        colnames(m) <- paste0(colnames(Ls)[j], ":", colnames(Xs))
        m
      })
      Z <- cbind(Z, do.call(cbind, prods))
    }
  }

  return(list(Z = Z, offset = L))
}

# ------------------------------------------------------------------------------

#' Probabilities from a Multinomial Logit
#'
#' Computes class probabilities from the regressors, the offset and the
#' coefficients of a multinomial logit with the first category as the
#' reference.
#' @param Z [mandatory] (matrix) Regressors.
#' @param offset [mandatory] (matrix) Offset, one column per non-reference
#'   category.
#' @param B [mandatory] (matrix) Coefficients, one column per non-reference
#'   category.
#' @return A matrix of class probabilities, reference first.
#' @keywords internal
#'
map_probs <- function(Z, offset, B) {

  eta <- cbind(0, offset + Z %*% B)
  mx <- eta[cbind(seq_len(nrow(eta)), max.col(eta, ties.method = "first"))]
  e <- exp(eta - mx)

  return(e / rowSums(e))
}

# ------------------------------------------------------------------------------

#' Fit a Multinomial Logit by Newton-Raphson
#'
#' Maximises the weighted log-likelihood of a multinomial logit with an
#' offset, starting from zero coefficients, with step halving. Columns of
#' \code{Z} that are collinear in the data get zero coefficients.
#' @param Z [mandatory] (matrix) Regressors.
#' @param Y [mandatory] (matrix) 0/1 indicators of the categories,
#'   reference first.
#' @param offset [mandatory] (matrix) Offset, one column per non-reference
#'   category.
#' @param w [mandatory] (numeric) Observation weights.
#' @param maxit [optional] (integer) Maximum number of iterations (default:
#'   \code{100}).
#' @param tol [optional] (numeric) Relative change of the log-likelihood at
#'   which the iterations stop (default: \code{1e-10}).
#' @return A list with the coefficients \code{coefficients} (one column per
#'   non-reference category), the log-likelihood \code{loglik}, the
#'   indicator \code{converged} and the number of iterations
#'   \code{iterations}.
#' @keywords internal
#'
fit_multinom <- function(Z, Y, offset, w, maxit = 100L, tol = 1e-10) {

  m <- ncol(Y) - 1L
  Yq <- Y[, -1L, drop = FALSE]

  # Drop columns that are collinear in these data
  qz <- qr(Z * sqrt(w), tol = 1e-7)
  keep <- sort(qz$pivot[seq_len(qz$rank)])
  Zk <- Z[, keep, drop = FALSE]
  qk <- length(keep)

  loglik <- function(B) {
    eta <- cbind(0, offset + Zk %*% B)
    mx <- eta[cbind(seq_len(nrow(eta)), max.col(eta, ties.method = "first"))]
    lse <- mx + log(rowSums(exp(eta - mx)))
    sum(w * (rowSums(Y * eta) - lse))
  }

  # Newton-Raphson from the identity map
  B <- matrix(0, qk, m)
  ll <- loglik(B)
  converged <- FALSE
  for (it in seq_len(maxit)) {

    Pt <- map_probs(Zk, offset, B)[, -1L, drop = FALSE]
    grad <- crossprod(Zk, w * (Yq - Pt))

    # Information matrix, one block per pair of categories
    info <- matrix(0, qk * m, qk * m)
    for (j in seq_len(m)) {
      for (l in j:m) {
        v <- Pt[, j] * ((j == l) - Pt[, l])
        blk <- crossprod(Zk * (w * v), Zk)
        ij <- (j - 1L) * qk + seq_len(qk)
        il <- (l - 1L) * qk + seq_len(qk)
        info[ij, il] <- blk
        info[il, ij] <- t(blk)
      }
    }
    step <- tryCatch(solve(info, as.vector(grad)), error = function(e) {
      qr.solve(info + diag(1e-8, nrow(info)), as.vector(grad))
    })
    step <- matrix(step, qk, m)

    # Halve the step until the log-likelihood does not decrease
    t <- 1
    repeat {
      ll_new <- loglik(B + t * step)
      if (is.finite(ll_new) && ll_new >= ll) break
      t <- t / 2
      if (t < 1e-10) break
    }
    if (t < 1e-10) {
      converged <- max(abs(grad)) < 1e-8 * sum(w)
      break
    }
    B <- B + t * step
    change <- ll_new - ll
    ll <- ll_new
    if (change < tol * (abs(ll) + 0.1)) {
      converged <- TRUE
      break
    }
  }

  coefficients <- matrix(0, ncol(Z), m,
                         dimnames = list(colnames(Z), colnames(Y)[-1L]))
  coefficients[keep, ] <- B

  return(list(coefficients = coefficients, loglik = ll,
              converged = converged, iterations = it))
}
