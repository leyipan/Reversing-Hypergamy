/*==============================================================================
  EDUCATION ASSORTATIVE MATING — BY RURAL / URBAN
  (historical line plot AND population-level stacked area)

  Data: cfps_couples_allwaves.dta (couple-level, built by build_couples_dataset.do)
        Raw CFPS adult/person files (for urban/rural dummy)
        Crude marriage rate (CMR) hardcoded from Ministry of Civil Affairs
          via Statista 2026.

  Aim: Replicate edu_assortmating_historical.do AND edu_assortmating_population.do,
       with trends split by whether the couple lives in an urban or rural area
       (NBS Census Bureau definition, as recorded at the respondent's interview
       wave).

  Approach:
    - Load the existing couples dataset.
    - For each wave, merge in the respondent's wave-specific urban dummy
      (urban / urban12 / urban14 / urban16 / urban18 / urban20 / urban22).
    - Clean negative missing codes to Stata missing.
    - Drop couples with missing urban status.
    - Produce TWO figures:
        (a) Two-panel line plot (rural | urban): hypergamy / homogamy /
            hypogamy shares by marriage year (1981–2022), with one panel
            per residence type.
        (b) Single-panel stacked area (2000–2022): 6 bands decomposing the
            national crude marriage rate (CMR) into sorting type ×
            rural/urban. Sorting type is encoded by COLOR (hyper / homo /
            hypo), rural vs urban by FILL PATTERN (urban = solid; rural =
            crosshatch). The bands sum exactly to the national CMR in
            each year.

  Population-level decomposition:
    pop_<type>_<group>(y) = CMR(y) × s_<group>(y) × pct_<type>_<group>(y) / 100
      where s_<group>(y) is the share of couples observed in year y
      classified as rural / urban. The 6 components sum to CMR by construction.

  Caveats:
    - Residence timing: the NBS `urban` variable records residence at the
      interview wave, not at time of marriage. Trends by marry_year describe
      today's rural vs. urban couples' historical sorting patterns.
    - The rural / urban share s_<group>(y) is the CFPS-sample share, not a
      population-weighted national share. Treat the decomposition as a
      stylized accounting of sorting composition within the CFPS couple
      sample, scaled to the national CMR.

  Selection: marry_year > 1980 (line plot); marry_year in 2000–2022 (area plot).

  Output:
    ${output}/edu_assortmating_historical_by_urban.png
    ${output}/edu_assortmating_historical_by_urban.csv
    ${output}/edu_assortmating_historical_by_urban_samples.csv
    ${output}/edu_assortmating_population_by_urban.png
    ${output}/edu_assortmating_population_by_urban.csv

  Prerequisites: Run master.do and build_couples_dataset.do first.
==============================================================================*/

clear all
set more off


* ============================================================================
* 1. LOAD COUPLES DATASET
* ============================================================================

use "${work}/cfps_couples_allwaves.dta", clear

di _n "=== Couples dataset as loaded ==="
count
local N_start = r(N)


* ============================================================================
* 2. BUILD WAVE-BY-WAVE URBAN LOOKUP FROM RAW FILES
*    Each wave's adult/person file has a wave-specific urban variable.
* ============================================================================

tempfile urban_all

* ---- 2010 ----
use pid urban using "${raw}/ecfps2010adult_201906.dta", clear
rename urban resp_urban
gen int wave = 2010
tempfile u2010
save `u2010'

* ---- 2012 ----
use pid urban12 using "${raw}/ecfps2012adult_202505.dta", clear
rename urban12 resp_urban
gen int wave = 2012
tempfile u2012
save `u2012'

* ---- 2014 ----
use pid urban14 using "${raw}/ecfps2014adult_201906.dta", clear
rename urban14 resp_urban
gen int wave = 2014
tempfile u2014
save `u2014'

* ---- 2016 ----
use pid urban16 using "${raw}/ecfps2016adult_201906.dta", clear
rename urban16 resp_urban
gen int wave = 2016
tempfile u2016
save `u2016'

* ---- 2018 ----
use pid urban18 using "${raw}/ecfps2018person_202012.dta", clear
rename urban18 resp_urban
gen int wave = 2018
tempfile u2018
save `u2018'

* ---- 2020 ----
use pid urban20 using "${raw}/ecfps2020person_202306.dta", clear
rename urban20 resp_urban
gen int wave = 2020
tempfile u2020
save `u2020'

* ---- 2022 ----
use pid urban22 using "${raw}/ecfps2022person_202410.dta", clear
rename urban22 resp_urban
gen int wave = 2022
tempfile u2022
save `u2022'

* ---- Append ----
use `u2010', clear
foreach yr in 2012 2014 2016 2018 2020 2022 {
    append using `u`yr''
}

* Clean negative missing codes
replace resp_urban = . if inlist(resp_urban, -1, -2, -8, -9, -10)

* Make sure (pid, wave) is unique before the merge
duplicates drop pid wave, force

save `urban_all', replace


* ============================================================================
* 3. MERGE URBAN ONTO COUPLES
* ============================================================================

use "${work}/cfps_couples_allwaves.dta", clear

merge 1:1 pid wave using `urban_all', keep(master match) nogen

label define urban_lbl 0 "Rural" 1 "Urban"
label values resp_urban urban_lbl
label var resp_urban "Couple rural/urban (respondent's residence at interview)"

* Couple-level dummy = respondent's urban (couples share a residence)
gen byte couple_urban = resp_urban
label values couple_urban urban_lbl
label var couple_urban "1 = Urban couple; 0 = Rural couple"


* ============================================================================
* 4. REPORT SAMPLE-SIZE IMPACT OF THE DUMMY
* ============================================================================

di _n "=== Couple-level sample sizes (diagnostic) ==="
di "Rows before adding dummy: `N_start'"
count
local N_after_merge = r(N)
di "Rows after merging urban (should equal): `N_after_merge'"

count if !missing(couple_urban)
local N_with_urban = r(N)
count if missing(couple_urban)
local N_missing_urban = r(N)
di "  with non-missing couple_urban: `N_with_urban'"
di "  with missing couple_urban:     `N_missing_urban'"

di _n "=== Missing couple_urban by wave ==="
tab wave, miss
tab wave couple_urban, miss


* ============================================================================
* 5. FIGURE FILTERS (match edu_assortmating_historical.do) + DROP MISSING
* ============================================================================

keep if marry_year > 1980 & !missing(marry_year)
di "After marry_year > 1980 filter:"
count

drop if missing(couple_urban)
di "After dropping missing couple_urban:"
count


* ============================================================================
* 6. MAP EDUCATION CODES TO 7 CATEGORIES (same mapping as original)
* ============================================================================

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

di _n "Final analytic sample (valid edu + non-missing urban):"
count


* ============================================================================
* 7. SORTING INDICATORS
* ============================================================================

gen edu_homo  = (h_ecat == w_ecat)
gen edu_hyper = (h_ecat >  w_ecat)          // husband more educated
gen edu_hypo  = (w_ecat >  h_ecat)          // wife more educated

label var edu_homo  "1 = Homogamy"
label var edu_hyper "1 = Hypergamy (husband more educated)"
label var edu_hypo  "1 = Hypogamy (wife more educated)"

di _n "=== Sorting shares by couple_urban ==="
bysort couple_urban: sum edu_homo edu_hyper edu_hypo


* ============================================================================
* 8. SAMPLE-SIZE TABLE (by wave x couple_urban)
* ============================================================================

preserve
    collapse (count) n = edu_homo, by(wave couple_urban)
    reshape wide n, i(wave) j(couple_urban)
    capture rename n0 n_rural
    capture rename n1 n_urban
    label var n_rural "Rural couples"
    label var n_urban "Urban couples"
    di _n "=== Sample by wave x rural/urban ==="
    list, clean noobs
    export delimited using "${output}/edu_assortmating_historical_by_urban_samples.csv", replace
restore


* ============================================================================
* 9. COLLAPSE TO SHARES BY MARRIAGE YEAR x RURAL/URBAN  (long format)
* ============================================================================

collapse (mean)  pct_homo  = edu_homo  ///
         (mean)  pct_hyper = edu_hyper ///
         (mean)  pct_hypo  = edu_hypo  ///
         (count) n         = edu_homo, ///
    by(marry_year couple_urban)

foreach v in pct_homo pct_hyper pct_hypo {
    replace `v' = `v' * 100
}

label var pct_homo  "Homogamy (%)"
label var pct_hyper "Hypergamy — husband more educated (%)"
label var pct_hypo  "Hypogamy — wife more educated (%)"
label var n         "Number of couples"
label values couple_urban urban_lbl

di _n "=== Shares by marriage year x rural/urban (first 20 rows) ==="
list marry_year couple_urban pct_hyper pct_homo pct_hypo n in 1/20, clean noobs


* ============================================================================
* 10. TWO-PANEL LINE PLOT (rural | urban)
*     One panel per residence type; 3 lines (hyper / homo / hypo) per panel.
* ============================================================================

twoway ///
    (line pct_hyper marry_year, lcolor(navy)      lwidth(medthick) lpattern(solid))  ///
    (line pct_homo  marry_year, lcolor(ebblue)    lwidth(medthick) lpattern(solid))  ///
    (line pct_hypo  marry_year, lcolor(cranberry) lwidth(medthick) lpattern(solid)), ///
    by(couple_urban, ///
       title("Education Assortative Mating Trends by Marriage Year", size(medium)) ///
       subtitle("By couple's residence (NBS urban/rural), CFPS 2010–2022", size(small)) ///
       note("Urban/rural measured at interview wave, not at marriage.", size(vsmall)) ///
       graphregion(color(white)) plotregion(color(white))) ///
    ytitle("Share of couples (%)") xtitle("Year of marriage") ///
    ylabel(0(10)100, angle(0)) ///
    xlabel(, angle(0)) ///
    legend(order(1 "Hypergamy" 2 "Homogamy" 3 "Hypogamy") ///
           position(6) rows(1) size(small)) ///
    scheme(s2color)

graph export "${output}/edu_assortmating_historical_by_urban.png", replace width(1400)


* ============================================================================
* 11. EXPORT HISTORICAL CSV  (long format)
* ============================================================================

export delimited using "${output}/edu_assortmating_historical_by_urban.csv", replace

* Keep the long-format shares in memory for the population-level chart
tempfile shares_by_urban_long
save `shares_by_urban_long'


* ============================================================================
* 12. POPULATION-LEVEL STACKED AREA CHART (single panel, 6 bands)
*     Encoding:
*       COLOR = sorting type:    hypergamy = blue,
*                                homogamy  = teal/mid-blue,
*                                hypogamy  = red.
*       SHADE = residence:       urban     = dark (full opacity),
*                                rural     = light (lower opacity).
*     True population decomposition:
*       pop_<type>_<group> = CMR × (n_group / n_total) × pct_<type>_<group> / 100
*     The six bands sum exactly to the national CMR.
* ============================================================================

* ---- Reshape the long couple-urban shares to wide, then proceed ----

use `shares_by_urban_long', clear

reshape wide pct_homo pct_hyper pct_hypo n, i(marry_year) j(couple_urban)

rename pct_homo0   pct_homo_rural
rename pct_homo1   pct_homo_urban
rename pct_hyper0  pct_hyper_rural
rename pct_hyper1  pct_hyper_urban
rename pct_hypo0   pct_hypo_rural
rename pct_hypo1   pct_hypo_urban
rename n0          n_rural
rename n1          n_urban

* Restrict to the CMR coverage window
keep if marry_year >= 2000 & marry_year <= 2022

* Fill missing cells (no couples observed in that (year, group) cell) with 0,
* so the stacked-area math is well-defined at every marry_year.
foreach v in n_rural n_urban ///
             pct_hyper_rural pct_hyper_urban ///
             pct_homo_rural  pct_homo_urban  ///
             pct_hypo_rural  pct_hypo_urban {
    replace `v' = 0 if missing(`v')
}

* ---- Merge in crude marriage rate (Ministry of Civil Affairs via Statista 2026) ----
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

sort marry_year


* ---- Couple-share weights (group share of observed couples in that year) ----

gen n_total = n_rural + n_urban
gen s_rural = n_rural / n_total
gen s_urban = n_urban / n_total

label var s_rural "Share of couples that year classified as rural"
label var s_urban "Share of couples that year classified as urban"


* ---- Per-1,000-population contributions (six components that sum to CMR) ----

gen pop_hyper_urban = cmr * s_urban * pct_hyper_urban / 100
gen pop_hyper_rural = cmr * s_rural * pct_hyper_rural / 100
gen pop_homo_urban  = cmr * s_urban * pct_homo_urban  / 100
gen pop_homo_rural  = cmr * s_rural * pct_homo_rural  / 100
gen pop_hypo_urban  = cmr * s_urban * pct_hypo_urban  / 100
gen pop_hypo_rural  = cmr * s_rural * pct_hypo_rural  / 100

label var pop_hyper_urban "Hypergamy urban (per 1,000 pop.)"
label var pop_hyper_rural "Hypergamy rural (per 1,000 pop.)"
label var pop_homo_urban  "Homogamy urban (per 1,000 pop.)"
label var pop_homo_rural  "Homogamy rural (per 1,000 pop.)"
label var pop_hypo_urban  "Hypogamy urban (per 1,000 pop.)"
label var pop_hypo_rural  "Hypogamy rural (per 1,000 pop.)"

* Sanity check: the six components should sum to CMR (tiny rounding OK)
gen pop_sum = pop_hyper_urban + pop_hyper_rural + ///
              pop_homo_urban  + pop_homo_rural  + ///
              pop_hypo_urban  + pop_hypo_rural
di _n "=== Sanity check: sum of 6 pop_* components vs. CMR ==="
list marry_year cmr pop_sum, clean noobs


* ---- Cumulative upper bounds for stacking ----
/*
   Stacking order (bottom to top):
     a1: hypergamy urban  (dark  navy)
     a2: hypergamy rural  (light navy)
     a3: homogamy urban   (dark  blue)
     a4: homogamy rural   (light blue)
     a5: hypogamy urban   (dark  red)
     a6: hypogamy rural   (light red)        -- a6 ≈ CMR
*/

gen a1 = pop_hyper_urban
gen a2 = a1 + pop_hyper_rural
gen a3 = a2 + pop_homo_urban
gen a4 = a3 + pop_homo_rural
gen a5 = a4 + pop_hypo_urban
gen a6 = a5 + pop_hypo_rural

di _n "=== Population-level rates per 1,000, rural+urban (2000–2022) ==="
list marry_year cmr pop_hyper_urban pop_hyper_rural ///
                    pop_homo_urban  pop_homo_rural  ///
                    pop_hypo_urban  pop_hypo_rural, clean noobs


* ---- Single-panel stacked area: COLOR = sorting type, SHADE = residence ----
/*
   Urban bands are filled at full opacity ("dark" shade); rural bands use
   the same base color at 45% opacity ("light" shade). This produces a
   within-color contrast that reads cleanly without needing hatching.

   Layer order (back to front):
     Layers 1–6 : stacked rarea bands
     Layer 7    : CMR outline
*/

twoway ///
    (area  a1    marry_year, fcolor("42 60 130")        lwidth(none)) ///
    (rarea a1 a2 marry_year, fcolor("42 60 130%45")     lwidth(none)) ///
    (rarea a2 a3 marry_year, fcolor("75 146 219")       lwidth(none)) ///
    (rarea a3 a4 marry_year, fcolor("75 146 219%45")    lwidth(none)) ///
    (rarea a4 a5 marry_year, fcolor("191 56 75")        lwidth(none)) ///
    (rarea a5 a6 marry_year, fcolor("191 56 75%45")     lwidth(none)) ///
    (line  cmr   marry_year, lcolor(black) lwidth(medthick) lpattern(solid)) ///
    , ///
    title("Education Sorting and Marriage Rate per 1,000 Population", size(medium)) ///
    subtitle("China, 2000–2022. Stacked bands = CMR × (group share) × (within-group sorting share).", size(vsmall)) ///
    note("Six bands decompose the national CMR into sorting type × rural/urban." ///
         " Color = sorting type (navy = hypergamy, blue = homogamy, red = hypogamy)." ///
         " Shade = residence (dark = urban, light = rural)." ///
         " CMR from Ministry of Civil Affairs. Urban/rural measured at interview wave.", size(vsmall)) ///
    ytitle("Per 1,000 population") xtitle("Year of marriage") ///
    ylabel(0(2)12, angle(0)) ///
    xlabel(2000(2)2022, angle(0)) ///
    legend(order(1 "Hypergamy, urban"  2 "Hypergamy, rural" ///
                 3 "Homogamy, urban"   4 "Homogamy, rural"  ///
                 5 "Hypogamy, urban"   6 "Hypogamy, rural"  ///
                 7 "Crude marriage rate") ///
           position(6) rows(4) size(small)) ///
    graphregion(color(white)) plotregion(color(white)) ///
    scheme(s2color)

graph export "${output}/edu_assortmating_population_by_urban.png", replace width(1400)


* ============================================================================
* 13. EXPORT POPULATION CSV
* ============================================================================

keep marry_year cmr ///
     pct_hyper_urban pct_hyper_rural ///
     pct_homo_urban  pct_homo_rural  ///
     pct_hypo_urban  pct_hypo_rural  ///
     n_urban n_rural s_urban s_rural ///
     pop_hyper_urban pop_hyper_rural ///
     pop_homo_urban  pop_homo_rural  ///
     pop_hypo_urban  pop_hypo_rural
order marry_year cmr s_urban s_rural ///
      pct_hyper_urban pct_hyper_rural ///
      pct_homo_urban  pct_homo_rural  ///
      pct_hypo_urban  pct_hypo_rural  ///
      pop_hyper_urban pop_hyper_rural ///
      pop_homo_urban  pop_homo_rural  ///
      pop_hypo_urban  pop_hypo_rural  ///
      n_urban n_rural

export delimited using "${output}/edu_assortmating_population_by_urban.csv", replace


* ============================================================================
* DONE
* ============================================================================

di _n "========================================"
di " Historical + population education assortative mating by rural/urban complete."
di " Output saved to: ${output}"
di "   edu_assortmating_historical_by_urban.png"
di "   edu_assortmating_historical_by_urban.csv"
di "   edu_assortmating_historical_by_urban_samples.csv"
di "   edu_assortmating_population_by_urban.png"
di "   edu_assortmating_population_by_urban.csv"
di "========================================"
