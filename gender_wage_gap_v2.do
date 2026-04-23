/*==============================================================================
  Gender Wage Gap by Survey Wave — v2
  gender_wage_gap_v2.do

  Output: a single LaTeX table (gender_wage_gap_by_wave.tex) containing
    Panel A  –  Male Mincer coefficients
    Panel B  –  Female Mincer coefficients
    Panel C  –  Oaxaca–Blinder decomposition (explained / unexplained gap)

  Columns  : survey waves 2010 2012 2014 2016 2018 2020 2022
  Rows     : return to education, potential experience, potential experience²
             (×10⁻³), married, Oaxaca explained gap, Oaxaca unexplained gap,
             + observations per gender per wave

  Sample   : all working-age adults (18–60) with positive income in each wave
  Estimator: OLS with robust SEs; twofold Oaxaca–Blinder (male coefficients
             as reference; weight(1) = Blinder 1973)

  NOTE: does NOT use predicted lifetime income estimated from 2018 coefficients.
        Income comes directly from each CFPS wave file.

  Dependencies: oaxaca (SSC).  Install once with: ssc install oaxaca
==============================================================================*/

clear all
set more off

/*==============================================================================
  1.  LOAD AND HARMONISE DATA ACROSS WAVES
==============================================================================*/

tempfile master

* ── 2010 ──────────────────────────────────────────────────────────────────────
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


* ── 2012 ──────────────────────────────────────────────────────────────────────
use pid cfps2012_gender cfps2012_age income_adj eduy2012 qe104 ///
    using "${raw}/ecfps2012adult_202505.dta", clear

rename cfps2012_gender   gender_h
rename cfps2012_age      age_h
rename income_adj        income_h
rename eduy2012          eduyears_h
rename qe104             marstat_h

gen int  wave    = 2012
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)

append using `master'
save `master', replace


* ── 2014 ──────────────────────────────────────────────────────────────────────
use pid cfps_gender cfps2014_age p_wage cfps2014eduy_im qea0 ///
    using "${raw}/ecfps2014adult_201906.dta", clear

rename cfps_gender       gender_h
rename cfps2014_age      age_h
rename p_wage            income_h
rename cfps2014eduy_im   eduyears_h
rename qea0              marstat_h

gen int  wave    = 2014
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)

append using `master'
save `master', replace


* ── 2016 ──────────────────────────────────────────────────────────────────────
use pid cfps_gender cfps_age income cfps2016eduy_im qea0 ///
    using "${raw}/ecfps2016adult_201906.dta", clear

rename cfps_gender       gender_h
rename cfps_age          age_h
rename income            income_h
rename cfps2016eduy_im   eduyears_h
rename qea0              marstat_h

gen int  wave    = 2016
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)

append using `master'
save `master', replace


* ── 2018 ──────────────────────────────────────────────────────────────────────
use pid gender age income cfps2018eduy_im qea0 ///
    using "${raw}/ecfps2018person_202012.dta", clear

rename gender            gender_h
rename age               age_h
rename income            income_h
rename cfps2018eduy_im   eduyears_h
rename qea0              marstat_h

gen int  wave    = 2018
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)

append using `master'
save `master', replace


* ── 2020 ──────────────────────────────────────────────────────────────────────
use pid gender age emp_income cfps2020eduy_im qea0 ///
    using "${raw}/ecfps2020person_202306.dta", clear

rename gender            gender_h
rename age               age_h
rename emp_income        income_h
rename cfps2020eduy_im   eduyears_h
rename qea0              marstat_h

gen int  wave    = 2020
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)

append using `master'
save `master', replace


* ── 2022 ──────────────────────────────────────────────────────────────────────
use pid gender age emp_income cfps2022eduy_im qea0 ///
    using "${raw}/ecfps2022person_202410.dta", clear

rename gender            gender_h
rename age               age_h
rename emp_income        income_h
rename cfps2022eduy_im   eduyears_h
rename qea0              marstat_h

gen int  wave    = 2022
gen byte married = inlist(marstat_h, 2, 3) if marstat_h >= 1 & !missing(marstat_h)

append using `master'
save `master', replace


/*==============================================================================
  2.  CONSTRUCT ANALYSIS VARIABLES
==============================================================================*/

* Female indicator (gender_h == 0 → female in CFPS coding)
gen byte female = (gender_h == 0) if !missing(gender_h)

* Potential experience and its square
gen potexp  = age_h - eduyears_h - 6 if !missing(age_h) & !missing(eduyears_h)
replace potexp = 0 if potexp < 0 & !missing(potexp)
gen potexp2 = potexp^2

* Log income
gen ln_income = ln(income_h) if income_h > 0 & !missing(income_h)

* Sample restrictions: working-age adults with complete data
keep if age_h >= 18 & age_h <= 60 & !missing(age_h)
keep if !missing(ln_income) & !missing(female) & !missing(eduyears_h) ///
      & !missing(potexp) & !missing(married)

* Quick sample summary
di as text _n "Sample size by wave and gender:"
tab wave female, missing


/*==============================================================================
  3.  ESTIMATION: MINCER BY GENDER + OAXACA–BLINDER, BY WAVE
==============================================================================*/

local waves  2010 2012 2014 2016 2018 2020 2022
local nwaves : word count `waves'
local xvars  eduyears_h potexp potexp2 married

*  Storage matrices
*  Rows  = 4 Mincer regressors (eduyears_h, potexp, potexp2, married)
*  Cols  = 7 waves

foreach grp in male female {
    matrix b_`grp'  = J(4, `nwaves', .)
    matrix se_`grp' = J(4, `nwaves', .)
    matrix n_`grp'  = J(1, `nwaves', .)
}

*  Oaxaca storage
*  Row 1 = explained component, Row 2 = unexplained component
matrix b_ob  = J(2, `nwaves', .)
matrix se_ob = J(2, `nwaves', .)

local w = 1
foreach yr of local waves {

    di as text _n "────────────────────────────────────────"
    di as text    "  Wave `yr'"
    di as text    "────────────────────────────────────────"

    * ── Male Mincer ──────────────────────────────────────────────────────────
    di as text "  Male OLS..."
    qui reg ln_income `xvars' if wave == `yr' & female == 0, robust
    matrix n_male[1, `w'] = e(N)
    local k = 1
    foreach v of local xvars {
        matrix b_male[`k', `w']  = _b[`v']
        matrix se_male[`k', `w'] = _se[`v']
        local ++k
    }

    * ── Female Mincer ────────────────────────────────────────────────────────
    di as text "  Female OLS..."
    qui reg ln_income `xvars' if wave == `yr' & female == 1, robust
    matrix n_female[1, `w'] = e(N)
    local k = 1
    foreach v of local xvars {
        matrix b_female[`k', `w']  = _b[`v']
        matrix se_female[`k', `w'] = _se[`v']
        local ++k
    }

    * ── Oaxaca–Blinder decomposition ─────────────────────────────────────────
    *  by(female): group 1 = male (female==0), group 2 = female (female==1)
    *  weight(1)  = Blinder (1973): male coefficients used as benchmark
    *  Positive explained component means male advantage due to characteristics
    *  Positive unexplained component = residual (discrimination + unobservables)
    di as text "  Oaxaca–Blinder..."
    qui oaxaca ln_income `xvars' if wave == `yr', by(female) weight(1) vce(robust)

    * On the first wave, print e(b) column names so you can verify the naming
    * convention below.  Comment out after confirming.
    if `w' == 1 {
        di as text "  Diagnostic — e(b) column names for Oaxaca:"
        matrix list e(b)
    }

    *  Column names in e(b) for a twofold oaxaca decomposition are:
    *    "explained:_cons"   – total gap due to endowment differences
    *    "unexplained:_cons" – residual gap (coefficients + intercept)
    *
    *  If the matrix list above shows different names, update the two lines
    *  below accordingly (e.g. replace "explained:_cons" with the actual name).
    matrix b_ob_w = e(b)
    matrix V_ob_w = e(V)

    matrix b_ob_w = e(b)
	matrix V_ob_w = e(V)

	matrix b_ob[1, `w']  = b_ob_w[1, 4]
	matrix b_ob[2, `w']  = b_ob_w[1, 5]
	matrix se_ob[1, `w'] = sqrt(V_ob_w[4, 4])
	matrix se_ob[2, `w'] = sqrt(V_ob_w[5, 5])

    local w = `w' + 1
}

di as text _n "Estimation complete."


/*==============================================================================
  4.  BUILD LATEX TABLE
==============================================================================*/

*  Row labels (numbered to avoid space-in-macro issues)
local varlabel_1 "Education (years)"
local varlabel_2 "Potential experience"
local varlabel_3 "Pot.\ exp$^{2}$ ($\times 10^{-3}$)"
local varlabel_4 "Married"

local oblabel_1  "Explained gap"
local oblabel_2  "Unexplained gap"

capture file close fh
file open fh using "${output}/gender_wage_gap_by_wave.tex", write replace

* ── Preamble ─────────────────────────────────────────────────────────────────
file write fh "% Auto-generated by gender_wage_gap_v2.do" _n
file write fh "% Do not edit by hand — re-run the do file to update." _n _n
file write fh "\begin{table}[htbp]" _n
file write fh "\centering" _n
file write fh "\caption{Gender Wage Gap by Survey Wave: Mincer Coefficients " _n
file write fh "         and Oaxaca--Blinder Decomposition" _n
file write fh "         \label{tab:gwg_by_wave}}" _n
file write fh "\footnotesize" _n
file write fh "\begin{tabular}{l*{7}{c}}" _n
file write fh "\toprule" _n
file write fh "& \multicolumn{7}{c}{Survey wave} \\" _n
file write fh "\cmidrule(lr){2-8}" _n
file write fh "& 2010 & 2012 & 2014 & 2016 & 2018 & 2020 & 2022 \\" _n
file write fh "\midrule" _n

* ── Generic row-writing macro ────────────────────────────────────────────────
*
*  For each panel we loop k = 1/4 (variables) or r = 1/2 (Oaxaca components).
*  We build two locals:
*    coeff_row  – the formatted coefficient with stars
*    se_row     – the SE in parentheses
*  then write both lines to the file.

* ── Panel A: Male ─────────────────────────────────────────────────────────────
file write fh "\multicolumn{8}{l}{\textit{Panel A: Male}}\\\\" _n

forvalues k = 1/4 {

    * Scale: report potexp2 coefficient × 1000 for readability
    local scale = 1
    if `k' == 3 local scale = 1000

    * Build coefficient row
    local coeff_row ""
    local se_row    ""

    forvalues w = 1/`nwaves' {
        local b  = b_male[`k', `w']
        local se = se_male[`k', `w']

        * Check for missing (wave may have had too few obs)
        if missing(`b') | missing(`se') {
            local coeff_row "`coeff_row' & --"
            local se_row    "`se_row' & "
            continue
        }

        local bs = `b'  * `scale'
        local ss = `se' * `scale'

        local tst = abs(`b' / `se')
        local star ""
        if `tst' >= 1.645 local star "*"
        if `tst' >= 1.960 local star "**"
        if `tst' >= 2.576 local star "***"

        local bfmt: display %8.3f `bs'
        local bfmt = strtrim("`bfmt'")
        local sefmt: display %8.3f `ss'
        local sefmt = strtrim("`sefmt'")

        local coeff_row "`coeff_row' & `bfmt'`star'"
        local se_row    "`se_row' & (`sefmt')"
    }

    file write fh "\quad `varlabel_`k'' `coeff_row' \\" _n
    file write fh " `se_row' \\" _n
}

* Observations row — Male
local obs_row ""
forvalues w = 1/`nwaves' {
    local n = n_male[1, `w']
    if missing(`n') {
        local obs_row "`obs_row' & --"
    }
    else {
        local nfmt: display %8.0fc `n'
        local nfmt = strtrim("`nfmt'")
        local obs_row "`obs_row' & `nfmt'"
    }
}
file write fh "\quad Observations `obs_row' \\" _n
file write fh "\addlinespace" _n

* ── Panel B: Female ───────────────────────────────────────────────────────────
file write fh "\multicolumn{8}{l}{\textit{Panel B: Female}}\\\\" _n

forvalues k = 1/4 {

    local scale = 1
    if `k' == 3 local scale = 1000

    local coeff_row ""
    local se_row    ""

    forvalues w = 1/`nwaves' {
        local b  = b_female[`k', `w']
        local se = se_female[`k', `w']

        if missing(`b') | missing(`se') {
            local coeff_row "`coeff_row' & --"
            local se_row    "`se_row' & "
            continue
        }

        local bs = `b'  * `scale'
        local ss = `se' * `scale'

        local tst = abs(`b' / `se')
        local star ""
        if `tst' >= 1.645 local star "*"
        if `tst' >= 1.960 local star "**"
        if `tst' >= 2.576 local star "***"

        local bfmt: display %8.3f `bs'
        local bfmt = strtrim("`bfmt'")
        local sefmt: display %8.3f `ss'
        local sefmt = strtrim("`sefmt'")

        local coeff_row "`coeff_row' & `bfmt'`star'"
        local se_row    "`se_row' & (`sefmt')"
    }

    file write fh "\quad `varlabel_`k'' `coeff_row' \\" _n
    file write fh " `se_row' \\" _n
}

* Observations row — Female
local obs_row ""
forvalues w = 1/`nwaves' {
    local n = n_female[1, `w']
    if missing(`n') {
        local obs_row "`obs_row' & --"
    }
    else {
        local nfmt: display %8.0fc `n'
        local nfmt = strtrim("`nfmt'")
        local obs_row "`obs_row' & `nfmt'"
    }
}
file write fh "\quad Observations `obs_row' \\" _n
file write fh "\addlinespace" _n

* ── Panel C: Oaxaca–Blinder ───────────────────────────────────────────────────
file write fh "\multicolumn{8}{l}{\textit{Panel C: Oaxaca--Blinder decomposition (male coefficients as reference)}}\\\\" _n

forvalues r = 1/2 {

    local coeff_row ""
    local se_row    ""

    forvalues w = 1/`nwaves' {
        local b  = b_ob[`r', `w']
        local se = se_ob[`r', `w']

        if missing(`b') | missing(`se') {
            local coeff_row "`coeff_row' & --"
            local se_row    "`se_row' & "
            continue
        }

        local tst = abs(`b' / `se')
        local star ""
        if `tst' >= 1.645 local star "*"
        if `tst' >= 1.960 local star "**"
        if `tst' >= 2.576 local star "***"

        local bfmt: display %8.3f `b'
        local bfmt = strtrim("`bfmt'")
        local sefmt: display %8.3f `se'
        local sefmt = strtrim("`sefmt'")

        local coeff_row "`coeff_row' & `bfmt'`star'"
        local se_row    "`se_row' & (`sefmt')"
    }

    file write fh "\quad `oblabel_`r'' `coeff_row' \\" _n
    file write fh " `se_row' \\" _n
}

* ── Footer ───────────────────────────────────────────────────────────────────
file write fh "\bottomrule" _n
file write fh "\end{tabular}" _n
file write fh "\smallskip" _n
file write fh "{\footnotesize \textit{Notes}: Robust standard errors in parentheses." _n
file write fh " $^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$." _n
file write fh " Sample: employed adults aged 18--60 with positive income, all CFPS waves." _n
file write fh " Potential experience $= \text{age} - \text{education years} - 6$, floored at zero." _n
file write fh " Potential experience$^2$ coefficients scaled by $10^{-3}$ for readability." _n
file write fh " Oaxaca--Blinder decomposition uses male coefficients as the reference" _n
file write fh " (Blinder 1973 weighting). A positive explained gap indicates male advantage" _n
file write fh " due to observable characteristics; a positive unexplained gap reflects the" _n
file write fh " residual attributable to differential returns and unobservables." _n
file write fh " Income is drawn directly from each wave's CFPS file; predicted" _n
file write fh " lifetime income (estimated from 2018 Mincer coefficients) is not used.}" _n
file write fh "\end{table}" _n

file close fh

di as text _n "Table written to: ${output}/gender_wage_gap_by_wave.tex"
di as text    "Run from master.do or standalone (paths auto-set above)."


/*==============================================================================
  5.  VISUALISATIONS
==============================================================================*/

* Build a small dataset from the Oaxaca matrices for plotting
preserve
clear
local nw = 7
set obs `nw'

gen wave = .
gen explained = .
gen unexplained = .

local w = 1
foreach yr in 2010 2012 2014 2016 2018 2020 2022 {
    replace wave        = `yr'           in `w'
    replace explained   = b_ob[1, `w']   in `w'
    replace unexplained = b_ob[2, `w']   in `w'
    local w = `w' + 1
}

gen total_gap = explained + unexplained

* --------------------------------------------------------------------------
* Chart 1: Total gender wage gap over time (line plot)
* --------------------------------------------------------------------------

twoway (connected total_gap wave, ///
            mcolor(navy) lcolor(navy) msymbol(circle) lwidth(medthick)) ///
    , ///
    title("Gender Wage Gap Over Time") ///
    subtitle("Total Oaxaca–Blinder gap (log income, male – female)") ///
    ytitle("Log income gap") xtitle("Survey wave") ///
    xlabel(2010 2012 2014 2016 2018 2020 2022) ///
    yline(0, lcolor(gs10) lpattern(dash)) ///
    legend(off) scheme(s2color)
graph export "${output}/gwg_total_gap_trend.png", replace width(1200)

* --------------------------------------------------------------------------
* Chart 2: Explained vs unexplained gap (centered bar chart)
*   Explained gap: bars going downward from 0
*   Unexplained gap: bars going upward from 0
*   Horizontal line at 0 divides the two components
* --------------------------------------------------------------------------

gen expl_bot = -explained
gen expl_top = 0
gen unexp_bot = 0
gen unexp_top = unexplained

gen str label_unexp = string(unexplained, "%5.3f")
gen str label_expl  = string(explained, "%5.3f")
gen y_label_unexp = unexplained / 2
gen y_label_expl  = -explained / 2

twoway (rbar expl_bot expl_top wave, ///
            barwidth(1.2) color(navy%70)) ///
       (rbar unexp_bot unexp_top wave, ///
            barwidth(1.2) color(cranberry%70)) ///
       (scatter y_label_expl wave, ///
            msymbol(none) mlabel(label_expl) mlabcolor(white) mlabsize(medsmall)) ///
       (scatter y_label_unexp wave, ///
            msymbol(none) mlabel(label_unexp) mlabcolor(white) mlabsize(medsmall)) ///
    , ///
    title("Oaxaca–Blinder Decomposition by Wave") ///
    subtitle("All working adults") ///
    ytitle("Log income gap") xtitle("Survey wave") ///
    xlabel(2010 2012 2014 2016 2018 2020 2022) ///
    yline(0, lcolor(black) lwidth(medium)) ///
    legend(order(1 "Explained (characteristics)" ///
                 2 "Unexplained (returns + residual)") ///
           position(6) rows(1) size(small)) ///
    scheme(s2color)
graph export "${output}/gwg_oaxaca_decomp_by_wave.png", replace width(1200)

restore
