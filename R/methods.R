# Methods ----------------------------------------------------------------------

#' Methods for softcats Fits
#'
#' Standard methods for objects returned by \code{\link{soft_lm}()}.
#' Inference is based on the normal approximation, so \code{summary()}
#' reports z statistics and \code{confint()} normal-theory intervals.
#' @param object,x [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()}; for \code{print.summary.softcats()}, an object
#'   of class \code{summary.softcats}.
#' @param parm [optional] (character or integer) Coefficients to report, by
#'   name or position (default: all coefficients).
#' @param level [optional] (numeric) Confidence level (default:
#'   \code{0.95}).
#' @param conf.int [optional] (logical) Whether \code{tidy()} adds confidence
#'   limits (default: \code{FALSE}).
#' @param conf.level [optional] (numeric) Confidence level for \code{tidy()}
#'   (default: \code{0.95}).
#' @param which [optional] (character) For \code{plot()}: \code{"coef"} draws
#'   the estimates with confidence intervals, \code{"spectrum"} the share of
#'   score variation that the controls do not explain, by direction (default:
#'   \code{"coef"}).
#' @param digits [optional] (integer) Number of significant digits to print
#'   (default: \code{max(3, getOption("digits") - 3)}).
#' @param ... [optional] Not used.
#' @return \code{coef()} a named vector; \code{vcov()} a matrix;
#'   \code{confint()} a matrix with one row per coefficient; \code{nobs()} an
#'   integer; \code{formula()} the model formula; \code{residuals()} and
#'   \code{fitted()} numeric vectors; \code{summary()} an object of class
#'   \code{summary.softcats}; \code{tidy()} and \code{glance()} data frames.
#'   The print and plot methods return \code{x} invisibly.
#' @examples
#' # Example: Standard methods on a fit with three categories
#' d <- sim_softcats(n = 1500, K = 3, seed = 3)
#' fit <- soft_lm(y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C,
#'                data = d, learner = lrn_lm(degree = 3), seed = 3)
#' coef(fit)
#' vcov(fit)
#' confint(fit, level = 0.9)
#' tidy(fit, conf.int = TRUE)
#' glance(fit)
#' plot(fit)
#' plot(fit, which = "spectrum")
#' @name softcats-methods
#'
NULL

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats coef
#'
coef.softcats <- function(object, ...) {
  object$coefficients
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats vcov
#'
vcov.softcats <- function(object, ...) {
  object$vcov
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats nobs
#'
nobs.softcats <- function(object, ...) {
  object$nobs
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats formula
#'
formula.softcats <- function(x, ...) {
  x$formula
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats residuals
#'
residuals.softcats <- function(object, ...) {
  object$residuals
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats fitted
#'
fitted.softcats <- function(object, ...) {
  object$data$y - object$residuals
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats coef confint qnorm vcov
#'
confint.softcats <- function(object, parm, level = 0.95, ...) {

  est <- coef(object)
  se <- sqrt(diag(vcov(object)))

  # Select the coefficients by name or position
  if (missing(parm)) parm <- names(est)
  if (is.numeric(parm)) parm <- names(est)[parm]
  bad <- setdiff(parm, names(est))
  if (length(bad)) {
    stop_input("Unknown coefficient(s): %s.", paste(bad, collapse = ", "))
  }

  # Normal-theory intervals
  a <- (1 - level) / 2
  z <- qnorm(1 - a)
  ci <- cbind(est[parm] - z * se[parm], est[parm] + z * se[parm])
  colnames(ci) <- paste(format(100 * c(a, 1 - a), trim = TRUE,
                               scientific = FALSE, digits = 3), "%")
  rownames(ci) <- parm

  return(ci)
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats coef confint vcov
#'
print.softcats <- function(x, digits = max(3L, getOption("digits") - 3L),
                           ...) {

  cat("Regression on predicted categories (calibrated soft labels)\n\n")
  cat("Call:\n")
  print(x$call)

  # Estimates with confidence intervals
  ci <- confint(x)
  tab <- cbind(Estimate = coef(x), `Std. Error` = sqrt(diag(vcov(x))), ci)
  cat("\nDifference from reference category '", x$reference, "':\n", sep = "")
  print(signif(tab, digits))

  cat(sprintf(paste0("\nObservations: %d   Cross-fitting: %d folds, ",
                     "%d split%s\nLearner: %s\n"),
              x$nobs, x$folds, x$n_rep, if (x$n_rep == 1L) "" else "s",
              learner_label(x)))

  invisible(x)
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats coef pnorm vcov
#'
summary.softcats <- function(object, ...) {

  # Coefficient table with z tests
  est <- coef(object)
  se <- sqrt(diag(vcov(object)))
  z <- est / se
  coefs <- cbind(Estimate = est, `Std. Error` = se, `z value` = z,
                 `Pr(>|z|)` = 2 * pnorm(-abs(z)))

  out <- structure(list(
    call = object$call,
    coefficients = coefs,
    reference = object$reference,
    categories = object$categories,
    nobs = object$nobs,
    weighted = object$weighted,
    vcov_type = vcov_label(object),
    folds = object$folds,
    n_rep = object$n_rep,
    learner = learner_label(object),
    spectrum = object$spectrum,
    na.action = object$na.action
  ), class = "summary.softcats")

  return(out)
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom stats printCoefmat
#'
print.summary.softcats <- function(x,
                                   digits = max(3L, getOption("digits") - 3L),
                                   ...) {

  cat("Regression on predicted categories (calibrated soft labels)\n\n")
  cat("Call:\n")
  print(x$call)

  # Design of the fit
  cat("\nReference category: ", x$reference, "   Categories: ",
      paste(x$categories, collapse = ", "), "\n", sep = "")
  cat("Observations: ", x$nobs,
      if (length(x$na.action)) {
        sprintf(" (%d removed for missing values)", length(x$na.action))
      },
      if (x$weighted) "   Weighted" else "", "\n", sep = "")
  cat("Cross-fitting: ", x$folds, " folds, ", x$n_rep,
      if (x$n_rep == 1L) " split" else " splits",
      "   Learner: ", x$learner, "\n", sep = "")
  cat("Standard errors: ", x$vcov_type, "\n\n", sep = "")

  # Coefficient table
  printCoefmat(x$coefficients, digits = digits, P.values = TRUE,
               has.Pvalue = TRUE, signif.legend = TRUE)

  # Information in the scores beyond the controls
  s <- x$spectrum
  cat("\nScore information beyond the controls\n")
  cat("  Share of score variance not explained by the controls: ",
      paste(formatC(s$shares, digits = 3, format = "g"), collapse = ", "),
      "\n", sep = "")
  if (length(s$values) > 1L) {
    cat("  Condition number of E[aa']: ",
        formatC(s$condition, digits = 3, format = "g"), "\n", sep = "")
  } else {
    cat("  Residual score variance V*: ",
        formatC(s$values, digits = 3, format = "g"), "\n", sep = "")
  }

  invisible(x)
}

# ------------------------------------------------------------------------------

#' @importFrom generics tidy
#' @export
#'
generics::tidy

# ------------------------------------------------------------------------------

#' @importFrom generics glance
#' @export
#'
generics::glance

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @method tidy softcats
#' @export
#' @importFrom stats coef confint pnorm vcov
#'
tidy.softcats <- function(x, conf.int = FALSE, conf.level = 0.95, ...) {

  est <- coef(x)
  se <- sqrt(diag(vcov(x)))
  z <- est / se
  out <- data.frame(term = names(est), estimate = unname(est),
                    std.error = unname(se), statistic = unname(z),
                    p.value = 2 * pnorm(-abs(unname(z))),
                    stringsAsFactors = FALSE)

  # Optional confidence limits
  if (conf.int) {
    ci <- confint(x, level = conf.level)
    out$conf.low <- unname(ci[, 1L])
    out$conf.high <- unname(ci[, 2L])
  }

  return(out)
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @method glance softcats
#' @export
#'
glance.softcats <- function(x, ...) {

  s <- x$spectrum

  out <- data.frame(nobs = x$nobs, n.categories = length(x$categories),
                    reference = x$reference, folds = x$folds,
                    n.rep = x$n_rep, n.clusters = x$n_clusters,
                    min.eigenvalue = min(s$values),
                    min.residual.share = s$min_share,
                    condition.number = s$condition,
                    learner = learner_label(x), stringsAsFactors = FALSE)

  return(out)
}

# ------------------------------------------------------------------------------

#' @rdname softcats-methods
#' @export
#' @importFrom graphics abline axis barplot par plot segments
#' @importFrom stats coef confint
#'
plot.softcats <- function(x, which = c("coef", "spectrum"), level = 0.95,
                          ...) {

  which <- match.arg(which)

  # Restore the graphical parameters on exit
  op <- par(no.readonly = TRUE)
  on.exit(par(op))

  if (which == "coef") {

    # Estimates with confidence intervals
    est <- coef(x)
    ci <- confint(x, level = level)
    k <- length(est)
    yy <- rev(seq_len(k))
    par(mar = c(4.5, max(4, max(nchar(names(est))) * 0.6 + 1), 1, 1))
    plot(est, yy, xlim = range(c(ci, 0)), ylim = c(0.5, k + 0.5),
         yaxt = "n", pch = 19,
         xlab = sprintf("Difference from '%s' (%g%% CI)", x$reference,
                        100 * level),
         ylab = "")
    segments(ci[, 1L], yy, ci[, 2L], yy)
    abline(v = 0, lty = 2, col = "grey50")
    axis(2, at = yy, labels = names(est), las = 1)

  } else {

    # Canonical shares not explained by the controls
    s <- x$spectrum
    barplot(s$shares, names.arg = seq_along(s$shares),
            ylim = c(0, 1),
            ylab = "Share not explained by the controls",
            xlab = "Canonical direction (weakest last)",
            col = "grey70", border = NA)
    abline(h = c(0.05, 0.01), lty = c(2, 3), col = "grey30")

  }

  invisible(x)
}

# Internal Functions -----------------------------------------------------------

#' Label of the Covariance Estimator
#'
#' Describes the standard errors of a fit for printed output.
#' @param object [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()}.
#' @return A character string.
#' @keywords internal
#'
vcov_label <- function(object) {

  if (is.na(object$n_clusters)) {
    return("heteroskedasticity-robust (HC0)")
  }

  return(sprintf("cluster-robust (CR1, %d clusters)", object$n_clusters))
}

# ------------------------------------------------------------------------------

#' Label of the Learners
#'
#' Describes the learners of a fit for printed output.
#' @param object [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()}.
#' @return A character string.
#' @keywords internal
#'
learner_label <- function(object) {

  if (identical(object$learner$m$name, object$learner$r$name)) {
    return(object$learner$m$name)
  }

  return(sprintf("%s (outcome), %s (scores)", object$learner$m$name,
                 object$learner$r$name))
}
