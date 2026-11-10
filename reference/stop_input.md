# Signal an Input Error

Formats a message with
[`sprintf()`](https://rdrr.io/r/base/sprintf.html) and stops without the
call.

## Usage

``` r
stop_input(...)
```

## Arguments

- ...:

  \[mandatory\] Format string and values passed to
  [`sprintf()`](https://rdrr.io/r/base/sprintf.html).

## Value

No return value, called for its error.
