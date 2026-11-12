# Main Function ----------------------------------------------------------------

#' Sensitivity of the Estimate to Calibration Error
#'
#' Bounds the bias of the \code{\link{soft_lm}()} estimate when the
#' probabilities are miscalibrated given the controls by at most
#' \eqn{\delta}, and reports how much miscalibration the conclusion can
#' tolerate.
#' @param object [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()}.
#' @param delta [optional] (numeric) Drift magnitude. If given, the bound and
#'   the intervals widened by the bound are added (default: \code{NULL}).
#' @param level [optional] (numeric) Confidence level (default:
#'   \code{0.95}).
#' @param x [mandatory] (softcats_sensitivity) Result of
#'   \code{drift_sensitivity()}.
#' @param digits [optional] (integer) Number of significant digits to print
#'   (default: \code{3}).
#' @param ... [optional] Not used.
#' @details Suppose that the probabilities are miscalibrated given the
#'   controls, \eqn{E[1\{G = k\} \mid p, X] = p_k + \eta_k(p, X)} with
#'   \eqn{|\eta_k| \le \delta} for every category. Then the estimator of
#'   \code{\link{soft_lm}()} converges to
#'   \eqn{\tau + M^{-1} E[a \eta^\top] \tau} with \eqn{M = E[a a^\top]}, and
#'   the bias of coefficient \eqn{k} is at most
#'   \deqn{\delta \, \|\tau\|_1 \, E\left|(M^{-1} a)_k\right| .}
#'   For two categories this is \eqn{|\tau| \, \delta \, E|a| / V^*}.
#'   \code{drift_sensitivity()} evaluates the factor multiplying
#'   \eqn{\delta} (the bias per unit of drift), using the estimate of
#'   \eqn{\tau}, and reports two robustness values in the spirit of Cinelli
#'   and Hazlett (2020):
#'   \itemize{
#'     \item \code{rv}: the drift \eqn{\delta} at which the bound equals the
#'       absolute estimate. For two categories the bias is proportional to
#'       \eqn{\tau}, so a drift below \code{rv} cannot reverse the sign of
#'       the effect;
#'     \item \code{rv_ci}: the drift at which the bound equals the distance
#'       from zero to the end of the confidence interval nearest to zero, so
#'       that the interval widened by the bound includes zero.
#'   }
#'
#'   The bound holds for every drift function within \eqn{\pm\delta} and is
#'   therefore conservative for any particular one. It is evaluated at the
#'   estimate of \eqn{\tau}, so the widened interval summarises sensitivity
#'   and is not a confidence interval with guaranteed coverage. A value of
#'   \eqn{\delta} can be taken from \code{\link{calibration_check}()}
#'   (\code{delta_hat}).
#' @return A data frame of class \code{softcats_sensitivity} with columns
#'   \code{term}, \code{estimate}, \code{std.error}, \code{bias_per_delta},
#'   \code{rv}, \code{rv_ci} and, if \code{delta} is given, \code{bound},
#'   \code{conf.low} and \code{conf.high} (the confidence interval widened by
#'   the bound on each side). The print method returns \code{x} invisibly.
#' @references
#' Kurbucz, M. T. (2026). Coarsening latent-class probabilities: Directional
#' distortion and coverage loss. arXiv preprint.
#' \doi{10.48550/arXiv.2608.11784}
#'
#' Cinelli, C. and Hazlett, C. (2020). Making sense of sensitivity: Extending
#' omitted variable bias. \emph{Journal of the Royal Statistical Society
#' Series B}, 82(1), 39--67. \doi{10.1111/rssb.12348}
#'
#' Kurbucz, M. T. (2026). When to trust confidence thresholding:
#' Calibration diagnostics for pseudo-labelled regression. arXiv preprint.
#' \doi{10.48550/arXiv.2605.12780}
#' @export
#' @examples
#' # Example: Robustness values and the bound at a drift of 0.02
#' d <- sim_softcats(n = 2000, K = 2, seed = 9)
#' fit <- soft_lm(y ~ x1 + x2 + x3, probs = d$prob_B, data = d,
#'                learner = lrn_lm(degree = 3), seed = 9)
#' drift_sensitivity(fit)
#' drift_sensitivity(fit, delta = 0.02)
#' @importFrom stats coef qnorm vcov
#'
drift_sensitivity <- function(object, delta = NULL, level = 0.95) {

  if (!inherits(object, "softcats")) {
    stop_input("`object` must be a softcats fit.")
  }
  if (!is.null(delta) &&
      (length(delta) != 1L || !is.finite(delta) || delta < 0)) {
    stop_input("`delta` must be a single non-negative number.")
  }

  tau <- coef(object)
  se <- sqrt(diag(vcov(object)))
  w <- object$weights

  # Bias per unit of drift, averaged over cross-fitting splits
  scale <- Reduce(`+`, lapply(object$reps, function(r) {
    ba <- r$a %*% solve(r$M)
    colSums(abs(ba) * w) / sum(w)
  })) / length(object$reps)
  scale <- sum(abs(tau)) * scale

  # Robustness values
  z <- qnorm(1 - (1 - level) / 2)
  out <- data.frame(term = names(tau), estimate = unname(tau),
                    std.error = unname(se),
                    bias_per_delta = unname(scale),
                    rv = unname(abs(tau) / scale),
                    rv_ci = unname(pmax(abs(tau) - z * se, 0) / scale),
                    stringsAsFactors = FALSE)

  # Bound and widened intervals at the given drift
  if (!is.null(delta)) {
    out$bound <- delta * out$bias_per_delta
    out$conf.low <- out$estimate - z * out$std.error - out$bound
    out$conf.high <- out$estimate + z * out$std.error + out$bound
  }

  out <- structure(out, class = c("softcats_sensitivity", "data.frame"),
                   delta = delta, level = level)

  return(out)
}

# Methods ----------------------------------------------------------------------

#' @rdname drift_sensitivity
#' @export
#'
print.softcats_sensitivity <- function(x, digits = 3L, ...) {

  cat("Sensitivity to calibration drift |eta| <= delta\n\n")

  show <- as.data.frame(unclass(x), stringsAsFactors = FALSE)
  num <- vapply(show, is.numeric, TRUE)
  show[num] <- lapply(show[num], signif, digits = digits)
  print(show, row.names = FALSE)

  cat("\nbias_per_delta: largest bias per unit of drift.\n",
      "rv: drift at which the bound equals the estimate.\n",
      "rv_ci: drift at which the widened interval reaches zero.\n",
      sep = "")

  d <- attr(x, "delta")
  if (!is.null(d)) {
    cat(sprintf(paste0("Intervals are %g%% confidence intervals widened by ",
                       "the bound at delta = %s.\n"),
                100 * attr(x, "level"), format(d)))
  }

  invisible(x)
}
