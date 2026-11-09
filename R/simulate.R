# Main Function ----------------------------------------------------------------

#' Simulate Data with Calibrated Class Probabilities
#'
#' Generates data that satisfy the assumptions of \code{\link{soft_lm}()},
#' with options to break them. It is used in the examples, the tests and the
#' vignette.
#' @param n [optional] (integer) Number of observations (default:
#'   \code{2000}).
#' @param K [optional] (integer) Number of categories (default: \code{2}).
#' @param tau [optional] (numeric) Effects of categories 2 to \code{K}
#'   relative to category 1. \code{NULL} uses the first \code{K - 1} values
#'   of \code{c(1, -0.5, 0.75, -0.25, 0.5)}, recycled (default:
#'   \code{NULL}).
#' @param n_controls [optional] (integer) Number of controls (default:
#'   \code{3}).
#' @param concentration [optional] (numeric) Dirichlet concentration; smaller
#'   values give more dispersed probabilities and more information beyond the
#'   controls (default: \code{5}).
#' @param z_effect [optional] (numeric) Effect of \eqn{Z} on the class
#'   probabilities (default: \code{1.5}).
#' @param direct_effect [optional] (numeric) Direct effect of \eqn{Z} on the
#'   outcome (default: \code{0}).
#' @param miscalibration [optional] (numeric) Strength of the conditional
#'   miscalibration of the returned probabilities (default: \code{0}).
#' @param nonlinear [optional] (logical) If \code{TRUE}, the outcome
#'   regression and the class probabilities are non-linear in the controls
#'   (default: \code{FALSE}).
#' @param labelled_share [optional] (numeric) Share of observations flagged
#'   in column \code{labelled}, for use as a labelled sample (default:
#'   \code{0.2}).
#' @param seed [optional] (integer) Seed. The random number generator state
#'   of the session is restored afterwards (default: \code{NULL}).
#' @details The controls \eqn{X} are independent standard normal variables,
#'   and \eqn{Z} is a standard normal classifier feature that is not a
#'   control. Class probabilities are drawn as \eqn{p \sim
#'   \mathrm{Dirichlet}(c\, \pi(X, Z))}, where \eqn{\pi} is a multinomial
#'   logit in \eqn{X} and \eqn{Z} and \eqn{c} is \code{concentration}. The
#'   group is drawn from \eqn{p}, so the probabilities are calibrated given
#'   \eqn{X} by construction. The outcome is \eqn{Y = \mu(X) + \sum_k \tau_k
#'   1\{G = k\} + \theta Z + \varepsilon} with \eqn{\varepsilon \sim N(0,
#'   1)} and \eqn{\theta} = \code{direct_effect}.
#'
#'   With \code{miscalibration} different from zero, the returned
#'   probabilities are distorted: the logit of the second category is shifted
#'   by \code{miscalibration * x1}, so they are no longer calibrated given
#'   \eqn{X}. With \code{direct_effect} different from zero, \eqn{Z} affects
#'   the outcome directly and the exclusion restriction fails.
#' @return A data frame with the outcome \code{y}, controls \code{x1},
#'   \code{x2}, ..., the classifier feature \code{z}, the latent group
#'   \code{group} (a factor with levels \code{A}, \code{B}, ...),
#'   probabilities \code{prob_A}, \code{prob_B}, ... and a logical
#'   \code{labelled}. Attributes: \code{tau} (the true effects),
#'   \code{m_true} (the true \eqn{E[Y \mid X]}) and \code{r_true} (the true
#'   \eqn{E[p \mid X]} of the calibrated probabilities), computed by
#'   Gauss-Hermite quadrature over \eqn{Z}.
#' @export
#' @examples
#' # Example: Three categories with the true effects
#' d <- sim_softcats(n = 500, K = 3, seed = 11)
#' head(d)
#' attr(d, "tau")
#' @importFrom stats rgamma rnorm runif setNames
#'
sim_softcats <- function(n = 2000L, K = 2L, tau = NULL, n_controls = 3L,
                         concentration = 5, z_effect = 1.5, direct_effect = 0,
                         miscalibration = 0, nonlinear = FALSE,
                         labelled_share = 0.2, seed = NULL) {

  # Validate the arguments
  K <- as.integer(K)
  n <- as.integer(n)
  d <- as.integer(n_controls)
  if (K < 2L) stop_input("`K` must be at least 2.")
  if (d < 1L) stop_input("`n_controls` must be at least 1.")
  tau <- tau %||% rep_len(c(1, -0.5, 0.75, -0.25, 0.5), K - 1L)
  if (length(tau) != K - 1L) {
    stop_input("`tau` must have length K - 1 = %d.", K - 1L)
  }
  levels_ <- if (K <= 26L) LETTERS[seq_len(K)] else paste0("C", seq_len(K))

  # Coefficients of the multinomial logit
  beta <- matrix(rep_len(c(0.6, -0.4, 0.3, 0.2, -0.2), d * (K - 1L)),
                 d, K - 1L)
  beta <- sweep(beta, 2L, (-1)^(seq_len(K - 1L) + 1L), `*`)
  gamma <- z_effect * rep_len(c(1, -1, 0.5, -0.5), K - 1L)

  index <- function(X, z) {
    lin <- X %*% beta + outer(z, gamma)
    if (nonlinear) lin[, 1L] <- lin[, 1L] + 0.5 * (X[, min(2L, d)]^2 - 1)
    cbind(0, lin)
  }
  softmax <- function(e) {
    e <- e - apply(e, 1L, max)
    ex <- exp(e)
    ex / rowSums(ex)
  }
  mu_fun <- function(X) {
    mu <- drop(X %*% rep_len(c(1, 0.5, -0.5), d))
    if (nonlinear) mu <- mu + sin(2 * X[, 1L])
    mu
  }

  # Draw the controls, probabilities, groups and outcome
  with_seed(seed, {
    X <- matrix(rnorm(n * d), n, d,
                dimnames = list(NULL, paste0("x", seq_len(d))))
    z <- rnorm(n)
    pi_ <- softmax(index(X, z))
    gam <- matrix(rgamma(n * K, shape = concentration * pi_), n, K)
    gam <- pmax(gam, 1e-12)
    p <- gam / rowSums(gam)
    cp <- t(apply(p, 1L, cumsum))
    u <- runif(n)
    G <- pmin(1L + rowSums(cp < u), K)
    onehot <- matrix(0, n, K)
    onehot[cbind(seq_len(n), G)] <- 1
    y <- mu_fun(X) + drop(onehot[, -1L, drop = FALSE] %*% tau) +
      direct_effect * z + rnorm(n)
    p_obs <- p
    if (miscalibration != 0) {
      lp <- log(p)
      lp[, 2L] <- lp[, 2L] + miscalibration * X[, 1L]
      p_obs <- softmax(lp)
    }
    labelled <- runif(n) < labelled_share
  })

  # True nuisances: E[p | X] = E_Z[pi(X, Z)] by Gauss-Hermite quadrature
  gh <- gauss_hermite(40L)
  r_true <- Reduce(`+`, lapply(seq_along(gh$nodes), function(i) {
    gh$weights[i] * softmax(index(X, rep(gh$nodes[i], n)))
  }))
  colnames(r_true) <- levels_
  m_true <- mu_fun(X) + drop(r_true[, -1L, drop = FALSE] %*% tau)

  # Assemble the data frame
  probs <- p_obs
  colnames(probs) <- paste0("prob_", levels_)
  out <- data.frame(y = y, X, z = z,
                    group = factor(levels_[G], levels = levels_),
                    probs, labelled = labelled)
  attr(out, "tau") <- setNames(tau, levels_[-1L])
  attr(out, "m_true") <- m_true
  attr(out, "r_true") <- r_true

  return(out)
}

# Internal Functions -----------------------------------------------------------

#' Gauss-Hermite Quadrature for the Standard Normal
#'
#' Computes nodes and weights for \eqn{E[f(Z)]}, \eqn{Z \sim N(0, 1)}, with
#' the Golub-Welsch algorithm.
#' @param k [mandatory] (integer) Number of nodes.
#' @return A list with \code{nodes} and \code{weights}.
#' @keywords internal
#'
gauss_hermite <- function(k) {

  J <- matrix(0, k, k)
  off <- sqrt(seq_len(k - 1L))
  J[cbind(seq_len(k - 1L), 2:k)] <- off
  J[cbind(2:k, seq_len(k - 1L))] <- off
  e <- eigen(J, symmetric = TRUE)

  return(list(nodes = e$values, weights = e$vectors[1L, ]^2))
}
