/*==============================================================================
  MASTER DO-FILE
  Data: China Family Panel Studies (CFPS) 2010-2022

  Pipeline order reflects the dependency graph between do-files. Each stage
  consumes outputs from earlier stages; within a stage, files are independent
  unless noted.
==============================================================================*/

clear all
set more off
set maxvar 10000

* ============================================================================
* 1. SET GLOBAL PATHS
* ============================================================================

global root     "/Users/leyismacbook/Documents/2024-2025/Marriage Research/Marriage Project"

global do       "${root}/do_files"
global raw      "${root}/raw_data"
global work     "${root}/working_data"
global output   "${root}/output"

* ============================================================================
* 2. RUN DO-FILES IN ORDER
* ============================================================================

* ----------------------------------------------------------------------------
* Stage 1 — Build couples dataset (foundation for nearly everything below)
*   Outputs: ${work}/cfps_couples_allwaves.dta
* ----------------------------------------------------------------------------
do "${do}/build_couples_dataset.do"

* ----------------------------------------------------------------------------
* Stage 2 — Education assortative-mating descriptives
*   edu_assortmating_population reads the CSV produced by
*   edu_assortmating_historical, so order within this stage matters.
*   Inputs:  ${work}/cfps_couples_allwaves.dta
*   Outputs: ${output}/edu_assortmating_historical.{png,csv}
*            ${output}/edu_assortmating_population.{png,csv}
*            ${output}/edu_assortmating_historical_by_urban.*
* ----------------------------------------------------------------------------
do "${do}/edu_assortmating_historical.do"
do "${do}/edu_assortmating_population.do"
do "${do}/edu_assortmating_historical_by_urban.do"

* ----------------------------------------------------------------------------
* Stage 3 — Mincerian earnings estimation
*   Step 1 produces the pooled Mincer coefficients (.ster files) that are
*   used by the earnings-power predictions and all counterfactuals.
*   Outputs: ${output}/mincer_male_pooled.ster
*            ${output}/mincer_female_pooled.ster
*            ${work}/cfps_couples_earnings_power_pooled.dta
* ----------------------------------------------------------------------------
do "${do}/mincerian_step1.do"
do "${do}/mincerian_earning_power.do"

* ----------------------------------------------------------------------------
* Stage 4 — Hypergamy vs. income gap diagnostic
*   Descriptive check on the permanent-income estimates before running
*   counterfactual exercises.
*   Inputs: ${work}/cfps_couples_earnings_power_pooled.dta
* ----------------------------------------------------------------------------
do "${do}/hypergamy_income_gap.do"

* ----------------------------------------------------------------------------
* Stage 5 — Counterfactual decomposition
*   counterfactual_3_both MUST run first: CF1 and CF2 both import
*   cfps_counterfactual_3_both.dta as a comparison baseline.
*   Outputs: ${work}/cfps_counterfactual_{1_age_channel,2_wage_gap,3_both}.dta
* ----------------------------------------------------------------------------
do "${do}/counterfactual_3_both.do"
do "${do}/counterfactual_1_age_channel.do"
do "${do}/counterfactual_2_wage_gap.do"

* ----------------------------------------------------------------------------
* Stage 6 — Decomposition outputs and spousal age-gap descriptives
*   Figures and tables consume all three counterfactual datasets plus the
*   baseline earnings-power dataset.
*   Outputs: ${output}/decomposition_figure.{gph,png,pdf,csv}
*            ${output}/decomposition_summary.tex
*            ${output}/decomposition_by_year.tex
*            ${work}/agegap_cohort_summary.dta
* ----------------------------------------------------------------------------
do "${do}/decomposition_figure.do"
do "${do}/decomposition_tables.do"
do "${do}/spousal_age_gap.do"

* ----------------------------------------------------------------------------
* Stage 7 — Standalone gender wage-gap analyses
*   These read raw CFPS files directly and do not depend on the couples
*   pipeline; kept at the end as a parallel reporting block.
*   Outputs: ${output}/gender_wage_gap_by_wave.tex
*            ${output}/gwg_detailed_unexplained.{tex,csv}
* ----------------------------------------------------------------------------
do "${do}/gender_wage_gap_v2.do"
do "${do}/gender_wage_gap_detailed_decomp.do"

di _n "================================================================="
di    "MASTER PIPELINE COMPLETE."
di    "================================================================="
