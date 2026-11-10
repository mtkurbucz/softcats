# Least Squares on Predicted Labels

Regresses the outcome on the label dummies and the controls entered
linearly, with robust (HC1) or cluster-robust (CR1) standard errors.

## Usage

``` r
hard_ols(object, H)
```

## Arguments

- object:

  \[mandatory\] (softcats) A fit returned by
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).

- H:

  \[mandatory\] (matrix) Label dummies without the reference category.

## Value

A list with the label coefficients `tau` and their covariance `vcov`.
