# Match Probability Columns to the Categories of a Fit

Checks that the probabilities have the categories of the fit and puts
their columns in the order of the fit.

## Usage

``` r
match_categories(mat, categories)
```

## Arguments

- mat:

  \[mandatory\] (matrix) Class probabilities with named columns.

- categories:

  \[mandatory\] (character) Categories of the fit, reference first.

## Value

The matrix with its columns in the order of `categories`.
