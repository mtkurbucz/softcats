# Extract the Outcome and the Controls

Evaluates the model formula and returns the outcome and the controls as
a data frame, possibly with zero columns. Matrix-valued terms such as
[`poly()`](https://rdrr.io/r/stats/poly.html) or
[`splines::ns()`](https://rdrr.io/r/splines/ns.html) are split into one
column per basis function.

## Usage

``` r
controls_frame(formula, data)
```

## Arguments

- formula:

  \[mandatory\] (formula) Model formula.

- data:

  \[mandatory\] (data.frame) Data.

## Value

A list with the outcome `y`, the controls `x` and the `terms` object.
