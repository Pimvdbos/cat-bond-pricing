# Reconstructed from PDF Listing B. Not the unavailable original source.
# See docs/code_provenance.md before execution.
library(quantmod)

# S&P 500 log returns
getSymbols( "^GSPC", src = "yahoo", from = "1950-01-01")
prices <- Ad(GSPC)
annual_returns <- periodReturn(prices, period = "yearly", type = "log")
years <- format(index(annual_returns), "%Y")
sp_returns <- data.frame(
Year = as.numeric(years),
SP500_log_return = as.numeric(coredata(annual_returns))
)

# ACE data
ace_data <- read.csv( "ace-north-atlantic-hurricanes.csv")
ace_na <- ace_data[, c( "Year", "Accumulated.cyclone.energy.index")]
colnames(ace_na) <- c( "Year", "ACE")

# Compute annual ACE log returns
ace_na <- ace_na[order(ace_na$Year), ]
ace_na$ACE_log_return <- c(
NA,
log(ace_na$ACE[-1] / ace_na$ACE[-nrow(ace_na)])
)

# Align the two annual return series
df <- merge(
ace_na[, c( "Year", "ACE_log_return")],
sp_returns,
by = "Year"
)
df <- na.omit(df)

# Pearson correlation test
cor.test(df$ACE_log_return, df$SP500_log_return, method = "pearson")

# Optional robustness check
cor.test(df$ACE_log_return, df$SP500_log_return,
method = "spearman", exact = FALSE)
