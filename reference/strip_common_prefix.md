# Remove a Shared Prefix from Column Names

Removes a prefix shared by all names (such as `"prob_"` or `".pred_"`),
cut back to the last `"_"` or `"."` inside the shared part. The names
are kept if the result would be empty or duplicated.

## Usage

``` r
strip_common_prefix(x)
```

## Arguments

- x:

  \[mandatory\] (character) Column names.

## Value

A character vector of the same length as `x`.
