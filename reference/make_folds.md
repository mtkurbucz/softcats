# Assign Observations to Cross-Fitting Folds

Draws balanced random folds. Whole clusters stay in one fold.

## Usage

``` r
make_folds(n, folds, cluster = NULL)
```

## Arguments

- n:

  \[mandatory\] (integer) Number of observations.

- folds:

  \[mandatory\] (integer) Number of folds.

- cluster:

  \[optional\] (vector) Cluster identifier (default: `NULL`).

## Value

An integer vector of fold indices of length `n`.
