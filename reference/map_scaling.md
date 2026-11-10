# Standardisation of the Map Features

Records the means and standard deviations of the log-odds and of the
design of the controls in the labelled sample.

## Usage

``` r
map_scaling(P, Xd)
```

## Arguments

- P:

  \[mandatory\] (matrix) Class probabilities, reference first.

- Xd:

  \[mandatory\] (matrix) Design matrix of the controls.

## Value

A list with elements `L` and `X`, each holding `centre` and `scale`.
