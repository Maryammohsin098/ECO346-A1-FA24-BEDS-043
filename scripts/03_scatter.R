# 03_scatter.R -- Question 3 (and redesign for Question 4): earnings vs age
source("scripts/00_helpers.R")
d <- load_earners()

bands <- d |>
  group_by(band, band_lab, mid) |>
  summarise(n = n(), wmean = round(wmean(earn_annual, hhweight)), .groups = "drop") |>
  mutate(thin = n < 30)
write_csv(bands, "tables/band_table_R.csv")
print(bands)

top <- bands |> slice_max(wmean, n = 1)
cat("Band 25-29:", bands$wmean[bands$band_lab == "25-29"],
    " Band 45-49:", bands$wmean[bands$band_lab == "45-49"],
    " Highest:", top$band_lab, "\n")

p <- ggplot() +
  geom_point(data = d, aes(age, earn_annual),
             alpha = 0.15, size = 1, colour = "grey30",       # alpha: choose and justify
             position = position_jitter(width = 0.4, height = 0, seed = 346)) +
  geom_line(data = bands, aes(mid, wmean), colour = "firebrick", linewidth = 0.8) +
  geom_point(data = bands, aes(mid, wmean, shape = thin),
             colour = "firebrick", size = 3.5, stroke = 1.2) +
  scale_shape_manual(values = c(`FALSE` = 16, `TRUE` = 1), guide = "none") +
  annotate("text", x = top$mid, y = top$wmean * 1.9, colour = "firebrick",
           label = paste0("Highest: ages ", top$band_lab,
                          "\nRs ", comma(top$wmean))) +
  scale_y_log10(limits = c(1e4, 1e7), breaks = 10^(4:7), labels = rs_labels(10^(4:7))) +
  scale_x_continuous(limits = c(14.5, 64.5), breaks = seq(15, 65, 5)) +
  labs(title = paste0("Mean earnings in urban Sindh rise with age, peaking at Rs ", top$band_lab, ")"),
       x = "Age (years)", y = "Annual earnings (log scale)",
       caption = paste0("Source: PSLM 2019-20, person file. Sample: earners aged 15-64, Sindh urban, ",
                        "weighted by household weight. Large markers = weighted band means; ",
                        "hollow = band with fewer than 30 observations. ",
                        "Two earners outside Rs 10,000-10,000,000 are not shown.")) +
  theme_minimal(base_size = 12) +
  theme(panel.grid.minor = element_blank(),
        plot.title.position = "plot", plot.caption = element_text(hjust = 0))

ggsave("figures/scatter.svg", p, width = 9, height = 5.5)
