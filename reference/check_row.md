# One Row of the Diagnostic Report

Creates a one-row data frame for the summary of
[`soft_check()`](https://mtkurbucz.github.io/softcats/reference/soft_check.md).

## Usage

``` r
check_row(check, status, detail)
```

## Arguments

- check:

  \[mandatory\] (character) Name of the check.

- status:

  \[mandatory\] (character) `"ok"`, `"warning"` or `"problem"`.

- detail:

  \[mandatory\] (character) Short description of the result.

## Value

A data frame with one row.
