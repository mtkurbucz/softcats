# Gauss-Hermite Quadrature for the Standard Normal

Computes nodes and weights for \\E\[f(Z)\]\\, \\Z \sim N(0, 1)\\, with
the Golub-Welsch algorithm.

## Usage

``` r
gauss_hermite(k)
```

## Arguments

- k:

  \[mandatory\] (integer) Number of nodes.

## Value

A list with `nodes` and `weights`.
