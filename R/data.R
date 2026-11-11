# Cache files are private/local; provenance records contain basenames, not machine paths.
file_provenance <- function(path, source_url, acquisition = "manual or cached") {
  if (!requireNamespace("digest", quietly = TRUE)) stop("Install digest: Rscript scripts/install.R")
  list(file = basename(path), source_url = source_url, acquisition = acquisition,
       inspected_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
       sha256 = digest::digest(file = path, algo = "sha256"), bytes = file.info(path)$size)
}

load_ace <- function(path = "data/raw/ace-north-atlantic-hurricanes.csv",
                     entity = "North Atlantic", indicator = NULL) {
  x <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  if (!"Year" %in% names(x)) stop("ACE file must contain Year.")
  entities <- if ("Entity" %in% names(x)) unique(x$Entity) else character()
  if (length(entities)) {
    # OWID has also encoded this single basin-wide indicator with entity World.
    # Do not silently treat World as a basin: explicitly pass entity='World' only
    # after confirming the indicator metadata identifies the North Atlantic.
    if (!entity %in% entities) stop("Requested entity absent. Available entities: ", paste(entities, collapse = ", "),
      ". Inspect source metadata; pass the matching entity explicitly.")
    x <- x[x$Entity == entity, , drop = FALSE]
  } else warning("No Entity column: accepting user-supplied single-series ACE file.")
  if (is.null(indicator)) {
    candidates <- names(x)[grepl("accumulated[ ._]cyclone[ ._]energy|^ACE$", names(x), ignore.case = TRUE)]
    if (length(candidates) != 1L) stop("Specify indicator explicitly after inspecting source metadata.")
    indicator <- candidates
  }
  if (!indicator %in% names(x)) stop("Indicator column absent: ", indicator)
  years <- suppressWarnings(as.numeric(x$Year))
  if (any(!is.finite(years)) || any(years != floor(years))) stop("Invalid year values.")
  values <- suppressWarnings(as.numeric(x[[indicator]]))
  if (any(!is.na(x[[indicator]]) & is.na(values))) stop("Non-numeric ACE values.")
  if (anyDuplicated(years)) stop("Duplicate years in selected entity.")
  coverage <- range(years)
  sample <- data.frame(Year = years, ACE = values)
  sample <- sample[sample$Year >= 1851 & sample$Year <= 2022, ]
  sample <- sample[order(sample$Year), ]
  if (!nrow(sample)) stop("No ACE observations in 1851-2022.")
  if (any(!is.na(sample$ACE) & (!is.finite(sample$ACE) | sample$ACE <= 0)))
    stop("ACE must be finite and strictly positive before logarithms.")
  sample$ACE_log_return <- c(NA_real_, diff(log(sample$ACE)))
  consecutive <- c(FALSE, diff(sample$Year) == 1)
  sample$ACE_log_return[!consecutive] <- NA_real_
  missing_years <- setdiff(1851:2022, sample$Year)
  missing_values <- sample$Year[is.na(sample$ACE)]
  if (length(missing_years) || length(missing_values))
    warning("Missing ACE years/values recorded; returns across gaps are NA, not imputed.")
  provenance <- c(file_provenance(path,
    "https://ourworldindata.org/grapher/ace-north-atlantic-hurricanes.csv"),
    list(entity = if (length(entities)) entity else "single-series file (no entity field)",
      available_entities = entities, indicator = indicator, downloaded_coverage = coverage,
      research_period = c(1851, 2022), retained_coverage = range(sample$Year),
      retained_rows = nrow(sample), finite_levels = sum(is.finite(sample$ACE)),
      annual_returns = sum(is.finite(sample$ACE_log_return)),
      missing_years = missing_years, missing_value_years = missing_values))
  list(data = sample, provenance = provenance)
}

load_sp500 <- function(path = "data/cache/GSPC.rds") {
  if (!requireNamespace("quantmod", quietly = TRUE)) stop("Install quantmod first.")
  if (grepl("\\.rds$", path, ignore.case = TRUE)) {
    prices <- quantmod::Ad(readRDS(path))
  } else {
    x <- read.csv(path, check.names = FALSE)
    if (!all(c("Date", "Adjusted") %in% names(x))) stop("Manual Yahoo CSV requires Date,Adjusted columns.")
    dates <- as.Date(x$Date)
    if (anyNA(dates) || anyDuplicated(dates)) stop("Invalid or duplicate dates.")
    prices <- xts::xts(as.numeric(x$Adjusted), order.by = dates)
  }
  prices <- prices["1950-01-01/2022-12-31"]
  if (!NROW(prices)) stop("No S&P observations in research period.")
  if (anyNA(prices) || any(!is.finite(prices)) || any(prices <= 0))
    stop("Adjusted prices must be complete, finite and positive; inspect source gaps.")
  annual <- quantmod::periodReturn(prices, period = "yearly", type = "log", leading = TRUE)
  returns <- data.frame(Year = as.integer(format(zoo::index(annual), "%Y")),
                        SP500_log_return = as.numeric(annual))
  provenance <- c(file_provenance(path, "https://finance.yahoo.com/quote/%5EGSPC/history/"),
    list(symbol = "^GSPC", provider = "Yahoo", price_field = "Adjusted",
      retained_daily_coverage = as.character(range(zoo::index(prices))),
      retained_annual_coverage = range(returns$Year), annual_rows = nrow(returns),
      first_return_convention = "leading=TRUE: first available price to final price of first calendar year; partial first year"))
  list(data = returns, provenance = provenance)
}

correlation_analysis <- function(ace, sp500) {
  paired <- merge(ace[, c("Year", "ACE_log_return")], sp500, by = "Year")
  paired <- paired[paired$Year >= 1950 & paired$Year <= 2022, ]
  omitted <- paired$Year[!complete.cases(paired)]
  paired <- paired[complete.cases(paired), ]
  if (nrow(paired) < 4) stop("Insufficient complete paired returns.")
  list(paired = paired, omitted_years = omitted,
    pearson = cor.test(paired$ACE_log_return, paired$SP500_log_return, method = "pearson"),
    spearman = cor.test(paired$ACE_log_return, paired$SP500_log_return, method = "spearman", exact = FALSE))
}
