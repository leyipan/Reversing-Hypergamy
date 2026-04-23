/*==============================================================================
  EARNINGS POWER: PREDICT PERMANENT INCOME FOR EACH SPOUSE
  Data: cfps_couples_allwaves.dta (built by build_couples_dataset.do)

  Purpose:
    1. Convert education levels to years of education.
    2. Using pooled Mincer coefficients (Step 1), predict PDV of lifetime
       income for each spouse from marriage age to retirement (60).
    3. Convert to permanent income via annuity formula.
    4. Compute spousal differences and hypergamy metrics.
    5. Produce trend visualisations by marriage year (2010–2020).

  Model: ln(income) = b0 + b1*eduyear + b2*potexp + b3*potexp2
         Coefficients loaded from Step 1 .ster files (gender-specific).

  Permanent income:
    NPV  = SUM_{a=marriage_age}^{60} exp(ln_y(a)) / (1+d)^(a-marriage_age)
    y^p  = d(1+d)^(T-1) / ((1+d)^T - 1) * NPV,  T = 75 - marriage_age

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

* Restrict to marriages between 2010 and 2020
keep if marry_year >= 2010 & marry_year <= 2020

tab wave
count

* ============================================================================
* 2.  CONVERT EDUCATION LEVELS TO YEARS
* ============================================================================

/*
   CFPS education coding (consistent across waves):
     1 = Illiterate / semi-literate     →  0 years
     2 = Primary school                 →  6 years
     3 = Junior high school             →  9 years
     4 = Senior high / vocational       → 12 years
     5 = 3-year college                 → 15 years
     6 = 4-year college / Bachelor's    → 16 years
     7 = Master's degree                → 19 years
     8 = Doctoral degree                → 22 years
     9 = No need to go to school        →  0 years
*/

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

di _n "=== Education conversion summary ==="
tab wife_eduyear, m
tab husband_eduyear, m


* ============================================================================
* 3.  COMPUTE MARRIAGE AGE
* ============================================================================

gen wife_marriage_age    = marry_year - wife_birthy
gen husband_marriage_age = marry_year - husband_birthy

label var wife_marriage_age    "Wife's age at marriage"
label var husband_marriage_age "Husband's age at marriage"

* Sanity check: drop implausible marriage ages
replace wife_marriage_age    = . if wife_marriage_age < 15 | wife_marriage_age > 60
replace husband_marriage_age = . if husband_marriage_age < 15 | husband_marriage_age > 60

sum wife_marriage_age husband_marriage_age, detail


* ============================================================================
* 4.  LOAD MINCER COEFFICIENTS FROM STEP 1
* ============================================================================

estimates use "${output}/mincer_male_pooled"
local b0_m = _b[_cons]
local b1_m = _b[eduyear]
local b2_m = _b[potexp]
local b3_m = _b[potexp2]

estimates use "${output}/mincer_female_pooled"
local b0_f = _b[_cons]
local b1_f = _b[eduyear]
local b2_f = _b[potexp]
local b3_f = _b[potexp2]

di _n "=== Loaded Mincer Coefficients ==="
di "  Male:   b0=`b0_m'  b1=`b1_m'  b2=`b2_m'  b3=`b3_m'"
di "  Female: b0=`b0_f'  b1=`b1_f'  b2=`b2_f'  b3=`b3_f'"


* ============================================================================
* 5.  PREDICT PDV OF LIFETIME INCOME FOR BOTH SPOUSES
* ============================================================================

local delta = 0.03
local retire_age = 60

* --- 5a. Wife's NPV (female coefficients) ---
gen double wife_NPV = 0

forvalues a = 16/`retire_age' {
    gen double _pe  = max(`a' - wife_eduyear - 6, 0)
    gen double _pe2 = _pe^2
    gen double _lny = `b0_f' + `b1_f' * wife_eduyear + `b2_f' * _pe + `b3_f' * _pe2
    gen double _ya  = exp(_lny)
    gen double _disc = (1 + `delta')^(`a' - wife_marriage_age)

    replace wife_NPV = wife_NPV + _ya / _disc ///
        if `a' >= wife_marriage_age & `a' <= `retire_age' ///
        & !missing(wife_eduyear) & !missing(wife_marriage_age)

    drop _pe _pe2 _lny _ya _disc
}

replace wife_NPV = . if missing(wife_eduyear) | missing(wife_marriage_age)
replace wife_NPV = . if wife_marriage_age > `retire_age'
label var wife_NPV "Wife's PDV of predicted lifetime income (d=3%)"

* --- 5b. Husband's NPV (male coefficients) ---
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
label var husband_NPV "Husband's PDV of predicted lifetime income (d=3%)"


* ============================================================================
* 6.  PERMANENT INCOME (ANNUITY EQUIVALENT)
* ============================================================================

* Wife
gen wife_T_perm = 75 - wife_marriage_age
gen double wife_yp = (`delta' * (1 + `delta')^(wife_T_perm - 1)) ///
                   / ((1 + `delta')^wife_T_perm - 1) * wife_NPV
replace wife_yp = . if wife_T_perm <= 0 | missing(wife_NPV)
gen double wife_ln_yp = ln(wife_yp) if wife_yp > 0 & !missing(wife_yp)

label var wife_yp    "Wife's permanent income y^p (d=3%)"
label var wife_ln_yp "Wife's log permanent income"

* Husband
gen husband_T_perm = 75 - husband_marriage_age
gen double husband_yp = (`delta' * (1 + `delta')^(husband_T_perm - 1)) ///
                      / ((1 + `delta')^husband_T_perm - 1) * husband_NPV
replace husband_yp = . if husband_T_perm <= 0 | missing(husband_NPV)
gen double husband_ln_yp = ln(husband_yp) if husband_yp > 0 & !missing(husband_yp)

label var husband_yp    "Husband's permanent income y^p (d=3%)"
label var husband_ln_yp "Husband's log permanent income"

* Drop cases where either spouse has missing permanent income
drop if missing(wife_yp) | missing(husband_yp)

di _n "=== Permanent income computed for both spouses ==="
count
sum wife_yp husband_yp, detail


* ============================================================================
* 7.  PERCENTILE RANKS WITHIN GENDER × MARRY YEAR
* ============================================================================

bysort marry_year (wife_yp): gen wife_pctile = (_n / _N) * 100 ///
    if !missing(wife_yp)
label var wife_pctile "Wife's permanent income percentile (within marry year)"

bysort marry_year (husband_yp): gen husband_pctile = (_n / _N) * 100 ///
    if !missing(husband_yp)
label var husband_pctile "Husband's permanent income percentile (within marry year)"


* ============================================================================
* 8.  SPOUSAL DIFFERENCES AND HYPERGAMY METRICS
* ============================================================================

* Signed difference (wife - husband)
gen diff_yp = wife_yp - husband_yp
label var diff_yp "Wife - Husband permanent income (yuan)"

* Percentage difference: |Ŷ_w - Ŷ_h| / ((Ŷ_w + Ŷ_h)/2)
gen double _couple_avg_yp = (wife_yp + husband_yp) / 2
gen double pct_diff_yp    = abs(wife_yp - husband_yp) / _couple_avg_yp ///
    if _couple_avg_yp > 0 & !missing(_couple_avg_yp)
label var pct_diff_yp "|(wife-husband) yp| / couple avg yp"
drop _couple_avg_yp

* Mutually exclusive categories (5% threshold)
gen homogamy_yp = (pct_diff_yp < 0.05) ///
    if !missing(pct_diff_yp)
label var homogamy_yp "1 = Perm income within 5% of couple average"

gen hypergamy_yp = (pct_diff_yp >= 0.05 & husband_yp > wife_yp) ///
    if !missing(pct_diff_yp)
label var hypergamy_yp "1 = Husband perm income >5% above couple avg"

gen hypogamy_yp = (pct_diff_yp >= 0.05 & wife_yp > husband_yp) ///
    if !missing(pct_diff_yp)
label var hypogamy_yp "1 = Wife perm income >5% above couple avg"

* Summary
di _n "=== Spousal difference summary ==="
sum diff_yp pct_diff_yp, detail
di _n "=== Homogamy / Hypergamy / Hypogamy (mutually exclusive, 5% threshold) ==="
tab homogamy_yp
tab hypergamy_yp
tab hypogamy_yp
bysort marry_year: sum homogamy_yp hypergamy_yp hypogamy_yp


* ============================================================================
* 9.  VISUALISATIONS BY MARRIAGE YEAR
* ============================================================================

* --------------------------------------------------------------------------
* Chart 1: Average signed difference in permanent income by marry year
* --------------------------------------------------------------------------

preserve

collapse (mean) mean_diff_yp = diff_yp ///
         (count) n_couples = diff_yp, ///
    by(marry_year)

twoway (connected mean_diff_yp marry_year, ///
            mcolor(navy) lcolor(navy) msymbol(circle) lwidth(medthick)) ///
    , ///
    title("Average Wife-Husband Permanent Income Gap") ///
    subtitle("Signed difference in y{superscript:p} (wife - husband)") ///
    ytitle("Mean difference (yuan/year)") xtitle("Marriage year") ///
    ylabel(, format(%12.0fc)) ///
    xlabel(2010(1)2020, angle(45)) ///
    yline(0, lcolor(red) lpattern(dash) lwidth(medium)) ///
    note("Below 0 = average hypergamy (husband earns more)" ///
         "Above 0 = average hypogamy (wife earns more)") ///
    legend(off) scheme(s2color)
graph export "${output}/trend_diff_yp_by_marryyear.png", replace width(1200)

restore

* --------------------------------------------------------------------------
* Chart 2: Stacked bar — hypergamy/homogamy/hypogamy proportions
* --------------------------------------------------------------------------

preserve

collapse (mean) pct_hyper_yp = hypergamy_yp ///
         (mean) pct_hypo_yp  = hypogamy_yp  ///
         (mean) pct_homo_yp  = homogamy_yp  ///
         (count) n = hypergamy_yp, ///
    by(marry_year)

foreach v in pct_hyper_yp pct_hypo_yp pct_homo_yp {
    replace `v' = `v' * 100
}

* Stacked bar coordinates (bottom to top: hypergamy, homogamy, hypogamy)
gen hyper_bot = 0
gen hyper_top = pct_hyper_yp
gen homo_bot  = hyper_top
gen homo_top  = homo_bot + pct_homo_yp
gen hypo_bot  = homo_top
gen hypo_top  = hypo_bot + pct_hypo_yp

* Labels (centred in each bar segment)
gen str label_hyper = string(pct_hyper_yp, "%4.1f") + "%"
gen str label_homo  = string(pct_homo_yp,  "%4.1f") + "%"
gen str label_hypo  = string(pct_hypo_yp,  "%4.1f") + "%"

gen y_label_hyper = (hyper_bot + hyper_top) / 2
gen y_label_homo  = (homo_bot  + homo_top)  / 2
gen y_label_hypo  = (hypo_bot  + hypo_top)  / 2

twoway (rbar hyper_bot hyper_top marry_year, ///
            barwidth(0.6) color(navy%70)) ///
       (rbar homo_bot homo_top marry_year, ///
            barwidth(0.6) color(forest_green%70)) ///
       (rbar hypo_bot hypo_top marry_year, ///
            barwidth(0.6) color(cranberry%70)) ///
       (scatter y_label_hyper marry_year, ///
            msymbol(none) mlabel(label_hyper) mlabcolor(white) mlabsize(vsmall)) ///
       (scatter y_label_homo marry_year, ///
            msymbol(none) mlabel(label_homo) mlabcolor(white) mlabsize(vsmall)) ///
       (scatter y_label_hypo marry_year, ///
            msymbol(none) mlabel(label_hypo) mlabcolor(white) mlabsize(vsmall)) ///
    , ///
    title("Hypergamy, Homogamy & Hypogamy by Marriage Year") ///
    subtitle("Based on permanent income y{superscript:p} (5% threshold)") ///
    ytitle("") xtitle("Marriage year") ///
    xlabel(2010(1)2020, angle(45)) ///
    ylabel(0 "0%" 25 "25%" 50 "50%" 75 "75%" 100 "100%", angle(0)) ///
    legend(order(1 "Hypergamy (husband >5% above)" ///
                 2 "Homogamy (within 5%)" ///
                 3 "Hypogamy (wife >5% above)") ///
           position(6) rows(1) size(small)) ///
    scheme(s2color)
graph export "${output}/bar_hypergamy_yp_by_marryyear.png", replace width(1200)

restore

* ============================================================================
* 10. SAVE
* ============================================================================

compress
save "${work}/cfps_couples_earnings_power_pooled.dta", replace

di _n "================================================================="
di    "DONE. Saved: ${work}/cfps_couples_earnings_power_pooled.dta"
di    "================================================================="
di    "  Couples with marry_year 2010–2020"
di    "  Permanent income y^p for both spouses"
di    "  (PDV of lifetime earnings, d=3%, retire at 60,"
di    "   annuity horizon T = 75 - marriage_age)"
di    "  Visualisations exported to ${output}/"
di    "================================================================="
tab marry_year
count
