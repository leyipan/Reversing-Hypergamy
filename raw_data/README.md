# raw_data/

This folder is intentionally empty in the public repository. The analyses use restricted microdata from the **China Family Panel Studies (CFPS)**, which cannot be redistributed under the data provider's terms of use. To reproduce the results you'll need to request the files directly from CFPS and place them here.

## How to get the data

CFPS is administered by the Institute of Social Science Survey (ISSS) at Peking University. Register for an account, agree to the terms of use, and download the relevant wave files:

<https://www.isss.pku.edu.cn/cfps/en/>

Access is free for academic use but requires registration.

## Files required

Place the following `.dta` files directly inside `raw_data/` (do not rename them — the do-files reference these exact filenames):

### Adult / person files (one per wave)

| Wave | File |
|------|------|
| 2010 | `ecfps2010adult_201906.dta` |
| 2012 | `ecfps2012adult_202505.dta` |
| 2014 | `ecfps2014adult_201906.dta` |
| 2016 | `ecfps2016adult_201906.dta` |
| 2018 | `ecfps2018person_202012.dta` |
| 2020 | `ecfps2020person_202306.dta` |
| 2022 | `ecfps2022person_202410.dta` |

### Family configuration (famconf) files — needed for spouse PIDs

| Wave | File |
|------|------|
| 2012 | `ecfps2012famconf_092015.dta` |
| 2016 | `ecfps2016famconf_201804.dta` |
| 2018 | `ecfps2018famconf_202008.dta` |
| 2020 | `ecfps2020famconf_202306.dta` |
| 2022 | `ecfps2022famconf_202410.dta` |

(For 2010 and 2014 the spouse PID `pid_s` is already in the adult file, so no famconf file is needed.)

### Cross-year individual file

| File |
|------|
| `ecfps2022crossyear_202601.dta` |

Used by `mincerian_step1.do` for harmonized education-years and birth-year variables across waves.

## Notes on filenames

CFPS re-releases files with updated suffixes (the date at the end of the filename, e.g. `_201906`, `_202505`). If you download a newer version with a different suffix, either rename it to match the list above or update the `use` statements at the top of the do-files that reference it.

## What not to commit

The `.gitignore` at the repo root excludes `raw_data/*.dta` so the actual CFPS files stay off GitHub even if you accidentally `git add` them. Only this README lives in the folder on the public repo.
