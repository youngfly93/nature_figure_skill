#!/usr/bin/env Rscript
# Archetype: 单细胞 UMAP atlas（聚类着色 + marker feature 分面）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(ggrastr); library(patchwork); library(viridisLite)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/sc-umap-atlas"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

s <- synth_scrna(n_cells=2000, n_types=6, n_markers=4, seed=11)
emb <- s$emb
cols <- setNames(nature_pal_anno[seq_len(nlevels(emb$celltype))], levels(emb$celltype))
# 簇中心（放直接标签）
cen <- aggregate(cbind(UMAP1,UMAP2)~celltype, emb, median)

pMain <- ggplot(emb, aes(UMAP1, UMAP2, colour=celltype)) +
  ggrastr::rasterise(geom_point(size=0.35, alpha=0.8), dpi=300) +
  geom_text(data=cen, aes(label=celltype), colour="black", size=2.2, fontface="bold") +
  scale_colour_manual(values=cols, guide="none") +
  coord_fixed() + labs(title="Cell-type atlas (UMAP)") + theme_nature() +
  theme(axis.text=element_blank(), axis.ticks=element_blank())

# 4 个 marker feature plot
mk <- s$markers$gene[match(levels(emb$celltype), s$markers$celltype)][1:4]
feat_panel <- function(g) {
  d <- emb; d$expr <- s$expr[g, ]
  ggplot(d, aes(UMAP1, UMAP2, colour=expr)) +
    ggrastr::rasterise(geom_point(size=0.3), dpi=300) +
    scale_colour_gradientn(colours=c("grey88", nature_seq[4], nature_div[1]), name="expr") +
    coord_fixed() + labs(title=g) + theme_nature(base_size=6) +
    theme(axis.text=element_blank(), axis.ticks=element_blank(), axis.title=element_blank(),
          legend.key.width=unit(2,"mm"), legend.key.height=unit(4,"mm"))
}
feats <- lapply(mk, feat_panel)

fig <- pMain + (feats[[1]]+feats[[2]]+feats[[3]]+feats[[4]] + plot_layout(ncol=2)) +
  plot_layout(widths=c(1.3,1)) +
  plot_annotation(tag_levels="A",
    caption="Synthetic scRNA-seq, style demo only (not real results). set.seed(11); n=2000 cells.",
    theme=theme(plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT)))

save_nature(fig, file.path(out,"ref"), width_mm=183, height_mm=110)
cat("done:", file.path(out,"ref.png"), "\n")
