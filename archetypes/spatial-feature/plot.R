#!/usr/bin/env Rscript
# Archetype: 空间组学 feature 叠图（空间域 + 连续 feature）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(ggrastr); library(patchwork); library(viridisLite)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/spatial-feature"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

sp <- synth_spatial(n_spots=1500, seed=12)
cols <- setNames(nature_pal_anno[seq_len(nlevels(sp$celltype))], levels(sp$celltype))
pA <- ggplot(sp, aes(x, y, colour=celltype)) +
  ggrastr::rasterise(geom_point(size=0.9), dpi=300) +
  scale_colour_manual(values=cols, name="Domain") +
  coord_fixed() + labs(title="Spatial domains") + theme_nature() +
  theme(axis.text=element_blank(), axis.ticks=element_blank())
pB <- ggplot(sp, aes(x, y, colour=feature)) +
  ggrastr::rasterise(geom_point(size=0.9), dpi=300) +
  scale_colour_viridis_c(option="magma", name="feature") +
  coord_fixed() + labs(title="Spatial feature gradient") + theme_nature() +
  theme(axis.text=element_blank(), axis.ticks=element_blank())
fig <- pA + pB + plot_layout(ncol=2) +
  plot_annotation(tag_levels="A",
    caption="Synthetic spatial data, style demo only (not real results). set.seed(12); n=1500 spots.",
    theme=theme(plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT)))
save_nature(fig, file.path(out,"ref"), width_mm=183, height_mm=95)
cat("done:", file.path(out,"ref.png"), "\n")
