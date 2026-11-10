# Resolve the Class Probabilities

Turns the `probs` argument into a numeric matrix with one column per
category.

## Usage

``` r
resolve_probs(probs, data, n)
```

## Arguments

- probs:

  \[mandatory\] (matrix, data.frame, character, formula or numeric)
  Class probabilities in any form accepted by
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).

- data:

  \[mandatory\] (data.frame or `NULL`) Data frame for column names and
  formulas.

- n:

  \[mandatory\] (integer) Expected number of rows.

## Value

A list with the matrix `mat`, the form of the input `spec` and the input
itself `raw`.
