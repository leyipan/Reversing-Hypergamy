# Reversing Hypergamy? Education, Earning Power, and Partner Selection in China

Replication code for my thesis on marriage patterns in China using the China Family Panel Studies (CFPS), 2010-2022. The project documents long-run trends in education assortative mating and spousal age gaps, estimates gender-specific Mincerian earnings functions, and decomposes the within-couple permanent-income gap into an age-at-marriage channel and a gender wage-gap channel.

## Data

All analyses use CFPS adult/person files and family-configuration (famconf) files from waves 2010, 2012, 2014, 2016, 2018, 2020, and 2022, plus the cross-year individual file. CFPS microdata cannot be redistributed, so this repository does **not** include the raw `.dta` files. See `raw_data/README.md` for the list of files required and instructions for requesting access.

## Repository structure

```
Marriage Project/
├── do_files/           Stata code — all analyses
├── raw_data/           CFPS microdata (not included; see raw_data/README.md)
├── working_data/       Intermediate .dta files built by the pipeline
├── output/             Final tables, figures, and saved Mincer coefficients
├── README.md
└── LICENSE
```

The `working_data/` and `output/` folders are regenerated in full by running the pipeline.

## How to reproduce

1. **Request CFPS access** through the Institute of Social Science Survey at Peking University (<https://www.isss.pku.edu.cn/cfps/en/>). Download the wave files listed in `raw_data/README.md`.
2. **Clone this repository** and place the CFPS `.dta` files in `raw_data/`.
3. **Edit `do_files/master.do`**: change the first global path to point at wherever you cloned the repo:
   ```stata
   global root "/path/to/Marriage Project"
   ```
4. **Install required Stata packages** (once):
   ```stata
   ssc install oaxaca
   ssc install estout
   ```
5. **Run the pipeline**:
   ```stata
   do "/path/to/Marriage Project/do_files/master.do"
   ```

`master.do` executes every analysis in dependency order. Expect a full run to take a while — the couples-dataset build touches every wave, and the Mincer block predicts permanent income for each spouse over their lifetime.

## Pipeline overview

The pipeline runs in seven stages:

1. **Build couples dataset** — `build_couples_dataset.do` merges adult/person and famconf files across all seven waves, assigns wife/husband roles, and deduplicates into one observation per couple.
2. **Education assortative mating** — historical trends (1981-2022) in hypergamy, homogamy, and hypogamy shares, overall and split by urban/rural residence; also combined with the national crude marriage rate to produce population-level stacked-area plots.
3. **Mincerian earnings estimation** — pooled Mincer coefficients 2010-2018, separately by gender, used to predict each spouse's lifetime earnings and permanent income.
4. **Hypergamy diagnostic** — descriptive check on whether the within-couple permanent-income gap differs between education-hypergamous and education-hypogamous couples.
5. **Counterfactual decomposition** — three counterfactuals: (CF1) women marry at their husband's age; (CF2) women face male labor-market returns; (CF3) both simultaneously. Wife income recomputed under each scenario; husband income held at baseline.
6. **Decomposition figures and tables** — overlay of reality vs. all three counterfactuals by marriage year; summary and year-by-year LaTeX tables. This stage also produces the spousal age-gap descriptives.
7. **Gender wage gap** — Oaxaca-Blinder decompositions by wave (aggregate and detailed per-covariate breakdowns of the unexplained gap).

## Software

Written and tested in Stata 17. The pipeline relies on the `oaxaca` and `estout` packages from SSC.

## License

This repository is released under the MIT License — see `LICENSE` for the full text. You're welcome to reuse the code with attribution.

## Author

Leyi — feedback and questions are welcome via GitHub issues.
