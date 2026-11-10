# Resolve an Optional Per-Row Vector

Turns an argument given as `NULL`, a vector, a column name of `data` or
a one-sided formula evaluated in `data` into a vector.

## Usage

``` r
resolve_vector(x, data, n, what)
```

## Arguments

- x:

  \[mandatory\] (vector, character, formula or `NULL`) The argument.

- data:

  \[mandatory\] (data.frame or `NULL`) Data frame for column names and
  formulas.

- n:

  \[mandatory\] (integer) Expected length.

- what:

  \[mandatory\] (character) Argument name used in error messages.

## Value

A vector of length `n`, or `NULL`.
