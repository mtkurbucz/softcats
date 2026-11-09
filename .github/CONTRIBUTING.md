# Contributing to softcats

## Bug reports

Please open an issue with a minimal reproducible example, preferably made
with [reprex](https://reprex.tidyverse.org), and the output of
`sessionInfo()`.

## Pull requests

* Open an issue first for changes beyond small fixes, so that the change can
  be discussed before work starts.
* Follow the style of the existing code: roxygen documentation without
  markdown, `[mandatory]`/`[optional]` argument descriptions with types and
  defaults, lines of at most 80 characters.
* Add tests with testthat for new behaviour and run
  `R CMD check --as-cran` before submitting.
* Add a bullet to `NEWS.md` describing the change.
