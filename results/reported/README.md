# Supplied research findings

These files transcribe Tables 1-7 and identified narrative statistics from [Pricing of a CAT bond](../../reports/Pricing_CAT_Bond.pdf), Pim van den Bos, 30 March 2026. They are **reported results, not outputs generated or independently verified by this repository**. Their published rounding is retained, including confidence-interval widths that need not equal subtraction of separately rounded endpoints. Never write fresh results here.

| File | Source (printed page; PDF page) | Definitions and units |
| --- | --- | --- |
| `table_1_epsilon.csv` | Table 1, p. 5; PDF 6 | Absolute annual log-return cutoff; jump/diffusion counts; threshold-based initial jump frequency per year, **not final MLE intensity**. |
| `table_2_estimates.csv` | Table 2, p. 6; PDF 7 | Annual drift `mu`; diffusion volatility `sigma` per square-root year; log-jump SD `delta`; Poisson intensity `lambda.p` per year; mean log jump `kv`. Standard errors in corresponding units; t and p dimensionless. Report prints intensity as lambda, distinguished here from pricing lambda. |
| `table_3_restarts.csv` | Table 3, p. 7; PDF 8 | Ten optimization runs; log-likelihood values at reported rounding. |
| `table_4_pearson.csv` | Table 4, p. 9; PDF 10 | Pearson correlation, two-sided t statistic, degrees of freedom, p-value and 95% interval; dimensionless. |
| `table_5_bond.csv` | Table 5, p. 10; PDF 11 | Bond inputs and report motivations; rates are decimals (0.03 = 3%). |
| `table_6_sensitivity.csv` | Table 6, p. 12; PDF 13 | PJD with VRT, lambda=0.05; N time steps, nsim paths; price and 95% CI endpoints/width in USD. |
| `table_7_prices.csv` | Table 7, p. 13; PDF 14 | N=500, nsim=6500; prices in USD; reported "Yield" is the continuously compounded yield **spread above the risk-free rate**, in annual decimals. |
| `narrative_statistics.csv` | Sections 3, 6, 7 | Additional narrative values; not additional tables. |

The table numbering and all numerical entries are preserved. Table 5's verbal motivations are condensed; consult the PDF for the full wording. `lambda.p` maps to `jump_intensity` and `kv` to `mean_log_jump` in maintained code. Scenario lambda maps to `market_price_of_risk`. Prices and spreads from Tables 6-7 are not market quotes.
