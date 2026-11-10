# Nuisance Learners

Learners estimate the two nuisance functions of
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md):
the outcome regression \\m(X) = E\[Y \mid X\]\\ and the score
regressions \\r_k(X) = E\[p_k \mid X\]\\. Each learner is an object of
class `softcats_learner` that knows how to fit a regression of a numeric
response on a data frame of controls and how to predict from that fit.
All learners accept observation weights.

- `lrn_ranger()` fits a random forest with ranger. It is the default
  because valid inference requires the nuisances to be estimated well,
  and both nuisances are typically non-linear.

- `lrn_lm()` fits least squares on the controls, optionally with raw
  polynomial terms of the numeric controls. It is fast and
  deterministic, and appropriate when the nuisances are close to
  polynomial.

- `lrn_glmnet()` fits a penalised regression with glmnet on a polynomial
  expansion of the controls, with the penalty chosen by
  cross-validation.

- `lrn_custom()` wraps any user-supplied pair of fit and predict
  functions.

## Usage

``` r
lrn_ranger(
  num.trees = 500L,
  mtry = NULL,
  min.node.size = NULL,
  num.threads = 1L,
  ...
)

lrn_lm(degree = 1L)

lrn_glmnet(alpha = 0, degree = 2L, nfolds = 5L, s = "lambda.min", ...)

lrn_custom(fit, predict, name = "custom")

# S3 method for class 'softcats_learner'
print(x, ...)
```

## Arguments

- num.trees:

  \[optional\] (integer) Number of trees (default: `500`).

- mtry:

  \[optional\] (integer) Number of controls considered at each split,
  capped at the number of controls. `NULL` uses the ranger default
  (default: `NULL`).

- min.node.size:

  \[optional\] (integer) Minimum node size. `NULL` uses the ranger
  default (default: `NULL`).

- num.threads:

  \[optional\] (integer) Number of threads used by ranger. One thread
  keeps results reproducible across machines (default: `1`).

- ...:

  \[optional\] Further arguments passed to
  [`ranger::ranger()`](http://imbs-hl.github.io/ranger/reference/ranger.md)
  or
  [`glmnet::cv.glmnet()`](https://rdrr.io/pkg/glmnet/man/cv.glmnet.html),
  except those set by the learner (`x`, `y`, the weights, `seed` and
  `verbose`). Use the `seed` argument of
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
  for reproducible forests.

- degree:

  \[optional\] (integer) Highest power of each numeric control in the
  design matrix (default: `1` for `lrn_lm()` and `2` for
  `lrn_glmnet()`).

- alpha:

  \[optional\] (numeric) Elastic-net mixing parameter: `0` is ridge, `1`
  is lasso (default: `0`).

- nfolds:

  \[optional\] (integer) Number of folds for the internal
  cross-validation of the penalty (default: `5`).

- s:

  \[optional\] (character or numeric) Value of the penalty used for
  prediction, as in
  [`glmnet::predict.cv.glmnet()`](https://rdrr.io/pkg/glmnet/man/predict.cv.glmnet.html)
  (default: `"lambda.min"`).

- fit:

  \[mandatory\] (function) A function `function(x, y, w)` that returns a
  fitted model. `x` is a data frame of controls, `y` a numeric vector
  and `w` a vector of non-negative weights.

- predict:

  \[mandatory\] (function) A function `function(model, newdata)` that
  returns a numeric vector of predictions.

- name:

  \[optional\] (character) A short label shown in printed output
  (default: `"custom"`).

- x:

  \[mandatory\] (softcats_learner) A learner.

## Value

An object of class `softcats_learner`. The print method returns `x`
invisibly.

## Details

The learner can be different for the two nuisances: pass
`learner = list(m = lrn_ranger(), r = lrn_lm(degree = 2))` to
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).

In `lrn_lm()` and `lrn_glmnet()`, factor and character controls enter as
treatment-coded dummies. A level that does not occur in a training fold
is predicted as the first level.

## Examples

``` r
# Example: Built-in learners
lrn_lm(degree = 2)
#> <softcats learner: lm (degree 2)>
lrn_ranger(num.trees = 200)
#> <softcats learner: ranger>

# Example: Natural splines in the first control, linear in the others
lrn_spline <- lrn_custom(
  fit = function(x, y, w) {
    stats::lm(y ~ splines::ns(x1, df = 4) + x2 + x3,
              data = cbind(x, y = y), weights = w)
  },
  predict = function(model, newdata) {
    stats::predict(model, newdata = newdata)
  },
  name = "natural splines"
)
lrn_spline
#> <softcats learner: natural splines>
```
