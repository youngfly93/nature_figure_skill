#!/usr/bin/env Rscript
# Archetype: KM 生存曲线 + number-at-risk 表（biomarker High/Low，log-rank + Cox HR，复用 nature_km）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(patchwork)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/clinical-km"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

df <- synth_km(seed = 51)   # data.frame(time, status, group=High/Low)

# nature_km 已内置：分层曲线 + 删失标记 + log-rank/Cox p + HR + number-at-risk 风险表
fig <- nature_km(df, time = "time", status = "status", group = "group",
                 levels = c("High","Low"),
                 title = "Overall survival by biomarker (synthetic demo)",
                 time_lab = "Time (months)", surv_lab = "Overall survival",
                 legend_title = "Biomarker",
                 cols = c(High = nature_sig_col[["High"]], Low = nature_sig_col[["Low"]]),
                 risk_table = TRUE, show_cox_p = TRUE)

fig <- fig + plot_annotation(
  caption = "Synthetic data, style demo only (not real results). set.seed(51); median split; log-rank & Cox HR shown.",
  theme = theme(plot.caption = element_text(size = 6, colour = "grey45", hjust = 0, family = NATURE_FONT)))

save_nature(fig, file.path(out,"ref"), width_mm = 110, height_mm = 115)
cat("done:", file.path(out,"ref.png"), "\n")
