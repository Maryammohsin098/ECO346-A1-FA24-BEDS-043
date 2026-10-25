# 04_python.py -- Question 5: recompute band table and redraw the Q3 figure in Python
import numpy as np, pandas as pd, matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

hh  = pd.read_csv("data/pslm_hh_subset.csv", usecols=["hhid","hhweight","prov_code","urban_rural"])
per = pd.read_csv("data/pslm_person_subset.csv")
d = per.merge(hh, on="hhid", how="left")
d = d[(d.prov_code == 3) & (d.urban_rural == 2) & d.age.between(15, 64) & (d.earn_annual > 0)].copy()
d["band"] = (d.age - 15) // 5
d["mid"]  = 17 + 5 * d.band
d["band_lab"] = (15 + 5*d.band).astype(int).astype(str) + "-" + (19 + 5*d.band).astype(int).astype(str)

rows = []
for (b, lab, mid), x in d.groupby(["band", "band_lab", "mid"]):
    rows.append({"band": b, "band_lab": lab, "mid": mid, "n": len(x),
                 "wmean": round((x.hhweight * x.earn_annual).sum() / x.hhweight.sum())})
bands = pd.DataFrame(rows)
bands["thin"] = bands.n < 30
bands.to_csv("tables/band_table_python.csv", index=False)
print(bands)

try:
    r = pd.read_csv("tables/band_table_R.csv")
    print("Max abs difference vs R (rupees):", (r.wmean - bands.wmean).abs().max())
except FileNotFoundError:
    print("Run scripts/03_scatter.R first to compare.")

rng = np.random.default_rng(346)
fig, ax = plt.subplots(figsize=(9, 5.5))
ax.scatter(d.age + rng.uniform(-0.4, 0.4, len(d)), d.earn_annual,
           s=6, alpha=0.15, color="0.2", linewidths=0)
ax.plot(bands.mid, bands.wmean, color="firebrick", lw=1.5)
solid, hollow = bands[~bands.thin], bands[bands.thin]
ax.scatter(solid.mid, solid.wmean, s=60, color="firebrick", zorder=3)
ax.scatter(hollow.mid, hollow.wmean, s=60, facecolors="none", edgecolors="firebrick", zorder=3)
top = bands.loc[bands.wmean.idxmax()]
ax.annotate(f"Highest: ages {top.band_lab}\nRs {int(top.wmean):,}",
            (top.mid, top.wmean), xytext=(0, 25), textcoords="offset points",
            ha="center", color="firebrick")
ax.set_yscale("log"); ax.set_ylim(1e4, 1e7); ax.set_xlim(15, 64)
ax.set_yticks([1e4,1e5,1e6,1e7]); ax.set_yticklabels([f"Rs {int(v):,}" for v in [1e4,1e5,1e6,1e7]])
ax.minorticks_off()
ax.set_xticks(range(15, 66, 5))
ax.set_xlabel("Age (years)"); ax.set_ylabel("Annual earnings (log scale)")
ax.set_title(f"Mean earnings in urban Sindh rise with age, peaking at Rs {int(top.wmean):,} at ages {top.band_lab}", loc="left"source("scripts/02_histogram.R")
source("scripts/03_scatter.R"))
for s in ["top","right"]: ax.spines[s].set_visible(False)
fig.text(0.01, 0.01, "Source: PSLM 2019-20, person file. Sample: earners aged 15-64, Sindh urban, weighted by household weight.\n"
         "Large markers = weighted band means; hollow = band with fewer than 30 observations.",
         fontsize=8, ha="left", va="bottom")
fig.tight_layout(rect=(0, 0.07, 1, 1))
fig.savefig("figures/scatter_python.svg")
