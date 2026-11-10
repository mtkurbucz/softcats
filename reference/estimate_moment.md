# Solve the Orthogonal Moment Equation

Solves \\\sum_i w_i a_i (R_i - a_i^\top \tau) = 0\\ for \\\tau\\, where
\\a = p - \hat r(X)\\ and \\R = Y - \hat m(X)\\, and computes the
sandwich covariance.

## Usage

``` r
estimate_moment(y, Pq, w, m_hat, r_hat, cluster = NULL)
```

## Arguments

- y:

  \[mandatory\] (numeric) Outcome.

- Pq:

  \[mandatory\] (matrix) Class probabilities without the reference
  column.

- w:

  \[mandatory\] (numeric) Observation weights.

- m_hat:

  \[mandatory\] (numeric) Predictions of \\E\[Y \mid X\]\\.

- r_hat:

  \[mandatory\] (matrix) Predictions of \\E\[p \mid X\]\\.

- cluster:

  \[optional\] (vector) Cluster identifier (default: `NULL`).

## Value

A list with the estimate `tau`, its covariance `vcov`, the residualised
scores `a` and outcome `R`, the nuisance predictions and the normalised
Jacobian `M`.
