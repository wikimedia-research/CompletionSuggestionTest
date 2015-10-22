


## Introduction

The **completion suggester** is meant to replace prefix searching, with the aim of increasing recall. Completion suggester benefits include: less typos suggested (e.g. if the redirect is close to the canonical title we will display the canonical title), fuzzy searching, and ignoring stop words. The drawbacks of completion suggester are: precision is sometimes very bad because the scoring formula is not well designed for some kinds of pages, fuzzy searching can display weird results, and page titles with punctuation or special characters only are not searchable.

## Methods

### Data

On every page load we do a 1 in 10,000 check, and if passed for that one page view then the user gets entered into the test as a control. If the check failed, we do another draw (1 in 9,999) for entering the user into the test as a test subject, with the completion suggester instead of prefix searching. The events were logged using the [Completion Suggestions](https://meta.wikimedia.org/wiki/Schema:CompletionSuggestions) schema.

### Analysis

We performed the analysis using Bayesian methods for categorical data in the language and environment R, using packages and code by Agresti & Min (2005) and Albert (2014). To obtain the posterior multionomial cell probabilities, we implemented the methods of Fienberg and Holland (1973) in a package which we are working on making available.

## Results

<!-- ### Data Validation -->


As the user is typing their query, they are interacting with the database. This means that we log multiple events throughout a single search session. There are three possible outcomes: all of the events were nonzero results, all of the events were zero results, or a combination of the two. That is, the user may have started typing and nothing was found at first but they kept typing and that's when we started retrieving articles that matched their query.

![](Report_files/figure-html/overall-1.png) 

A greater percentage of users in the test group had a 'nonzero results only' outcome than in the control group (83% in test vs 70% in control).

![](Report_files/figure-html/last_event-1.png) 

When we look at what truly matters (the final outcome of the search session), we see that 85.1% of the searches in the test group ended in nonzero results, compared to the 77.3% of the searches in the control group -- a 7.8% difference!

<table class='table table-condensed contingency' >
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> last event: nonzero result </th>
   <th style="text-align:right;"> last event: zero results </th>
   <th style="text-align:right;"> sum </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> cirrus-suggest </td>
   <td style="text-align:right;"> 4911 (40.9%) </td>
   <td style="text-align:right;"> 857 (7.1%) </td>
   <td style="text-align:right;"> 5768 (48.0%) </td>
  </tr>
  <tr>
   <td style="text-align:left;"> opensearch </td>
   <td style="text-align:right;"> 4834 (40.2%) </td>
   <td style="text-align:right;"> 1418 (11.8%) </td>
   <td style="text-align:right;"> 6252 (52.0%) </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sum </td>
   <td style="text-align:right;"> 9745 (81.1%) </td>
   <td style="text-align:right;"> 2275 (18.9%) </td>
   <td style="text-align:right;"> 12020 (100.0%) </td>
  </tr>
</tbody>
</table>

|&nbsp;                     |&nbsp;              |Comment                          |
|:--------------------------|:-------------------|:--------------------------------|
|Bayes Factor               |**VERY** large.     |Very strong evidence against hypothesis of independence. |
|95% C.I. for Difference    |(0.064,&nbsp;0.091) |Probability of getting nonzero results goes up by 6.4%-9.1% in the suggester group.|
|95% C.I. for Relative Risk |(1.082,&nbsp;1.120) |Suggester group is 1.1-1.2 times more likely to get nonzero results!|
|95% C.I. for Odds Ratio    |(1.531,&nbsp;1.846) |Odds of suggester group getting nonzero results are 1.5-1.8 times those of controls!|

### German Wikipedia vs English Wikipedia

So far we have looked at the results pooled across the two populations of users. In this section, we look at the outcomes for German Wikipedia and English Wikipedia users separately.

![](Report_files/figure-html/bucketing_differences_wiki-1.png) 

#### German Wikipedia

<table class='table table-condensed contingency' >
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> last event: nonzero result </th>
   <th style="text-align:right;"> last event: zero results </th>
   <th style="text-align:right;"> sum </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> cirrus-suggest </td>
   <td style="text-align:right;"> 1225 (40.1%) </td>
   <td style="text-align:right;"> 205 (6.8%) </td>
   <td style="text-align:right;"> 1430 (46.9%) </td>
  </tr>
  <tr>
   <td style="text-align:left;"> opensearch </td>
   <td style="text-align:right;"> 1242 (40.7%) </td>
   <td style="text-align:right;"> 380 (12.4%) </td>
   <td style="text-align:right;"> 1622 (53.1%) </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sum </td>
   <td style="text-align:right;"> 2467 (80.8%) </td>
   <td style="text-align:right;"> 585 (19.2%) </td>
   <td style="text-align:right;"> 3052 (100.0%) </td>
  </tr>
</tbody>
</table>

|&nbsp;                     |&nbsp;              |Comment                          |
|:--------------------------|:-------------------|:--------------------------------|
|Bayes Factor               |**VERY** large.|Very strong evidence against hypothesis of independence|
|95% C.I. for Difference    |(0.063,&nbsp;0.118) |Probability of getting nonzero results goes up by 6.3%-11.8% for *dewiki* users with the completion suggester.|
|95% C.I. for Relative Risk |(1.081,&nbsp;1.158) |The *dewiki* test group is 1.1-1.2 times more likely to get nonzero results than controls.|
|95% C.I. for Odds Ratio    |(1.516,&nbsp;2.204) |Odds of *dewiki* test group getting nonzero results are 1.5-2.2 times those of controls.|

#### English Wikipedia

<table class='table table-condensed contingency' >
 <thead>
  <tr>
   <th style="text-align:left;">   </th>
   <th style="text-align:right;"> last event: nonzero result </th>
   <th style="text-align:right;"> last event: zero results </th>
   <th style="text-align:right;"> sum </th>
  </tr>
 </thead>
<tbody>
  <tr>
   <td style="text-align:left;"> cirrus-suggest </td>
   <td style="text-align:right;"> 3686 (41.1%) </td>
   <td style="text-align:right;"> 652 (7.3%) </td>
   <td style="text-align:right;"> 4338 (48.4%) </td>
  </tr>
  <tr>
   <td style="text-align:left;"> opensearch </td>
   <td style="text-align:right;"> 3592 (40.0%) </td>
   <td style="text-align:right;"> 1038 (11.6%) </td>
   <td style="text-align:right;"> 4630 (51.6%) </td>
  </tr>
  <tr>
   <td style="text-align:left;"> sum </td>
   <td style="text-align:right;"> 7278 (81.1%) </td>
   <td style="text-align:right;"> 1690 (18.9%) </td>
   <td style="text-align:right;"> 8968 (100.0%) </td>
  </tr>
</tbody>
</table>

|&nbsp;                     |&nbsp;              |Comment                          |
|:--------------------------|:-------------------|:--------------------------------|
|Bayes Factor               |**VERY** large.|Very strong evidence against hypothesis of independence. |
|95% C.I. for Difference    |(0.058,&nbsp;0.090) |Probability of getting nonzero results goes up by 5.8%-9% for *enwiki* users with the completion suggester.|
|95% C.I. for Relative Risk |(1.074,&nbsp;1.117) |The *enwiki* test group is 1.07-1.12 times more likely to get nonzero results than controls.|
|95% C.I. for Odds Ratio    |(1.466,&nbsp;1.820) |Odds of *enwiki* test group getting nonzero results are 1.5-1.8 times those of controls.|

## Discussion

We can see that users have a greater outcome of getting results. This does not necessarily equate to a better outcome. The new approach may increase the number of results, for example, while also decreasing the quality of those results. Based on the evidence presented, we recommend looking at clickthrough rates as a basic satisfaction heuristic before we recommend moving forward with the completion suggester.

## References

Albert, J. (2009, 2014). Bayesian Computation with R. Springer Science & Business Media. http://doi.org/10.1007/978-0-387-92298-0 Accompanying R package: *LearnBayes: Functions for Learning Bayesian Inference* (Version 2.15). URL http://CRAN.R-project.org/package=LearnBayes

Agresti, A., and Min, Y. (2005). Frequentist performance of Bayesian confidence intervals for comparing proportions in 2 x 2 contingency tables. *Biometrics*, **61**(2), 515–523. http://doi.org/10.1111/j.1541-0420.2005.031228.x URL http://www.stat.ufl.edu/~aa/cda/R/bayes/bayes.html

Fienberg, S. E., and Holland, P. W. (1973). Simultaneous estimation of multinomial cell probabilities. Journal of the American Statistical Association, **68**, 683-691. URL http://www.jstor.org/stable/2284799

R Core Team (2015). R: A language and environment for statistical computing. R Foundation for Statistical Computing, Vienna, Austria. URL https://www.R-project.org/.
