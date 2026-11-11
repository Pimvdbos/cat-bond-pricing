# Data acquisition and provenance

Historical data are optional: pricing uses the report's fixed parameters. Run commands from the project root. Raw data, caches, user helpers and data-derived fresh outputs are ignored by Git.

## ACE

Source: [OWID North Atlantic ACE indicator](https://ourworldindata.org/grapher/ace-north-atlantic-hurricanes), [CSV](https://ourworldindata.org/grapher/ace-north-atlantic-hurricanes.csv), [chart metadata](https://ourworldindata.org/grapher/ace-north-atlantic-hurricanes.metadata.json), [full indicator metadata](https://api.ourworldindata.org/v1/indicators/898994.metadata.json). The report's older narrative URL is [accumulated-cyclone-energy](https://ourworldindata.org/grapher/accumulated-cyclone-energy); acquisition uses the matching hurricane indicator, not an assumed replacement series.

**Recovered on 11 November 2026.** Python HTTP requests initially returned 403 for CSV and metadata; R `download.file(method="libcurl")` successfully acquired both. The current metadata identifies entity **North Atlantic**, column **Accumulated cyclone energy index**, variable **898994**, source **HURDAT, National Oceanic and Atmospheric Administration (2024), processed by Our World in Data**. The chart metadata records 4 April 2024 as last updated; full indicator metadata contains a later metadata update timestamp. Both snapshots are retained under [provenance/](provenance/). Original source link: [NOAA HURDAT comparison table](https://www.aoml.noaa.gov/hrd/hurdat/comparison_table.html).

Actual acquired CSV SHA-256:

```text
24efd1d37eca638a58dbc252d13efa4bcf8b8911d0f501e18a56eb624cbb7762
```

The downloaded and retained coverage is **1851-2022: 172 positive annual levels, 171 consecutive annual log returns**, with no missing years/levels in this acquired file. The narrative describes 171 observations and 170 returns, while Table 1 classifications sum to 171. These source/sample-description differences are recorded without removing observations or treating the publication task as a numerical audit. The lost local original cannot be identified as byte-for-byte or value-for-value identical to this recovered version.

```sh
Rscript --vanilla scripts/install.R
Rscript --vanilla scripts/acquire_data.R ace
Rscript --vanilla scripts/analyze.R initial
```

If access is blocked, open the OWID chart in a browser, select North Atlantic, download its full CSV and metadata, and save them as `data/raw/ace-north-atlantic-hurricanes.csv` and `data/raw/ace-north-atlantic-hurricanes.metadata.json`. Record the actual retrieval date. `load_ace()` computes the checksum of the file actually read, selects the entity, maps the indicator to `ACE`, sorts by year, restricts 1851-2022 and checks positivity. Missing years and missing values are recorded; returns across gaps are NA. No interpolation, forced row count or imputation is used.

The legacy dotted R column name is recognized, as is the current spaced name. If a future file contains multiple candidate indicators, supply the exact column after checking its metadata. The command supports positional overrides:

```sh
Rscript --vanilla scripts/analyze.R correlation data/raw/ace-north-atlantic-hurricanes.csv "North Atlantic" data/cache/GSPC.rds "Accumulated cyclone energy index"
```

If the CSV uses a different entity label, do not guess: inspect metadata and pass the intended basin label explicitly. A single-series manual file without Entity is accepted with a warning. Metadata and source attributions are committed; raw files remain local. Full OWID metadata states `nonRedistributable: false`; the repository nevertheless avoids bundling the raw download and does not extend that statement to other sources. OWID's general content license is CC BY unless otherwise stated; third-party source terms still apply.

## S&P 500

Source/convention: Yahoo Finance **`^GSPC`**, `quantmod::getSymbols`, `Ad(GSPC)`, `periodReturn(period="yearly", type="log", leading=TRUE)`. No ETF, total-return index or alternative provider is substituted.

**Acquired successfully on 11 November 2026.** Daily adjusted prices retained from **1950-01-03 through 2022-12-30** produce **73 annual returns, 1950-2022**. The first annual return is the log ratio of the last 1950 adjusted price to the first available 1950 adjusted price. This preserves the original partial-period convention; it is not a full prior-year-close-to-year-end 1950 return.

```sh
Rscript --vanilla scripts/acquire_data.R sp500
Rscript --vanilla scripts/analyze.R correlation
```

The download is bounded at `to="2023-01-01"` and the loader independently filters to 1950-2022. `data/cache/GSPC.rds` stores the acquired Yahoo xts object locally. Checksum of the acquired RDS serialization:

```text
3728e65b8e55984041f1bf744902d24882f9e271e55b6fb4d7ea8eb11f93ba6a
```

The checksum identifies this cached file, not a permanently immutable Yahoo dataset. A new serialization or revised download can differ. Raw prices and return caches are **not redistributed**; no redistribution permission is assumed.

If Yahoo acquisition fails, save the failure record and obtain **the same Yahoo ^GSPC adjusted-price history** through authorized access at [Yahoo's historical-data page](https://finance.yahoo.com/quote/%5EGSPC/history/). A manually supplied CSV must have `Date` (ISO YYYY-MM-DD) and `Adjusted` columns. Preserve source, retrieval date and full coverage. Do not replace missing data with another security. Example:

```sh
Rscript --vanilla scripts/analyze.R correlation data/raw/ace-north-atlantic-hurricanes.csv "North Atlantic" data/cache/GSPC-manual.csv
```

ACE and S&P returns are merged by Year, bounded to 1950-2022 and filtered to complete pairs. Run provenance records actual coverage, omission information and checksums. Acquisition never overwrites an existing cache; move an old cache deliberately before requesting a new one.

## Provenance records

`provenance/acquisition.R` records the successful retrieval timestamps and file checksums; `ace_sample.R` and `sp500_sample.R` record loader inspection/coverage. Their `inspected_at_utc` times are distinct from source publication dates; a cached-file inspection alone does not establish its retrieval date. Source metadata snapshots retain their upstream retrieval/update fields. Future acquisitions produce their own records under ignored `results/generated/` rather than modifying this publication snapshot.
