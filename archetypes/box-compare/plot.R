#!/usr/bin/env Rscript
# Archetype: Boxplot with significance annotations (ggpubr stat_compare_means)
# Four treatment groups: Ctrl / LowDose / HighDose / Combo
# House style: figure_setup.R (Helvetica + theme_nature + save_nature + NATURE_FONT)
# Colour: ggsci npg via ggpubr palette="npg" (local; does not modify theme)
suppressPackageStartupMessages({
  .plot_file <- local({
    f <- grep("--file=", commandArgs(FALSE), value = TRUE)
    if (length(f)) normalizePath(sub("--file=", "", f[1])) else NA_character_
  })
  source(file.path(
    if (!is.na(.plot_file)) dirname(.plot_file) else "archetypes/box-compare",
    "..", "_lib", "figure_setup.R"
  ))
  library(ggplot2)
  library(ggpubr)
})

here <- if (!is.na(.plot_file)) dirname(.plot_file) else "archetypes/box-compare"
source(file.path(here, "..", "_lib", "synth_data.R"))
out <- file.path(here, "out")
dir.create(out, showWarnings = FALSE, recursive = TRUE)

# ── Data ─────────────────────────────────────────────────────────────────────
d <- synth_box(seed = 32)

# Pairwise comparisons vs Ctrl
cmp <- list(
  c("Ctrl", "LowDose"),
  c("Ctrl", "HighDose"),
  c("Ctrl", "Combo")
)

# ── Plot ─────────────────────────────────────────────────────────────────────
p <- ggpubr::ggboxplot(
    d,
    x      = "group",
    y      = "value",
    color  = "group",
    palette = "npg",
    add    = "jitter",
    add.params = list(size = 0.6, alpha = 0.5)
  ) +
  ggpubr::stat_compare_means(
    comparisons = cmp,
    label       = "p.signif",
    method      = "wilcox.test",
    size        = 2.4
  ) +
  ggpubr::stat_compare_means(
    method  = "kruskal.test",
    label.y = max(d$value) + 2.2,
    size    = 2.4
  ) +
  labs(
    x       = NULL,
    y       = "Expression",
    title   = "Group comparison with significance (synthetic demo)",
    caption = paste(
      "Synthetic data only — not real results. set.seed(32); n = 160 (40/group).",
      "Pairwise: Wilcoxon rank-sum vs Ctrl (no multiplicity correction shown).",
      "Global: Kruskal-Wallis. * p<0.05; ** p<0.01; *** p<0.001; ns p≥0.05.",
      "Colour: ggsci npg palette (via ggpubr).",
      sep = " "
    )
  ) +
  theme_nature() +
  theme(
    legend.position = "none",
    plot.caption    = element_text(size = 6, colour = "grey45", hjust = 0,
                                   family = NATURE_FONT)
  )

# ── Export ────────────────────────────────────────────────────────────────────
save_nature(p, file.path(out, "ref"), width_mm = 120, height_mm = 110)
cat("done:", file.path(out, "ref.png"), "\n")
