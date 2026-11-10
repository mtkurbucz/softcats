# Validate and Normalise Class Probabilities

Checks that the probabilities are finite, lie in \\\[0, 1\]\\ and sum to
one in every row up to a tolerance, then clips and renormalises them.

## Usage

``` r
validate_probs(mat, tol = 1e-04)
```

## Arguments

- mat:

  \[mandatory\] (matrix) Class probabilities.

- tol:

  \[optional\] (numeric) Tolerance (default: `1e-4`).

## Value

The clipped and renormalised matrix.
