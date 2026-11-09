# Main Function ----------------------------------------------------------------

#' Diagnostic Report for a softcats Fit
#'
#' Collects the checks that decide whether a \code{\link{soft_lm}()} estimate
#' can be trusted, and grades each as \code{ok}, \code{warning} or
#' \code{problem}:
#' \enumerate{
#'   \item \strong{Information beyond the controls}
#'     (\code{\link{score_spectrum}()}): the smallest canonical share of
#'     score variance not explained by the controls.
#'   \item \strong{Direct effects of classifier features}
#'     (\code{\link{exclusion_test}()}), if \code{extra} is given.
#'   \item \strong{Calibration given the controls}
#'     (\code{\link{calibration_check}()}), if labelled data are given,
#'     graded by the overall test, which detects every departure from
#'     \eqn{E[1\{G = k\} \mid p, X] = p_k}, whether or not it depends on the
#'     controls.
#'   \item \strong{Sensitivity to calibration drift}
#'     (\code{\link{drift_sensitivity}()}), at the drift \code{delta} or, if
#'     it is not given, at the largest calibration gap beyond sampling noise
#'     found by the calibration check.
#' }
#' @param object [mandatory] (softcats) A fit returned by
#'   \code{\link{soft_lm}()}.
#' @param labelled [optional] (data.frame) Labelled observations (default:
#'   \code{NULL}).
#' @param group [optional] (vector or character) Observed category labels in
#'   \code{labelled}: a column name or a vector. Required with
#'   \code{labelled} (default: \code{NULL}).
#' @param probs [optional] (matrix, data.frame, character, formula or
#'   numeric) Probabilities for the labelled observations. \code{NULL} reuses
#'   the \code{probs} specification of the fit, which works when it was given
#'   as column names or a formula (default: \code{NULL}).
#' @param extra [optional] (formula or character) Classifier features that
#'   are not controls, for the exclusion test: a one-sided formula or column
#'   names (default: \code{NULL}).
#' @param by [optional] (vector, character or formula) Grouping variable for
#'   subgroup calibration gaps (default: \code{NULL}).
#' @param delta [optional] (numeric) Drift magnitude for the sensitivity
#'   check (default: \code{NULL}).
#' @param x [mandatory] (softcats_check) Result of \code{soft_check()}.
#' @param ... [optional] Not used.
#' @details The first check needs only the fit. The others need a labelled
#'   sample in which the group is observed, with the outcome, the controls and
#'   the probabilities. These checks are unweighted and use standard errors
#'   that are not cluster-robust; call \code{\link{exclusion_test}()} and
#'   \code{\link{calibration_check}()} directly to use weights or clusters.
#'   The drift check is skipped when \code{delta} is not given and the
#'   calibration check finds no cell large enough to estimate the gap. When
#'   calibration fails, \code{\link{recalibrate}()} recalibrates the
#'   probabilities on the labelled sample.
#'
#'   The grading thresholds are rules of thumb. Information: \code{problem}
#'   below a share of 0.01, \code{warning} below 0.05. Exclusion and
#'   calibration: \code{problem} below p = 0.001, \code{warning} below
#'   p = 0.05. Drift: \code{problem} if \code{delta} reaches the robustness
#'   value \code{rv}, at which the bias bound equals the estimate, and
#'   \code{warning} if it reaches \code{rv_ci}, at which the widened
#'   interval includes zero.
#' @return An object of class \code{softcats_check}: a list with
#'   \code{summary} (a data frame with columns \code{check}, \code{status}
#'   and \code{detail}) and the component results \code{spectrum},
#'   \code{calibration}, \code{exclusion} and \code{sensitivity} (\code{NULL}
#'   when not run). The print method returns \code{x} invisibly.
#' @export
#' @examples
#' # Example: All checks on the labelled subsample
#' d <- sim_softcats(n = 3000, K = 2, seed = 10)
#' fit <- soft_lm(y ~ x1 + x2 + x3, probs = c("prob_A", "prob_B"), data = d,
#'                learner = lrn_lm(degree = 3), seed = 10)
#' soft_check(fit, labelled = d[d$labelled, ], group = "group", extra = ~ z)
#' @importFrom stats reformulate
#'
soft_check <- function(object, labelled = NULL, group = NULL, probs = NULL,
                       extra = NULL, by = NULL, delta = NULL) {

  if (!inherits(object, "softcats")) {
    stop_input("`object` must be a softcats fit.")
  }

  # Information beyond the controls
  spec <- score_spectrum(object)
  s <- spec$min_share
  rows <- list(check_row(
    "Information beyond the controls",
    if (!is.finite(s) || s < 0.01) {
      "problem"
    } else if (s < 0.05) {
      "warning"
    } else {
      "ok"
    },
    sprintf("smallest share not explained by the controls: %.3g", s)
  ))

  # Checks on the labelled sample
  cal <- exc <- sens <- NULL
  if (!is.null(labelled)) {

    if (is.null(group)) {
      stop_input("`group` is needed with `labelled`.")
    }
    probs <- probs %||% object$probs_arg
    if (is.null(probs)) {
      stop_input(paste0("Supply `probs` for the labelled data (the fit ",
                        "received the probabilities as a matrix or vector)."))
    }

    # Direct effects of the classifier features
    if (!is.null(extra)) {
      exc <- exclusion_test(object$formula, group = group, extra = extra,
                            data = labelled, reference = NULL)
      rows <- c(rows, list(check_row(
        "Direct effects of classifier features",
        grade_p(exc$p.value),
        sprintf("Wald %s on %d df", p_text(exc$p.value), exc$df)
      )))
    }

    # Calibration given the controls, graded by the overall test, which
    # covers departures with and without dependence on the controls
    labels <- attr(object$terms, "term.labels")
    controls <- if (length(labels)) reformulate(labels) else NULL
    cal <- calibration_check(probs = probs, group = group, data = labelled,
                             controls = controls, by = by)
    p_cal <- min(cal$table$p_overall_holm)
    rows <- c(rows, list(check_row(
      if (cal$has_controls) "Calibration given the controls" else "Calibration",
      grade_p(p_cal),
      sprintf("smallest Holm-adjusted %s; largest gap beyond noise = %.3g",
              p_text(p_cal), cal$delta_hat)
    )))
  }

  # Sensitivity to calibration drift
  d_use <- delta %||% (if (!is.null(cal)) cal$delta_hat else NULL)
  if (is.null(delta) && !is.null(cal) && isTRUE(cal$delta_hat == 0)) {
    rows <- c(rows, list(check_row(
      "Sensitivity to calibration drift", "ok",
      "no gap beyond sampling noise; set `delta` to bound a given drift"
    )))
  } else if (!is.null(d_use) && is.finite(d_use)) {
    sens <- drift_sensitivity(object, delta = d_use)
    status <- if (any(sens$rv <= d_use)) {
      "problem"
    } else if (any(sens$rv_ci <= d_use)) {
      "warning"
    } else {
      "ok"
    }
    rows <- c(rows, list(check_row(
      "Sensitivity to calibration drift", status,
      sprintf("delta = %.3g; smallest robustness value %.3g (interval: %.3g)",
              d_use, min(sens$rv), min(sens$rv_ci))
    )))
  }

  out <- structure(list(summary = do.call(rbind, rows), spectrum = spec,
                        calibration = cal, exclusion = exc,
                        sensitivity = sens),
                   class = "softcats_check")

  return(out)
}

# Methods ----------------------------------------------------------------------

#' @rdname soft_check
#' @export
#'
print.softcats_check <- function(x, ...) {

  cat("softcats diagnostic report\n\n")

  # One line per check with its status
  s <- x$summary
  tag <- c(ok = "[ok]     ", warning = "[warning]",
           problem = "[problem]")[s$status]
  for (i in seq_len(nrow(s))) {
    cat(tag[i], " ", s$check[i], "\n", sep = "")
    cat("          ", s$detail[i], "\n", sep = "")
  }

  if (is.null(x$calibration)) {
    cat("\nCalibration and exclusion need labelled data: pass `labelled` ",
        "and `group`.\n", sep = "")
  }
  if (any(s$status == "problem")) {
    cat("\nAt least one check failed; see the component results for ",
        "details.\n", sep = "")
  }

  invisible(x)
}

# Internal Functions -----------------------------------------------------------

#' One Row of the Diagnostic Report
#'
#' Creates a one-row data frame for the summary of
#' \code{\link{soft_check}()}.
#' @param check [mandatory] (character) Name of the check.
#' @param status [mandatory] (character) \code{"ok"}, \code{"warning"} or
#'   \code{"problem"}.
#' @param detail [mandatory] (character) Short description of the result.
#' @return A data frame with one row.
#' @keywords internal
#'
check_row <- function(check, status, detail) {
  data.frame(check = check, status = status, detail = detail,
             stringsAsFactors = FALSE)
}

# ------------------------------------------------------------------------------

#' Grade a p-Value
#'
#' Grades a p-value as \code{"problem"} below 0.001, \code{"warning"} below
#' 0.05 or if it is not finite, and \code{"ok"} otherwise.
#' @param p [mandatory] (numeric) A p-value.
#' @return A character string.
#' @keywords internal
#'
grade_p <- function(p) {

  if (!is.finite(p)) {
    return("warning")
  }
  if (p < 0.001) {
    return("problem")
  }
  if (p < 0.05) {
    return("warning")
  }

  return("ok")
}
