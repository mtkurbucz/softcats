# Largest Calibration Gap

Computes the largest calibration gap over subgroups (or score bins), raw
and net of sampling noise. The adjusted gap subtracts a
Bonferroni-corrected multiple of the standard error of the cell gap
under perfect calibration, so it is zero when no cell departs from
calibration by more than chance.

## Usage

``` r
max_gap(y, p, w, by, bins, min_cell)
```

## Arguments

- y:

  \[mandatory\] (numeric) 0/1 indicator of the category.

- p:

  \[mandatory\] (numeric) Probability of the category.

- w:

  \[mandatory\] (numeric) Observation weights.

- by:

  \[mandatory\] (factor or `NULL`) Subgroups; `NULL` uses score bins.

- bins:

  \[mandatory\] (integer) Number of equal-width bins.

- min_cell:

  \[mandatory\] (integer) Smallest cell size used.

## Value

A named vector with elements `raw` and `adjusted`.
