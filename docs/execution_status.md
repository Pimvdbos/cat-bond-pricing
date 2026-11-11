# Execution status

Publication preparation: **11 November 2026**. Checks below assess software behavior and packaging, not the validity of the supplied research findings.

## Completed locally

Environment: Windows, **R 4.5.3 (2026-03-11 ucrt)**. Optional installed package versions and their dependency closure are recorded in [config/tested-packages.csv](../config/tested-packages.csv); this is an actual installed-version manifest, not a fabricated lockfile. Base/recommended R is sufficient for pricing, main tests and figures. Initial host locale warnings did not prevent execution; no machine-specific locale settings are required by the project.

| Check | Outcome |
| --- | --- |
| All recovered appendix listings and maintained R files parse | Passed |
| Clean `Rscript --vanilla` sourcing and configuration loading | Passed |
| Trigger equals threshold, including a pre-maturity hit | Passed |
| Discounted no-trigger, full-loss, partial-loss and zero-loss principal | Passed |
| Known control-variate fixture: coefficient 2, adjusted values all 4 | Passed |
| Constant-control-variance fallback | Passed |
| Both signs included in initial jump classification | Passed |
| 20-step/40-path serial simulation and adjusted-payoff SE/CI arithmetic | Passed |
| Two-worker PSOCK smoke test and exact equality with serial outputs | Passed; actual backend PSOCK |
| Caller RNG state restored | Passed |
| Offline example: 50 steps, 100 paths, all four prices/spreads | Executed successfully |
| Synthetic data-loader checks | Passed entity selection, year sorting, gap handling, positivity, partial first year, 2022 cutoff, alignment, Pearson/Spearman execution |
| Optional dependency installation | Completed; maxLik and doParallel plus needed dependencies installed |
| OWID CSV, chart metadata and full indicator metadata | Acquired successfully using R after earlier Python HTTP 403 responses |
| Yahoo ^GSPC adjusted history | Acquired and loaded successfully; 1950-2022 boundary checked |
| Three figures regenerated from reported tables | SVG/PNG outputs visually inspected |
| Original PDF preservation | Byte-for-byte comparison passed |

Source/report SHA-256:

```text
003184e40356aaad004c534f1dcb067036acda250f7e01ec6d2cac8fbbe445bd
```

Commands used for software checks:

```sh
Rscript --vanilla scripts/install.R
Rscript --vanilla tests/run_tests.R
Rscript --vanilla tests/data_tests.R
Rscript --vanilla scripts/price.R small 1
Rscript --vanilla scripts/figures.R
Rscript --vanilla scripts/acquire_data.R all
```

The acquisition command writes actual timestamps/checksums; publication snapshots are in [data/provenance/](../data/provenance/). Locally generated run directories are ignored, so market caches, transient worker output and host paths do not enter the repository.

## Not performed or unavailable

* No full research simulation grid, all-scenario research rerun or parameter re-estimation was required or performed for publication.
* Original estimation helpers `functions.R` and `LL.R` remain unavailable. MLE cannot be executed as original research until they are recovered and their interface checked. No inferred likelihood is claimed as the original.
* The historical correlation results were not independently re-estimated for comparison with the report. Correlation software was exercised on explicitly artificial fixtures.
* Newly downloaded files are not asserted identical to the lost original research data.
* Optional dependencies are installed from CRAN when absent; their future resolution is not frozen. Use the recorded R/package versions to reconstruct the checked environment.

## Continuous integration

[The workflow](../.github/workflows/checks.yml) runs the base-R artificial-fixture tests and regenerates report-based figures on Windows and Ubuntu with R 4.5.3. It makes no live Yahoo/OWID requests and does not run the research grid. The GitHub Actions run is the authoritative record of remote CI status; the table above records local checks.
