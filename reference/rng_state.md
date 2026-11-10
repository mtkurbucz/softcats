# Get the State of the Random Number Generator

Returns the current state of the random number generator of the session
without changing it.

## Usage

``` r
rng_state()
```

## Value

The value of `.Random.seed`, or `NULL` if it does not exist.
