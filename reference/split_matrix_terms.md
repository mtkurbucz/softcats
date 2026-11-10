# Split Matrix-Valued Terms into Columns

Replaces each matrix-valued column of a model frame, such as the basis
of [`poly()`](https://rdrr.io/r/stats/poly.html), by one column per
basis function.

## Usage

``` r
split_matrix_terms(x)
```

## Arguments

- x:

  \[mandatory\] (data.frame) Columns of a model frame.

## Value

A data frame without matrix-valued columns.
