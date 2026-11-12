# Code provenance and reconstruction log

Source: Pim van den Bos, *Pricing of a CAT bond*, 30 March 2026, 24-page PDF. The unchanged report is in [reports/Pricing_CAT_Bond.pdf](../reports/Pricing_CAT_Bond.pdf). At initial publication the editable source files were not supplied. On 12 November 2026 the original teaching files were recovered; see [original/teaching/](../original/teaching/). The report-specific editable files remain unavailable. The three `original/appendix_*.R` files are **reconstructed transcriptions**; files in `original/teaching/` are actual recovered originals.

## Listing map

| PDF listing | Complete transcription | Maintained implementation |
| --- | --- | --- |
| Appendix A, Listing 1, 59 numbered lines, PDF pp. 16-17 | [appendix_A_estimation.R](../original/appendix_A_estimation.R) | [R/estimation.R](../R/estimation.R): `initial_estimates`, `epsilon_sensitivity`, `estimate_pjd`; [scripts/analyze.R](../scripts/analyze.R), modes initial/estimate; [R/data.R](../R/data.R): ACE loading |
| Appendix B, Listing 2, 38 numbered lines, PDF p. 17 | [appendix_B_correlation.R](../original/appendix_B_correlation.R) | [R/data.R](../R/data.R): `load_sp500`, `load_ace`, `correlation_analysis`; [scripts/acquire_data.R](../scripts/acquire_data.R); analyze mode correlation |
| Appendix C, Listing 3, 173 numbered lines, PDF pp. 18-22 | [appendix_C_pricing.R](../original/appendix_C_pricing.R) | [R/pricing.R](../R/pricing.R), [config/default.R](../config/default.R), [scripts/price.R](../scripts/price.R), [R/output.R](../R/output.R) |

All numbered listing content, including the repeated pricing block and sensitivity loop in C, is retained. The two leading provenance comments shift transcript line numbers by two. Wrapped PDF statements/comments are joined onto their original numbered line. Minor whitespace is normalized; no numerical model expressions or reported estimates were altered.

## Transcription repairs

* Removed PDF line-number prefixes and layout page breaks, joined wrapped comments and statements.
* Restored missing quotation marks around filenames, `BHHH`, the Yahoo symbol/source/date, period/type strings, format strings, column names, test methods, and printed labels/newline strings.
* Replaced typographical `ˆ` with ASCII `^` for powers and the `^GSPC` symbol.
* Rejoined the split identifier `diffprice. GBM` as `diffprice.GBM` in C lines 79 and 153.
* Checked the visually ambiguous powers, wrapped increments, jump expressions and covariance denominator against rendered appendix pages. All transcriptions pass R parsing.

The original comments about verifying a global maximum and closeness of prices are retained as archival text, not new repository verification claims. Likewise, the original B live-download end date and C manual scenario editing remain in the minimally repaired transcripts. Use maintained scripts for bounded data acquisition, automated scenarios and portable workers. A's original `results=list()` can behave poorly if failed runs leave missing trailing indices; maintained code preallocates ten restart records and captures failures.

## Recovered original dependencies (12 November 2026)

The initial publication's public/workspace searches did not locate `functions.R` or `LL.R`. The user subsequently supplied these files and teaching parts 1-5. Their unmodified bytes and source hashes are preserved under [original/teaching/](../original/teaching/). These are actual recovered helpers, not inferred replacements.

`estimate_pjd()` now sources the original helpers from `original/teaching/` into a shared closure containing annual ACE `return.cat` and `delta.t=1`. `LL.R` sets `njumps=50` and returns the observation-wise normal/Poisson mixture required by BHHH. The other helper defines constant time functions. Pricing retains the report's fixed estimates and independent configuration.

The teaching pricing kernels and both reconstructed Appendix C kernels were executed with the same ACE configuration over 30 seeded paths and agree with the maintained implementation. Part 5's repetition seed was also checked. The independent vectorized diagnostic implementation agrees on these path payoffs. The recovered part 2 confirms the likelihood/initialization workflow; report-specific epsilon, annual time step and `abs` inside the initial jump-SD formula are retained.

[The teaching-file inventory](../original/teaching/README.md) documents the missing `est_param.txt` (a generated output), comment-only `set_param.R`, the part 4 commented-out r assignment, the part 1 final-step jump loop and optional platform/data packages. None blocks the maintained ACE workflows. The example workbook is not used or redistributed.

[Reproduction and diagnostics](reproduction.md) are newly authored investigation code. They do not change archived teaching files, PDF reconstructions, report tables or default pricing mechanics.

## Engineering changes outside the archival transcriptions

| Change | Reason and analytical effect |
| --- | --- |
| Explicit configuration and descriptive names | Distinguish physical jump intensity from market-price-of-risk lambda; numerical defaults unchanged. |
| Functions and command-line entry points | Avoid global mutable state; automate all three scenarios and the full sensitivity grid. |
| Base `parallel` PSOCK plus serial fallback | Portable on Windows/Linux; preserve per-path draws, seeds and result order; workers stopped on exit. |
| Explicit RNG kind and caller-state restoration | Document the runtime convention; no replacement seed rule or alternative RNG mode. |
| Input validation and constant-control guard | Stop invalid configs; warn and use coefficient zero when control variance is zero. No change for ordinary nondegenerate runs. |
| Preallocated ten optimization restarts and error records | Preserve each attempt, starting vector and failure without an indexing error. |
| Explicit year/entity/column selection, positivity and gap checks | Bound the research sample, identify current source schema, and avoid fictitious annual returns over missing years. |
| Cached/manual Yahoo prices and fixed end date | Retain Yahoo/adjusted/yearly-log convention; prevent accidental extension beyond 2022. |
| SE/CI fields for unadjusted simulated outputs too | Same sample-payoff SE formula; analytical benchmark uncertainty marked NA. Adjusted estimate retains original SE and 1.96 interval. |
| Unique generated-output directories | Keep new executions and configuration/session metadata separate from transcribed report tables. |

## Teaching foundations and rights

The report explicitly credits `part2_cat_est.R` and `part4_cat_price_vrt.R`. Appendix C states that it replaced doMC with doParallel for Windows, hard-coded MLE estimates, defined time functions locally, supplied bond terms and added sensitivity loops. No author or license for those teaching scripts is identified in the supplied report. This repository does not invent one or grant a blanket license over them. See [RIGHTS.md](../RIGHTS.md).

The report's original AI statement and references are preserved in the PDF; its AI statement is also reproduced in the README. Codex assisted with transcription, software packaging and documentation, followed by the separately requested reproduction and independent estimator investigation. Findings and limitations of that investigation are recorded separately from the report.
