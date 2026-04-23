/*==============================================================================
  HYPERGAMY vs HYPOGAMY: WITHIN-COUPLE PERMANENT INCOME GAP
  Data: cfps_couples_earnings_power_pooled.dta
        (built by mincerian_earning_power.do)

  Purpose:
    Test whether the mean within-couple permanent income gap
    (Wife - Husband) among EDUCATION HYPERGAMOUS couples is larger
    in absolute value than among EDUCATION HYPOGAMOUS couples.

  Definitions (education is categorical / ordinal: wife_edu, husband_edu):
    - Education hypergamous : husband_edu > wife_edu   (wife married "up")
    - Education hypogamous  : wife_edu    > husband_edu (wife married "down")
    - Education homogamous  : wife_edu    = husband_edu (reference, excluded
                                                         from the main contrast)

  Outcome:
    diff_yp = wife_yp - husband_yp  (signed, in yuan; already on file)

  Approach: Descriptives only (no formal test), as requested.
    - Report mean, SD, and N of diff_yp by education-hypergamy group.
    - Compute |mean diff_yp| for hypergamous and hypogamous groups and
      report their difference.

  Prerequisite: master.do (defines $work, $output).
==============================================================================*/

clear all
set more off
set maxvar 10000

* Run master.do if globals are not yet defined
capture confirm existence "${work}"
if _rc {
    do "${do}/master.do"
}


* ============================================================================
* 1. LOAD DATA
* ============================================================================

use "${work}/cfps_couples_earnings_power_pooled.dta", clear

* ============================================================================
* 2. CLASSIFY COUPLES BY EDUCATION ASSORTATIVE MATING
* ============================================================================

* edu_match = 1 hypergamous (husband > wife)
*           = 0 homogamous  (husband = wife)
*           = -1 hypogamous (husband < wife, i.e. wife's edu higher)
gen byte edu_match = .
replace  edu_match =  1 if husband_edu >  wife_edu
replace  edu_match =  0 if husband_edu == wife_edu
replace  edu_match = -1 if husband_edu <  wife_edu

label define edumatch -1 "Hypogamous (Wife > Husband)" ///
                      0 "Homogamous (Wife = Husband)" ///
                      1 "Hypergamous (Husband > Wife)"
label values edu_match edumatch
label variable edu_match "Education assortative-mating type"

tab edu_match, missing


* ============================================================================
* 3. WITHIN-COUPLE PERMANENT INCOME GAP (Wife - Husband)
* ============================================================================

* Sanity check: diff_yp should equal wife_yp - husband_yp
gen double _diff_check = wife_yp - husband_yp
assert abs(diff_yp - _diff_check) < 1e-6
drop _diff_check

label variable diff_yp "Within-couple perm. income gap: Wife - Husband (yuan)"


* ============================================================================
* 4. DESCRIPTIVES: MEAN GAP BY GROUP
* ============================================================================

di _newline(2) as text "{hline 78}"
di as text "  Mean within-couple permanent income gap (Wife - Husband, yuan)"
di as text "  by education assortative-mating type"
di as text "{hline 78}"

* Summary of signed gap by group
tabstat diff_yp, by(edu_match) ///
        statistics(mean sd min p50 max count) ///
        columns(statistics) format(%12.2f)

* Same, restricted to the two groups of interest
di _newline as text "-- Restricted to hypergamous vs hypogamous --"
tabstat diff_yp if inlist(edu_match, -1, 1), by(edu_match) ///
        statistics(mean sd count) ///
        columns(statistics) format(%12.2f)


* ============================================================================
* 5. COMPARE |MEAN GAP| ACROSS HYPERGAMOUS vs HYPOGAMOUS
* ============================================================================

* Store group means in scalars
quietly summarize diff_yp if edu_match == 1          //  hypergamous
scalar mean_hyper   = r(mean)
scalar n_hyper      = r(N)

quietly summarize diff_yp if edu_match == -1         //  hypogamous
scalar mean_hypo    = r(mean)
scalar n_hypo       = r(N)

scalar abs_hyper    = abs(mean_hyper)
scalar abs_hypo     = abs(mean_hypo)
scalar abs_diff     = abs_hyper - abs_hypo

di _newline(2) as text "{hline 78}"
di as text "  |Mean within-couple gap| by group"
di as text "{hline 78}"
di as text  "  Hypergamous (husband > wife):  N = " as result %6.0f n_hyper ///
            as text "   mean = "  as result %12.2f mean_hyper ///
            as text "   |mean| = " as result %12.2f abs_hyper
di as text  "  Hypogamous  (wife > husband):  N = " as result %6.0f n_hypo ///
            as text "   mean = "  as result %12.2f mean_hypo ///
            as text "   |mean| = " as result %12.2f abs_hypo
di _newline ///
   as text "  |mean|_hyper - |mean|_hypo = " as result %12.2f abs_diff

if abs_hyper > abs_hypo {
    di _newline as result ///
       "  => Yes: the mean gap is LARGER in absolute value among " ///
       "HYPERGAMOUS couples."
}
else if abs_hyper < abs_hypo {
    di _newline as result ///
       "  => No: the mean gap is LARGER in absolute value among " ///
       "HYPOGAMOUS couples."
}
else {
    di _newline as result ///
       "  => The two |means| are equal."
}


* ============================================================================
* 6. EXPORT RESULTS
* ============================================================================

capture mkdir "${output}"

* Save a small summary file with the group means and |means|
preserve
    clear
    set obs 2
    gen str30 group   = ""
    gen long  n       = .
    gen double mean_gap   = .
    gen double abs_mean_gap = .

    replace group = "Hypergamous (H>W)" in 1
    replace n     = n_hyper             in 1
    replace mean_gap     = mean_hyper   in 1
    replace abs_mean_gap = abs_hyper    in 1

    replace group = "Hypogamous (W>H)"  in 2
    replace n     = n_hypo              in 2
    replace mean_gap     = mean_hypo    in 2
    replace abs_mean_gap = abs_hypo     in 2

    export delimited using ///
        "${output}/hypergamy_income_gap_summary.csv", replace
restore


di _newline(2) as result "Done. Summary written to " ///
   "${output}/hypergamy_income_gap_summary.csv"
