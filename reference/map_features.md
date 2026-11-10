# Features of the Recalibration Map

Builds the regressors of the map (an intercept, the standardised
log-odds, the standardised controls and, optionally, their products) and
the offset (the log-odds).

## Usage

``` r
map_features(P, Xd, scaling, interactions)
```

## Arguments

- P:

  \[mandatory\] (matrix) Class probabilities, reference first.

- Xd:

  \[mandatory\] (matrix) Design matrix of the controls.

- scaling:

  \[mandatory\] (list) Result of
  [`map_scaling()`](https://mtkurbucz.github.io/softcats/reference/map_scaling.md).

- interactions:

  \[mandatory\] (logical) Whether to include the products of the
  log-odds and the controls.

## Value

A list with the regressors `Z` and the offset `offset`.
