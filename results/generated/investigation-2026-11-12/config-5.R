list(config = list(mu = 0.196, sigma = 0.66, jump_sd = 1.55,
    jump_intensity = 0.135, mean_log_jump = 0.202, face_value = 1000,
    initial_index = 100, threshold = 200, maturity = 1, loss_fraction = 1,
    risk_free_rate = 0.03, market_price_of_risk = 0.7, N = 500L,
    nsim = 2000L, scenarios = c(0.05, 0.3, 0.7), grid_N = c(100L,
    500L, 1000L), grid_nsim = c(3500L, 5000L, 6500L)), repetitions = 100L,
    workers = 2L, seed_rule = "set.seed(nsim * p + repetition)",
    rng = c("Mersenne-Twister", "Inversion", "Rejection"))
