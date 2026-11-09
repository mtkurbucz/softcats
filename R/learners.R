# Main Functions ---------------------------------------------------------------

#' Nuisance Learners
#'
#' Learners estimate the two nuisance functions of \code{\link{soft_lm}()}:
#' the outcome regression \eqn{m(X) = E[Y \mid X]} and the score regressions
#' \eqn{r_k(X) = E[p_k \mid X]}. Each learner is an object of class
#' \code{softcats_learner} that knows how to fit a regression of a numeric
#' response on a data frame of controls and how to predict from that fit. All
#' learners accept observation weights.
#' \itemize{
#'   \item \code{lrn_ranger()} fits a random forest with \pkg{ranger}. It is
#'     the default because valid inference requires the nuisances to be
#'     estimated well, and both nuisances are typically non-linear.
#'   \item \code{lrn_lm()} fits least squares on the controls, optionally
#'     with raw polynomial terms of the numeric controls. It is fast and
#'     deterministic, and appropriate when the nuisances are close to
#'     polynomial.
#'   \item \code{lrn_glmnet()} fits a penalised regression with \pkg{glmnet}
#'     on a polynomial expansion of the controls, with the penalty chosen by
#'     cross-validation.
#'   \item \code{lrn_custom()} wraps any user-supplied pair of fit and
#'     predict functions.
#' }
#' @param num.trees [optional] (integer) Number of trees (default:
#'   \code{500}).
#' @param mtry [optional] (integer) Number of controls considered at each
#'   split, capped at the number of controls. \code{NULL} uses the
#'   \pkg{ranger} default (default: \code{NULL}).
#' @param min.node.size [optional] (integer) Minimum node size. \code{NULL}
#'   uses the \pkg{ranger} default (default: \code{NULL}).
#' @param num.threads [optional] (integer) Number of threads used by
#'   \pkg{ranger}. One thread keeps results reproducible across machines
#'   (default: \code{1}).
#' @param ... [optional] Further arguments passed to
#'   \code{\link[ranger:ranger]{ranger::ranger()}} or
#'   \code{glmnet::cv.glmnet()}, except those set by the learner
#'   (\code{x}, \code{y}, the weights, \code{seed} and \code{verbose}).
#'   Use the \code{seed} argument of \code{\link{soft_lm}()} for
#'   reproducible forests.
#' @param degree [optional] (integer) Highest power of each numeric control
#'   in the design matrix (default: \code{1} for \code{lrn_lm()} and
#'   \code{2} for \code{lrn_glmnet()}).
#' @param alpha [optional] (numeric) Elastic-net mixing parameter: \code{0} is
#'   ridge, \code{1} is lasso (default: \code{0}).
#' @param nfolds [optional] (integer) Number of folds for the internal
#'   cross-validation of the penalty (default: \code{5}).
#' @param s [optional] (character or numeric) Value of the penalty used for
#'   prediction, as in
#'   \code{\link[glmnet:predict.cv.glmnet]{glmnet::predict.cv.glmnet()}}
#'   (default: \code{"lambda.min"}).
#' @param fit [mandatory] (function) A function \code{function(x, y, w)} that
#'   returns a fitted model. \code{x} is a data frame of controls, \code{y} a
#'   numeric vector and \code{w} a vector of non-negative weights.
#' @param predict [mandatory] (function) A function
#'   \code{function(model, newdata)} that returns a numeric vector of
#'   predictions.
#' @param name [optional] (character) A short label shown in printed output
#'   (default: \code{"custom"}).
#' @param x [mandatory] (softcats_learner) A learner.
#' @details The learner can be different for the two nuisances: pass
#'   \code{learner = list(m = lrn_ranger(), r = lrn_lm(degree = 2))} to
#'   \code{\link{soft_lm}()}.
#'
#'   In \code{lrn_lm()} and \code{lrn_glmnet()}, factor and character
#'   controls enter as treatment-coded dummies. A level that does not occur
#'   in a training fold is predicted as the first level.
#' @return An object of class \code{softcats_learner}. The print method
#'   returns \code{x} invisibly.
#' @examples
#' # Example: Built-in learners
#' lrn_lm(degree = 2)
#' lrn_ranger(num.trees = 200)
#'
#' # Example: Natural splines in the first control, linear in the others
#' lrn_spline <- lrn_custom(
#'   fit = function(x, y, w) {
#'     stats::lm(y ~ splines::ns(x1, df = 4) + x2 + x3,
#'               data = cbind(x, y = y), weights = w)
#'   },
#'   predict = function(model, newdata) {
#'     stats::predict(model, newdata = newdata)
#'   },
#'   name = "natural splines"
#' )
#' lrn_spline
#' @name learners
#'
NULL

# ------------------------------------------------------------------------------

#' @rdname learners
#' @export
#' @importFrom ranger ranger
#' @importFrom stats predict
#'
lrn_ranger <- function(num.trees = 500L, mtry = NULL, min.node.size = NULL,
                       num.threads = 1L, ...) {

  dots <- list(...)
  reserved <- intersect(names(dots), c("x", "y", "case.weights", "seed",
                                       "verbose"))
  if (length(reserved)) {
    stop_input(paste0("Arguments set by lrn_ranger() cannot be passed in ",
                      "`...`: %s. Use the `seed` argument of soft_lm() for ",
                      "reproducible forests."),
               paste(reserved, collapse = ", "))
  }

  learner <- new_learner(
    name = "ranger",
    fit = function(x, y, w) {
      args <- c(list(x = x, y = y, num.trees = num.trees,
                     case.weights = w, num.threads = num.threads,
                     seed = sample.int(.Machine$integer.max, 1L),
                     verbose = FALSE),
                dots)
      if (!is.null(mtry)) args$mtry <- min(mtry, ncol(x))
      if (!is.null(min.node.size)) args$min.node.size <- min.node.size
      do.call(ranger, args)
    },
    predict = function(model, newdata) {
      predict(model, data = newdata, num.threads = num.threads)$predictions
    },
    details = list(num.trees = num.trees)
  )

  return(learner)
}

# ------------------------------------------------------------------------------

#' @rdname learners
#' @export
#' @importFrom stats lm.wfit
#'
lrn_lm <- function(degree = 1L) {

  degree <- as.integer(degree)
  if (length(degree) != 1L || is.na(degree) || degree < 1L) {
    stop_input("`degree` must be a positive integer.")
  }

  learner <- new_learner(
    name = if (degree == 1L) "lm" else sprintf("lm (degree %d)", degree),
    fit = function(x, y, w) {
      xlev <- factor_levels(x)
      xm <- cbind(`(Intercept)` = 1, design_matrix(x, degree, xlev))
      fit <- lm.wfit(xm, y, w)
      beta <- fit$coefficients
      beta[is.na(beta)] <- 0
      list(beta = beta, xlev = xlev)
    },
    predict = function(model, newdata) {
      xm <- cbind(`(Intercept)` = 1,
                  design_matrix(newdata, degree, model$xlev))
      drop(xm %*% model$beta)
    },
    details = list(degree = degree)
  )

  return(learner)
}

# ------------------------------------------------------------------------------

#' @rdname learners
#' @export
#' @importFrom stats predict
#'
lrn_glmnet <- function(alpha = 0, degree = 2L, nfolds = 5L, s = "lambda.min",
                       ...) {

  if (!requireNamespace("glmnet", quietly = TRUE)) {
    stop_input(paste0("lrn_glmnet() needs the 'glmnet' package. Install it ",
                      "with install.packages(\"glmnet\")."))
  }

  degree <- as.integer(degree)
  if (length(degree) != 1L || is.na(degree) || degree < 1L) {
    stop_input("`degree` must be a positive integer.")
  }
  dots <- list(...)
  reserved <- intersect(names(dots), c("x", "y", "weights"))
  if (length(reserved)) {
    stop_input("Arguments set by lrn_glmnet() cannot be passed in `...`: %s.",
               paste(reserved, collapse = ", "))
  }

  learner <- new_learner(
    name = sprintf("glmnet (alpha = %s, degree %d)", format(alpha), degree),
    fit = function(x, y, w) {
      xlev <- factor_levels(x)
      xm <- design_matrix(x, degree, xlev)
      # glmnet needs two columns; a constant column is never selected
      pad <- ncol(xm) == 1L
      if (pad) xm <- cbind(xm, .zero = 0)
      args <- c(list(x = xm, y = y, weights = w, alpha = alpha,
                     nfolds = nfolds), dots)
      list(fit = do.call(glmnet::cv.glmnet, args), xlev = xlev, pad = pad)
    },
    predict = function(model, newdata) {
      xm <- design_matrix(newdata, degree, model$xlev)
      if (model$pad) xm <- cbind(xm, .zero = 0)
      drop(predict(model$fit, newx = xm, s = s))
    },
    details = list(alpha = alpha, degree = degree)
  )

  return(learner)
}

# ------------------------------------------------------------------------------

#' @rdname learners
#' @export
#'
lrn_custom <- function(fit, predict, name = "custom") {

  if (!is.function(fit) || !is.function(predict)) {
    stop_input("`fit` and `predict` must be functions.")
  }

  return(new_learner(name = name, fit = fit, predict = predict))
}

# Methods ----------------------------------------------------------------------

#' @rdname learners
#' @export
#'
print.softcats_learner <- function(x, ...) {

  cat("<softcats learner: ", x$name, ">\n", sep = "")

  invisible(x)
}

# Internal Functions -----------------------------------------------------------

#' Construct a Learner
#'
#' Creates an object of class \code{softcats_learner}.
#' @param name [mandatory] (character) Label shown in printed output.
#' @param fit [mandatory] (function) Fitting function
#'   \code{function(x, y, w)}.
#' @param predict [mandatory] (function) Prediction function
#'   \code{function(model, newdata)}.
#' @param details [optional] (list) Settings stored with the learner
#'   (default: \code{list()}).
#' @return An object of class \code{softcats_learner}.
#' @keywords internal
#'
new_learner <- function(name, fit, predict, details = list()) {
  structure(list(name = name, fit = fit, predict = predict, details = details),
            class = "softcats_learner")
}

# ------------------------------------------------------------------------------

#' Resolve the Learner Argument
#'
#' Accepts a single learner or a list \code{list(m = , r = )}.
#' @param learner [mandatory] (softcats_learner or list) The \code{learner}
#'   argument of \code{\link{soft_lm}()}.
#' @return A list with the learners \code{m} and \code{r}.
#' @keywords internal
#'
resolve_learner <- function(learner) {

  if (inherits(learner, "softcats_learner")) {
    return(list(m = learner, r = learner))
  }

  if (is.list(learner) && all(c("m", "r") %in% names(learner)) &&
      inherits(learner$m, "softcats_learner") &&
      inherits(learner$r, "softcats_learner")) {
    return(list(m = learner$m, r = learner$r))
  }

  stop_input(paste0("`learner` must be a learner such as lrn_ranger(), or ",
                    "list(m = <learner>, r = <learner>)."))
}

# ------------------------------------------------------------------------------

#' Fit a Learner and Predict Held-Out Rows
#'
#' Fits the learner on the training rows and predicts the test rows. Without
#' controls, the prediction is the weighted mean of the training response.
#' @param learner [mandatory] (softcats_learner) Learner.
#' @param x [mandatory] (data.frame) Controls.
#' @param y [mandatory] (numeric) Response.
#' @param w [mandatory] (numeric) Observation weights.
#' @param train [mandatory] (integer) Indices of the training rows.
#' @param test [mandatory] (integer) Indices of the test rows.
#' @return A numeric vector of predictions for the test rows.
#' @keywords internal
#'
fit_predict <- function(learner, x, y, w, train, test) {

  if (ncol(x) == 0L) {
    return(rep(sum(w[train] * y[train]) / sum(w[train]), length(test)))
  }

  model <- learner$fit(x[train, , drop = FALSE], y[train], w[train])
  pred <- as.numeric(learner$predict(model, x[test, , drop = FALSE]))

  if (length(pred) != length(test) || any(!is.finite(pred))) {
    stop_input(paste0("Learner '%s' returned %d predictions (expected %d) ",
                      "or non-finite values."),
               learner$name, length(pred), length(test))
  }

  return(pred)
}
