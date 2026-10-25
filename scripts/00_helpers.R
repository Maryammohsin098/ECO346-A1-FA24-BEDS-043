# 00_helpers.R -- shared functions and data preparation (sourced by scripts 01-03)
# Run all scripts with the repository folder as the working directory.
library(tidyverse)
library(svglite)
library(scales)

VARIANT_PROV  <- 3   # Sindh
VARIANT_AREA  <- 2   # urban

# Weighted mean: sum(w*x)/sum(w)
wmean <- function(x, w) sum(w * x) / sum(w)

# Weighted p-th quantile, exactly as defined in the assignment:
# sort by x, cumulative share of weight, smallest x where share >= p
wquant <- function(x, w, p) {
  o  <- order(x)
  x  <- x[o]; w <- w[o]
  cs <- cumsum(w) / sum(w)
  x[which(cs >= p - 1e-12)[1]]
}

load_earners <- function() {
  hh  <- read_csv("data/pslm_hh_subset.csv",
                  col_select = c(hhid, hhweight, prov_code, urban_rural),
                  show_col_types = FALSE)
  per <- read_csv("data/pslm_person_subset.csv", show_col_types = FALSE)
  per |>
    left_join(hh, by = "hhid") |>
    filter(prov_code == VARIANT_PROV, urban_rural == VARIANT_AREA,
           age >= 15, age <= 64, !is.na(earn_annual), earn_annual > 0) |>
    mutate(band     = (age - 15) %/% 5,                 # 0..9
           band_lab = paste0(15 + 5 * band, "-", 19 + 5 * band),
           mid      = 17 + 5 * band)
}

rs_labels <- function(x) paste0("Rs ", comma(x))
