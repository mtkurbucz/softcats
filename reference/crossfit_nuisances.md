# Cross-Fit the Nuisance Functions

Estimates the outcome regression \\m(X)\\ and the score regressions
\\r_k(X)\\ out of fold.

## Usage

``` r
crossfit_nuisances(y, Pq, x, w, fold_id, learners)
```

## Arguments

- y:

  \[mandatory\] (numeric) Outcome.

- Pq:

  \[mandatory\] (matrix) Class probabilities without the reference
  column.

- x:

  \[mandatory\] (data.frame) Controls.

- w:

  \[mandatory\] (numeric) Observation weights.

- fold_id:

  \[mandatory\] (integer) Fold index of each observation.

- learners:

  \[mandatory\] (list) Learners `m` and `r`.

## Value

A list with the out-of-fold predictions `m_hat` (vector) and `r_hat`
(matrix), and `r_states`, the state of the random number generator
before each score regression (by fold, then column).
