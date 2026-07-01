#!/usr/bin/env Rscript
# Archetype: 列线图 nomogram（rms::cph 多变量 Cox → 预测 1/3/5 年生存概率）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(rms); library(ragg)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/clinical-nomogram"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d <- synth_nomogram_cohort(seed = 52)   # 生存结局 + Age/Stage/Grade/Biomarker
dd <- datadist(d); options(datadist = "dd")

f <- cph(Surv(time, status) ~ Age + Stage + Grade + Biomarker, data = d,
         surv = TRUE, x = TRUE, y = TRUE)

surv <- Survival(f)                              # 生存概率函数（月）
p12 <- function(x) surv(12, x)                   # 1 年
p36 <- function(x) surv(36, x)                   # 3 年
p60 <- function(x) surv(60, x)                   # 5 年
nom <- nomogram(f, fun = list(p12, p36, p60),
                funlabel = c("1-year survival","3-year survival","5-year survival"),
                fun.at = c(0.1, 0.3, 0.5, 0.7, 0.85, 0.95))

# nomogram 是 base graphics（非 ggplot）→ 不走 save_nature，显式设备流程
draw <- function() {
  par(family = NATURE_FONT, mar = c(4, 2, 2.5, 2), cex = 0.7)
  plot(nom, xfrac = 0.32, cex.axis = 0.72, cex.var = 0.85, lmgp = 0.22,
       col.grid = c("grey90","grey97"))
  title(main = "Prognostic nomogram (synthetic demo)", cex.main = 0.95, font.main = 1)
  mtext("Synthetic data, style demo only (not real results). set.seed(52); rms::cph multivariable Cox.",
        side = 1, line = 2.6, adj = 0, cex = 0.5, col = "grey45")
}
w_in <- 180/25.4; h_in <- 120/25.4
ragg::agg_png(file.path(out,"ref.png"), width = w_in, height = h_in, units = "in", res = 600, bg = "white")
draw(); dev.off()
grDevices::cairo_pdf(file.path(out,"ref.pdf"), width = w_in, height = h_in, family = NATURE_FONT, bg = "white")
draw(); dev.off()
unlink("Rplots.pdf")
cat("done:", file.path(out,"ref.png"), "\n")
