# Main Function ----------------------------------------------------------------

#' Check Conditional Calibration on Labelled Data
#'
#' \code{\link{soft_lm}()} requires the class probabilities to be calibrated
#' given the controls, \eqn{E[1\{G = k\} \mid p, X] = p_k}, which is stronger
#' than the marginal calibration targeted by Platt scaling or isotonic
#' regression. \code{calibration_check()} tests both on a sample where the
#' group is observed.
#' @param probs [mandatory] (matrix, data.frame, character, formula or
#'   numeric) Class probabilities for the labelled observations, in any form
#'   accepted by \code{\link{soft_lm}()}.
#' @param group [mandatory] (vector or character) Observed category labels: a
#'   vector or a column name of \code{data}. Labels must match the category
#'   names of \code{probs}; for a numeric probability vector use 0/1 or
#'   \code{FALSE}/\code{TRUE}.
#' @param data [optional] (data.frame) Data frame holding the variables
#'   referred to by name (default: \code{NULL}).
#' @param controls [optional] (formula, data.frame or matrix) Controls as a
#'   one-sided formula evaluated in \code{data}, or as a data frame or matrix.
#'   \code{NULL} tests marginal calibration only (default: \code{NULL}).
#' @param degree [optional] (integer) Degree of the polynomial in the logit of
#'   the probability (default: \code{3}).
#' @param by [optional] (vector, character or formula) Grouping variable for
#'   subgroup calibration gaps: a vector, a column name of \code{data} or a
#'   one-sided formula (default: \code{NULL}).
#' @param bins [optional] (integer) Number of equal-width probability bins
#'   for the ECE and the reliability curves (default: \code{10}).
#' @param weights [optional] (numeric, character or formula) Observation
#'   weights. With non-integer weights the likelihood-ratio tests are
#'   approximate (default: \code{NULL}).
#' @param min_cell [optional] (integer) Smallest subgroup or bin size used for
#'   the largest gap (default: \code{25}).
#' @param x [mandatory] (softcats_calibration) Result of
#'   \code{calibration_check()}.
#' @param digits [optional] (integer) Number of significant digits to print
#'   (default: \code{3}).
#' @param ... [optional] Not used.
#' @details For each category (one category suffices for a binary group),
#'   the indicator of that category is regressed by logistic regression on a
#'   polynomial in the logit of its probability and on the controls, with the
#'   logit as an offset, so that the null model is perfect calibration. This
#'   extends the logistic recalibration model of Cox (1958).
#'   \itemize{
#'     \item The \emph{overall} test compares the full model with the
#'       offset-only model. It detects any departure from calibration,
#'       marginal or conditional.
#'     \item The \emph{conditional} test compares the full model with the
#'       model without the controls. It detects miscalibration that depends
#'       on the controls and that marginal recalibration does not remove.
#'   }
#'
#'   Both are likelihood-ratio tests; p-values are Holm-adjusted across
#'   categories. The function also reports the expected calibration error
#'   (ECE, equal-width bins), the Brier score and the largest calibration
#'   gap, within subgroups if \code{by} is given and within score bins
#'   otherwise. Raw gaps in small cells are dominated by sampling noise, so
#'   each gap is also reported net of a Bonferroni-corrected multiple of its
#'   standard error under perfect calibration. The largest net gap is
#'   returned as \code{delta_hat}, an estimate of the drift magnitude for
#'   \code{\link{drift_sensitivity}()}; it is zero when no cell departs from
#'   calibration by more than chance. When the tests reject,
#'   \code{\link{recalibrate}()} recalibrates the probabilities on the score
#'   and the controls together.
#' @return An object of class \code{softcats_calibration}: a list with
#'   \code{table} (one row per tested category), \code{delta_hat},
#'   \code{delta_source}, \code{reliability} (binned mean probabilities and
#'   frequencies) and \code{nobs}. \code{delta_hat} is \code{NA} when no
#'   cell has at least \code{min_cell} observations. The print and plot
#'   methods return \code{x} invisibly.
#' @references
#' Cox, D. R. (1958). Two further applications of a model for binary
#' regression. \emph{Biometrika}, 45(3--4), 562--565.
#' \doi{10.1093/biomet/45.3-4.562}
#'
#' Holm, S. (1979). A simple sequentially rejective multiple test procedure.
#' \emph{Scandinavian Journal of Statistics}, 6(2), 65--70.
#'
#' Kurbucz, M. T. (2026). When to trust confidence thresholding:
#' Calibration diagnostics for pseudo-labelled regression. arXiv preprint.
#' \doi{10.48550/arXiv.2605.12780}
#' @export
#' @examples
#' # Example: Probabilities miscalibrated given the first control
#' d <- sim_softcats(n = 3000, K = 2, miscalibration = 0.8, seed = 7)
#' lab <- d[d$labelled, ]
#' cc <- calibration_check(probs = c("prob_A", "prob_B"), group = "group",
#'                         data = lab, controls = ~ x1 + x2 + x3)
#' cc
#' plot(cc)
#' @importFrom stats binomial complete.cases glm.fit model.frame na.pass
#'   p.adjust pchisq qlogis sd
#'
calibration_check <- function(probs, group, data = NULL, controls = NULL,
                              degree = 3L, by = NULL, bins = 10L,
                              weights = NULL, min_cell = 25L) {

  # Number of observations, from the data or from the labels
  n <- if (!is.null(data)) {
    nrow(data)
  } else {
    if (is.character(group) && length(group) == 1L) {
      stop_input("`group` is a column name but `data` is missing.")
    }
    length(group)
  }

  # Resolve the probabilities, labels, subgroups and weights
  pr <- resolve_probs(probs, data, n)
  g <- resolve_vector(group, data, n, "group")
  if (is.logical(g)) g <- as.integer(g)
  bvar <- resolve_vector(by, data, n, "by")
  w <- resolve_vector(weights, data, n, "weights") %||% rep(1, n)

  # Design matrix of the controls
  Xd <- if (is.null(controls)) {
    matrix(numeric(0), n, 0L)
  } else if (inherits(controls, "formula")) {
    mf <- model.frame(controls, data = data, na.action = na.pass)
    design_matrix(as.data.frame(mf), 1L)
  } else {
    design_matrix(as.data.frame(controls), 1L)
  }
  if (nrow(Xd) != n) {
    stop_input("`controls` must have one row per observation.")
  }

  # Keep complete observations
  ok <- complete.cases(pr$mat) & !is.na(g) & !is.na(w)
  if (ncol(Xd)) ok <- ok & complete.cases(Xd)
  if (!is.null(bvar)) ok <- ok & !is.na(bvar)
  P <- validate_probs(pr$mat[ok, , drop = FALSE])
  Y <- one_hot(g[ok], colnames(P))
  Xd <- Xd[ok, , drop = FALSE]
  w <- as.numeric(w[ok])
  if (any(!is.finite(w)) || any(w < 0) || sum(w) <= 0) {
    stop_input("`weights` must be finite, non-negative and not all zero.")
  }
  bvar <- if (is.null(bvar)) NULL else factor(bvar[ok])
  cats <- colnames(P)
  tested <- if (ncol(P) == 2L) 2L else seq_along(cats)

  # Likelihood-ratio tests and calibration errors for each tested category
  rows <- lapply(tested, function(k) {

    y <- Y[, k]
    p <- pmin(pmax(P[, k], 1e-6), 1 - 1e-6)
    off <- qlogis(p)

    # Standardised polynomial in the logit
    s <- sd(off)
    qs <- if (s > 0) (off - mean(off)) / s else off - mean(off)
    Q <- vapply(seq_len(degree), function(d) qs^d, numeric(length(qs)))
    Q <- matrix(Q, ncol = degree)

    # Deviances of the calibrated, score-only and full models
    dev0 <- -2 * sum(w * (y * log(p) + (1 - y) * log(1 - p)))
    dev_glm <- function(X) {
      suppressWarnings(glm.fit(X, y, weights = w, offset = off,
                               family = binomial()))
    }
    fit2 <- dev_glm(cbind(1, Q))
    fit1 <- if (ncol(Xd)) dev_glm(cbind(1, Q, Xd)) else fit2
    dev2 <- fit2$deviance
    dev1 <- fit1$deviance

    mg <- max_gap(y, p, w, bvar, bins, min_cell)
    df1 <- 1L + degree + ncol(Xd)
    lr1 <- max(dev0 - dev1, 0)
    lr2 <- if (ncol(Xd)) max(dev2 - dev1, 0) else NA_real_

    row <- data.frame(
      category = cats[k], n = length(y),
      ece = ece(y, p, w, bins), brier = sum(w * (y - p)^2) / sum(w),
      lr_overall = lr1, df_overall = df1,
      p_overall = pchisq(lr1, df1, lower.tail = FALSE),
      lr_conditional = lr2,
      df_conditional = if (ncol(Xd)) ncol(Xd) else NA_integer_,
      p_conditional = if (ncol(Xd)) {
        pchisq(lr2, ncol(Xd), lower.tail = FALSE)
      } else {
        NA_real_
      },
      max_gap = mg[["raw"]], max_gap_adj = mg[["adjusted"]],
      stringsAsFactors = FALSE
    )
    list(row = row, converged = fit1$converged && fit2$converged)
  })

  # Report logistic regressions that did not converge
  if (!all(vapply(rows, `[[`, TRUE, "converged"))) {
    warning(paste0("A calibration regression did not converge; the ",
                   "likelihood-ratio tests may be unreliable."),
            call. = FALSE)
  }

  # Holm adjustment across categories
  tab <- do.call(rbind, lapply(rows, `[[`, "row"))
  tab$p_overall_holm <- p.adjust(tab$p_overall, "holm")
  tab$p_conditional_holm <- if (ncol(Xd)) {
    p.adjust(tab$p_conditional, "holm")
  } else {
    NA_real_
  }

  # Reliability curves
  reliability <- lapply(tested, function(k) binned(P[, k], Y[, k], w, bins))
  names(reliability) <- cats[tested]

  delta_hat <- if (all(is.na(tab$max_gap_adj))) {
    NA_real_
  } else {
    max(tab$max_gap_adj, na.rm = TRUE)
  }

  out <- structure(list(
    table = tab,
    delta_hat = delta_hat,
    delta_source = if (is.null(bvar)) "score bins" else "subgroups",
    reliability = reliability,
    nobs = sum(ok),
    degree = degree,
    has_controls = ncol(Xd) > 0L
  ), class = "softcats_calibration")

  return(out)
}

# Methods ----------------------------------------------------------------------

#' @rdname calibration_check
#' @export
#'
print.softcats_calibration <- function(x, digits = 3L, ...) {

  cat("Calibration check on", x$nobs, "labelled observations\n\n")

  # Table of calibration errors and tests
  t <- x$table
  show <- data.frame(category = t$category, ECE = signif(t$ece, digits),
                     Brier = signif(t$brier, digits),
                     `overall p` = format_p(t$p_overall_holm),
                     check.names = FALSE)
  if (x$has_controls) show$`conditional p` <- format_p(t$p_conditional_holm)
  show$`max gap` <- signif(t$max_gap, digits)
  show$`net of noise` <- signif(t$max_gap_adj, digits)
  print(show, row.names = FALSE)

  cat(sprintf("\nLargest calibration gap beyond sampling noise (%s): %s\n",
              x$delta_source, format(signif(x$delta_hat, digits))))
  cat("p-values are from Holm-adjusted likelihood-ratio tests of perfect ",
      "calibration\n",
      sprintf("(polynomial of degree %d in the logit).\n", x$degree),
      sep = "")

  # Advice when calibration given the controls is rejected
  if (x$has_controls && any(x$table$p_conditional_holm < 0.05, na.rm = TRUE)) {
    cat("The probabilities are miscalibrated given the controls. ",
        "Recalibrating on the\n",
        "score alone (Platt, isotonic) does not repair this. recalibrate() ",
        "recalibrates\n",
        "on the score and the controls together, and drift_sensitivity() ",
        "bounds the bias.\n", sep = "")
  }

  invisible(x)
}

# ------------------------------------------------------------------------------

#' @rdname calibration_check
#' @export
#' @importFrom graphics abline par plot
#'
plot.softcats_calibration <- function(x, ...) {

  # One panel per tested category; restore the graphical parameters on exit
  k <- length(x$reliability)
  op <- par(mfrow = c(1L, k), no.readonly = TRUE)
  on.exit(par(op))

  for (nm in names(x$reliability)) {
    b <- x$reliability[[nm]]
    b <- b[b$n > 0, , drop = FALSE]
    plot(b$probability, b$frequency, xlim = c(0, 1), ylim = c(0, 1),
         type = "b", pch = 19, xlab = "Predicted probability",
         ylab = "Observed frequency", main = nm)
    abline(0, 1, lty = 2, col = "grey50")
  }

  invisible(x)
}

# Internal Functions -----------------------------------------------------------

#' Expected Calibration Error
#'
#' Computes the weighted mean absolute gap between the binned frequencies
#' and probabilities.
#' @param y [mandatory] (numeric) 0/1 indicator of the category.
#' @param p [mandatory] (numeric) Probability of the category.
#' @param w [mandatory] (numeric) Observation weights.
#' @param bins [mandatory] (integer) Number of equal-width bins.
#' @return A single number.
#' @keywords internal
#'
ece <- function(y, p, w, bins) {

  b <- binned(p, y, w, bins)
  b <- b[b$weight > 0, , drop = FALSE]

  return(sum(b$weight * abs(b$frequency - b$probability)) / sum(b$weight))
}

# ------------------------------------------------------------------------------

#' Binned Probabilities and Frequencies
#'
#' Computes the weighted mean probability and observed frequency within
#' equal-width probability bins.
#' @param p [mandatory] (numeric) Probability of the category.
#' @param y [mandatory] (numeric) 0/1 indicator of the category.
#' @param w [mandatory] (numeric) Observation weights.
#' @param bins [mandatory] (integer) Number of equal-width bins.
#' @return A data frame with columns \code{bin}, \code{probability},
#'   \code{frequency}, \code{weight} and \code{n}.
#' @keywords internal
#'
binned <- function(p, y, w, bins) {

  cut_id <- cut(p, breaks = seq(0, 1, length.out = bins + 1L),
                include.lowest = TRUE)

  out <- lapply(split(seq_along(p), cut_id), function(i) {
    if (!length(i)) {
      return(c(probability = NA, frequency = NA, weight = 0, n = 0))
    }
    c(probability = sum(w[i] * p[i]) / sum(w[i]),
      frequency = sum(w[i] * y[i]) / sum(w[i]),
      weight = sum(w[i]), n = length(i))
  })

  out <- as.data.frame(do.call(rbind, out))
  out$bin <- levels(cut_id)
  rownames(out) <- NULL

  return(out[, c("bin", "probability", "frequency", "weight", "n")])
}

# ------------------------------------------------------------------------------

#' Largest Calibration Gap
#'
#' Computes the largest calibration gap over subgroups (or score bins), raw
#' and net of sampling noise. The adjusted gap subtracts a
#' Bonferroni-corrected multiple of the standard error of the cell gap under
#' perfect calibration, so it is zero when no cell departs from calibration
#' by more than chance.
#' @param y [mandatory] (numeric) 0/1 indicator of the category.
#' @param p [mandatory] (numeric) Probability of the category.
#' @param w [mandatory] (numeric) Observation weights.
#' @param by [mandatory] (factor or \code{NULL}) Subgroups; \code{NULL} uses
#'   score bins.
#' @param bins [mandatory] (integer) Number of equal-width bins.
#' @param min_cell [mandatory] (integer) Smallest cell size used.
#' @return A named vector with elements \code{raw} and \code{adjusted}.
#' @keywords internal
#' @importFrom stats qnorm
#'
max_gap <- function(y, p, w, by, bins, min_cell) {

  groups <- if (is.null(by)) {
    cut(p, breaks = seq(0, 1, length.out = bins + 1L), include.lowest = TRUE)
  } else {
    by
  }

  cells <- Filter(function(i) length(i) >= min_cell,
                  split(seq_along(p), groups))
  if (!length(cells)) {
    return(c(raw = NA_real_, adjusted = NA_real_))
  }

  # Raw and noise-adjusted gap of each cell
  zc <- qnorm(1 - 0.025 / length(cells))
  g <- vapply(cells, function(i) {
    gap <- abs(sum(w[i] * (y[i] - p[i]))) / sum(w[i])
    se <- sqrt(sum(w[i]^2 * p[i] * (1 - p[i]))) / sum(w[i])
    c(gap, max(gap - zc * se, 0))
  }, numeric(2))

  return(c(raw = max(g[1L, ]), adjusted = max(g[2L, ])))
}
