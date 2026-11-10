# Grade a p-Value

Grades a p-value as `"problem"` below 0.001, `"warning"` below 0.05 or
if it is not finite, and `"ok"` otherwise.

## Usage

``` r
grade_p(p)
```

## Arguments

- p:

  \[mandatory\] (numeric) A p-value.

## Value

A character string.
