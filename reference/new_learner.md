# Construct a Learner

Creates an object of class `softcats_learner`.

## Usage

``` r
new_learner(name, fit, predict, details = list())
```

## Arguments

- name:

  \[mandatory\] (character) Label shown in printed output.

- fit:

  \[mandatory\] (function) Fitting function `function(x, y, w)`.

- predict:

  \[mandatory\] (function) Prediction function
  `function(model, newdata)`.

- details:

  \[optional\] (list) Settings stored with the learner (default:
  [`list()`](https://rdrr.io/r/base/list.html)).

## Value

An object of class `softcats_learner`.
