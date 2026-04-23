/*==============================================================================
  HISTORICAL EDUCATION ASSORTATIVE MATING TRENDS (LINE PLOT)
  Data: cfps_couples_allwaves.dta (couple-level dataset)

  Aim: Plot hypergamy / homogamy / hypogamy shares by marriage year,
       pooling couple observations from every available CFPS wave to
       extend coverage from ~1981 through ~2022.

  wife_edu / husband_edu are CFPS education level codes (1–9),
  mapped directly to 5 chart categories. No years conversion needed.

  Selection: marry_year > 1980

  Output:
    ${output}/edu_assortmating_historical.png
    ${output}/edu_assortmating_historical.csv
    ${output}/edu_assortmating_historical_samples_bywave.csv
    ${output}/edu_assortmating_historical_samples_detailed.csv

  Prerequisites: Run master.do and build_couples_dataset.do first.
==============================================================================*/

clear all
set more off


* ============================================================================
* 1. LOAD DATA AND FILTER
* ============================================================================

use "${work}/cfps_couples_allwaves.dta", clear

keep if marry_year > 1980 & !missing(marry_year)


* ============================================================================
* 2. MAP EDUCATION LEVEL CODES TO 5 CATEGORIES
* ============================================================================

/*
   CFPS codes → 7 chart categories:
     1 "Primary or below"  ← codes 1, 2, 9
     2 "Middle school"     ← code 3
     3 "High school"       ← code 4
     4 "College"           ← code 5
     5 "Bachelor's"        ← code 6
     6 "Master's"          ← code 7
     7 "Doctoral"          ← code 8
*/

foreach role in w h {
    local src = cond("`role'" == "w", "wife_edu", "husband_edu")
    gen `role'_ecat = .
    replace `role'_ecat = 1 if inlist(`src', 1, 2, 9)
    replace `role'_ecat = 2 if `src' == 3
    replace `role'_ecat = 3 if `src' == 4
    replace `role'_ecat = 4 if `src' == 5
    replace `role'_ecat = 5 if `src' == 6
    replace `role'_ecat = 6 if `src' == 7
    replace `role'_ecat = 7 if `src' == 8
}

label define edu_lbl 1 "Primary or below" 2 "Middle" 3 "High school" ///
                     4 "College" 5 "Bachelor's" 6 "Master's" 7 "Doctoral"
label values h_ecat edu_lbl
label values w_ecat edu_lbl

drop if missing(h_ecat) | missing(w_ecat)

di "Couples with valid education for both spouses: `=_N'"


* ============================================================================
* 3. SORTING INDICATORS
* ============================================================================

gen edu_homo  = (h_ecat == w_ecat)
gen edu_hyper = (h_ecat >  w_ecat)          // husband more educated
gen edu_hypo  = (w_ecat >  h_ecat)          // wife more educated

label var edu_homo  "1 = Homogamy (same degree level)"
label var edu_hyper "1 = Hypergamy (husband more educated)"
label var edu_hypo  "1 = Hypogamy (wife more educated)"

di _n "=== Overall education sorting ==="
sum edu_homo edu_hyper edu_hypo


* ============================================================================
* 4. SAMPLE TABLES
* ============================================================================

* --- 4a. Summary by wave ---
preserve

collapse (count) n = edu_homo, by(wave)

label var wave "CFPS wave"
label var n    "Number of couple-observations"

di _n "=== Sample by wave ==="
list, clean noobs

export delimited using "${output}/edu_assortmating_historical_samples_bywave.csv", replace

restore

* --- 4b. Detailed: sample by wave × marriage year ---
preserve

collapse (count) n = edu_homo, by(marry_year wave)
reshape wide n, i(marry_year) j(wave)

foreach yr in 2010 2012 2014 2016 2018 2020 2022 {
    capture rename n`yr' n_wave`yr'
}

di _n "=== Sample by marriage year x wave (first 20 rows) ==="
list in 1/20, clean noobs

export delimited using "${output}/edu_assortmating_historical_samples_detailed.csv", replace

restore


* ============================================================================
* 5. COLLAPSE TO SHARES BY MARRIAGE YEAR
* ============================================================================

collapse (mean) pct_homo  = edu_homo  ///
         (mean) pct_hyper = edu_hyper ///
         (mean) pct_hypo  = edu_hypo  ///
         (count) n        = edu_homo, ///
    by(marry_year)

foreach v in pct_homo pct_hyper pct_hypo {
    replace `v' = `v' * 100
}

label var pct_homo  "Homogamy (%)"
label var pct_hyper "Hypergamy — husband more educated (%)"
label var pct_hypo  "Hypogamy — wife more educated (%)"
label var n         "Number of couples"

di _n "=== Shares by marriage year (first 20 rows) ==="
list marry_year pct_hyper pct_homo pct_hypo n in 1/20, clean noobs


* ============================================================================
* 6. LINE PLOT
* ============================================================================

twoway ///
    (line pct_hyper marry_year, lcolor(navy)      lwidth(medthick) lpattern(solid))  ///
    (line pct_homo  marry_year, lcolor(ebblue)    lwidth(medthick) lpattern(solid))  ///
    (line pct_hypo  marry_year, lcolor(cranberry)  lwidth(medthick) lpattern(solid)) ///
    , ///
    title("Education Assortative Mating Trends by Marriage Year", size(medium)) ///
    subtitle("By Year of Marriage, CFPS 2010–2022") ///
    ytitle("Share of couples (%)") xtitle("Year of marriage") ///
    ylabel(0(10)100, angle(0)) ///
    xlabel(, angle(0)) ///
    legend(order(1 "Hypergamy" ///
                 2 "Homogamy" ///
                 3 "Hypogamy") ///
           position(6) rows(1) size(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    scheme(s2color)

graph export "${output}/edu_assortmating_historical.png", replace width(1200)


* ============================================================================
* 7. EXPORT CSV
* ============================================================================

export delimited using "${output}/edu_assortmating_historical.csv", replace


* ============================================================================
* DONE
* ============================================================================

di _n "========================================"
di " Historical education assortative mating complete."
di " Output saved to: ${output}"
di "   edu_assortmating_historical.png"
di "   edu_assortmating_historical.csv"
di "   edu_assortmating_historical_samples_bywave.csv"
di "   edu_assortmating_historical_samples_detailed.csv"
di "========================================"
