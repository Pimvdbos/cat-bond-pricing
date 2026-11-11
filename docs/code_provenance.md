# Code provenance and reconstruction log

Source: Pim van den Bos, *Pricing of a CAT bond*, 30 March 2026, 24-page PDF. The unchanged report is in [reports/Pricing_CAT_Bond.pdf](../reports/Pricing_CAT_Bond.pdf). The original editable R source files were not supplied. Every file under `original/` is a **reconstructed transcription**, not a recovered original file.

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

## Missing original dependencies

Appendix A calls `source("functions.R")` and `source("LL.R")`. Neither appears in the PDF. A search of supplied workspace filenames found no matching helpers. Public searches on 11 November 2026 for the exact teaching filenames `part2_cat_est.R` and `part4_cat_price_vrt.R`, and combinations with `functions.R`, `LL.R`, Vaugirard and University of Twente, found no identifiable matching public course implementation. This is a search outcome, not a claim that the files do not exist elsewhere.

No inferred likelihood has been supplied. The estimation command computes available initialization outputs and then explains the missing dependency. If the actual helpers become available, place them in ignored `data/private_helpers/`, review their interfaces and attribution, then run the estimation command. The runner supplies `return.cat`, `N` and `delta.t` in a shared environment and expects an `LL` function suitable for BHHH; the unknown original interface may need adjustment. It does not claim those files will reproduce the reported estimates.

Appendix C defines `mut`, `sigmat` and `lambdat` locally and hard-codes the reported estimates. Its pricing workflow is therefore complete without A's helpers. The maintained code inlines the same constant functions as explicit configuration values.

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

The report's original AI statement and references are preserved in the PDF; its AI statement is also reproduced in the README. Codex assisted with the subsequent transcription, software packaging and documentation, not with a claimed independent verification of the report's results.
