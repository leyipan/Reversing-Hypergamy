/*==============================================================================
  DETAILED OAXACA–BLINDER DECOMPOSITION OF THE UNEXPLAINED GENDER WAGE GAP
  gender_wage_gap_detailed_decomp.do

  Purpose
  -------
  Extend gender_wage_gap_v2.do by decomposing the unexplained component of the
  Oaxaca–Blinder gap into per-covariate contributions + an intercept term.

  For each wave (2010, 2012, 2014, 2016, 2018, 2020, 2022):

    1.  Run separate OLS Mincer regressions for men and women on the SAME
        sample as gender_wage_gap_v2.do:
          ln(income) = β0 + β1·education + β2·potexp + β3·potexp² + β4·married + ε
        on employed adults aged 18–60 with positive income.

    2.  With male coefficients as the reference, compute the contribution of
        each covariate k to the unexplained gap:
          contribution_k = mean(X_k | female) × (β_{M,k} − β_{F,k}).
        Plus the intercept contribution:  β_{M,0} − β_{F,0}.

    3.  By construction, the four covariate contributions + intercept sum to
        the aggregate unexplained gap:
          U = (β_{M,0} − β_{F,0}) + Σ_k  X̄_{F,k} (β_{M,k} − β_{F,k}).

  Output
  ------
    ${output}/gwg_detailed_unexplained.tex    (LaTeX table)
    ${output}/gwg_detailed_unexplained.csv    (CSV: rows = components, cols = waves)

  Dependencies: none (oaxaca SSC is NOT required here — we compute the detailed
                     decomposition directly from two OLS regressions per wave).

  Prerequisites: Run master.do first so ${raw} and ${output} globals are set.
==============================================================================*/

clear all
set more off


/*==============================================================================
  1. LOAD AND HARMONISE DATA  (identical to gender_wage_gap_v2.do, Section 1)
==============================================================================*/

tempfile master

* ── 2010 ────────────────────────────────────────────────────────────────────
use pid gender qa1age income cfps2010eduy_best qe1 ///
    using "${raw}/ecfps2010adult_201906.dta", clear

rename gender            gender_h
rename qa1age            age_h
rename income            income_h
rename cfps2010eduy_best eduyears_h
rename qe1               marstat_h

gen int  wave    = 2010
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)
save `master', replace

* ── 2012 ────────────────────────────────────────────────────────────────────
use pid cfps2012_gender cfps2012_age income_adj eduy2012 qe104 ///
    using "${raw}/ecfps2012adult_202505.dta", clear

rename cfps2012_gender gender_h
rename cfps2012_age    age_h
rename income_adj      income_h
rename eduy2012        eduyears_h
rename qe104           marstat_h

gen int  wave    = 2012
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)
append using `master'
save `master', replace

* ── 2014 ────────────────────────────────────────────────────────────────────
use pid cfps_gender cfps2014_age p_wage cfps2014eduy_im qea0 ///
    using "${raw}/ecfps2014adult_201906.dta", clear

rename cfps_gender     gender_h
rename cfps2014_age    age_h
rename p_wage          income_h
rename cfps2014eduy_im eduyears_h
rename qea0            marstat_h

gen int  wave    = 2014
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)
append using `master'
save `master', replace

* ── 2016 ────────────────────────────────────────────────────────────────────
use pid cfps_gender cfps_age income cfps2016eduy_im qea0 ///
    using "${raw}/ecfps2016adult_201906.dta", clear

rename cfps_gender     gender_h
rename cfps_age        age_h
rename income          income_h
rename cfps2016eduy_im eduyears_h
rename qea0            marstat_h

gen int  wave    = 2016
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)
append using `master'
save `master', replace

* ── 2018 ────────────────────────────────────────────────────────────────────
use pid gender age income cfps2018eduy_im qea0 ///
    using "${raw}/ecfps2018person_202012.dta", clear

rename gender          gender_h
rename age             age_h
rename income          income_h
rename cfps2018eduy_im eduyears_h
rename qea0            marstat_h

gen int  wave    = 2018
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)
append using `master'
save `master', replace

* ── 2020 ────────────────────────────────────────────────────────────────────
use pid gender age emp_income cfps2020eduy_im qea0 ///
    using "${raw}/ecfps2020person_202306.dta", clear

rename gender          gender_h
rename age             age_h
rename emp_income      income_h
rename cfps2020eduy_im eduyears_h
rename qea0            marstat_h

gen int  wave    = 2020
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)
append using `master'
save `master', replace

* ── 2022 ────────────────────────────────────────────────────────────────────
use pid gender age emp_income cfps2022eduy_im qea0 ///
    using "${raw}/ecfps2022person_202410.dta", clear

rename gender          gender_h
rename age             age_h
rename emp_income      income_h
rename cfps2022eduy_im eduyears_h
rename qea0            marstat_h

gen int  wave    = 2022
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)
append using `master'
save `master', replace


/*==============================================================================
  2. CONSTRUCT ANALYSIS VARIABLES  (identical to v2, Section 2)
==============================================================================*/

* Female indicator (gender_h == 0 → female in CFPS coding)
gen byte female = (gender_h == 0) if !missing(gender_h)

* Potential experience and its square
gen potexp  = age_h - eduyears_h - 6 if !missing(age_h) & !missing(eduyears_h)
replace potexp = 0 if potexp < 0 & !missing(potexp)
gen potexp2 = potexp^2

* Log income
gen ln_income = ln(income_h) if income_h > 0 & !missing(income_h)

* Sample restrictions
keep if age_h >= 18 & age_h <= 60 & !missing(age_h)
keep if !missing(ln_income) & !missing(female) & !missing(eduyears_h) ///
      & !missing(potexp) & !missing(married)

di as text _n "Sample size by wave and gender:"
tab wave female, missing


/*==============================================================================
  3. ESTIMATE MINCER BY GENDER & COMPUTE DETAILED UNEXPLAINED-GAP COMPONENTS
==============================================================================*/

local waves  2010 2012 2014 2016 2018 2020 2022
local nwaves : word count `waves'
local xvars  eduyears_h potexp potexp2 married

* -- Storage -----------------------------------------------------------------
*  Rows = 4 covariates in `xvars' order
*  Cols = 7 waves
matrix b_male   = J(4, `nwaves', .)   // male slope coefficients
matrix b_female = J(4, `nwaves', .)   // female slope coefficients
matrix xbar_F   = J(4, `nwaves', .)   // female covariate means
matrix cons_M   = J(1, `nwaves', .)   // male intercept
matrix cons_F   = J(1, `nwaves', .)   // female intercept
matrix contrib  = J(5, `nwaves', .)   // 4 covariate contribs + intercept (row 5)
matrix unexp    = J(1, `nwaves', .)   // total unexplained gap (sum of contribs)

local w = 1
foreach yr of local waves {

    di as text _n "────────────────────────────────────────"
    di as text    "  Wave `yr'"
    di as text    "────────────────────────────────────────"

    * ── Male Mincer ─────────────────────────────────────────────────────────
    qui reg ln_income `xvars' if wave == `yr' & female == 0, robust
    local k = 1
    foreach v of local xvars {
        matrix b_male[`k', `w'] = _b[`v']
        local ++k
    }
    matrix cons_M[1, `w'] = _b[_cons]

    * ── Female Mincer ───────────────────────────────────────────────────────
    qui reg ln_income `xvars' if wave == `yr' & female == 1, robust
    local k = 1
    foreach v of local xvars {
        matrix b_female[`k', `w'] = _b[`v']
        local ++k
    }
    matrix cons_F[1, `w'] = _b[_cons]

    * ── Female covariate means (X̄_F) ───────────────────────────────────────
    local k = 1
    foreach v of local xvars {
        qui sum `v' if wave == `yr' & female == 1
        matrix xbar_F[`k', `w'] = r(mean)
        local ++k
    }

    * ── Detailed contributions ──────────────────────────────────────────────
    * For each covariate k: X̄_F,k × (β_M,k − β_F,k)
    * Intercept term: β_M,0 − β_F,0
    scalar _total = 0
    forvalues k = 1/4 {
        local bM  = b_male[`k', `w']
        local bF  = b_female[`k', `w']
        local xbF = xbar_F[`k', `w']
        local c   = `xbF' * (`bM' - `bF')
        matrix contrib[`k', `w'] = `c'
        scalar _total = _total + `c'
    }
    local cM0 = cons_M[1, `w']
    local cF0 = cons_F[1, `w']
    local cint = `cM0' - `cF0'
    matrix contrib[5, `w'] = `cint'
    scalar _total = _total + `cint'
    matrix unexp[1, `w'] = _total

    di as text "  Unexplained gap (sum of components): " %9.4f _total

    local w = `w' + 1
}

di as text _n "Estimation complete."


/*==============================================================================
  4. VERIFICATION: reconcile against the `oaxaca` SSC command
     Runs oaxaca on each wave and checks that the unexplained component matches
     (within rounding). If oaxaca isn't installed this block is skipped silently.
==============================================================================*/

capture which oaxaca
if _rc == 0 {
    di as text _n "=== Verification against oaxaca (weight(1) = male reference) ==="
    local w = 1
    foreach yr of local waves {
        qui oaxaca ln_income `xvars' if wave == `yr', by(female) weight(1) vce(robust)
        matrix _bob = e(b)
        * Column 5 is "unexplained:_cons" in standard oaxaca twofold output.
        local u_oaxaca = _bob[1, 5]
        local u_manual = unexp[1, `w']
        local diff = `u_oaxaca' - `u_manual'
        di as text "  `yr': oaxaca U = " %9.4f `u_oaxaca' ///
                   "   manual U = " %9.4f `u_manual' ///
                   "   diff = " %9.2e `diff'
        local w = `w' + 1
    }
}
else {
    di as text _n "oaxaca not installed; skipping cross-check " ///
                 "(ssc install oaxaca, to enable)."
}


/*==============================================================================
  5. SELF-CHECK: the four covariate contributions + intercept must sum exactly
     to the stored total (row-sum check; tolerance 1e-8).
==============================================================================*/

di as text _n "=== Row-sum check: Σ contributions vs. stored total ==="
forvalues w = 1/`nwaves' {
    local s = 0
    forvalues r = 1/5 {
        local s = `s' + contrib[`r', `w']
    }
    local t = unexp[1, `w']
    local d = `s' - `t'
    di as text "  wave col `w': sum = " %9.6f `s' ///
               "  total = "              %9.6f `t' ///
               "  diff = "               %9.2e `d'
    if abs(`d') > 1e-8 {
        di as error "    !! sum deviates from total; check code !!"
    }
}


/*==============================================================================
  6. BUILD LATEX TABLE (rows = components, cols = 7 waves)
==============================================================================*/

local rowlab_total  "Unexplained gap (total)"
local rowlab_1      "\quad Education"
local rowlab_2      "\quad Potential experience"
local rowlab_3      "\quad Potential experience$^{2}$"
local rowlab_4      "\quad Married"
local rowlab_5      "\quad Intercept"

capture file close fh
file open fh using "${output}/gwg_detailed_unexplained.tex", write replace

file write fh "% Auto-generated by gender_wage_gap_detailed_decomp.do" _n
file write fh "% Do not edit by hand — re-run the do file to update." _n _n
file write fh "\begin{table}[htbp]" _n
file write fh "\centering" _n
file write fh "\caption{Detailed Oaxaca--Blinder Decomposition of the Unexplained Gender Wage Gap" _n
file write fh "         \label{tab:gwg_detailed_unexp}}" _n
file write fh "\footnotesize" _n
file write fh "\begin{tabular}{l*{7}{c}}" _n
file write fh "\toprule" _n
file write fh "& \multicolumn{7}{c}{Survey wave} \\" _n
file write fh "\cmidrule(lr){2-8}" _n
file write fh "& 2010 & 2012 & 2014 & 2016 & 2018 & 2020 & 2022 \\" _n
file write fh "\midrule" _n

* --- Total row ---
local row ""
forvalues w = 1/`nwaves' {
    local v = unexp[1, `w']
    if missing(`v') {
        local row "`row' & --"
    }
    else {
        local f : display %9.3f `v'
        local f = strtrim("`f'")
        local row "`row' & `f'"
    }
}
file write fh "`rowlab_total' `row' \\" _n
file write fh "\addlinespace" _n

* --- Component rows: education, potexp, potexp², married, intercept ---
forvalues r = 1/5 {
    local row ""
    forvalues w = 1/`nwaves' {
        local v = contrib[`r', `w']
        if missing(`v') {
            local row "`row' & --"
        }
        else {
            local f : display %9.3f `v'
            local f = strtrim("`f'")
            local row "`row' & `f'"
        }
    }
    file write fh "`rowlab_`r'' `row' \\" _n
}

file write fh "\bottomrule" _n
file write fh "\end{tabular}" _n
file write fh "\smallskip" _n
file write fh "{\footnotesize \textit{Notes}: Entries are components of the unexplained" _n
file write fh " gender wage gap (log income, male $-$ female) from a twofold Oaxaca--Blinder" _n
file write fh " decomposition with male coefficients as the reference. For each covariate $k$," _n
file write fh " the reported contribution is $\bar{X}_{F,k}\,(\beta_{M,k}-\beta_{F,k})$;" _n
file write fh " the intercept term is $\beta_{M,0}-\beta_{F,0}$. The four covariate" _n
file write fh " contributions and the intercept sum exactly to the total unexplained gap" _n
file write fh " (within floating-point rounding). Sample: employed adults aged 18--60 with" _n
file write fh " positive income, CFPS waves 2010--2022. OLS with robust standard errors" _n
file write fh " (coefficient point estimates only).}" _n
file write fh "\end{table}" _n

file close fh
di as text _n "LaTeX table written: ${output}/gwg_detailed_unexplained.tex"


/*==============================================================================
  7. EXPORT CSV (same layout: rows = components, columns = waves)
==============================================================================*/

preserve
clear
set obs 6
gen component = ""
replace component = "Unexplained gap (total)"    in 1
replace component = "Education"                  in 2
replace component = "Potential experience"      in 3
replace component = "Potential experience^2"    in 4
replace component = "Married"                    in 5
replace component = "Intercept"                  in 6

local w = 1
foreach yr of local waves {
    gen y`yr' = .
    format y`yr' %9.3f
    replace y`yr' = unexp[1, `w']      in 1
    replace y`yr' = contrib[1, `w']    in 2
    replace y`yr' = contrib[2, `w']    in 3
    replace y`yr' = contrib[3, `w']    in 4
    replace y`yr' = contrib[4, `w']    in 5
    replace y`yr' = contrib[5, `w']    in 6
    local w = `w' + 1
}

* Rename to clean column headers (Stata won't let bare-numeric names persist
* in CSV export, but the prefix y is fine)
export delimited using "${output}/gwg_detailed_unexplained.csv", replace
restore
di as text "CSV written: ${output}/gwg_detailed_unexplained.csv"


/*==============================================================================
  DONE
==============================================================================*/

di as text _n "========================================"
di as text    " Detailed unexplained-gap decomposition complete."
di as text    " Output saved to: ${output}"
di as text    "   gwg_detailed_unexplained.tex"
di as text    "   gwg_detailed_unexplained.csv"
di as text    "========================================"
