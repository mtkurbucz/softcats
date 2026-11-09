# Main Function ----------------------------------------------------------------

#' Test Whether Classifier Features Affect the Outcome Directly
#'
#' The classifier behind the probabilities must use features beyond the
#' controls, and these features must affect the outcome only through the
#' group. If an extra feature has its own effect on the outcome, the model of
#' \code{\link{soft_lm}()} is misspecified and the estimate is biased. On
#' labelled data this is testable: \code{exclusion_test()} regresses the
#' outcome on the observed group, the controls and the extra features by
#' least squares, and reports a robust Wald test that the coefficients of the
#' extra features are zero.
#' @param formula [mandatory] (formula) A formula \code{outcome ~ controls},
#'   as in \code{\link{soft_lm}()}.
#' @param group [mandatory] (vector or character) Observed category labels:
#'   a vector or a column name of \code{data}.
#' @param extra [mandatory] (formula or character) The classifier features
#'   that are not controls: a one-sided formula or a character vector of
#'   column names.
#' @param data [mandatory] (data.frame) A data frame of labelled
#'   observations.
#' @param reference [optional] (character) Reference level of \code{group}.
#'   \code{NULL} uses the first level (default: \code{NULL}).
#' @param weights [optional] (numeric, character or formula) Observation
#'   weights (default: \code{NULL}).
#' @param cluster [optional] (vector, character or formula) Cluster
#'   identifier for cluster-robust standard errors. Without clusters the
#'   standard errors are HC1, with the factor \eqn{n / (n - p)} for \eqn{p}
#'   regressors; with clusters they are CR1, with the factors
#'   \eqn{(n - 1) / (n - p)} and \eqn{G / (G - 1)} for \eqn{G} clusters
#'   (default: \code{NULL}).
#' @param x [mandatory] (softcats_exclusion) Result of
#'   \code{exclusion_test()}.
#' @param digits [optional] (integer) Number of significant digits to print
#'   (default: \code{3}).
#' @param ... [optional] Not used.
#' @details The test is linear in the extra features and in the terms of
#'   \code{formula}. Add transformations to \code{formula} or \code{extra} to
#'   test other forms of dependence.
#' @return An object of class \code{softcats_exclusion} with the Wald
#'   \code{statistic}, its degrees of freedom \code{df}, the \code{p.value},
#'   the \code{coefficients} of the extra features and \code{nobs}. The print
#'   method returns \code{x} invisibly.
#' @export
#' @examples
#' # Example: The classifier feature z affects the outcome directly
#' d <- sim_softcats(n = 3000, K = 2, direct_effect = 0.5, seed = 8)
#' lab <- d[d$labelled, ]
#' exclusion_test(y ~ x1 + x2 + x3, group = "group", extra = ~ z, data = lab)
#' @importFrom stats complete.cases lm.wfit model.frame model.matrix
#'   model.response na.pass pchisq pnorm relevel
#'
exclusion_test <- function(formula, group, extra, data, reference = NULL,
                           weights = NULL, cluster = NULL) {

  if (!is.data.frame(data)) {
    stop_input("`data` must be a data frame.")
  }
  n <- nrow(data)

  # Resolve the labels, extra features, weights and clusters
  g <- resolve_vector(group, data, n, "group")
  zdf <- if (inherits(extra, "formula")) {
    model.frame(extra, data = data, na.action = na.pass)
  } else if (is.character(extra)) {
    miss <- setdiff(extra, names(data))
    if (length(miss)) {
      stop_input("Columns not found in `data`: %s.",
                 paste(miss, collapse = ", "))
    }
    data[, extra, drop = FALSE]
  } else {
    stop_input("`extra` must be a one-sided formula or column names.")
  }
  w <- resolve_vector(weights, data, n, "weights") %||% rep(1, n)
  clus <- resolve_vector(cluster, data, n, "cluster")

  # Keep complete observations
  mf_all <- model.frame(formula, data = data, na.action = na.pass)
  ok <- complete.cases(mf_all) & !is.na(g) & complete.cases(zdf) & !is.na(w)
  if (!is.null(clus)) ok <- ok & !is.na(clus)

  # Design matrix: controls, group dummies and extra features
  d_ok <- data[ok, , drop = FALSE]
  mf <- model.frame(formula, data = d_ok)
  y <- model.response(mf)
  Xd <- model.matrix(formula, data = d_ok)
  gf <- factor(g[ok])
  if (!is.null(reference)) gf <- relevel(gf, ref = reference)
  if (nlevels(gf) < 2L) {
    stop_input("`group` must have at least two observed categories.")
  }
  Gd <- model.matrix(~ gf)[, -1L, drop = FALSE]
  colnames(Gd) <- paste0("group", levels(gf)[-1L])
  Zd <- design_matrix(zdf[ok, , drop = FALSE], 1L)
  D <- cbind(Xd, Gd, Zd)
  w <- as.numeric(w[ok])
  if (any(!is.finite(w)) || any(w < 0) || sum(w) <= 0) {
    stop_input("`weights` must be finite, non-negative and not all zero.")
  }
  clus <- if (is.null(clus)) NULL else clus[ok]

  # Weighted least squares
  fit <- lm.wfit(D, y, w)
  if (fit$rank < ncol(D)) {
    stop_input(paste0("The extra features are collinear with the controls ",
                      "or the group."))
  }

  # Robust covariance with the small-sample correction
  u <- fit$residuals
  J <- crossprod(D * w, D)
  psi <- D * (w * u)
  nn <- nrow(D)
  p <- ncol(D)
  V <- if (is.null(clus)) {
    sandwich_vcov(psi, J) * nn / (nn - p)
  } else {
    sandwich_vcov(psi, J, clus) * (nn - 1) / (nn - p)
  }

  # Wald test that the coefficients of the extra features are zero
  idx <- ncol(Xd) + ncol(Gd) + seq_len(ncol(Zd))
  b <- fit$coefficients[idx]
  Vz <- V[idx, idx, drop = FALSE]
  stat <- drop(crossprod(b, solve(Vz, b)))
  se <- sqrt(diag(Vz))
  coefs <- data.frame(term = colnames(Zd), estimate = unname(b),
                      std.error = unname(se), statistic = unname(b / se),
                      p.value = 2 * pnorm(-abs(unname(b / se))),
                      stringsAsFactors = FALSE)

  out <- structure(list(
    statistic = stat,
    df = length(idx),
    p.value = pchisq(stat, length(idx), lower.tail = FALSE),
    coefficients = coefs,
    nobs = nn,
    vcov_type = if (is.null(clus)) "HC1" else "CR1"
  ), class = "softcats_exclusion")

  return(out)
}

# Methods ----------------------------------------------------------------------

#' @rdname exclusion_test
#' @export
#'
print.softcats_exclusion <- function(x, digits = 3L, ...) {

  cat("Direct-effect test for the classifier features (", x$nobs,
      " labelled observations)\n\n", sep = "")

  cf <- x$coefficients
  cf[, 2:5] <- lapply(cf[, 2:5], signif, digits = digits)
  print(cf, row.names = FALSE)

  cat(sprintf(paste0("\nWald chi-squared = %s on %d df, %s ",
                     "(%s standard errors)\n"),
              format(signif(x$statistic, digits)), x$df, p_text(x$p.value),
              x$vcov_type))

  # Advice when the exclusion restriction is rejected
  if (x$p.value < 0.05) {
    cat("The extra features predict the outcome beyond the group and the ",
        "controls,\n",
        "which violates the exclusion restriction of soft_lm(). Move them ",
        "into the\n",
        "controls or use a classifier without them.\n", sep = "")
  }

  invisible(x)
}
