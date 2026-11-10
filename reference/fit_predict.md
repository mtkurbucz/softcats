# Fit a Learner and Predict Held-Out Rows

Fits the learner on the training rows and predicts the test rows.
Without controls, the prediction is the weighted mean of the training
response.

## Usage

``` r
fit_predict(learner, x, y, w, train, test)
```

## Arguments

- learner:

  \[mandatory\] (softcats_learner) Learner.

- x:

  \[mandatory\] (data.frame) Controls.

- y:

  \[mandatory\] (numeric) Response.

- w:

  \[mandatory\] (numeric) Observation weights.

- train:

  \[mandatory\] (integer) Indices of the training rows.

- test:

  \[mandatory\] (integer) Indices of the test rows.

## Value

A numeric vector of predictions for the test rows.
