# Base R only. Every plotted number comes from the transcribed report tables.
dir.create("assets/figures", recursive = TRUE, showWarnings = FALSE)
prices <- read.csv("results/reported/table_7_prices.csv")
grid <- read.csv("results/reported/table_6_sensitivity.csv")
navy <- "#16324F"
teal <- "#087E8B"
orange <- "#C66526"
draw <- function(name, plotter) {
  for (format in c("svg", "png")) {
    file <- file.path("assets/figures", paste0(name, ".", format))
    if (format == "svg") svg(file, width = 9, height = 5.4, family = "sans")
    else png(file, width = 1440, height = 864, res = 160)
    par(mar = c(5.4, 5.2, 4.2, 1.6), mgp = c(3.1, 0.8, 0),
        col.axis = navy, col.lab = navy, fg = navy, las = 1)
    plotter()
    mtext("Source: Pricing of a CAT bond (2026), reported results; no new simulation.",
          side = 1, line = 4.3, cex = 0.72, col = "#536170")
    dev.off()
  }
}
scenario_plot <- function(y1, y2, ylabel, title, limits, labels) {
  x <- prices$market_price_of_risk
  plot(x, y1, type = "n", ylim = limits, xlim = c(0, 0.76), xaxt = "n",
       xlab = "Market price of risk (lambda)", ylab = ylabel, main = title, bty = "l")
  axis(1, at = x, labels = sprintf("%.2f", x))
  abline(h = axTicks(2), col = "#E8EDF1", lwd = 0.7)
  lines(x, y2, type = "b", col = orange, lty = 2, pch = 1, lwd = 2)
  lines(x, y1, type = "b", col = teal, pch = 19, lwd = 2)
  text(x, y1, labels = labels, pos = if (ylabel == "Bond price (USD)") 1 else 3, cex = 0.85, col = teal)
  legend("topleft", c("PJD with control variate", "PJD without control variate"),
         col = c(teal, orange), pch = c(19, 1), lty = c(1, 2), lwd = 2, bty = "n", cex = 0.85)
}
draw("reported_prices", function() scenario_plot(prices$pjd_price_vrt, prices$pjd_price_no_vrt,
  "Bond price (USD)", "Reported CAT-bond prices | Table 7", c(640, 910), sprintf("$%.2f", prices$pjd_price_vrt)))
draw("reported_spreads", function() scenario_plot(100 * prices$spread_vrt, 100 * prices$spread_no_vrt,
  "Continuous yield spread (% per year)", "Reported yield spreads above the risk-free rate | Table 7",
  c(12, 45), sprintf("%.2f%%", 100 * prices$spread_vrt)))
draw("reported_ci_widths", function() {
  cols <- c(teal, navy, orange)
  plot(0, 0, type = "n", xlim = c(3300, 6700), ylim = c(9, 15.7), xaxt = "n",
       xlab = "Simulation paths (nsim)", ylab = "95% confidence-interval width (USD)",
       main = "Reported simulation precision | Table 6, lambda = 0.05", bty = "l")
  axis(1, at = c(3500, 5000, 6500))
  abline(h = 10:15, col = "#E8EDF1", lwd = 0.7)
  for (i in seq_along(cols)) {
    d <- grid[grid$N == c(100, 500, 1000)[i], ]
    lines(d$nsim, d$ci_width, type = "b", pch = c(19, 17, 15)[i], col = cols[i], lwd = 2, lty = i)
  }
  legend("topright", paste("N =", c(100, 500, 1000)), col = cols, pch = c(19, 17, 15),
         lty = 1:3, lwd = 2, bty = "n", horiz = TRUE, cex = 0.85)
})
