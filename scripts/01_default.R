# 01_default.R -- Question 4: R's untouched default scatterplot
source("scripts/00_helpers.R")
d <- load_earners()

p <- ggplot(d, aes(age, earn_annual)) + geom_point()
ggsave("figures/default.svg", p)
