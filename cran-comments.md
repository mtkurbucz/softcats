## Test environments

* local: macOS Sequoia 15.1 (aarch64-apple-darwin20), R 4.5.1
* GitHub Actions: macOS (R-release), Windows (R-release), Ubuntu (R-devel,
  R-release, R-oldrel-1)
* win-builder: Windows Server 2022 x64, R-devel (2026-11-11 r90876 ucrt)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.

The words flagged as possibly misspelled in the Description are names
(Kurbucz, Chernozhukov, and Neyman in "Neyman-orthogonal"), the abbreviation
"et al." and the technical term "heteroskedasticity".

## Random seeds

Functions with a `seed` argument set the seed only when the user supplies one
(the default is `NULL`) and restore the previous state of the random number
generator on exit.

`recalibrate()` refits regressions of a `soft_lm()` fit with the random number
generator states that `soft_lm()` recorded, so that random forests draw the
same random numbers as in the fit. It restores the previous state of the
session on exit.
