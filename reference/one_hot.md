# One-Hot Coding of Observed Labels

Codes observed labels against the categories of a probability matrix.
Missing labels give rows of `NA`.

## Usage

``` r
one_hot(labels, categories)
```

## Arguments

- labels:

  \[mandatory\] (vector) Observed labels.

- categories:

  \[mandatory\] (character) Category names.

## Value

A 0/1 matrix with one column per category.
