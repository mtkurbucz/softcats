# Log-Odds Against the Reference Category

Computes the log-odds of each category against the first, with the
probabilities bounded below by `1e-6`.

## Usage

``` r
log_odds(P)
```

## Arguments

- P:

  \[mandatory\] (matrix) Class probabilities, reference first.

## Value

A matrix with one column per non-reference category.
