# Design Matrix for Linear Learners

Builds treatment-coded dummies for factor controls and raw powers up to
`degree` for numeric controls. Rows are never dropped: a level not seen
in the training data gets zero dummies (the first level), and a missing
value gives missing dummies.

## Usage

``` r
design_matrix(x, degree = 1L, xlev = NULL)
```

## Arguments

- x:

  \[mandatory\] (data.frame) Controls.

- degree:

  \[optional\] (integer) Highest power of each numeric control (default:
  `1`).

- xlev:

  \[optional\] (list) Factor levels from the training data (default:
  `NULL`).

## Value

A numeric matrix without an intercept column and with one row per row of
`x`.
