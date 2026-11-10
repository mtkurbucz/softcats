# Evaluate Code with a Temporary Seed

Evaluates `code` after setting the seed and restores the random number
generator state of the session afterwards. With `seed = NULL`, the code
is evaluated without changing the state.

## Usage

``` r
with_seed(seed, code)
```

## Arguments

- seed:

  \[mandatory\] (integer or `NULL`) Seed.

- code:

  \[mandatory\] (expression) Code to evaluate.

## Value

The value of `code`.
