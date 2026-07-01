#!/usr/bin/env Rscript
# Archetype: 全基因组 CNV 频率谱（GISTIC 样，amplification 上 / deletion 下，线性染色体布局）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/cnv-gistic"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

cnv <- synth_cnv_freq(seed = 56)   # chr / bin / gain / loss（频率 0–1）

chr_levels <- levels(cnv$chr)
sizes  <- as.numeric(tapply(cnv$bin, cnv$chr, length)[chr_levels])
offset <- c(0, cumsum(sizes))[seq_along(chr_levels)]; names(offset) <- chr_levels
bounds <- cumsum(sizes)                                   # 各染色体右边界
centers <- offset + sizes / 2                             # 标签居中
cnv$x <- offset[as.character(cnv$chr)] + cnv$bin

plot_df <- rbind(
  data.frame(x = cnv$x, freq =  cnv$gain, dir = "Gain"),
  data.frame(x = cnv$x, freq = -cnv$loss, dir = "Loss"))
odd  <- seq(1, length(offset), by = 2)                    # 奇数染色体加浅底带
band <- data.frame(xmin = offset[odd], xmax = bounds[odd])

p <- ggplot() +
  geom_rect(data = band, aes(xmin = xmin, xmax = xmax, ymin = -1, ymax = 1),
            fill = "grey96", inherit.aes = FALSE) +
  geom_col(data = plot_df, aes(x, freq, fill = dir), width = 1) +
  geom_hline(yintercept = 0, linewidth = 0.3, colour = "grey40") +
  geom_vline(xintercept = bounds, linewidth = 0.15, colour = "grey80") +
  scale_fill_manual(values = c(Gain = nature_sig_col[["Up"]], Loss = nature_sig_col[["Down"]]), name = NULL) +
  scale_x_continuous(breaks = centers, labels = sub("chr", "", chr_levels), expand = c(0, 0)) +
  scale_y_continuous("Alteration frequency", limits = c(-1, 1),
                     breaks = seq(-1, 1, 0.5), labels = function(v) scales::percent(abs(v))) +
  labs(x = "Chromosome", title = "Genome-wide CNV frequency (GISTIC-style, synthetic demo)",
       caption = "Synthetic data, style demo only (not real results). set.seed(56); amplification up / deletion down.") +
  theme_nature() +
  theme(panel.grid = element_blank(), legend.position = "top",
        plot.caption = element_text(size = 6, colour = "grey45", hjust = 0, family = NATURE_FONT))

save_nature(p, file.path(out,"ref"), width_mm = 183, height_mm = 76)
cat("done:", file.path(out,"ref.png"), "\n")
