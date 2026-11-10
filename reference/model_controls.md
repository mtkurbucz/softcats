# Evaluate the Controls of a Fit in Other Data

Evaluates the right-hand side of a model formula in other data. The
stored terms reproduce data-dependent bases such as
[`poly()`](https://rdrr.io/r/stats/poly.html), and matrix-valued terms
are split into single columns as in
[`controls_frame()`](https://mtkurbucz.github.io/softcats/reference/controls_frame.md).

## Usage

``` r
model_controls(terms, data)
```

## Arguments

- terms:

  \[mandatory\] (terms) Terms of the fit without the response.

- data:

  \[mandatory\] (data.frame) Data.

## Value

A data frame of controls with one row per row of `data`.
