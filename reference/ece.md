# Expected Calibration Error

Computes the weighted mean absolute gap between the binned frequencies
and probabilities.

## Usage

``` r
ece(y, p, w, bins)
```

## Arguments

- y:

  \[mandatory\] (numeric) 0/1 indicator of the category.

- p:

  \[mandatory\] (numeric) Probability of the category.

- w:

  \[mandatory\] (numeric) Observation weights.

- bins:

  \[mandatory\] (integer) Number of equal-width bins.

## Value

A single number.
