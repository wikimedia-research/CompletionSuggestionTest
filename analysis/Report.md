


## Introduction

The **completion suggester** is meant to replace prefix searching, with the aim of increasing recall. Completion suggester benefits include: less typos suggested (e.g. if the redirect is close to the canonical title we will display the canonical title), fuzzy searching, and ignoring stop words. The drawbacks of completion suggester are: precision is sometimes very bad because the scoring formula is not well designed for some kind of pages, fuzzy searching can display weird results, and page titles with punctuation or special characters only are not searchable.

## Methods

### Data

On every page load we do a 1 in 10,000 check, and if passed for that one page view then the user gets entered into the test as a control. If the check failed, we do another draw (1 in 9,999) for entering the user into the test as a test subject, with the completion suggester instead of prefix searching.

### Analysis

We performed the analysis using Bayesian methods for categorical data in the software R using packages and code by Albert (2014), Overstall and King (2014), and Agresti and Min (2005).

## Results

### Data validation

![](Report_files/figure-html/bucketing_differences-1.png) ![](Report_files/figure-html/bucketing_differences-2.png) 

### Overall results

![](Report_files/figure-html/overall-1.png) 

![](Report_files/figure-html/last_event-1.png) 



|                                       |Value          |Comment                          |
|:--------------------------------------|:--------------|:--------------------------------|
|Bayes Factor                           |**VERY** large.|Very strong evidence against hypothesis of independence. |
|95% C.I. for Difference of Proportions |(0.064, 0.091) |Probability of getting nonzero results goes up by 6.4%-9.1% in the suggester group.|
|95% C.I. for Relative Risk             |(1.082, 1.120) |Suggester group is 1.1-1.2 times more likely to get nonzero results!|
|95% C.I. for Odds Ratio                |(1.531, 1.846) |Odds of suggester group getting nonzero results are 1.5-1.8 times those of controls!|

### Some zero and some nonzero results

![](Report_files/figure-html/searches_within_outcome_some-1.png) 



|                                       |Value            |Comment                          |
|:--------------------------------------|:----------------|:--------------------------------|
|Bayes Factor                           |**VERY** large.  |Very strong evidence against H0. |
|95% C.I. for Difference of Proportions |(-0.157, -0.082) |                                 |
|95% C.I. for Relative Risk             |(0.505, 0.717)   |                                 |
|95% C.I. for Odds Ratio                |(0.411, 0.642)   |                                 |

### All zero results or all nonzero results

![](Report_files/figure-html/searches_within_outcome_all-1.png) 



|                                       |Value          |Comment                          |
|:--------------------------------------|:--------------|:--------------------------------|
|Bayes Factor                           |**VERY** large.|Very strong evidence against H0. |
|95% C.I. for Difference of Proportions |(0.017, 0.038) |                                 |
|95% C.I. for Relative Risk             |(1.019, 1.042) |                                 |
|95% C.I. for Odds Ratio                |(1.298, 1.769) | 

### German Wikipedia vs English Wikipedia

So far we have looked at the results pooled across the two populations of users. In this section, we look at the outcomes for German Wikipedia and English Wikipedia users separately.

![](Report_files/figure-html/bucketing_differences_wiki-1.png) 

#### German Wikipedia



|                                       |Value          |Comment                          |
|:--------------------------------------|:--------------|:--------------------------------|
|Bayes Factor                           |**VERY** large.|Very strong evidence against H0. |
|95% C.I. for Difference of Proportions |(0.063, 0.118) |                                 |
|95% C.I. for Relative Risk             |(1.081, 1.158) |                                 |
|95% C.I. for Odds Ratio                |(1.516, 2.204) |                                 |

#### English Wikipedia



|                                       |Value          |Comment                          |
|:--------------------------------------|:--------------|:--------------------------------|
|Bayes Factor                           |**VERY** large.|Very strong evidence against H0. |
|95% C.I. for Difference of Proportions |(0.058, 0.090) |                                 |
|95% C.I. for Relative Risk             |(1.074, 1.117) |                                 |
|95% C.I. for Odds Ratio                |(1.466, 1.820) |                                 |

## Discussion

## References

Albert, J. (2009, 2014). Bayesian Computation with R. Springer Science & Business Media. http://doi.org/10.1007/978-0-387-92298-0 Accompanying R package: *LearnBayes: Functions for Learning Bayesian Inference* (Version 2.15). URL http://CRAN.R-project.org/package=LearnBayes

Overstall, A. M. and King, R. (2014). conting: An R Package for Bayesian Analysis of Complete and Incomplete Contingency Tables. *Journal of Statistical Software*, **58**(7), 1-27. URL http://www.jstatsoft.org/v58/i07/

Agresti, A., & Min, Y. (2005). Frequentist performance of Bayesian confidence intervals for comparing proportions in 2 x 2 contingency tables. *Biometrics*, **61**(2), 515–523. http://doi.org/10.1111/j.1541-0420.2005.031228.x URL http://www.stat.ufl.edu/~aa/cda/R/bayes/bayes.html

R Core Team (2015). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. URL https://www.R-project.org/.
