# 02_histogram.R -- Question 2: weighted histogram of earnings on a log10 scale
source("scripts/00_helpers.R")
d <- load_earners()
d$lx <- log10(d$earn_annual)

# --- numbers to report (all earners) ---
n_earners <- nrow(d)
w_med  <- wquant(d$earn_annual, d$hhweight, 0.5)
u_med  <- median(d$earn_annual)            # unweighted
w_p10  <- wquant(d$earn_annual, d$hhweight, 0.1)
w_p90  <- wquant(d$earn_annual, d$hhweight, 0.9)
ratio  <- round(w_p90 / w_p10, 2)

inr <- d |> filter(lx >= 4, lx <= 7)
n_excl <- n_earners - nrow(inr)

cat("Earners:", n_earners, "\n",
    "Weighted median:", round(w_med), " Unweighted median:", round(u_med), "\n",
    "p10:", round(w_p10), " p90:", round(w_p90), " p90/p10:", ratio, "\n",
    "Excluded (outside Rs 10,000-10,000,000):", n_excl, "\n")

# --- weighted density per log10 unit; 30 bins of width 0.1 ---
inr <- inr |> mutate(bin = pmin(floor((lx - 4) / 0.1 + 1e-9), 29))
h <- inr |>
  group_by(bin) |>
  summarise(w = sum(hhweight), .groups = "drop") |>
  mutate(density = w / sum(w) / 0.1,       # area under bars = 1
         xmin = 4 + 0.1 * bin, xmax = xmin + 0.1)

ymax <- max(h$density)
p <- ggplot(h) +
  geom_rect(aes(xmin = xmin, xmax = xmax, ymin = 0, ymax = density),
            fill = "grey55", colour = "white", linewidth = 0.2) +
  geom_vline(xintercept = log10(c(w_med, w_p90)), linetype = "dashed") +
  annotate("text", x = log10(w_med) - 0.03, y = ymax * 1.02, hjust = 1,
           label = paste0("Weighted median\nRs ", comma(round(w_med)))) +
  annotate("text", x = log10(w_p90) + 0.03, y = ymax * 1.02, hjust = 0,
           label = paste0("90th percentile\nRs ", comma(round(w_p90)))) +
  scale_x_continuous(breaks = 4:7, labels = rs_labels(10^(4:7)),
                     limits = c(3.9, 7.1)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
  labs(title = "Earnings in urban Sindh are widely spread: the 90th percentile is 5.8 times the 10th",
       x = "Annual earnings (log scale)", y = "Density per log10 unit",
       caption = paste0("Source: PSLM 2019-20, person file. Sample: earners aged 15-64, Sindh urban, ",
                        "weighted by household weight. ", n_excl,
                        " earners outside Rs 10,000-10,000,000 excluded.")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.x = element_blank(),
        plot.title.position = "plot", plot.caption = element_text(hjust = 0))

ggsave("figures/histogram.svg", p, width = 9, height = 5.5)
