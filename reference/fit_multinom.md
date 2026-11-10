# Fit a Multinomial Logit by Newton-Raphson

Maximises the weighted log-likelihood of a multinomial logit with an
offset, starting from zero coefficients, with step halving. Columns of
`Z` that are collinear in the data get zero coefficients.

## Usage

``` r
fit_multinom(Z, Y, offset, w, maxit = 100L, tol = 1e-10)
```

## Arguments

- Z:

  \[mandatory\] (matrix) Regressors.

- Y:

  \[mandatory\] (matrix) 0/1 indicators of the categories, reference
  first.

- offset:

  \[mandatory\] (matrix) Offset, one column per non-reference category.

- w:

  \[mandatory\] (numeric) Observation weights.

- maxit:

  \[optional\] (integer) Maximum number of iterations (default: `100`).

- tol:

  \[optional\] (numeric) Relative change of the log-likelihood at which
  the iterations stop (default: `1e-10`).

## Value

A list with the coefficients `coefficients` (one column per
non-reference category), the log-likelihood `loglik`, the indicator
`converged` and the number of iterations `iterations`.
