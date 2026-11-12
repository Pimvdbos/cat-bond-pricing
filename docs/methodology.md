# Methodology

This document explains the implementation in the [source report](../reports/Pricing_CAT_Bond.pdf). Reported tables remain transcribed and unchanged. A separate [reproduction and estimator investigation](reproduction.md) now evaluates fresh results; the pricing inputs are not recalibrated. The project studies a hypothetical parametric catastrophe bond and does not value a traded security.

## Insurance and physical-risk context

Catastrophe bonds transfer specified insurance risk to capital-market investors. Under the modeled contract, the investor's terminal principal is reduced when North Atlantic hurricane activity reaches an ACE threshold. Capital retained after triggering represents risk transfer to the issuer. The model includes no separate coupon stream, transaction costs or observed bond quotes.

ACE summarizes cyclone-season activity through storm intensity and duration. The downloaded indicator describes a sum of squared maximum sustained surface winds measured every six hours while storms are named. It measures basin-wide activity, not insured losses. Geographical exposure, vulnerability and insurance terms create **parametric basis risk** between activity and an insurer's losses. Physical climate risk motivates the application; nonstationarity limits extrapolation of historical estimates.

## Historical data and dependence

The research period is 1851-2022 for ACE. Annual log returns are `log(ACE[t] / ACE[t-1])`. Maintained loading selects North Atlantic, identifies the indicator column, sorts unique years, validates positive levels and refuses to calculate one-year returns across absent years. Missing levels propagate to missing returns. It does not fill years or trim the sample to match a reported count.

The financial comparison uses `quantmod::getSymbols("^GSPC", src="yahoo", from="1950-01-01")`, adjusted prices via `Ad`, and `periodReturn(..., period="yearly", type="log")`. The maintained fetch bounds the end date and filters all inputs to 1950-2022. The original default `leading=TRUE` produces a first return from the first available trading price to the last price of that calendar year; it is not a previous-December-close return. The recovered sample starts on 3 January 1950. Returns align by calendar year and use complete paired observations, with omissions recorded.

Pearson tests a linear correlation; Spearman tests rank association (`exact=FALSE`, as in Appendix B). The reported coefficients are 0.0514 and 0.0867 with p-values 0.6659 and 0.4660 respectively. The Pearson 95% interval is [-0.1808, 0.2782], with 73 reported pairs. Neither test is statistically significant in this sample. Heavy tails and extreme observations motivate cautious interpretation; insignificance is not proof of independence, zero beta or no tail dependence.

## Parameter-estimation workflow

Appendix A uses annual `delta.t=1`. Epsilon sensitivity at 0.8, 1.0 and 1.2 separates initial jump observations using **absolute** log returns; both positive and negative extremes count. At selected epsilon=1.0, let `Rjumps` and `Rdiffusion` denote the two sets. The exact starting formulas are:

```r
sigma_hat = sd(Rdiffusion) / sqrt(delta.t)
mu_hat = (2*mean(Rdiffusion) + sigma_hat^2*delta.t) / (2*delta.t)
lambdap_hat = length(jumpindex) / (N * delta.t)
delta_hat = sqrt(abs(var(Rjumps) - sigma_hat^2*delta.t))
kv_hat = mean(Rjumps) - (mu_hat - sigma_hat^2/2)*delta.t
```

Here N is the number of annual returns (distinct from pricing N, the number of time steps). The threshold-based initial frequency is not the final MLE intensity. The report gives final estimates `(mu, sigma, delta, lambda.p, kv) = (0.196, 0.660, 1.550, 0.135, 0.202)` and approximate optimum log-likelihood -208.94. `kv` is a **mean log-jump size**, not the mean relative jump.

The estimation workflow retains `maxLik(LL, method="BHHH", control=list(iterlim=1000))`, plus ten random starting points formed by multiplying the initial vector by `runif(5, 0.5, 1.5)` after `set.seed(123)`. The recovered [original LL.R](../original/teaching/LL.R) returns one log density per observation:

```text
f(return) = sum over k=0,...,50 of
  Poisson(k; lambda.p * delta.t) *
  NormalDensity(return; (mu - sigma^2/2)*delta.t + k*kv,
                        sqrt(sigma^2*delta.t + k*delta^2))
```

The original helper is used unchanged. This is a truncated compound-Poisson/lognormal mixture, with no added jump compensator. The likelihood squares sigma and delta, so signs are not identified by the density alone; reported positive scales are used for pricing. Unconstrained optimization may propose a negative Poisson intensity and generate NaN warnings. These are counted by stage; the original routine and stopping criteria are retained. All ten restarts completed. Truncation and stopping-tolerance diagnostics are separate outputs, not replacement estimates. See the [reproduction](reproduction.md) for numerical comparisons.

## Bond and dynamics

The face value is USD 1,000; initial ACE 100; trigger K=200; maturity T=1 year; loss fraction w=1; continuously compounded risk-free rate r=0.03. Two different quantities must not be confused:

| Appendix name | Maintained name | Role |
| --- | --- | --- |
| `lambda.p` | `jump_intensity` | Physical Poisson arrival rate, 0.135 per year |
| `lambda` | `market_price_of_risk` | Sensitivity parameter in drift adjustment, 0.05/0.30/0.70 |
| `delta` | `jump_sd` | Standard deviation of normal log-jump size, 1.550 |
| `kv` | `mean_log_jump` | Mean normal log-jump size, 0.202 |

For `dt=T/N`, Appendix C implements the Euler update:

```text
arrival_count[i] ~ Poisson(jump_intensity * dt)
relative_jump[j] = exp(jump_sd * Z[j] + mean_log_jump) - 1
increment = (mu - market_price_of_risk * sigma) * dt
            + sigma * Brownian[i] * sqrt(dt) + sum(relative_jump)
index[i+1] = index[i] + increment * index[i]
```

The paired GBM path omits the jump sum and shares the same Brownian vector. Each path draws all N Brownian normals, then N Poisson counts, then jump-size normals step by step. Both paths include their initial value. The original seed is `set.seed(nsim*p)` for path p; it is retained, and there is no alternative RNG mode. Maintained execution specifies Mersenne-Twister/Inversion/Rejection and restores the caller's RNG state. Changing nsim changes the seeds, as in the appendix.

The sum of relative jumps is retained even when multiple arrivals occur in a time step. There is no replacement with an exact exponential process, no clipping of negative Euler levels, no jump compensator added, and no interpolation between grid points. Euler paths can become negative; positivity is enforced for historical logarithms, not by changing the simulated dynamics.

The trigger is `max(path) >= K`, including equality. Payoff is:

```text
PV = exp(-r*T) * F * (1 - w * triggered)
```

This is discounted **terminal principal**, not a terminal-index-only trigger or coupon model. Annual historical dynamics and a within-year continuous-risk approximation are modeling assumptions: simulated paths are not physically constrained to seasonal cumulative ACE.

## Analytical control and Monte Carlo uncertainty

The Appendix C GBM formula is preserved. With `a = mu - lambda*sigma`:

```text
d1 = [log(I0/K) + (a - sigma^2/2)*T] / (sigma*sqrt(T))
d2 = [log(I0/K) - (a - sigma^2/2)*T] / (sigma*sqrt(T))
E  = Phi(d1) + (I0/K)^(1 - 2*a/sigma^2) * Phi(d2)
PV_GBM_formula = exp(-r*T) * (F - w*F*E)
```

The maintained interface requires `0 < I0 < K`, positive volatility and maturity. The control is a continuous-barrier GBM formula, whereas simulated payoffs use an Euler grid; this discrepancy remains part of the supplied method and is not removed through recalibration.

```text
diffprice.GBM = PV_GBM_simulated - PV_GBM_formula
coefficient = cov(PV_PJD, diffprice.GBM) / var(diffprice.GBM)
adjusted_PJD = PV_PJD - coefficient * diffprice.GBM
price = mean(adjusted_PJD)
SE = sd(adjusted_PJD) / sqrt(nsim)
CI = price +/- 1.96 * SE
```

For constant GBM payoffs in very small runs, maintained code warns and sets the coefficient to zero rather than dividing by zero. The formula price has no Monte Carlo SE; its SE/CI fields are NA. The reported CI is a normal Monte Carlo interval, not a measure of parameter, climate, calibration or discretization uncertainty. Individual adjusted payoffs and even small-run estimates need not stay within physical principal bounds; prices are not clipped, and a nonpositive estimate has undefined spread (NA).

All four price/spread outputs are retained. Spreads use `-log(price/F)/T-r`, a continuously compounded annual spread over r. Higher lambda lowers the adjusted drift and, under this implementation, lowers trigger probability and increases price. It is a sensitivity convention, not a market calibration.

## Sensitivity and reproducibility boundaries

The full grid is N = 100, 500, 1000 crossed with nsim = 3500, 5000, 6500 at lambda=0.05. Main scenarios use selected N=500, nsim=6500 and all three lambda values automatically. Portable PSOCK workers return results in path order; failed cluster creation falls back to serial with a warning, and worker cleanup is registered on exit.

Transcribed [reported tables](../results/reported/) are immutable research records for this project. Fresh runs write separate local outputs with configurations, RNG/backend details and R session information. Software fixtures establish executability. Full reproduction and independent estimator diagnostics are documented separately in [reproduction.md](reproduction.md); original reported results are not overwritten.
