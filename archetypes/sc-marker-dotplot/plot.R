#!/usr/bin/env Rscript
# Archetype: 单细胞 marker dotplot（基因×细胞类型；点大小=表达比例，色=平均表达 z）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/sc-marker-dotplot"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

s <- synth_scrna(seed=11); expr <- s$expr; ct <- s$emb$celltype
genes <- s$markers$gene
# 每 (gene, celltype): pct 表达(>0) + 平均表达
agg <- do.call(rbind, lapply(genes, function(g) {
  v <- expr[g, ]
  data.frame(gene=g, celltype=levels(ct),
             pct = tapply(v>0, ct, mean)*100,
             mean= tapply(v, ct, mean))
}))
# 按基因把平均表达 z-score（跨 celltype），更能显特异性
agg$z <- ave(agg$mean, agg$gene, FUN=function(x) as.numeric(scale(x)))
agg$gene <- factor(agg$gene, levels=rev(genes))
agg$celltype <- factor(agg$celltype, levels=levels(ct))

p <- ggplot(agg, aes(celltype, gene)) +
  geom_point(aes(size=pct, colour=z)) +
  scale_size_continuous(range=c(0.2,4.2), name="% expr") +
  scale_colour_gradientn(colours=rev(nature_div), name="mean expr (z)") +
  labs(x=NULL, y=NULL, title="Marker expression dotplot (synthetic demo)",
       caption="Synthetic scRNA-seq, style demo only (not real results). set.seed(11).") +
  theme_nature() +
  theme(axis.text.x=element_text(angle=45, hjust=1),
        axis.text.y=element_text(size=4.5),
        panel.grid.major=element_line(linewidth=0.15, colour="grey92"),
        plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT))

save_nature(p, file.path(out,"ref"), width_mm=120, height_mm=150)
cat("done:", file.path(out,"ref.png"), "\n")
