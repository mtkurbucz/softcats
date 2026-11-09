# Main Function ----------------------------------------------------------------

#' Information in the Scores Beyond the Controls
#'
#' Identification in \code{\link{soft_lm}()} rests on the matrix
#' \eqn{E[a a^\top]}, the covariance of the class probabilities after the
#' controls have been partialled out. \code{score_spectrum()} reports its
#' eigenvalues and eigenvectors, and the canonical shares: the eigenvalues of
#' \eqn{E[a a^\top]} relative to the covariance of the scores, that is, for
#' each canonical direction, the fraction of score variance that the controls
#' do not explain.
#' @param object [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()}.
#' @param x [mandatory] (softcats_spectrum) Result of
#'   \code{score_spectrum()}.
#' @param digits [optional] (integer) Number of significant digits to print
#'   (default: \code{3}).
#' @param ... [optional] Not used.
#' @details A share near zero means that, in that direction, the scores are
#'   almost a function of the controls and the corresponding contrast is
#'   weakly identified. \eqn{E[a a^\top]} is then nearly singular, and the
#'   eigenvector of its smallest eigenvalue shows which categories the weak
#'   direction involves.
#'
#'   The shares are estimated from the cross-fitted residuals, which also
#'   contain the estimation error of \eqn{E[p \mid X]}. When the controls
#'   explain little of the scores, a share can therefore exceed one slightly.
#'
#'   The canonical shares and the following thresholds are conventions of the
#'   package. As rules of thumb, a smallest share below 0.05 deserves attention
#'   and one
#'   below 0.01 means the estimate should not be used. For two categories the
#'   single eigenvalue is the residual score variance \eqn{V^*}.
#' @return An object of class \code{softcats_spectrum}: a list with
#'   \code{values} (eigenvalues of \eqn{E[a a^\top]}, decreasing),
#'   \code{vectors} (eigenvectors, one column per direction), \code{shares}
#'   (canonical shares, decreasing), \code{min_share}, \code{condition} (ratio
#'   of the largest to the smallest eigenvalue), \code{M} and
#'   \code{score_cov} (covariance of the scores). The print method returns
#'   \code{x} invisibly.
#' @references
#' Kurbucz, M. T. (2026). Coarsening latent-class probabilities: Directional
#' distortion and coverage loss. arXiv preprint.
#' \doi{10.48550/arXiv.2608.11784}
#' @export
#' @examples
#' # Example: Canonical shares with three categories
#' d <- sim_softcats(n = 2000, K = 3, seed = 4)
#' fit <- soft_lm(y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C,
#'                data = d, learner = lrn_lm(degree = 3), seed = 4)
#' score_spectrum(fit)
#'
score_spectrum <- function(object) {

  if (!inherits(object, "softcats")) {
    stop_input("`object` must be a softcats fit.")
  }

  out <- structure(object$spectrum, class = "softcats_spectrum",
                   reference = object$reference)

  return(out)
}

# Methods ----------------------------------------------------------------------

#' @rdname score_spectrum
#' @export
#' @importFrom stats setNames
#'
print.softcats_spectrum <- function(x, digits = 3L, ...) {

  q <- length(x$values)

  cat("Score information beyond the controls\n\n")
  cat("Canonical shares not explained by the controls (largest first):\n")
  print(setNames(signif(x$shares, digits), seq_len(q)))
  cat("\nEigenvalues of E[aa'] (eigenvectors dir1, dir2, ...):\n")
  print(setNames(signif(x$values, digits), colnames(x$vectors)))

  # Condition number and loadings of the weakest direction
  if (q > 1L) {
    cat("\nCondition number: ", signif(x$condition, digits), "\n", sep = "")
    weakest <- x$vectors[, q]
    weakest <- weakest * sign(weakest[which.max(abs(weakest))])
    cat("Weakest direction of E[aa'] (loadings on categories, relative ",
        "to '", attr(x, "reference"), "'):\n", sep = "")
    print(signif(weakest, digits))
  }

  # Verdict on the smallest share
  verdict <- if (!is.finite(x$min_share)) {
    "could not be computed."
  } else if (x$min_share < 0.01) {
    "too small: the effect is not identified in practice."
  } else if (x$min_share < 0.05) {
    "small: expect wide intervals for contrasts along the weakest direction."
  } else {
    "adequate."
  }
  cat("\nSmallest share ", signif(x$min_share, digits), " is ", verdict, "\n",
      sep = "")

  invisible(x)
}
