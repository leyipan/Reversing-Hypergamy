/*==============================================================================
  BUILD COUPLES DATASET – ALL WAVES (2010–2022)
  Data: CFPS adult / person files + famconf files (for spouse pid)

  Purpose: Couple-level dataset with one observation per couple:
           wife_pid, husband_pid, wave, marry_year,
           wife_edu, husband_edu, wife_birthy, husband_birthy

  pid_s sources:
    2010, 2014  – directly in the adult file
    2012        – ecfps2012famconf_092015 (pid_s)
    2016        – ecfps2016famconf_201804 (pid_s)
    2018        – ecfps2018famconf_202008 (pid_a_s)
    2020        – ecfps2020famconf_202306 (pid_a_s)
    2022        – ecfps2022famconf_202410 (pid_s)

  Includes respondents WITHOUT a valid pid_s.  For these, spouse-reported
  characteristics (edu, birthy) are retained but wife_pid / husband_pid
  for the spouse side will be missing.

  Deduplication (two tracks):
    A. has_pid_s == 1: deduplicate by wife_pid × husband_pid
       (keeps one record per couple, most complete first).
    B. has_pid_s == 0: deduplicate by pid × marry_year across waves (keeps one record per unique combination).

  Prerequisites: Run master.do first (sets $root, $raw, $work, $do, $output).
==============================================================================*/

clear all
set more off

* Uncomment if not using master.do:
// global root   "/Users/leyismacbook/Documents/2024-2025/Marriage Research/Marriage Project"
// global raw    "${root}/raw_data"
// global work   "${root}/working_data"
// global do     "${root}/do_files"
// global output "${root}/output"


* ============================================================================
* 1.  WAVE 2010  (pid_s in adult file)
* ============================================================================

use pid pid_s gender cfps2010edu_best qa1y_best qe210y sedu qe211y ///
    using "${raw}/ecfps2010adult_201906.dta", clear

rename cfps2010edu_best resp_edu
rename gender           resp_gender
rename qa1y_best        resp_birthy
rename qe210y           marry_year
rename sedu             spouse_edu
rename qe211y           spouse_birthy

foreach v of varlist resp_edu resp_birthy marry_year spouse_edu spouse_birthy pid_s {
    replace `v' = . if inlist(`v', -1, -2, -8, -10)
}

* Flag whether pid_s is valid (keep all observations)
gen byte has_pid_s = (!missing(pid_s) & pid_s > 79)
replace pid_s = . if pid_s <= 79

gen int wave = 2010

tempfile wave2010
save `wave2010'


* ============================================================================
* 2.  WAVE 2012  (pid_s from famconf)
* ============================================================================

use pid edu2012 cfps2012_gender_best cfps2012_birthy_best ///
    qe208y qe209a spouse_birth_year ///
    using "${raw}/ecfps2012adult_202505.dta", clear

rename edu2012               resp_edu
rename cfps2012_gender_best  resp_gender
rename cfps2012_birthy_best  resp_birthy
rename qe208y                marry_year
rename qe209a                spouse_edu
rename spouse_birth_year     spouse_birthy

foreach v of varlist resp_edu resp_birthy marry_year spouse_edu spouse_birthy {
    replace `v' = . if inlist(`v', -1, -2, -8, -10)
}

* Merge pid_s from famconf (keep all, including unmatched)
drop if missing(pid)
preserve
    use pid pid_s using "${raw}/ecfps2012famconf_092015.dta", clear
    drop if missing(pid)
    replace pid_s = . if inlist(pid_s, -1, -2, -8, -10)
    duplicates drop pid, force
    tempfile fc2012
    save `fc2012'
restore

merge 1:1 pid using `fc2012', keep(master match) nogen

gen byte has_pid_s = (!missing(pid_s) & pid_s > 79)
replace pid_s = . if pid_s <= 79

gen int wave = 2012

tempfile wave2012
save `wave2012'


* ============================================================================
* 3.  WAVE 2014  (pid_s in adult file)
* ============================================================================

use pid pid_s cfps_gender cfps2014edu cfps_birthy ///
    eeb401y_a_1 eeb4021_a_1 qea201y ///
    using "${raw}/ecfps2014adult_201906.dta", clear

drop if missing(pid)

rename cfps_gender   resp_gender
rename cfps2014edu   resp_edu
rename cfps_birthy   resp_birthy
rename eeb401y_a_1   marry_year
rename eeb4021_a_1   spouse_edu
rename qea201y       spouse_birthy

foreach v of varlist resp_edu resp_birthy marry_year spouse_edu spouse_birthy pid_s {
    replace `v' = . if inlist(`v', -1, -2, -8, -10)
}

gen byte has_pid_s = (!missing(pid_s) & pid_s > 79)
replace pid_s = . if pid_s <= 79

gen int wave = 2014

tempfile wave2014
save `wave2014'


* ============================================================================
* 4.  WAVE 2016  (pid_s from famconf)
* ============================================================================

use pid cfps_gender cfps2016edu cfps_birthy ///
    eeb401y_a_1 eeb4021_a_1 qea201y ///
    using "${raw}/ecfps2016adult_201906.dta", clear

drop if missing(pid)

rename cfps_gender   resp_gender
rename cfps2016edu   resp_edu
rename cfps_birthy   resp_birthy
rename eeb401y_a_1   marry_year
rename eeb4021_a_1   spouse_edu
rename qea201y       spouse_birthy

foreach v of varlist resp_edu resp_birthy marry_year spouse_edu spouse_birthy {
    replace `v' = . if inlist(`v', -1, -2, -8, -10)
}

preserve
    use pid pid_s using "${raw}/ecfps2016famconf_201804.dta", clear
    drop if missing(pid)
    replace pid_s = . if inlist(pid_s, -1, -2, -8, -10)
    duplicates drop pid, force
    tempfile fc2016
    save `fc2016'
restore

merge 1:1 pid using `fc2016', keep(master match) nogen

gen byte has_pid_s = (!missing(pid_s) & pid_s > 79)
replace pid_s = . if pid_s <= 79

gen int wave = 2016

tempfile wave2016
save `wave2016'


* ============================================================================
* 5.  WAVE 2018  (pid_a_s from famconf)
* ============================================================================

use pid gender cfps2018edu ibirthy_update ///
    eeb401y_a_1 eeb4021_a_1 qea201y ///
    using "${raw}/ecfps2018person_202012.dta", clear

drop if missing(pid)

rename gender         resp_gender
rename cfps2018edu    resp_edu
rename ibirthy_update resp_birthy
rename eeb401y_a_1    marry_year
rename eeb4021_a_1    spouse_edu
rename qea201y        spouse_birthy

foreach v of varlist resp_edu resp_birthy marry_year spouse_edu spouse_birthy {
    replace `v' = . if inlist(`v', -1, -2, -8, -10)
}

preserve
    use pid pid_a_s using "${raw}/ecfps2018famconf_202008.dta", clear
    drop if missing(pid)
    rename pid_a_s pid_s
    replace pid_s = . if inlist(pid_s, -1, -2, -8, -10)
    duplicates drop pid, force
    tempfile fc2018
    save `fc2018'
restore

merge 1:1 pid using `fc2018', keep(master match) nogen

gen byte has_pid_s = (!missing(pid_s) & pid_s > 79)
replace pid_s = . if pid_s <= 79

gen int wave = 2018

tempfile wave2018
save `wave2018'


* ============================================================================
* 6.  WAVE 2020  (pid_a_s from famconf)
* ============================================================================

use pid gender cfps2020edu ibirthy_update ///
    eeb401y_a_1 eeb4021_a_1 qea201y ///
    using "${raw}/ecfps2020person_202306.dta", clear

drop if missing(pid)

rename gender         resp_gender
rename cfps2020edu    resp_edu
rename ibirthy_update resp_birthy
rename eeb401y_a_1    marry_year
rename eeb4021_a_1    spouse_edu
rename qea201y        spouse_birthy

foreach v of varlist resp_edu resp_birthy marry_year spouse_edu spouse_birthy {
    replace `v' = . if inlist(`v', -1, -2, -8, -10)
}

preserve
    use pid pid_a_s using "${raw}/ecfps2020famconf_202306.dta", clear
    drop if missing(pid)
    rename pid_a_s pid_s
    replace pid_s = . if inlist(pid_s, -1, -2, -8, -10)
    duplicates drop pid, force
    tempfile fc2020
    save `fc2020'
restore

merge 1:1 pid using `fc2020', keep(master match) nogen

gen byte has_pid_s = (!missing(pid_s) & pid_s > 79)
replace pid_s = . if pid_s <= 79

gen int wave = 2020

tempfile wave2020
save `wave2020'


* ============================================================================
* 7.  WAVE 2022  (pid_s from famconf)
* ============================================================================

use pid gender cfps2022edu ibirthy_update ///
    eeb401y_a_1 eeb4021_a_1 qea201y ///
    using "${raw}/ecfps2022person_202410.dta", clear

drop if missing(pid)

rename gender         resp_gender
rename cfps2022edu    resp_edu
rename ibirthy_update resp_birthy
rename eeb401y_a_1    marry_year
rename eeb4021_a_1    spouse_edu
rename qea201y        spouse_birthy

foreach v of varlist resp_edu resp_birthy marry_year spouse_edu spouse_birthy {
    replace `v' = . if inlist(`v', -1, -2, -8, -10)
}

preserve
    use pid pid_s tb1y_a_s using "${raw}/ecfps2022famconf_202410.dta", clear
    drop if missing(pid)
    replace pid_s = . if inlist(pid_s, -1, -2, -8, -10)
    replace tb1y_a_s = . if inlist(tb1y_a_s, -1, -2, -8, -10)
    duplicates drop pid, force
    tempfile fc2022
    save `fc2022'
restore

merge 1:1 pid using `fc2022', keep(master match) nogen

* Impute missing spouse_birthy from famconf's tb1y_a_s
replace spouse_birthy = tb1y_a_s if missing(spouse_birthy) & !missing(tb1y_a_s)
drop tb1y_a_s

gen byte has_pid_s = (!missing(pid_s) & pid_s > 79)
replace pid_s = . if pid_s <= 79

gen int wave = 2022

tempfile wave2022
save `wave2022'


* ============================================================================
* 8.  APPEND ALL WAVES
* ============================================================================

use `wave2010', clear
append using `wave2012'
append using `wave2014'
append using `wave2016'
append using `wave2018'
append using `wave2020'
append using `wave2022'

di _n "=== Sample by wave and pid_s availability ==="
tab wave has_pid_s


* ============================================================================
* 9.  ASSIGN WIFE / HUSBAND BASED ON GENDER
* ============================================================================

* --- Drop observations where respondent gender is missing ---
drop if missing(resp_gender)

* --- Create couple-level variables ---
gen double wife_pid     = .
gen double husband_pid  = .
gen wife_edu            = .
gen husband_edu         = .
gen wife_birthy         = .
gen husband_birthy      = .

* Respondent is wife (female = 0)
replace wife_pid       = pid           if resp_gender == 0
replace wife_edu       = resp_edu      if resp_gender == 0
replace wife_birthy    = resp_birthy   if resp_gender == 0
replace husband_pid    = pid_s         if resp_gender == 0
replace husband_edu    = spouse_edu    if resp_gender == 0
replace husband_birthy = spouse_birthy if resp_gender == 0

* Respondent is husband (male = 1)
replace husband_pid    = pid           if resp_gender == 1
replace husband_edu    = resp_edu      if resp_gender == 1
replace husband_birthy = resp_birthy   if resp_gender == 1
replace wife_pid       = pid_s         if resp_gender == 1
replace wife_edu       = spouse_edu    if resp_gender == 1
replace wife_birthy    = spouse_birthy if resp_gender == 1

format wife_pid husband_pid %15.0f


* ============================================================================
* 10. CROSS-WAVE BACKWARD FILL FOR COUPLES WITH VALID pid_s
*     For each (wife_pid × husband_pid) group appearing in multiple waves,
*     fill missing values in earlier waves from consecutive later waves.
* ============================================================================

di _n "=== Cross-wave backward fill (has_pid_s == 1) ==="

* Sort latest wave first so _n-1 references carry later-wave values backward
gsort wife_pid husband_pid -wave
foreach v in marry_year wife_edu husband_edu wife_birthy husband_birthy {
    by wife_pid husband_pid: ///
        replace `v' = `v'[_n-1] if missing(`v') & has_pid_s == 1
}

* Restore chronological sort
sort wife_pid husband_pid wave


* ============================================================================
* 10b. CROSS-WAVE BACKWARD FILL FOR OBSERVATIONS WITHOUT VALID pid_s
*      For each pid with multiple waves, fill missing values in earlier waves
*      from later waves. Before drawing on any later wave, compare its
*      marry_year with the earliest wave's marry_year: if they differ, stop
*      imputing (don't use that wave or any subsequent wave). If the later
*      wave's marry_year matches or is missing, continue.
* ============================================================================

di _n "=== Cross-wave backward fill (has_pid_s == 0) ==="

preserve
    keep if has_pid_s == 0

    * Chronological sort so _n==1 is the earliest wave within each pid
    sort pid wave

    * Reference marry_year: earliest non-missing marry_year within each pid
    by pid: egen int ref_marry_pid = min(cond(!missing(marry_year), ///
        marry_year, .))

    * Conflict: wave has a non-missing marry_year that differs from reference
    by pid: gen byte conflict_pid = ///
        (!missing(marry_year) & !missing(ref_marry_pid) & marry_year != ref_marry_pid)

    * Unusable: at or after the first conflict (cumulative sum tips above 0)
    by pid: gen byte unusable_pid = (sum(conflict_pid) > 0)

    * Backward fill: sort latest wave first so _n-1 is a chronologically
    * later wave. Only propagate through observations that are both usable.
    gsort pid -wave
    foreach v in marry_year wife_edu husband_edu wife_birthy husband_birthy {
        by pid: replace `v' = `v'[_n-1] ///
            if missing(`v') & unusable_pid == 0 & unusable_pid[_n-1] == 0
    }

    sort pid wave
    drop ref_marry_pid conflict_pid unusable_pid

    tempfile track_b_filled
    save `track_b_filled'
restore

drop if has_pid_s == 0
append using `track_b_filled'


* ============================================================================
* 11. DEDUPLICATE
* ============================================================================

* ------------------------------------------------------------------
* Track A: has_pid_s == 1 — deduplicate by wife_pid × husband_pid
*          (both spouses may appear as respondents; keep most complete)
* ------------------------------------------------------------------

* Count non-missing values across key variables
gen byte n_complete = !missing(wife_edu)    + !missing(husband_edu)    ///
                    + !missing(wife_birthy) + !missing(husband_birthy) ///
                    + !missing(marry_year)

preserve
    keep if has_pid_s == 1

    gsort wife_pid husband_pid wave -n_complete pid
    by wife_pid husband_pid: gen byte dup_n = _n
    di "Track A — duplicate couple-wave records to drop: " _c
    count if dup_n > 1
    drop if dup_n > 1
    drop dup_n

    tempfile track_a
    save `track_a'
restore

* ------------------------------------------------------------------
* Track B: has_pid_s == 0 — deduplicate by pid × marry_year ×
*          spouse_birthy × spouse_edu across waves
*          (keep one record per unique pid–marry_year–spouse info set)
* ------------------------------------------------------------------

preserve
    keep if has_pid_s == 0

    * Sort: earliest wave first, then most complete, then smallest pid
    gsort pid marry_year wave -n_complete pid
    by pid marry_year: gen byte dup_n = _n
    di "Track B — duplicate pid-marry_year-spouse records to drop: " _c
    count if dup_n > 1
    drop if dup_n > 1
    drop dup_n

    tempfile track_b
    save `track_b'
restore

* Combine
use `track_a', clear
append using `track_b'
drop n_complete


* ============================================================================
* 12. KEEP FINAL VARIABLES AND SAVE
* ============================================================================

drop if missing(marry_year, wife_edu, husband_edu)
drop if marry_year < 1900
drop if wife_edu < 0
drop if husband_edu < 0

keep wife_pid husband_pid wave marry_year ///
     wife_edu husband_edu wife_birthy husband_birthy ///
     has_pid_s pid resp_gender spouse_edu spouse_birthy

order wife_pid husband_pid wave marry_year ///
      wife_edu husband_edu wife_birthy husband_birthy ///
      has_pid_s

label var wife_pid       "Wife personal ID"
label var husband_pid    "Husband personal ID"
label var wave           "Interview wave"
label var marry_year     "Year married current spouse"
label var wife_edu       "Wife highest education"
label var husband_edu    "Husband highest education"
label var wife_birthy    "Wife birth year"
label var husband_birthy "Husband birth year"
label var has_pid_s      "1 = spouse pid available"

compress
save "${work}/cfps_couples_allwaves.dta", replace

di _n "================================================================="
di    "DONE. Saved: ${work}/cfps_couples_allwaves.dta"
di    "================================================================="
tab wave has_pid_s
count
describe
