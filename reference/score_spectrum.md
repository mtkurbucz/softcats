# Information in the Scores Beyond the Controls

Identification in
[`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md)
rests on the matrix \\E\[a a^\top\]\\, the covariance of the class
probabilities after the controls have been partialled out.
`score_spectrum()` reports its eigenvalues and eigenvectors, and the
canonical shares: the eigenvalues of \\E\[a a^\top\]\\ relative to the
covariance of the scores, that is, for each canonical direction, the
fraction of score variance that the controls do not explain.

## Usage

``` r
score_spectrum(object)

# S3 method for class 'softcats_spectrum'
print(x, digits = 3L, ...)
```

## Arguments

- object:

  \[mandatory\] (softcats) A fit returned by
  [`soft_lm()`](https://mtkurbucz.github.io/softcats/reference/soft_lm.md).

- x:

  \[mandatory\] (softcats_spectrum) Result of `score_spectrum()`.

- digits:

  \[optional\] (integer) Number of significant digits to print (default:
  `3`).

- ...:

  \[optional\] Not used.

## Value

An object of class `softcats_spectrum`: a list with `values`
(eigenvalues of \\E\[a a^\top\]\\, decreasing), `vectors` (eigenvectors,
one column per direction), `shares` (canonical shares, decreasing),
`min_share`, `condition` (ratio of the largest to the smallest
eigenvalue), `M` and `score_cov` (covariance of the scores). The print
method returns `x` invisibly.

## Details

A share near zero means that, in that direction, the scores are almost a
function of the controls and the corresponding contrast is weakly
identified. \\E\[a a^\top\]\\ is then nearly singular, and the
eigenvector of its smallest eigenvalue shows which categories the weak
direction involves.

The shares are estimated from the cross-fitted residuals, which also
contain the estimation error of \\E\[p \mid X\]\\. When the controls
explain little of the scores, a share can therefore exceed one slightly.

The canonical shares and the following thresholds are conventions of the
package. As rules of thumb, a smallest share below 0.05 deserves
attention and one below 0.01 means the estimate should not be used. For
two categories the single eigenvalue is the residual score variance
\\V^\*\\.

## References

Kurbucz, M. T. (2026). Coarsening latent-class probabilities:
Directional distortion and coverage loss. arXiv preprint.
[doi:10.48550/arXiv.2608.11784](https://doi.org/10.48550/arXiv.2608.11784)

## Examples

``` r
# Example: Canonical shares with three categories
d <- sim_softcats(n = 2000, K = 3, seed = 4)
fit <- soft_lm(y ~ x1 + x2 + x3, probs = ~ prob_A + prob_B + prob_C,
               data = d, learner = lrn_lm(degree = 3), seed = 4)
score_spectrum(fit)
#> Score information beyond the controls
#> 
#> Canonical shares not explained by the controls (largest first):
#>     1     2 
#> 0.957 0.861 
#> 
#> Eigenvalues of E[aa'] (eigenvectors dir1, dir2, ...):
#>   dir1   dir2 
#> 0.2120 0.0174 
#> 
#> Condition number: 12.2
#> Weakest direction of E[aa'] (loadings on categories, relative to 'A'):
#>     B     C 
#> 0.720 0.693 
#> 
#> Smallest share 0.861 is adequate.
```
