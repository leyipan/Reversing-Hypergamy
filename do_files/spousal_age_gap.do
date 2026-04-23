/*==============================================================================
  SPOUSAL AGE GAP: DISTRIBUTION AND TRENDS
  Data: cfps_couples_allwaves.dta (built by build_couples_dataset.do)

  Purpose:
    1. Compute spousal age gap (husband age − wife age at marriage).
    2. Summarise overall distribution (mean, median, SD, percentiles).
    3. Show how the gap distributes by marriage-year cohort (2010–2020).
    4. Test whether the gap is narrowing over time.

  Outputs:
    - Histogram of overall age gap distribution
    - Connected-line plot of mean & median gap by marry year
    - Box plot of gap distribution by marry year
    - Collapsed cohort-level summary saved as .dta

  Prerequisites: Run master.do first (sets global paths).
==============================================================================*/

clear all
set more off
set maxvar 10000


* ============================================================================
* 1.  LOAD COUPLES DATASET AND RESTRICT SAMPLE
* ============================================================================

use "${work}/cfps_couples_allwaves.dta", clear

drop if wife_birthy < 1900 | missing(wife_birthy)
drop if husband_birthy < 1900 | missing(husband_birthy)

* Restrict to marriages between 2010 and 2020
keep if marry_year >= 2010 & marry_year <= 2020


* ============================================================================
* 2.  COMPUTE AGES AT MARRIAGE AND SPOUSAL AGE GAP
* ============================================================================

gen wife_marriage_age    = marry_year - wife_birthy
gen husband_marriage_age = marry_year - husband_birthy

label var wife_marriage_age    "Wife's age at marriage"
label var husband_marriage_age "Husband's age at marriage"

* Spousal age gap: husband − wife (positive = husband older)
gen age_gap = husband_marriage_age - wife_marriage_age ///
    if !missing(husband_marriage_age) & !missing(wife_marriage_age)
label var age_gap "Spousal age gap (husband age − wife age at marriage)"

drop if missing(age_gap)

di _n "=== Sample size ==="
count
tab marry_year


* ============================================================================
* 3.  OVERALL DISTRIBUTION
* ============================================================================

di _n "=== Overall spousal age gap distribution ==="
sum age_gap, detail

* Tabulate common gap values
di _n "=== Frequency of integer gap values ==="
tab age_gap if inrange(age_gap, -10, 15)


* ============================================================================
* 4.  CHART 1: HISTOGRAM OF OVERALL AGE GAP
* ============================================================================

histogram age_gap if inrange(age_gap, -10, 15), ///
    width(1) frequency ///
    fcolor(navy%70) lcolor(navy%90) ///
    xline(0, lcolor(red) lpattern(dash) lwidth(medium)) ///
    title("Distribution of Spousal Age Gap at Marriage") ///
    subtitle("Husband age − Wife age (marriages 2010–2020)") ///
    xtitle("Age gap (years)") ytitle("Number of couples") ///
    xlabel(-10(2)15) ///
    note("Red dashed line = zero gap (same age)") ///
    scheme(s2color)
graph export "${output}/agegap_histogram.png", replace width(1200)


* ============================================================================
* 5.  COHORT-LEVEL SUMMARY STATISTICS
* ============================================================================

preserve

collapse (mean)   mean_gap   = age_gap  ///
         (median) median_gap = age_gap  ///
         (sd)     sd_gap     = age_gap  ///
         (p25)    p25_gap    = age_gap  ///
         (p75)    p75_gap    = age_gap  ///
         (count)  n_couples  = age_gap, ///
    by(marry_year)

label var mean_gap   "Mean spousal age gap"
label var median_gap "Median spousal age gap"
label var sd_gap     "SD of spousal age gap"
label var p25_gap    "25th percentile"
label var p75_gap    "75th percentile"
label var n_couples  "Number of couples"

di _n "=== Cohort-level summary ==="
list marry_year n_couples mean_gap median_gap sd_gap p25_gap p75_gap, ///
    separator(0) noobs

* Save cohort summary
save "${work}/agegap_cohort_summary.dta", replace


* ============================================================================
* 6.  CHART 2: MEAN AND MEDIAN GAP BY MARRIAGE YEAR
* ============================================================================

twoway (connected mean_gap marry_year, ///
            mcolor(navy) lcolor(navy) msymbol(circle) lwidth(medthick)) ///
       (connected median_gap marry_year, ///
            mcolor(cranberry) lcolor(cranberry) msymbol(triangle) ///
            lwidth(medthick) lpattern(dash)) ///
    , ///
    title("Spousal Age Gap by Marriage Year") ///
    subtitle("Husband age − Wife age at marriage") ///
    ytitle("Age gap (years)") xtitle("Marriage year") ///
    ylabel(, format(%3.1f)) ///
    xlabel(2010(1)2020, angle(45)) ///
    yline(0, lcolor(gs10) lpattern(dot) lwidth(thin)) ///
    legend(order(1 "Mean" 2 "Median") ///
           position(6) rows(1) size(small)) ///
    scheme(s2color)
graph export "${output}/agegap_trend_mean_median.png", replace width(1200)

restore


* ============================================================================
* 7.  CHART 3: BOX PLOT BY MARRIAGE YEAR
* ============================================================================

graph box age_gap if inrange(age_gap, -10, 15), ///
    over(marry_year, label(angle(45))) ///
    box(1, fcolor(navy%60) lcolor(navy)) ///
    medline(lcolor(cranberry) lwidth(medthick)) ///
    title("Distribution of Spousal Age Gap by Marriage Year") ///
    subtitle("Husband age − Wife age at marriage") ///
    ytitle("Age gap (years)") ///
    yline(0, lcolor(red) lpattern(dash) lwidth(medium)) ///
    note("Box = IQR; line = median; whiskers = 1.5×IQR" ///
         "Trimmed to [−10, 15] for display") ///
    scheme(s2color)
graph export "${output}/agegap_boxplot_by_year.png", replace width(1200)


* ============================================================================
* 8.  TREND TEST: IS THE GAP NARROWING?
* ============================================================================

di _n "=== OLS: age_gap on marry_year (linear trend) ==="
reg age_gap marry_year
estimates store trend_linear

di _n "=== Interpretation ==="
local b_trend = _b[marry_year]
local p_trend = 2 * ttail(e(df_r), abs(_b[marry_year] / _se[marry_year]))
di "  Slope = " %6.4f `b_trend' " years per calendar year"
di "  p-value = " %6.4f `p_trend'
if `b_trend' < 0 & `p_trend' < 0.05 {
    di "  --> The spousal age gap is significantly NARROWING over time."
}
else if `b_trend' > 0 & `p_trend' < 0.05 {
    di "  --> The spousal age gap is significantly WIDENING over time."
}
else {
    di "  --> No statistically significant linear trend (p >= 0.05)."
}


* ============================================================================
* 9.  CHART 4: SHARE WITH WIFE OLDER OR SAME AGE BY YEAR
* ============================================================================

gen wife_older_or_equal = (age_gap <= 0) if !missing(age_gap)
label var wife_older_or_equal "1 = Wife same age or older than husband"

preserve

collapse (mean) share_wife_older = wife_older_or_equal ///
         (count) n = wife_older_or_equal, ///
    by(marry_year)

replace share_wife_older = share_wife_older * 100

twoway (connected share_wife_older marry_year, ///
            mcolor(navy) lcolor(navy) msymbol(circle) lwidth(medthick)) ///
    , ///
    title("Share of Couples Where Wife is Same Age or Older") ///
    subtitle("By marriage year (2010–2020)") ///
    ytitle("Percent (%)") xtitle("Marriage year") ///
    ylabel(, format(%3.1f)) ///
    xlabel(2010(1)2020, angle(45)) ///
    yline(50, lcolor(gs10) lpattern(dot) lwidth(thin)) ///
    legend(off) scheme(s2color)
graph export "${output}/agegap_share_wife_older.png", replace width(1200)

restore


* ============================================================================
* 10. DONE
* ============================================================================

di _n "================================================================="
di    "DONE — Spousal Age Gap Analysis"
di    "  Sample: cfps_couples_allwaves.dta, marry_year 2010–2020"
di    "  Gap defined as: husband age − wife age at marriage"
di    "================================================================="
di    "  Charts exported to ${output}/"
di    "    agegap_histogram.png"
di    "    agegap_trend_mean_median.png"
di    "    agegap_boxplot_by_year.png"
di    "    agegap_share_wife_older.png"
di    "  Cohort summary: ${work}/agegap_cohort_summary.dta"
di    "================================================================="
