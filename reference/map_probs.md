# Probabilities from a Multinomial Logit

Computes class probabilities from the regressors, the offset and the
coefficients of a multinomial logit with the first category as the
reference.

## Usage

``` r
map_probs(Z, offset, B)
```

## Arguments

- Z:

  \[mandatory\] (matrix) Regressors.

- offset:

  \[mandatory\] (matrix) Offset, one column per non-reference category.

- B:

  \[mandatory\] (matrix) Coefficients, one column per non-reference
  category.

## Value

A matrix of class probabilities, reference first.
