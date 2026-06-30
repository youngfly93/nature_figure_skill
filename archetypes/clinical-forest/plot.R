#!/usr/bin/env Rscript
# Archetype: 森林图 — Cox 多变量 HR 可视化（nature_forest）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/clinical-forest"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

df <- synth_forest(seed = 31)

p <- nature_forest(df, title = "Multivariable Cox forest (synthetic demo)") +
  labs(caption = "Synthetic data, style demo only (not real results). set.seed(31); HR with 95% CI.") +
  theme(plot.caption = element_text(size = 6, colour = "grey45", hjust = 0, family = NATURE_FONT))

save_nature(p, file.path(out, "ref"), width_mm = 120, height_mm = 100)
cat("done:", file.path(out, "ref.png"), "\n")
