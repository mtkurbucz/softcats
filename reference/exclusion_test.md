# Test Whether Classifier Features Affect the Outcome Directly

The classifier behind the probabilities must use features beyond the
controls, and these features must affect the outcome only through the
group. If an extra feature has its own effect on the outcome, the model
of
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
is misspecified and the estimate is biased. On labelled data this is
testable: `exclusion_test()` regresses the outcome on the observed
group, the controls and the extra features by least squares, and reports
a robust Wald test that the coefficients of the extra features are zero.

## Usage

``` r
exclusion_test(
  formula,
  group,
  extra,
  data,
  reference = NULL,
  weights = NULL,
  cluster = NULL
)

# S3 method for class 'softcats_exclusion'
print(x, digits = 3L, ...)
```

## Arguments

- formula:

  \[mandatory\] (formula) A formula `outcome ~ controls`, as in
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).

- group:

  \[mandatory\] (vector or character) Observed category labels: a vector
  or a column name of `data`.

- extra:

  \[mandatory\] (formula or character) The classifier features that are
  not controls: a one-sided formula or a character vector of column
  names.

- data:

  \[mandatory\] (data.frame) A data frame of labelled observations.

- reference:

  \[optional\] (character) Reference level of `group`. `NULL` uses the
  first level (default: `NULL`).

- weights:

  \[optional\] (numeric, character or formula) Observation weights
  (default: `NULL`).

- cluster:

  \[optional\] (vector, character or formula) Cluster identifier for
  cluster-robust standard errors. Without clusters the standard errors
  are HC1, with the factor \\n / (n - p)\\ for \\p\\ regressors; with
  clusters they are CR1, with the factors \\(n - 1) / (n - p)\\ and \\G
  / (G - 1)\\ for \\G\\ clusters (default: `NULL`).

- x:

  \[mandatory\] (softcats_exclusion) Result of `exclusion_test()`.

- digits:

  \[optional\] (integer) Number of significant digits to print (default:
  `3`).

- ...:

  \[optional\] Not used.

## Value

An object of class `softcats_exclusion` with the Wald `statistic`, its
degrees of freedom `df`, the `p.value`, the `coefficients` of the extra
features and `nobs`. The print method returns `x` invisibly.

## Details

The test is linear in the extra features and in the terms of `formula`.
Add transformations to `formula` or `extra` to test other forms of
dependence.

## Examples

``` r
# Example: The classifier feature z affects the outcome directly
d <- sim_softcats(n = 3000, K = 2, direct_effect = 0.5, seed = 8)
lab <- d[d$labelled, ]
exclusion_test(y ~ x1 + x2 + x3, group = "group", extra = ~ z, data = lab)
#> Direct-effect test for the classifier features (590 labelled observations)
#> 
#>  term estimate std.error statistic  p.value
#>     z    0.432     0.046      9.39 6.21e-21
#> 
#> Wald chi-squared = 88.1 on 1 df, p < 1e-04 (HC1 standard errors)
#> The extra features predict the outcome beyond the group and the controls,
#> which violates the exclusion restriction of soft_lm(). Move them into the
#> controls or use a classifier without them.
```
