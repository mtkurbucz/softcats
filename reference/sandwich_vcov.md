# Sandwich Covariance of an Estimating Equation

Computes \\J^{-1} B J^{-1}\\ for per-observation scores `psi` and
Jacobian `J`, with cluster sums and the small-sample factor \\G / (G -
1)\\ when `cluster` is given.

## Usage

``` r
sandwich_vcov(psi, J, cluster = NULL)
```

## Arguments

- psi:

  \[mandatory\] (matrix) Scores, one row per observation.

- J:

  \[mandatory\] (matrix) Jacobian.

- cluster:

  \[optional\] (vector) Cluster identifier (default: `NULL`).

## Value

A symmetric covariance matrix.
