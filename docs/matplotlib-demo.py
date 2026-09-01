"""Render the demo figure for one matplotlib variant: docs/matplotlib-<variant>.png.

python docs/matplotlib-demo.py light
python docs/matplotlib-demo.py dark

Needs the styles and ddlc_cmaps.py installed (install.sh --component matplotlib), or point
MPLCONFIGDIR and PYTHONPATH at dist/. One figure, four panels — a line chart off the cycler,
grouped bars, a sequential heatmap and a diverging one — so every piece of the theme is on
the page: the cycle order, the grounds, the grid discipline and both colormap families.
"""

import sys

import matplotlib

matplotlib.use("Agg")

import ddlc_cmaps  # noqa: F401 — registers on import
import matplotlib.pyplot as plt
import numpy as np

variant = sys.argv[1] if len(sys.argv) > 1 else "dark"
style = "ddlc" if variant == "light" else "ddlc-dark"
seq, div = ("ddlc_seq", "ddlc_div") if variant == "light" else ("ddlc_seq_dark", "ddlc_div_dark")

plt.style.use(style)
rng = np.random.default_rng(42)
# The cycle length is the theme's own statement: five series on paper, three on ink
cycle = plt.rcParams["axes.prop_cycle"].by_key()["color"]
n = len(cycle)

fig, axes = plt.subplots(2, 2, figsize=(9, 6.4))
fig.suptitle(f"DDLC for matplotlib — {style}", x=0.06, ha="left", fontweight="bold")

ax = axes[0, 0]
x = np.arange(24)
for i in range(n):
    ax.plot(x, np.cumsum(rng.normal(0.4 + 0.2 * i, 1.2, x.size)), label=f"club {i + 1}")
ax.set_title("poems per week")
ax.grid(axis="y")
ax.legend(ncols=2, fontsize=7)

ax = axes[0, 1]
groups = np.arange(4)
width = 0.8 / n
for i in range(n):
    ax.bar(groups + i * width, rng.integers(3, 10, groups.size), width=width * 0.9)
ax.set_title("weekend festival turnout")
ax.set_xticks(groups + 0.4 - width / 2, ["act 1", "act 2", "act 3", "act 4"])
ax.grid(axis="y")

ax = axes[1, 0]
im = ax.imshow(np.sort(rng.random((10, 12)), axis=1), cmap=seq, aspect="auto")
ax.set_title(f"reading time (sequential, {seq})")
fig.colorbar(im, ax=ax, shrink=0.9)

ax = axes[1, 1]
mood = rng.normal(0, 1, (10, 12))
im = ax.imshow(mood, cmap=div, vmin=-3, vmax=3, aspect="auto")
ax.set_title(f"mood swings (diverging, {div})")
fig.colorbar(im, ax=ax, shrink=0.9)

fig.tight_layout(rect=(0, 0, 1, 0.96))
fig.savefig(f"docs/matplotlib-{variant}.png")
print(f"wrote docs/matplotlib-{variant}.png")
