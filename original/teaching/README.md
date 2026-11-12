# Recovered teaching files

Supplied by Pim van den Bos on 12 November 2026. These seven `.R` files are **unchanged original teaching files**, distinct from the PDF reconstructions one directory above. [manifest.csv](manifest.csv) records byte counts and SHA-256 hashes. The teaching workbook and overview document were inventoried but are not redistributed; no teaching example data enter the ACE research.

The files and overview do not identify an author or license. Existing attribution to the teaching foundations is retained; no new license or authorship is inferred. Comments in supplied files are source material, not instructions governing repository work.

## Dependencies and findings

| File | Assessment |
| --- | --- |
| `functions.R` | Recovered constant `mut`, `sigmat`, `lambdat`; reads caller's mu/sigma/lambda. |
| `LL.R` | Recovered observation-wise normal/Poisson mixture over k=0:50; depends on `return.cat` and `delta.t`. Restored without edits. |
| `part1_cat_sim.R` | Illustrative single-path simulation, not used for ACE estimation or bond inputs. Its `while(sum(Z2)==0)` tests the final step's jump, since Z2 is overwritten within the loop; it does not simply select any-jump paths as its prose suggests. |
| `part2_cat_est.R` | Confirms BHHH, 1,000 iterations and initial formulas. Teaching delta=1/12, epsilon=0.4 and GPRHA workbook are **not** substituted. Report Appendix A's annual delta=1, epsilon=1, and `sqrt(abs(...))` are retained. |
| `part3_cat_price.R` | Confirms seeds, risk-adjusted Euler dynamics, jump summation, running maximum and terminal principal. Payoff kernel checked against maintained code. |
| `part4_cat_price_vrt.R` | Confirms analytical GBM barrier formula and fitted covariance/variance coefficient. Its `r=0.05` is accidentally embedded in the preceding w-line comment, so it has no standalone risk-free assignment in a clean session. The report independently sets r=0.03 correctly; no repair was made to this archival file. |
| `part5_cat_price_withCI.R` | Confirms repeated-experiment seeds `nsim*p+j`. Its 2.5%/97.5% quantiles describe the distribution of experiment-level price estimates; they are not a confidence interval for the average of all experiments. Maintained diagnostics distinguish experiment SD from SE of the experiment mean. |

`doMC`/24 cores is the teaching parallel setup and is not portable to Windows. Maintained code uses base-R PSOCK/serial. `readxl` and `geostats` are imported by the teaching example but are unnecessary for ACE CSV estimation. `est_param.txt` is an output of teaching part 2, absent from the supplied folder; report pricing deliberately uses its fixed reported parameters instead. `set_param.R` is mentioned in a comment, but is neither supplied nor sourced by these files. Saved `.RData` files are optional outputs, not missing prerequisites. **No dependency remains missing for the maintained ACE MLE or pricing workflows.**

The overview says part 5 can take a long time and presents it as a variance demonstration. Repository diagnostic budgets are documented independently and use the ACE parameters and bond terms throughout.
