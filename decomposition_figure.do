/*==============================================================================
  DECOMPOSITION FIGURE  (overlay of Reality, CF1, CF2, CF3 by marriage year)

  Purpose:
    Plot the mean wife - husband permanent income gap by marriage year under
    reality and each of the three counterfactuals, overlaid on one figure.

  Inputs:
    - ${work}/cfps_couples_earnings_power_pooled.dta   (reality)
    - ${work}/cfps_counterfactual_1_age_channel.dta    (CF1: age)
    - ${work}/cfps_counterfactual_2_wage_gap.dta       (CF2: wage gap)
    - ${work}/cfps_counterfactual_3_both.dta           (CF3: both)

  Outputs:
    - ${output}/decomposition_figure.gph
    - ${output}/decomposition_figure.png
    - ${output}/decomposition_figure.pdf
    - ${output}/decomposition_figure_data.csv   (underlying means)

  Prerequisites: Run master.do first (sets global paths).
==============================================================================*/

clear all
set more off
set maxvar 10000

* ============================================================================
* 1.  COLLAPSE EACH DATASET TO MARRIAGE-YEAR MEANS
* ============================================================================

* --- Reality ---
use "${work}/cfps_couples_earnings_power_pooled.dta", clear
collapse (mean) reality = diff_yp, by(marry_year)
tempfile m_reality
save `m_reality'

* --- CF1: no age gap at marriage ---
use "${work}/cfps_counterfactual_1_age_channel.dta", clear
collapse (mean) cf1 = diff_yp_cf, by(marry_year)
tempfile m_cf1
save `m_cf1'

* --- CF2: no gender wage gap ---
use "${work}/cfps_counterfactual_2_wage_gap.dta", clear
collapse (mean) cf2 = diff_yp_cf, by(marry_year)
tempfile m_cf2
save `m_cf2'

* --- CF3: both ---
use "${work}/cfps_counterfactual_3_both.dta", clear
collapse (mean) cf3 = diff_yp_cf, by(marry_year)
tempfile m_cf3
save `m_cf3'


* ============================================================================
* 2.  MERGE INTO A SINGLE YEAR-LEVEL DATASET
* ============================================================================

use `m_reality', clear
merge 1:1 marry_year using `m_cf1', nogen
merge 1:1 marry_year using `m_cf2', nogen
merge 1:1 marry_year using `m_cf3', nogen

* Restrict to the analytic window
keep if marry_year >= 2010 & marry_year <= 2020
sort marry_year

list marry_year reality cf1 cf2 cf3, sep(0) noobs


* ============================================================================
* 3.  OVERLAY PLOT:  Reality vs CF1 vs CF2 vs CF3
* ============================================================================

capture mkdir "${output}"

twoway ///
    (connected reality marry_year, ///
        lcolor(cranberry)    lwidth(medthick)  lpattern(solid) ///
        mcolor(cranberry)    msymbol(circle)         msize(medium)) ///
    (connected cf1     marry_year, ///
        lcolor(navy)         lwidth(medthick)  lpattern(dash) ///
        mcolor(navy)         msymbol(diamond)        msize(medium)) ///
    (connected cf2     marry_year, ///
        lcolor(olive_teal)   lwidth(medthick)  lpattern(shortdash) ///
        mcolor(olive_teal)   msymbol(triangle)       msize(medium)) ///
    (connected cf3     marry_year, ///
        lcolor(dkorange)     lwidth(medthick)  lpattern(longdash_dot) ///
        mcolor(dkorange)     msymbol(square)         msize(medium)) ///
    , ///
    yline(0, lcolor(gs8) lpattern(dash)) ///
    ylabel(-8000(2000)4000, angle(horizontal) format(%9.0fc) grid) ///
    xlabel(2010(1)2020, angle(45)) ///
    ytitle("Mean wife {c 0-} husband permanent" "income gap (yuan/yr)", size(small)) ///
    xtitle("Marriage year") ///
    title("Wife{c 0-}Husband Permanent Income Gap by Marriage Year", ///
          size(medium) color(navy)) ///
    subtitle("Reality vs. CF1 (no age gap), CF2 (no wage gap), CF3 (both)", ///
             size(small)) ///
    legend(order(1 "Reality" ///
                 2 "CF1: No age gap at marriage" ///
                 3 "CF2: No gender wage gap" ///
                 4 "CF3: No wage gap + no age gap") ///
           cols(2) size(small) region(lcolor(gs10))) ///
    note("Below 0 = hypergamy (husband earns more); Above 0 = hypogamy (wife earns more)." ///
         "CF1 equalises age at marriage; CF2 equalises Mincer coefficients; CF3 equalises both.", ///
         size(vsmall)) ///
    graphregion(color(white) margin(medium)) plotregion(color(white))

graph export "${output}/decomposition_figure.png", replace width(1800)
graph export "${output}/decomposition_figure.pdf", replace
graph save   "${output}/decomposition_figure.gph", replace


* ============================================================================
* 4.  EXPORT THE UNDERLYING NUMBERS
* ============================================================================

export delimited marry_year reality cf1 cf2 cf3 ///
    using "${output}/decomposition_figure_data.csv", replace


di _newline(2) as result "================================================================="
di             as result "DONE - Decomposition overlay figure"
di             as result "  ${output}/decomposition_figure.png"
di             as result "  ${output}/decomposition_figure.pdf"
di             as result "  ${output}/decomposition_figure.gph"
di             as result "  ${output}/decomposition_figure_data.csv"
di             as result "================================================================="
