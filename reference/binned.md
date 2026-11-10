# Binned Probabilities and Frequencies

Computes the weighted mean probability and observed frequency within
equal-width probability bins.

## Usage

``` r
binned(p, y, w, bins)
```

## Arguments

- p:

  \[mandatory\] (numeric) Probability of the category.

- y:

  \[mandatory\] (numeric) 0/1 indicator of the category.

- w:

  \[mandatory\] (numeric) Observation weights.

- bins:

  \[mandatory\] (integer) Number of equal-width bins.

## Value

A data frame with columns `bin`, `probability`, `frequency`, `weight`
and `n`.
