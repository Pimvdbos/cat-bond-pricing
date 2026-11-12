# Fresh execution outputs

Scripts create unique timestamped subdirectories containing configurations, session information and generated results. These local directories are excluded from Git. Reported tables remain in `../reported/` and are never overwritten. A small example run demonstrates software execution, not research reproduction. Data-derived outputs can include market data and remain local.

The following **curated aggregate snapshots** from 12 November 2026 are committed as explicit exceptions:

* [reproduction-2026-11-12/](reproduction-2026-11-12/): Tables 1-7 reruns, comparisons, MLE diagnostics and all four pricing outputs per configuration.
* [investigation-2026-11-12/](investigation-2026-11-12/): 100 repeated experiments per setting, target/variance diagnostics and configurations.
* [continuous-benchmark-2026-11-12/](continuous-benchmark-2026-11-12/): independent event-time/bridge continuous-PJD estimates and configurations.

These snapshots contain no raw market prices, paired historical return series or serialized estimation environments. They preserve full precision; source-code hashes and session information identify their implementation. [Interpretation](../../docs/reproduction.md) distinguishes reported findings, reproduction differences and new investigations.
