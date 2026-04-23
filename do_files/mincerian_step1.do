/*==============================================================================
  STEP 1: Estimate Mincerian Earnings Function — Pooled 2010–2018

  Data: CFPS person/adult files 2010–2018, merged with cross-year backbone.
  Purpose: Estimate pooled Mincer coefficients on unmarried working
           individuals across five waves, separately by gender.

  Model: ln(income) = b0 + b1*eduyear + b2*potexp + b3*potexp2

  Variable mapping across waves:
    Wave  File                              Income var    Marital status var
    2010  ecfps2010adult_201906.dta          income        qe1_best
    2012  ecfps2012adult_202505.dta          income_adj    qe104
    2014  ecfps2014adult_201906.dta          p_income      qea0
    2016  ecfps2016adult_201906.dta          income        qea0
    2018  ecfps2018person_202012.dta         income        qea0

  Education: cfps20XXeduy_im from cross-year file
  Birth year: birthy from cross-year file
  Gender: gender from cross-year file (0 = female, 1 = male)

  Sample: Unmarried (never married / divorced / widowed),
          working-age (16–60), annual income > 1,200 yuan.

  Prerequisites: Run master.do first.
==============================================================================*/

clear all
set more off
set maxvar 10000


* ============================================================================
* 0. LOAD CROSS-YEAR BACKBONE
* ============================================================================

use pid birthy gender ///
    cfps2010eduy_im cfps2012eduy_im cfps2014eduy_im cfps2016eduy_im ///
    cfps2018eduy_im ///
    using "${raw}/ecfps2022crossyear_202601.dta", clear

* Clean
replace birthy = . if birthy < 0
foreach yr in 2010 2012 2014 2016 2018 {
    replace cfps`yr'eduy_im = . if cfps`yr'eduy_im < 0
}

gen female = (gender == 0)

tempfile crossyear
save `crossyear'


* ============================================================================
* 1. BUILD POOLED ESTIMATION SAMPLE (2010–2018)
* ============================================================================

/*
   For each wave 2010–2018, we:
   (a) Load the person/adult file for income and marital status
   (b) Merge with cross-year file for education years and birth year
   (c) Construct sample of unmarried working individuals
   (d) Append into a single pooled dataset
*/

tempfile pooled

* ---- 2010 ----
use pid income qe1_best using "${raw}/ecfps2010adult_201906.dta", clear
rename income annual_income
rename qe1_best marstat
merge m:1 pid using `crossyear', keep(match) nogen

local yr = 2010
gen eduyear = cfps2010eduy_im
gen age = `yr' - birthy
gen potexp = age - eduyear - 6
replace potexp = 0 if potexp < 0 & potexp != .
gen potexp2 = potexp^2

replace marstat = . if marstat <= 0
gen unmarried = (marstat == 1 | marstat == 4 | marstat == 5)
replace annual_income = . if annual_income < 0
replace annual_income = . if annual_income == 0
replace annual_income = . if annual_income < 1200
gen ln_income = ln(annual_income)

gen in_sample = (unmarried == 1) & !missing(ln_income) & !missing(eduyear) ///
              & !missing(potexp) & (age >= 16 & age <= 60)
gen int wave = `yr'

keep if in_sample == 1
keep pid female eduyear potexp potexp2 ln_income annual_income wave age
save `pooled', replace


* ---- 2012 ----
use pid income_adj qe104 using "${raw}/ecfps2012adult_202505.dta", clear
rename income_adj annual_income
rename qe104 marstat
merge m:1 pid using `crossyear', keep(match) nogen

local yr = 2012
gen eduyear = cfps2012eduy_im
gen age = `yr' - birthy
gen potexp = age - eduyear - 6
replace potexp = 0 if potexp < 0 & potexp != .
gen potexp2 = potexp^2

replace marstat = . if marstat <= 0
gen unmarried = (marstat == 1 | marstat == 4 | marstat == 5)
replace annual_income = . if annual_income < 0
replace annual_income = . if annual_income == 0
replace annual_income = . if annual_income < 1200
gen ln_income = ln(annual_income)

gen in_sample = (unmarried == 1) & !missing(ln_income) & !missing(eduyear) ///
              & !missing(potexp) & (age >= 16 & age <= 60)
gen int wave = `yr'

keep if in_sample == 1
keep pid female eduyear potexp potexp2 ln_income annual_income wave age
append using `pooled'
save `pooled', replace


* ---- 2014 ----
use pid p_income qea0 using "${raw}/ecfps2014adult_201906.dta", clear
rename p_income annual_income
rename qea0 marstat
merge m:1 pid using `crossyear', keep(match) nogen

local yr = 2014
gen eduyear = cfps2014eduy_im
gen age = `yr' - birthy
gen potexp = age - eduyear - 6
replace potexp = 0 if potexp < 0 & potexp != .
gen potexp2 = potexp^2

replace marstat = . if marstat <= 0
gen unmarried = (marstat == 1 | marstat == 4 | marstat == 5)
replace annual_income = . if annual_income < 0
replace annual_income = . if annual_income == 0
replace annual_income = . if annual_income < 1200
gen ln_income = ln(annual_income)

gen in_sample = (unmarried == 1) & !missing(ln_income) & !missing(eduyear) ///
              & !missing(potexp) & (age >= 16 & age <= 60)
gen int wave = `yr'

keep if in_sample == 1
keep pid female eduyear potexp potexp2 ln_income annual_income wave age
append using `pooled'
save `pooled', replace


* ---- 2016 ----
use pid income qea0 using "${raw}/ecfps2016adult_201906.dta", clear
rename income annual_income
rename qea0 marstat
merge m:1 pid using `crossyear', keep(match) nogen

local yr = 2016
gen eduyear = cfps2016eduy_im
gen age = `yr' - birthy
gen potexp = age - eduyear - 6
replace potexp = 0 if potexp < 0 & potexp != .
gen potexp2 = potexp^2

replace marstat = . if marstat <= 0
gen unmarried = (marstat == 1 | marstat == 4 | marstat == 5)
replace annual_income = . if annual_income < 0
replace annual_income = . if annual_income == 0
replace annual_income = . if annual_income < 1200
gen ln_income = ln(annual_income)

gen in_sample = (unmarried == 1) & !missing(ln_income) & !missing(eduyear) ///
              & !missing(potexp) & (age >= 16 & age <= 60)
gen int wave = `yr'

keep if in_sample == 1
keep pid female eduyear potexp potexp2 ln_income annual_income wave age
append using `pooled'
save `pooled', replace


* ---- 2018 ----
use pid income qea0 using "${raw}/ecfps2018person_202012.dta", clear
rename income annual_income
rename qea0 marstat
merge m:1 pid using `crossyear', keep(match) nogen

local yr = 2018
gen eduyear = cfps2018eduy_im
gen age = `yr' - birthy
gen potexp = age - eduyear - 6
replace potexp = 0 if potexp < 0 & potexp != .
gen potexp2 = potexp^2

replace marstat = . if marstat <= 0
gen unmarried = (marstat == 1 | marstat == 4 | marstat == 5)
replace annual_income = . if annual_income < 0
replace annual_income = . if annual_income == 0
replace annual_income = . if annual_income < 1200
gen ln_income = ln(annual_income)

gen in_sample = (unmarried == 1) & !missing(ln_income) & !missing(eduyear) ///
              & !missing(potexp) & (age >= 16 & age <= 60)
gen int wave = `yr'

keep if in_sample == 1
keep pid female eduyear potexp potexp2 ln_income annual_income wave age
append using `pooled'
save `pooled', replace


* ============================================================================
* 2. POOLED SAMPLE SUMMARY
* ============================================================================

use `pooled', clear

di ""
di "============================================="
di " POOLED SAMPLE SUMMARY (2010–2018)"
di " Unmarried working individuals, age 16–60"
di " Annual income > 1,200 yuan"
di "============================================="
tab wave female
count

* Age group table
gen age_group = .
replace age_group = 1 if age >= 16 & age <= 20
replace age_group = 2 if age >= 21 & age <= 25
replace age_group = 3 if age >= 26 & age <= 30
replace age_group = 4 if age >= 31 & age <= 35
replace age_group = 5 if age >= 36 & age <= 40
replace age_group = 6 if age >= 41 & age <= 45
replace age_group = 7 if age >= 46 & age <= 50
replace age_group = 8 if age >= 51 & age <= 55
replace age_group = 9 if age >= 56 & age <= 60

label define age_grp 1 "16-20" 2 "21-25" 3 "26-30" 4 "31-35" 5 "36-40" ///
                     6 "41-45" 7 "46-50" 8 "51-55" 9 "56-60"
label values age_group age_grp

di ""
di "=== Pooled Sample by Age Group ==="
di "--- Males ---"
tab age_group if female == 0
di "--- Females ---"
tab age_group if female == 1


* ============================================================================
* 3. STEP 1 REGRESSION: MINCERIAN EARNINGS FUNCTION (SEPARATE BY GENDER)
* ============================================================================

/*
   We estimate separately for males and females on the pooled sample.
   Model progression:
     M1: Classic Mincer (eduyear + potexp + potexp2)
     M2: + Wave fixed effects (absorb time-varying macro conditions)

   The pooled approach gives more statistical power and produces a single
   set of gender-specific returns that average over the 2010–2018 period.
*/


* ==========================================================================
* MALE SAMPLE
* ==========================================================================

* Model M1: Classic Mincer (pooled)
reg ln_income eduyear potexp potexp2 ///
    if female == 0, robust
estimates store m_male1
estadd local WaveFE "No"

* Model M2: + Wave fixed effects
reg ln_income eduyear potexp potexp2 i.wave ///
    if female == 0, robust
estimates store m_male2
estadd local WaveFE "Yes"

* Display male results
esttab m_male1 m_male2, ///
     b(%9.3f) se(%9.3f) ///
     star(* 0.10 ** 0.05 *** 0.01) ///
     stats(N r2_a WaveFE, ///
           labels("Observations" "Adjusted R²" "Wave FE") ///
           fmt(%9.0g %9.3f %s)) ///
     title("Mincerian Earnings Function: MALES (Pooled 2010–2018)") ///
     mtitles("Classic" "+Wave FE") ///
     drop(*wave*) ///
     note("Robust standard errors in parentheses." ///
          "Dependent variable: log annual income." ///
          "Sample: unmarried working adults aged 16–60, pooled 2010–2018.")


* ==========================================================================
* FEMALE SAMPLE
* ==========================================================================

* Model F1: Classic Mincer (pooled)
reg ln_income eduyear potexp potexp2 ///
    if female == 1, robust
estimates store m_female1
estadd local WaveFE "No"

* Model F2: + Wave fixed effects
reg ln_income eduyear potexp potexp2 i.wave ///
    if female == 1, robust
estimates store m_female2
estadd local WaveFE "Yes"

* Display female results
esttab m_female1 m_female2, ///
     b(%9.3f) se(%9.3f) ///
     star(* 0.10 ** 0.05 *** 0.01) ///
     stats(N r2_a WaveFE, ///
           labels("Observations" "Adjusted R²" "Wave FE") ///
           fmt(%9.0g %9.3f %s)) ///
     title("Mincerian Earnings Function: FEMALES (Pooled 2010–2018)") ///
     mtitles("Classic" "+Wave FE") ///
     drop(*wave*) ///
     note("Robust standard errors in parentheses." ///
          "Dependent variable: log annual income." ///
          "Sample: unmarried working adults aged 16–60, pooled 2010–2018.")


* ==========================================================================
* COMBINED TABLE FOR THESIS (Classic Mincer, side by side)
* ==========================================================================

esttab m_male1 m_female1, ///
    b(%9.3f) se(%9.3f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2_a, ///
          labels("Observations" "Adjusted R²") ///
          fmt(%9.0g %9.3f)) ///
    title("Mincerian Earnings Function by Gender (Pooled 2010–2018)") ///
    mtitles("Male" "Female") ///
    note("Robust standard errors in parentheses." ///
         "Dependent variable: log annual income." ///
         "Sample: unmarried working adults aged 16–60, pooled 2010–2018.")

* Export to LaTeX
esttab m_male1 m_female1 using "${output}/mincer_step1_bygender.tex", replace ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2_a, ///
          labels("Observations" "Adj. R\textsuperscript{2}") ///
          fmt(%9.0g %9.3f)) ///
    title("Mincerian Earnings Function by Gender (Pooled 2010--2018)\label{tab:mincerbaseline}") ///
    mtitles("Male" "Female") booktabs ///
    gaps ///
    addnotes("Robust standard errors in parentheses. Dependent variable: log annual income." ///
             "Sample: unmarried working adults aged 16--60, pooled CFPS 2010--2018.")

* Combined table with wave FE
esttab m_male2 m_female2 using "${output}/mincer_step1_bygender_wavefe.tex", replace ///
    b(%9.3f) se(%9.3f) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2_a WaveFE, ///
          labels("Observations" "Adj. R\textsuperscript{2}" "Wave FE") ///
          fmt(%9.0g %9.3f %s)) ///
    title("Mincerian Earnings Function with Wave FE (Pooled 2010--2018)\label{tab:mincerwavefe}") ///
    mtitles("Male" "Female") booktabs ///
    drop(*wave*) gaps ///
    addnotes("Robust standard errors in parentheses. Dependent variable: log annual income." ///
             "Sample: unmarried working adults aged 16--60, pooled CFPS 2010--2018.")


* ============================================================================
* 4. SAVE COEFFICIENTS FOR STEP 2
* ============================================================================

* --- Male (classic Mincer, no wave FE — used for prediction) ---
quietly reg ln_income eduyear potexp potexp2 ///
    if female == 0, robust
estimates save "${output}/mincer_male_pooled", replace
matrix b_male = e(b)
matrix list b_male

* --- Female ---
quietly reg ln_income eduyear potexp potexp2 ///
    if female == 1, robust
estimates save "${output}/mincer_female_pooled", replace
matrix b_female = e(b)
matrix list b_female


* ============================================================================
* 5. DIAGNOSTICS
* ============================================================================

* Check for multicollinearity
quietly reg ln_income eduyear potexp potexp2
vif

* Residual distribution — Male
quietly reg ln_income eduyear potexp potexp2 ///
    if female == 0, robust
predict resid_male if e(sample), residuals
histogram resid_male, normal ///
    title("Residuals from Pooled Mincer Model (Male)") ///
    note("Sample: unmarried working males, pooled 2010–2018")
graph export "${output}/resid_hist_male.png", replace

* Residual distribution — Female
quietly reg ln_income eduyear potexp potexp2 ///
    if female == 1, robust
predict resid_female if e(sample), residuals
histogram resid_female, normal ///
    title("Residuals from Pooled Mincer Model (Female)") ///
    note("Sample: unmarried working females, pooled 2010–2018")
graph export "${output}/resid_hist_female.png", replace

* Predicted vs actual — Male
quietly reg ln_income eduyear potexp potexp2 ///
    if female == 0, robust
predict yhat_male if e(sample), xb
twoway (scatter ln_income yhat_male if e(sample), msize(tiny) mcolor(gs10)) ///
       (line yhat_male yhat_male, lcolor(red)), ///
    title("Predicted vs. Actual Log Income (Male)") ///
    subtitle("Pooled 2010–2018") ///
    xtitle("Predicted ln(income)") ytitle("Actual ln(income)")
graph export "${output}/pred_vs_actual_male.png", replace

* Predicted vs actual — Female
quietly reg ln_income eduyear potexp potexp2 ///
    if female == 1, robust
predict yhat_female if e(sample), xb
twoway (scatter ln_income yhat_female if e(sample), msize(tiny) mcolor(gs10)) ///
       (line yhat_female yhat_female, lcolor(red)), ///
    title("Predicted vs. Actual Log Income (Female)") ///
    subtitle("Pooled 2010–2018") ///
    xtitle("Predicted ln(income)") ytitle("Actual ln(income)")
graph export "${output}/pred_vs_actual_female.png", replace


* ============================================================================
* 6. SUMMARY STATISTICS TABLE
* ============================================================================

* --- Male sample ---
estpost summarize ln_income annual_income eduyear potexp age ///
    if female == 0

esttab using "${output}/summary_stats_male.tex", replace ///
    cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0)) count(fmt(0))") ///
    title("Summary Statistics: Unmarried Working Males (Pooled 2010--2018)") ///
    nomtitle nonumber booktabs

* --- Female sample ---
estpost summarize ln_income annual_income eduyear potexp age ///
    if female == 1

esttab using "${output}/summary_stats_female.tex", replace ///
    cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0)) count(fmt(0))") ///
    title("Summary Statistics: Unmarried Working Females (Pooled 2010--2018)") ///
    nomtitle nonumber booktabs

* --- Combined table (both genders side by side) ---
estpost summarize ln_income annual_income eduyear potexp age ///
    if female == 0
estimates store stats_male

estpost summarize ln_income annual_income eduyear potexp age ///
    if female == 1
estimates store stats_female

esttab stats_male stats_female using "${output}/summary_stats_bygender.tex", replace ///
    cells("mean(fmt(2)) sd(par fmt(2))") ///
    title("Summary Statistics by Gender (Pooled 2010--2018)") ///
    mtitles("Male" "Female") ///
    nonumber booktabs

save "${work}/cfps_mincer_step1_pooled.dta", replace

di "============================================="
di " Step 1 (pooled 2010–2018) complete."
di " Estimated: ln(income) = b0 + b1*eduyear + b2*potexp + b3*potexp2"
di " Separately by gender on pooled sample."
di " Coefficients saved to:"
di "   ${output}/mincer_male_pooled.ster"
di "   ${output}/mincer_female_pooled.ster"
di "============================================="
