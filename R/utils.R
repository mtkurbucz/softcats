# Internal Functions -----------------------------------------------------------

#' Default for NULL Values
#'
#' Returns \code{y} if \code{x} is \code{NULL} and \code{x} otherwise.
#' @param x [mandatory] (any) Value to test.
#' @param y [mandatory] (any) Default value.
#' @return \code{x}, or \code{y} if \code{x} is \code{NULL}.
#' @name null-default
#' @aliases %||%
#' @keywords internal
#'
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

# ------------------------------------------------------------------------------

#' Signal an Input Error
#'
#' Formats a message with \code{sprintf()} and stops without the call.
#' @param ... [mandatory] Format string and values passed to
#'   \code{sprintf()}.
#' @return No return value, called for its error.
#' @keywords internal
#'
stop_input <- function(...) {
  stop(sprintf(...), call. = FALSE)
}

# ------------------------------------------------------------------------------

#' Evaluate Code with a Temporary Seed
#'
#' Evaluates \code{code} after setting the seed and restores the random number
#' generator state of the session afterwards. With \code{seed = NULL}, the
#' code is evaluated without changing the state.
#' @param seed [mandatory] (integer or \code{NULL}) Seed.
#' @param code [mandatory] (expression) Code to evaluate.
#' @return The value of \code{code}.
#' @keywords internal
#'
with_seed <- function(seed, code) {

  if (is.null(seed)) {
    return(force(code))
  }

  # Save the current state and restore it on exit
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had_seed) {
    old <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  }
  on.exit({
    if (had_seed) {
      assign(".Random.seed", old, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  })

  set.seed(seed)

  return(force(code))
}

# ------------------------------------------------------------------------------

#' Get the State of the Random Number Generator
#'
#' Returns the current state of the random number generator of the session
#' without changing it.
#' @return The value of \code{.Random.seed}, or \code{NULL} if it does not
#'   exist.
#' @keywords internal
#'
rng_state <- function() {
  get0(".Random.seed", envir = globalenv(), inherits = FALSE)
}

# ------------------------------------------------------------------------------

#' Set the State of the Random Number Generator
#'
#' Restores a state returned by \code{rng_state()}. \code{NULL} removes the
#' state, as in a session that has not used the generator.
#' @param state [mandatory] (integer or \code{NULL}) A value of
#'   \code{.Random.seed}.
#' @return \code{NULL}, invisibly; called for its side effect.
#' @keywords internal
#'
set_rng_state <- function(state) {

  if (is.null(state)) {
    if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  } else {
    assign(".Random.seed", state, envir = globalenv())
  }

  return(invisible(NULL))
}

# ------------------------------------------------------------------------------

#' Resolve an Optional Per-Row Vector
#'
#' Turns an argument given as \code{NULL}, a vector, a column name of
#' \code{data} or a one-sided formula evaluated in \code{data} into a vector.
#' @param x [mandatory] (vector, character, formula or \code{NULL}) The
#'   argument.
#' @param data [mandatory] (data.frame or \code{NULL}) Data frame for column
#'   names and formulas.
#' @param n [mandatory] (integer) Expected length.
#' @param what [mandatory] (character) Argument name used in error messages.
#' @return A vector of length \code{n}, or \code{NULL}.
#' @keywords internal
#'
resolve_vector <- function(x, data, n, what) {

  if (is.null(x)) {
    return(NULL)
  }

  if (inherits(x, "formula")) {
    if (length(x) != 2L) {
      stop_input("`%s` must be a one-sided formula such as `~ id`.", what)
    }
    if (is.null(data)) {
      stop_input("`%s` is a formula but `data` is missing.", what)
    }
    v <- eval(x[[2L]], as.list(data), environment(x))
  } else if (is.character(x) && length(x) == 1L && !is.null(data) &&
             x %in% names(data)) {
    v <- data[[x]]
  } else {
    v <- x
  }

  # A single string that is not a column name is most likely a typo
  if (is.character(x) && length(x) == 1L && n != 1L && !is.null(data) &&
      !x %in% names(data)) {
    stop_input("Column '%s' given in `%s` not found in `data`.", x, what)
  }
  if (length(v) != n) {
    stop_input("`%s` must have one value per row of the data (%d), not %d.",
               what, n, length(v))
  }

  return(v)
}

# ------------------------------------------------------------------------------

#' Remove a Shared Prefix from Column Names
#'
#' Removes a prefix shared by all names (such as \code{"prob_"} or
#' \code{".pred_"}), cut back to the last \code{"_"} or \code{"."} inside the
#' shared part. The names are kept if the result would be empty or
#' duplicated.
#' @param x [mandatory] (character) Column names.
#' @return A character vector of the same length as \code{x}.
#' @keywords internal
#'
strip_common_prefix <- function(x) {

  if (length(x) < 2L) {
    return(x)
  }

  # Length of the longest shared prefix
  chars <- strsplit(x, "", fixed = TRUE)
  len <- min(lengths(chars))
  k <- 0L
  while (k < len && length(unique(vapply(chars, `[`, "", k + 1L))) == 1L) {
    k <- k + 1L
  }
  if (k == 0L) {
    return(x)
  }

  # Cut the prefix back to its last separator
  prefix <- substr(x[1L], 1L, k)
  cut <- max(c(0L, unlist(gregexpr("[_.]", prefix))))
  if (cut <= 0L) {
    return(x)
  }
  out <- substring(x, cut + 1L)

  if (any(!nzchar(out)) || anyDuplicated(out)) {
    return(x)
  }

  return(out)
}

# ------------------------------------------------------------------------------

#' Resolve the Class Probabilities
#'
#' Turns the \code{probs} argument into a numeric matrix with one column per
#' category.
#' @param probs [mandatory] (matrix, data.frame, character, formula or
#'   numeric) Class probabilities in any form accepted by
#'   \code{\link{soft_lm}()}.
#' @param data [mandatory] (data.frame or \code{NULL}) Data frame for column
#'   names and formulas.
#' @param n [mandatory] (integer) Expected number of rows.
#' @return A list with the matrix \code{mat}, the form of the input
#'   \code{spec} and the input itself \code{raw}.
#' @keywords internal
#'
resolve_probs <- function(probs, data, n) {

  spec <- "matrix"

  if (inherits(probs, "formula")) {

    # One-sided formula naming the probability columns
    if (length(probs) != 2L) {
      stop_input(paste0("`probs` must be a one-sided formula such as ",
                        "`~ p_a + p_b + p_c`."))
    }
    if (is.null(data)) {
      stop_input("`probs` is a formula but `data` is missing.")
    }
    vars <- all.vars(probs)
    missing_vars <- setdiff(vars, names(data))
    if (length(missing_vars)) {
      stop_input("Columns not found in `data`: %s.",
                 paste(missing_vars, collapse = ", "))
    }
    mat <- as.matrix(as.data.frame(data)[, vars, drop = FALSE])
    spec <- "formula"

  } else if (is.character(probs)) {

    # Column names of the probabilities
    if (is.null(data)) {
      stop_input("`probs` gives column names but `data` is missing.")
    }
    missing_vars <- setdiff(probs, names(data))
    if (length(missing_vars)) {
      stop_input("Columns not found in `data`: %s.",
                 paste(missing_vars, collapse = ", "))
    }
    mat <- as.matrix(as.data.frame(data)[, probs, drop = FALSE])
    spec <- "names"

  } else if (is.numeric(probs) && is.null(dim(probs))) {

    # Probability of the second category of a binary group
    mat <- cbind(`0` = 1 - probs, `1` = probs)
    spec <- "vector"

  } else if (is.matrix(probs) || is.data.frame(probs)) {
    mat <- as.matrix(probs)
  } else {
    stop_input(paste0("`probs` must be a matrix, a data frame, a numeric ",
                      "vector, column names or a one-sided formula."))
  }

  # Check the type and dimensions
  if (!is.numeric(mat)) {
    stop_input("`probs` must contain numeric probabilities.")
  }
  if (nrow(mat) != n) {
    stop_input("`probs` must have one row per observation (%d), not %d.",
               n, nrow(mat))
  }
  if (ncol(mat) < 2L) {
    stop_input(paste0("`probs` needs one column per category (at least ",
                      "two). For a binary group, a numeric vector of ",
                      "P(group = 1) is also accepted."))
  }

  # Derive the category labels from the column names
  if (is.null(colnames(mat))) {
    colnames(mat) <- paste0("cat", seq_len(ncol(mat)))
  }
  colnames(mat) <- strip_common_prefix(colnames(mat))

  return(list(mat = mat, spec = spec, raw = probs))
}

# ------------------------------------------------------------------------------

#' Validate and Normalise Class Probabilities
#'
#' Checks that the probabilities are finite, lie in \eqn{[0, 1]} and sum to
#' one in every row up to a tolerance, then clips and renormalises them.
#' @param mat [mandatory] (matrix) Class probabilities.
#' @param tol [optional] (numeric) Tolerance (default: \code{1e-4}).
#' @return The clipped and renormalised matrix.
#' @keywords internal
#'
validate_probs <- function(mat, tol = 1e-4) {

  if (any(!is.finite(mat))) {
    stop_input("`probs` contains non-finite values.")
  }
  if (any(mat < -tol | mat > 1 + tol)) {
    stop_input("`probs` must lie in [0, 1].")
  }
  s <- rowSums(mat)
  if (any(abs(s - 1) > tol)) {
    stop_input(paste0("Each row of `probs` must sum to one (largest ",
                      "deviation %.3g). Supply probabilities for all ",
                      "categories."), max(abs(s - 1)))
  }

  mat <- pmin(pmax(mat, 0), 1)

  return(mat / rowSums(mat))
}

# ------------------------------------------------------------------------------

#' Put the Reference Category First
#'
#' Reorders the columns of the probability matrix so that the reference
#' category comes first.
#' @param mat [mandatory] (matrix) Class probabilities.
#' @param reference [mandatory] (character or integer) Reference category, by
#'   name or position.
#' @return The reordered matrix.
#' @keywords internal
#'
order_reference <- function(mat, reference) {

  cats <- colnames(mat)

  if (length(reference) != 1L) {
    stop_input("`reference` must be a single category name or index.")
  }
  if (is.character(reference)) {
    ref <- match(reference, cats)
    if (is.na(ref)) {
      stop_input("Reference category '%s' not found. Categories: %s.",
                 reference, paste(cats, collapse = ", "))
    }
  } else {
    ref <- as.integer(reference)
    if (length(ref) != 1L || is.na(ref) || ref < 1L || ref > length(cats)) {
      stop_input(paste0("`reference` must be a category name or an index ",
                        "between 1 and %d."), length(cats))
    }
  }

  return(mat[, c(ref, setdiff(seq_along(cats), ref)), drop = FALSE])
}

# ------------------------------------------------------------------------------

#' Extract the Outcome and the Controls
#'
#' Evaluates the model formula and returns the outcome and the controls as a
#' data frame, possibly with zero columns. Matrix-valued terms such as
#' \code{poly()} or \code{splines::ns()} are split into one column per basis
#' function.
#' @param formula [mandatory] (formula) Model formula.
#' @param data [mandatory] (data.frame) Data.
#' @return A list with the outcome \code{y}, the controls \code{x} and the
#'   \code{terms} object.
#' @keywords internal
#' @importFrom stats model.frame model.response na.pass setNames terms
#'
controls_frame <- function(formula, data) {

  mf <- model.frame(formula, data = data, na.action = na.pass)
  y <- model.response(mf)
  x <- mf[, -1L, drop = FALSE]
  attr(x, "terms") <- NULL
  x <- split_matrix_terms(as.data.frame(x))

  return(list(y = y, x = x, terms = terms(mf)))
}

# ------------------------------------------------------------------------------

#' Evaluate the Controls of a Fit in Other Data
#'
#' Evaluates the right-hand side of a model formula in other data. The stored
#' terms reproduce data-dependent bases such as \code{poly()}, and
#' matrix-valued terms are split into single columns as in
#' \code{controls_frame()}.
#' @param terms [mandatory] (terms) Terms of the fit without the response.
#' @param data [mandatory] (data.frame) Data.
#' @return A data frame of controls with one row per row of \code{data}.
#' @keywords internal
#' @importFrom stats model.frame na.pass
#'
model_controls <- function(terms, data) {

  mf <- model.frame(terms, data = data, na.action = na.pass)
  attr(mf, "terms") <- NULL

  return(split_matrix_terms(as.data.frame(mf)))
}

# ------------------------------------------------------------------------------

#' Split Matrix-Valued Terms into Columns
#'
#' Replaces each matrix-valued column of a model frame, such as the basis of
#' \code{poly()}, by one column per basis function.
#' @param x [mandatory] (data.frame) Columns of a model frame.
#' @return A data frame without matrix-valued columns.
#' @keywords internal
#' @importFrom stats setNames
#'
split_matrix_terms <- function(x) {

  if (!any(vapply(x, is.matrix, TRUE))) {
    return(x)
  }

  cols <- lapply(names(x), function(nm) {
    v <- x[[nm]]
    if (!is.matrix(v)) {
      return(setNames(list(v), nm))
    }
    lab <- colnames(v)
    if (is.null(lab)) lab <- seq_len(ncol(v))
    setNames(lapply(seq_len(ncol(v)), function(j) as.vector(v[, j])),
             paste0(nm, lab))
  })

  return(as.data.frame(unlist(cols, recursive = FALSE), check.names = FALSE,
                       stringsAsFactors = FALSE))
}

# ------------------------------------------------------------------------------

#' Weighted Column Means
#'
#' Computes the weighted mean of each column.
#' @param m [mandatory] (matrix) Numeric matrix.
#' @param w [mandatory] (numeric) Weights.
#' @return A numeric vector with one element per column.
#' @keywords internal
#'
weighted_colmeans <- function(m, w) {
  colSums(m * w) / sum(w)
}

# ------------------------------------------------------------------------------

#' Weighted Covariance Matrix
#'
#' Computes the weighted covariance of the columns, normalised by the sum of
#' the weights.
#' @param m [mandatory] (matrix) Numeric matrix.
#' @param w [mandatory] (numeric) Weights.
#' @return A square matrix.
#' @keywords internal
#'
weighted_cov <- function(m, w) {

  centred <- sweep(m, 2L, weighted_colmeans(m, w))

  return(crossprod(centred * sqrt(w)) / sum(w))
}

# ------------------------------------------------------------------------------

#' Sandwich Covariance of an Estimating Equation
#'
#' Computes \eqn{J^{-1} B J^{-1}} for per-observation scores \code{psi} and
#' Jacobian \code{J}, with cluster sums and the small-sample factor
#' \eqn{G / (G - 1)} when \code{cluster} is given.
#' @param psi [mandatory] (matrix) Scores, one row per observation.
#' @param J [mandatory] (matrix) Jacobian.
#' @param cluster [optional] (vector) Cluster identifier (default:
#'   \code{NULL}).
#' @return A symmetric covariance matrix.
#' @keywords internal
#'
sandwich_vcov <- function(psi, J, cluster = NULL) {

  Jinv <- solve(J)

  # Meat of the sandwich, summed within clusters if given
  if (is.null(cluster)) {
    meat <- crossprod(psi)
  } else {
    sums <- rowsum(psi, cluster, reorder = FALSE)
    g <- nrow(sums)
    meat <- crossprod(sums) * g / (g - 1)
  }

  v <- Jinv %*% meat %*% t(Jinv)

  return((v + t(v)) / 2)
}

# ------------------------------------------------------------------------------

#' Design Matrix for Linear Learners
#'
#' Builds treatment-coded dummies for factor controls and raw powers up to
#' \code{degree} for numeric controls. Rows are never dropped: a level not
#' seen in the training data gets zero dummies (the first level), and a
#' missing value gives missing dummies.
#' @param x [mandatory] (data.frame) Controls.
#' @param degree [optional] (integer) Highest power of each numeric control
#'   (default: \code{1}).
#' @param xlev [optional] (list) Factor levels from the training data
#'   (default: \code{NULL}).
#' @return A numeric matrix without an intercept column and with one row per
#'   row of \code{x}.
#' @keywords internal
#'
design_matrix <- function(x, degree = 1L, xlev = NULL) {

  if (ncol(x) == 0L) {
    return(matrix(numeric(0), nrow(x), 0L))
  }

  num <- vapply(x, is.numeric, TRUE)
  pieces <- list()

  # Dummies for factor, character and logical controls
  for (nm in names(x)[!num]) {
    v <- as.character(x[[nm]])
    lev <- if (!is.null(xlev[[nm]])) xlev[[nm]] else levels(factor(x[[nm]]))
    dm <- matrix(numeric(0), length(v), 0L)
    if (length(lev) > 1L) {
      dm <- vapply(lev[-1L], function(l) as.numeric(v == l),
                   numeric(length(v)))
      dm <- matrix(dm, nrow = length(v),
                   dimnames = list(NULL, paste0(nm, lev[-1L])))
    }
    pieces <- c(pieces, list(dm))
  }

  # Raw powers of numeric controls
  if (any(num)) {
    xn <- as.matrix(x[, num, drop = FALSE])
    pw <- lapply(seq_len(degree), function(d) {
      out <- xn^d
      colnames(out) <- paste0(colnames(xn),
                              if (d > 1L) paste0("^", d) else "")
      out
    })
    pieces <- c(pieces, pw)
  }

  return(do.call(cbind, pieces))
}

# ------------------------------------------------------------------------------

#' Levels of Factor Controls
#'
#' Records the levels of the non-numeric controls.
#' @param x [mandatory] (data.frame) Controls.
#' @return A named list of character vectors.
#' @keywords internal
#'
factor_levels <- function(x) {

  num <- vapply(x, is.numeric, TRUE)

  return(lapply(x[, !num, drop = FALSE], function(v) levels(factor(v))))
}

# ------------------------------------------------------------------------------

#' One-Hot Coding of Observed Labels
#'
#' Codes observed labels against the categories of a probability matrix.
#' Missing labels give rows of \code{NA}.
#' @param labels [mandatory] (vector) Observed labels.
#' @param categories [mandatory] (character) Category names.
#' @return A 0/1 matrix with one column per category.
#' @keywords internal
#'
one_hot <- function(labels, categories) {

  idx <- match(as.character(labels), categories)
  if (anyNA(idx[!is.na(labels)])) {
    bad <- unique(as.character(labels)[is.na(idx) & !is.na(labels)])
    stop_input("Labels not found among the categories (%s): %s.",
               paste(categories, collapse = ", "), paste(bad, collapse = ", "))
  }

  out <- matrix(0, length(labels), length(categories),
                dimnames = list(NULL, categories))
  out[cbind(seq_along(labels), idx)] <- 1
  out[is.na(idx), ] <- NA

  return(out)
}

# ------------------------------------------------------------------------------

#' Format p-Values
#'
#' Formats p-values with three significant digits and a floor of
#' \code{1e-4}.
#' @param p [mandatory] (numeric) p-values.
#' @return A character vector.
#' @keywords internal
#'
format_p <- function(p) {
  format.pval(p, digits = 3, eps = 1e-4)
}

# ------------------------------------------------------------------------------

#' Format p-Values in Text
#'
#' Formats p-values for running text as \code{"p = 0.0123"} or
#' \code{"p < 1e-04"}.
#' @param p [mandatory] (numeric) p-values.
#' @return A character vector.
#' @keywords internal
#'
p_text <- function(p) {

  fp <- format_p(p)
  small <- startsWith(fp, "<")

  return(ifelse(small, paste("p <", sub("^<\\s*", "", fp)),
                paste("p =", fp)))
}
