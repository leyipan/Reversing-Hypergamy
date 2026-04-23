/*==============================================================================
  COUNTERFACTUAL 3: EQUALISE BOTH CHANNELS SIMULTANEOUSLY

  Question: "What if women faced male labour-market returns AND married at
             the same age as their husbands?"

  Method:   Recompute every wife's permanent income using:
              • MALE Mincer coefficients  (wage-gap channel)
              • HUSBAND's age at marriage  (age channel)
            Husband's permanent income is unchanged (baseline male coefficients).

  Outputs:
    1. Stacked bar chart — % hypergamy / hypogamy / homogamy by marry year
    2. Trend line — average (wife − husband) permanent income by marry year

  Prerequisites: Run master.do and mincerian_step1.do first.
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

keep if marry_year >= 2010 & marry_year <= 2020


* ============================================================================
* 2.  CONVERT EDUCATION LEVELS TO YEARS
* ============================================================================

foreach role in wife husband {
    gen `role'_eduyear = .
    replace `role'_eduyear = 0  if `role'_edu == 1
    replace `role'_eduyear = 6  if `role'_edu == 2
    replace `role'_eduyear = 9  if `role'_edu == 3
    replace `role'_eduyear = 12 if `role'_edu == 4
    replace `role'_eduyear = 15 if `role'_edu == 5
    replace `role'_eduyear = 16 if `role'_edu == 6
    replace `role'_eduyear = 19 if `role'_edu == 7
    replace `role'_eduyear = 22 if `role'_edu == 8
    replace `role'_eduyear = 0  if `role'_edu == 9
    label var `role'_eduyear "`role's years of education"
}


* ============================================================================
* 3.  COMPUTE MARRIAGE AGE
* ============================================================================

gen wife_marriage_age    = marry_year - wife_birthy
gen husband_marriage_age = marry_year - husband_birthy

label var wife_marriage_age    "Wife's age at marriage"
label var husband_marriage_age "Husband's age at marriage"

replace wife_marriage_age    = . if wife_marriage_age < 15 | wife_marriage_age > 60
replace husband_marriage_age = . if husband_marriage_age < 15 | husband_marriage_age > 60


* ============================================================================
* 4.  LOAD MINCER COEFFICIENTS (MALE ONLY — used for both spouses)
* ============================================================================

estimates use "${output}/mincer_male_pooled"
local b0_m = _b[_cons]
local b1_m = _b[eduyear]
local b2_m = _b[potexp]
local b3_m = _b[potexp2]

di _n "=== Counterfactual 3: Wife uses MALE coefficients + HUSBAND's marriage age ==="
di "  Male: b0=`b0_m'  b1=`b1_m'  b2=`b2_m'  b3=`b3_m'"


* ============================================================================
* 5.  PREDICT PDV OF LIFETIME INCOME
* ============================================================================

local delta = 0.03
local retire_age = 60

* --- 5a. Wife's NPV using MALE coefficients + HUSBAND's marriage age ---
gen double wife_NPV_cf = 0

forvalues a = 16/`retire_age' {
    gen double _pe  = max(`a' - wife_eduyear - 6, 0)
    gen double _pe2 = _pe^2
    gen double _lny = `b0_m' + `b1_m' * wife_eduyear + `b2_m' * _pe + `b3_m' * _pe2
    gen double _ya  = exp(_lny)
    gen double _disc = (1 + `delta')^(`a' - husband_marriage_age)

    replace wife_NPV_cf = wife_NPV_cf + _ya / _disc ///
        if `a' >= husband_marriage_age & `a' <= `retire_age' ///
        & !missing(wife_eduyear) & !missing(husband_marriage_age)

    drop _pe _pe2 _lny _ya _disc
}

replace wife_NPV_cf = . if missing(wife_eduyear) | missing(husband_marriage_age)
replace wife_NPV_cf = . if husband_marriage_age > `retire_age'
label var wife_NPV_cf "Wife's CF3 PDV (male coefficients, husband's marriage age)"

* --- 5b. Husband's NPV (baseline — male coefficients) ---
gen double husband_NPV = 0

forvalues a = 16/`retire_age' {
    gen double _pe  = max(`a' - husband_eduyear - 6, 0)
    gen double _pe2 = _pe^2
    gen double _lny = `b0_m' + `b1_m' * husband_eduyear + `b2_m' * _pe + `b3_m' * _pe2
    gen double _ya  = exp(_lny)
    gen double _disc = (1 + `delta')^(`a' - husband_marriage_age)

    replace husband_NPV = husband_NPV + _ya / _disc ///
        if `a' >= husband_marriage_age & `a' <= `retire_age' ///
        & !missing(husband_eduyear) & !missing(husband_marriage_age)

    drop _pe _pe2 _lny _ya _disc
}

replace husband_NPV = . if missing(husband_eduyear) | missing(husband_marriage_age)
replace husband_NPV = . if husband_marriage_age > `retire_age'
label var husband_NPV "Husband's PDV (baseline male coefficients)"


* ============================================================================
* 6.  PERMANENT INCOME (ANNUITY EQUIVALENT)
* ============================================================================

* Wife (counterfactual): annuity horizon uses HUSBAND's marriage age
gen wife_T_perm = 75 - husband_marriage_age
gen double wife_yp_cf = (`delta' * (1 + `delta')^(wife_T_perm - 1)) ///
                      / ((1 + `delta')^wife_T_perm - 1) * wife_NPV_cf
replace wife_yp_cf = . if wife_T_perm <= 0 | missing(wife_NPV_cf)
label var wife_yp_cf "Wife's CF3 permanent income (male coeff, husband's age)"

* Husband (baseline)
gen husband_T_perm = 75 - husband_marriage_age
gen double husband_yp = (`delta' * (1 + `delta')^(husband_T_perm - 1)) ///
                      / ((1 + `delta')^husband_T_perm - 1) * husband_NPV
replace husband_yp = . if husband_T_perm <= 0 | missing(husband_NPV)
label var husband_yp "Husband's permanent income (baseline)"

* Drop cases with missing permanent income
drop if missing(wife_yp_cf) | missing(husband_yp)

di _n "=== CF3 permanent income computed ==="
count
sum wife_yp_cf husband_yp, detail


* ============================================================================
* 7.  SPOUSAL DIFFERENCES AND HYPERGAMY METRICS
* ============================================================================

gen diff_yp_cf = wife_yp_cf - husband_yp
label var diff_yp_cf "CF3: Wife - Husband permanent income (yuan)"

* Percentage difference: |Ŷ_w - Ŷ_h| / ((Ŷ_w + Ŷ_h)/2)
gen double _couple_avg = (wife_yp_cf + husband_yp) / 2
gen double pct_diff_cf = abs(wife_yp_cf - husband_yp) / _couple_avg ///
    if _couple_avg > 0 & !missing(_couple_avg)
label var pct_diff_cf "CF3: |(wife-husband) yp| / couple avg yp"
drop _couple_avg

* Mutually exclusive categories (5% threshold)
gen homogamy_cf = (pct_diff_cf < 0.05) ///
    if !missing(pct_diff_cf)
label var homogamy_cf "CF3: 1 = Perm income within 5% of couple avg"

gen hypergamy_cf = (pct_diff_cf >= 0.05 & husband_yp > wife_yp_cf) ///
    if !missing(pct_diff_cf)
label var hypergamy_cf "CF3: 1 = Husband perm income >5% above couple avg"

gen hypogamy_cf = (pct_diff_cf >= 0.05 & wife_yp_cf > husband_yp) ///
    if !missing(pct_diff_cf)
label var hypogamy_cf "CF3: 1 = Wife perm income >5% above couple avg"

* ============================================================================
* 8.  VISUALISATIONS
* ============================================================================

* --------------------------------------------------------------------------
* Chart 1: Average wife − husband permanent income gap (CF3)
* --------------------------------------------------------------------------

preserve

collapse (mean) mean_diff = diff_yp_cf ///
         (count) n_couples = diff_yp_cf, ///
    by(marry_year)

twoway (connected mean_diff marry_year, ///
            mcolor(navy) lcolor(navy) msymbol(circle) lwidth(medthick)) ///
    , ///
    title("CF3: Average Wife-Husband Permanent Income Gap") ///
    subtitle("Wife uses male coefficients + husband's marriage age") ///
    ytitle("Mean difference (yuan/year)") xtitle("Marriage year") ///
    ylabel(, format(%12.0fc)) ///
    xlabel(2010(1)2020, angle(45)) ///
    yline(0, lcolor(red) lpattern(dash) lwidth(medium)) ///
    note("Below 0 = hypergamy (husband earns more)" ///
         "Above 0 = hypogamy (wife earns more)") ///
    legend(off) scheme(s2color)
graph export "${output}/cf3_trend_diff_yp.png", replace width(1200)

restore


* --------------------------------------------------------------------------
* Chart 2: Stacked bar — % hypergamy / hypogamy / homogamy (CF3)
* --------------------------------------------------------------------------

preserve

collapse (mean) pct_hyper = hypergamy_cf ///
         (mean) pct_hypo  = hypogamy_cf  ///
		 (mean) pct_homo  = homogamy_cf  ///
         (count) n = hypergamy_cf, ///
    by(marry_year)

foreach v in pct_hyper pct_hypo pct_homo {
    replace `v' = `v' * 100
}

* Stacked bar coordinates (bottom to top: hypergamy, homogamy, hypogamy)
gen hyper_bot = 0
gen hyper_top = pct_hyper
gen homo_bot  = hyper_top
gen homo_top  = homo_bot + pct_homo
gen hypo_bot  = homo_top
gen hypo_top  = hypo_bot + pct_hypo

* Labels (positioned at midpoint of each segment)
gen str label_hyper = string(pct_hyper, "%4.1f") + "%"
gen str label_homo  = string(pct_homo,  "%4.1f") + "%"
gen str label_hypo  = string(pct_hypo,  "%4.1f") + "%"

gen y_label_hyper = (hyper_bot + hyper_top) / 2
gen y_label_homo  = (homo_bot  + homo_top)  / 2
gen y_label_hypo  = (hypo_bot  + hypo_top)  / 2

twoway (rbar hyper_bot hyper_top marry_year, ///
            barwidth(0.6) color(navy%70)) ///
       (rbar homo_bot homo_top marry_year, ///
            barwidth(0.6) color(gs10%70)) ///
       (rbar hypo_bot hypo_top marry_year, ///
            barwidth(0.6) color(cranberry%70)) ///
       (scatter y_label_hyper marry_year, ///
            msymbol(none) mlabel(label_hyper) mlabcolor(white) mlabsize(vsmall)) ///
       (scatter y_label_homo marry_year, ///
            msymbol(none) mlabel(label_homo) mlabcolor(white) mlabsize(vsmall)) ///
       (scatter y_label_hypo marry_year, ///
            msymbol(none) mlabel(label_hypo) mlabcolor(white) mlabsize(vsmall)) ///
    , ///
    title("CF3: Hypergamy / Homogamy / Hypogamy by Marriage Year") ///
    subtitle("Wife uses male coefficients + husband's marriage age (5% threshold)") ///
    ytitle("") xtitle("Marriage year") ///
    xlabel(2010(1)2020, angle(45)) ///
    ylabel(0 "0%" 25 "25%" 50 "50%" 75 "75%" 100 "100%", angle(0)) ///
    legend(order(1 "Hypergamy (husband >5% above)" ///
                 2 "Homogamy (within 5%)" ///
                 3 "Hypogamy (wife >5% above)") ///
           position(6) rows(1) size(small)) ///
    scheme(s2color)
graph export "${output}/cf3_bar_hypergamy.png", replace width(1200)

restore


* --------------------------------------------------------------------------
* Chart 3: CF3 vs Reality — average wife-husband permanent income gap
* --------------------------------------------------------------------------

preserve

* --- Collapse counterfactual mean gap by marry_year ---
collapse (mean) mean_diff_cf = diff_yp_cf ///
         (count) n_cf = diff_yp_cf, ///
    by(marry_year)

tempfile cf_collapsed
save `cf_collapsed'

* --- Load baseline (reality) dataset and collapse its mean gap ---
use "${work}/cfps_couples_earnings_power_pooled.dta", clear
keep marry_year diff_yp
collapse (mean) mean_diff_real = diff_yp ///
         (count) n_real = diff_yp, ///
    by(marry_year)

* --- Merge counterfactual onto baseline ---
merge 1:1 marry_year using `cf_collapsed', nogen

* --- Combined plot ---
twoway (connected mean_diff_real marry_year, ///
            mcolor(cranberry) lcolor(cranberry) msymbol(circle) ///
            lwidth(medthick) lpattern(solid)) ///
       (connected mean_diff_cf marry_year, ///
            mcolor(navy) lcolor(navy) msymbol(diamond) ///
            lwidth(medthick) lpattern(dash)) ///
    , ///
    title("Wife-Husband Permanent Income Gap: Reality vs CF3") ///
    subtitle("CF3: Wife uses male coefficients + husband's marriage age") ///
    ytitle("Mean difference (yuan/year)") xtitle("Marriage year") ///
    ylabel(, format(%12.0fc)) ///
    xlabel(2010(1)2020, angle(45)) ///
    yline(0, lcolor(gs8) lpattern(dash) lwidth(thin)) ///
    legend(order(1 "Reality (gender-specific coefficients)" ///
                 2 "CF3: No wage gap + no age gap") ///
           position(6) rows(1) size(small)) ///
    note("Below 0 = hypergamy (husband earns more)" ///
         "Above 0 = hypogamy (wife earns more)") ///
    scheme(s2color)
graph export "${output}/cf3_vs_reality_trend_diff_yp.png", replace width(1200)

restore


* ============================================================================
* 9.  SAVE
* ============================================================================

compress
save "${work}/cfps_counterfactual_3_both.dta", replace

di _n "================================================================="
di    "DONE — Counterfactual 3: Both Channels Equalised"
di    "  Wife's y^p recomputed with MALE coefficients"
di    "  AND HUSBAND's age at marriage."
di    "  Saved: ${work}/cfps_counterfactual_3_both.dta"
di    "  Charts: ${output}/cf3_*.png"
di    "================================================================="
tab marry_year
count
