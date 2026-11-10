# Eigen-Decomposition of the Score Information

Computes the eigenvalues and eigenvectors of \\M = E\[a a^\top\]\\ and
the canonical shares, the eigenvalues of \\C^{-1/2} M C^{-1/2}\\ with
\\C\\ the covariance of the scores.

## Usage

``` r
compute_spectrum(M, C)
```

## Arguments

- M:

  \[mandatory\] (matrix) Normalised Jacobian \\E\[a a^\top\]\\.

- C:

  \[mandatory\] (matrix) Weighted covariance of the scores.

## Value

A list with `values`, `vectors`, `shares`, `min_share`, `condition`, `M`
and `score_cov`.
