# Set the State of the Random Number Generator

Restores a state returned by
[`rng_state()`](https://mtkurbucz.github.io/softcats/reference/rng_state.md).
`NULL` removes the state, as in a session that has not used the
generator.

## Usage

``` r
set_rng_state(state)
```

## Arguments

- state:

  \[mandatory\] (integer or `NULL`) A value of `.Random.seed`.

## Value

`NULL`, invisibly; called for its side effect.
