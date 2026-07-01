#!/usr/bin/env Rscript
# Archetype: 免疫浸润组成（CIBERSORT 样堆叠占比条 + 关键细胞型 Tumor/Normal 组间比较）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(patchwork); library(ggpubr)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/immune-infiltration"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

im   <- synth_immune(seed = 54)
frac <- im$fractions; grp <- im$group; cells <- im$cells

long <- data.frame(
  sample = rep(rownames(frac), times = ncol(frac)),
  cell   = factor(rep(colnames(frac), each = nrow(frac)), levels = cells),
  frac   = as.vector(frac),
  group  = rep(grp, times = ncol(frac)))
ord <- order(grp, -frac[, "Macro M2"])                   # 组内按 M2 占比排，读图更顺
long$sample <- factor(long$sample, levels = rownames(frac)[ord])

# 10 细胞型需 >3 色（领域必需，见 card）：nature_pal_anno 插值补足
cell_cols <- setNames(colorRampPalette(nature_pal_anno)(length(cells)), cells)

## A) 每样本堆叠占比条
pA <- ggplot(long, aes(sample, frac, fill = cell)) +
  geom_col(width = 1) +
  facet_grid(~ group, scales = "free_x", space = "free_x") +
  scale_fill_manual(values = cell_cols, name = "Cell type") +
  scale_y_continuous(expand = c(0, 0), labels = scales::percent) +
  labs(x = "Samples", y = "Estimated fraction", title = "Immune cell composition") +
  theme_nature() +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        legend.key.size = unit(7, "pt"), legend.text = element_text(size = 6))

## B) 关键 TME 细胞型的组间比较（Wilcoxon）
key <- c("CD8 T","Treg","Macro M2")
sub <- long[long$cell %in% key, ]; sub$cell <- factor(sub$cell, levels = key)
pB <- ggplot(sub, aes(group, frac, fill = group)) +
  geom_boxplot(width = 0.6, outlier.size = 0.4, linewidth = 0.3) +
  geom_jitter(width = 0.15, size = 0.4, alpha = 0.4, colour = "grey25") +
  facet_wrap(~ cell, nrow = 1, scales = "free_y") +
  ggpubr::stat_compare_means(method = "wilcox.test", label = "p.format", size = 2.1) +
  scale_fill_manual(values = nature_group_cols(levels(grp)), guide = "none") +
  scale_y_continuous(expand = expansion(mult = c(0.05, 0.15))) +
  labs(x = NULL, y = "Fraction", title = "Key TME cell types (Wilcoxon rank-sum)") +
  theme_nature()

fig <- pA / pB + plot_layout(heights = c(1.3, 1)) +
  plot_annotation(tag_levels = "A",
    caption = "Synthetic data, style demo only (not real results). set.seed(54); rows sum to 1; Wilcoxon rank-sum.",
    theme = theme(plot.caption = element_text(size = 6, colour = "grey45", hjust = 0, family = NATURE_FONT)))

save_nature(fig, file.path(out,"ref"), width_mm = 183, height_mm = 132)
cat("done:", file.path(out,"ref.png"), "\n")
