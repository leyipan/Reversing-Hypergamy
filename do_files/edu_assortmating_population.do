/*==============================================================================
  EDUCATION ASSORTATIVE MATING — POPULATION-LEVEL STACKED AREA CHART

  Aim: Combine the crude marriage rate (CMR, from Ministry of Civil Affairs
       via Statista) with the education sorting shares from CFPS to show
       hypergamy / homogamy / hypogamy as rates per 1,000 population.

       The three stacked areas sum to the CMR line, visually decomposing
       the marriage rate into its sorting components.

  Inputs:
    ${output}/edu_assortmating_historical.csv   (sorting shares by marry_year)
    CMR data hardcoded below (Ministry of Civil Affairs, via Statista 2026)

  Output:
    ${output}/edu_assortmating_population.png
    ${output}/edu_assortmating_population.csv

  Prerequisites: Run master.do and edu_assortmating_historical.do first.
==============================================================================*/

clear all
set more off


* ============================================================================
* 1. LOAD SORTING SHARES FROM CFPS
* ============================================================================

import delimited using "${output}/edu_assortmating_historical.csv", clear

keep if marry_year >= 2000 & marry_year <= 2022

di _n "=== Sorting shares (2000–2022) ==="
list marry_year pct_hyper pct_homo pct_hypo n, clean noobs


* ============================================================================
* 2. MERGE IN CRUDE MARRIAGE RATE (per 1,000 population)
* ============================================================================

/*
   Source: Ministry of Civil Affairs (China), via Statista 2026.
   "Marriage rate in China from 2000 to 2024 (per 1,000 population)"
   https://www.statista.com/statistics/1055659/china-marriage-rate/
*/

gen cmr = .
replace cmr = 6.7 if marry_year == 2000
replace cmr = 6.3 if marry_year == 2001
replace cmr = 6.1 if marry_year == 2002
replace cmr = 6.3 if marry_year == 2003
replace cmr = 6.7 if marry_year == 2004
replace cmr = 6.3 if marry_year == 2005
replace cmr = 7.2 if marry_year == 2006
replace cmr = 7.5 if marry_year == 2007
replace cmr = 8.3 if marry_year == 2008
replace cmr = 9.1 if marry_year == 2009
replace cmr = 9.3 if marry_year == 2010
replace cmr = 9.7 if marry_year == 2011
replace cmr = 9.8 if marry_year == 2012
replace cmr = 9.9 if marry_year == 2013
replace cmr = 9.6 if marry_year == 2014
replace cmr = 9.0 if marry_year == 2015
replace cmr = 8.3 if marry_year == 2016
replace cmr = 7.7 if marry_year == 2017
replace cmr = 7.3 if marry_year == 2018
replace cmr = 6.6 if marry_year == 2019
replace cmr = 5.8 if marry_year == 2020
replace cmr = 5.4 if marry_year == 2021
replace cmr = 4.8 if marry_year == 2022

label var cmr "Crude marriage rate (per 1,000 pop.)"


* ============================================================================
* 3. COMPUTE POPULATION-LEVEL RATES (per 1,000)
* ============================================================================

gen pop_hyper = cmr * (pct_hyper / 100)
gen pop_homo  = cmr * (pct_homo  / 100)
gen pop_hypo  = cmr * (pct_hypo  / 100)

label var pop_hyper "Hypergamy rate (per 1,000 pop.)"
label var pop_homo  "Homogamy rate (per 1,000 pop.)"
label var pop_hypo  "Hypogamy rate (per 1,000 pop.)"

* Stacked area cumulative bounds
gen area_hyper = pop_hyper
gen area_homo  = pop_hyper + pop_homo
gen area_hypo  = pop_hyper + pop_homo + pop_hypo

label var area_hyper "Upper bound: hypergamy band"
label var area_homo  "Upper bound: homogamy band"
label var area_hypo  "Upper bound: hypogamy band (≈ CMR)"

di _n "=== Population-level rates (per 1,000) ==="
list marry_year pop_hyper pop_homo pop_hypo cmr, clean noobs


* ============================================================================
* 4. STACKED AREA CHART
* ============================================================================

/*
   Strategy: Plot three filled areas from bottom to top using rarea,
   layered so that the topmost area is drawn first (background) and
   the bottommost last (foreground). Then overlay the CMR line.

   Stata's twoway rarea(y1 y2 x) fills between y1 and y2.

   Layer order (back to front):
     1. rarea: 0 → area_hypo  (hypogamy, top band)
     2. rarea: 0 → area_homo  (homogamy, middle band)
     3. rarea: 0 → area_hyper (hypergamy, bottom band)
     4. line:  cmr            (marriage rate outline)
*/

twoway ///
    (rarea area_homo area_hypo marry_year,   ///
        fcolor("191 56 75%60") lwidth(none)) ///
    (rarea area_hyper area_homo marry_year,  ///
        fcolor("75 146 219%60") lwidth(none)) ///
    (rarea area_hyper area_hyper marry_year,  ///
        color("42 60 130%0"))                 ///
    (area area_hyper marry_year,             ///
        fcolor("42 60 130%60") lwidth(none)) ///
    (line cmr marry_year,                    ///
        lcolor(black) lwidth(medthick) lpattern(solid)) ///
    , ///
    title("Education Sorting and Marriage Rate per 1,000 Population", size(medium)) ///
    subtitle("China, 2000–2022. Marriage rate from Ministry of Civil Affairs; sorting from CFPS.", size(vsmall)) ///
    ytitle("Per 1,000 population") xtitle("Year") ///
    ylabel(0(2)12, angle(0)) ///
    xlabel(2000(2)2022, angle(0)) ///
    legend(order(4 "Hypergamy (husband more educated)" ///
                 2 "Homogamy (same level)" ///
                 1 "Hypogamy (wife more educated)" ///
                 5 "Crude marriage rate") ///
           position(6) rows(2) size(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    scheme(s2color)

graph export "${output}/edu_assortmating_population.png", replace width(1200)


* ============================================================================
* 5. EXPORT CSV
* ============================================================================

keep marry_year pct_hyper pct_homo pct_hypo cmr pop_hyper pop_homo pop_hypo n

order marry_year cmr pct_hyper pct_homo pct_hypo pop_hyper pop_homo pop_hypo n

export delimited using "${output}/edu_assortmating_population.csv", replace


* ============================================================================
* DONE
* ============================================================================

di _n "========================================"
di " Population-level education sorting chart complete."
di " Output saved to: ${output}"
di "   edu_assortmating_population.png"
di "   edu_assortmating_population.csv"
di "========================================"
