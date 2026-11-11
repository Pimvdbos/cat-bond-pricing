# Optional loader checks with artificial fixtures; never research evidence.
source("R/data.R")
stopifnot(requireNamespace("digest", quietly = TRUE), requireNamespace("quantmod", quietly = TRUE))
ace_file <- tempfile(fileext = ".csv")
sp_file <- tempfile(fileext = ".csv")
tryCatch({
  x <- data.frame(Entity = c(rep("North Atlantic", 4), "Other basin"),
                  Year = c(1953, 1949, 1950, 1951, 1950),
                  ACE = c(80, 100, 110, 121, 999))
  write.csv(x, ace_file, row.names = FALSE)
  ace <- suppressWarnings(load_ace(ace_file))
  stopifnot(identical(ace$data$Year, c(1949, 1950, 1951, 1953)),
            is.na(tail(ace$data$ACE_log_return, 1)),
            all.equal(ace$data$ACE_log_return[2], log(1.1)),
            !1952 %in% ace$data$Year,
            ace$provenance$retained_rows == 4)
  x$ACE[2] <- 0
  write.csv(x, ace_file, row.names = FALSE)
  rejected <- try(load_ace(ace_file), silent = TRUE)
  stopifnot(inherits(rejected, "try-error"))
  # Synthetic prices confirm leading-period convention and 2022 cutoff.
  write.csv(data.frame(Date = c("1950-01-03", "1950-12-29", "1951-12-31", "2023-01-03"),
                        Adjusted = c(100, 110, 121, 150)), sp_file, row.names = FALSE)
  sp <- load_sp500(sp_file)
  stopifnot(max(sp$data$Year) == 1951,
            all.equal(sp$data$SP500_log_return[1], log(1.1)))
  # Complete artificial annual pairs; exercise both tests and year alignment.
  a <- data.frame(Year = 1949:1955, ACE_log_return = c(0.1, 0.2, -0.1, NA, 0.4, -0.2, 0.3))
  s <- data.frame(Year = 1950:1956, SP500_log_return = c(0.3, -0.2, 0.1, 0.2, 0.5, -0.1, 0.7))
  result <- correlation_analysis(a, s)
  stopifnot(nrow(result$paired) == 5, identical(result$omitted_years, 1952L),
            is.finite(result$pearson$p.value), is.finite(result$spearman$p.value))
}, finally = unlink(c(ace_file, sp_file)))
cat("PASS: synthetic entity selection, sorting, gap handling, positivity, partial first year,\n",
    "2022 cutoff, year alignment, Pearson and Spearman execution.\n")
