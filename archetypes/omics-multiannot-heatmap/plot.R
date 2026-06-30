#!/usr/bin/env Rscript
# Archetype: 多注释轨道差异热图 (ComplexHeatmap)
suppressPackageStartupMessages({
  source("~/.claude/assets/figure-style/nature_theme.R")
  library(ComplexHeatmap); library(circlize); library(grid)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/omics-multiannot-heatmap"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d <- synth_expr(n_genes=40, n_samples=60, seed=1); mat <- d$mat; anno <- d$col_anno
sub_lv <- levels(anno$Subtype); stg_lv <- levels(anno$Stage); tis_lv <- levels(anno$Tissue)
legp <- function() list(title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT),
                        labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT))
top <- HeatmapAnnotation(
  Subtype=anno$Subtype, Stage=anno$Stage, Tissue=anno$Tissue,
  col=list(Subtype=setNames(nature_pal_anno[seq_along(sub_lv)], sub_lv),
           Stage  =setNames(nature_seq[c(2,4,6)][seq_along(stg_lv)], stg_lv),
           Tissue =setNames(nature_pal_anno[4:5][seq_along(tis_lv)], tis_lv)),
  annotation_name_gp=gpar(fontsize=6,fontfamily=NATURE_FONT),
  simple_anno_size=unit(2.5,"mm"), gap=unit(0.6,"mm"),
  annotation_legend_param=list(Subtype=legp(), Stage=legp(), Tissue=legp()))
ht <- Heatmap(mat, name="Z-score", col=nature_heatmap_col(), top_annotation=top,
  show_column_names=FALSE, row_names_gp=gpar(fontsize=5,fontfamily=NATURE_FONT),
  clustering_distance_rows="pearson", clustering_distance_columns="pearson",
  row_dend_width=unit(6,"mm"), column_dend_height=unit(6,"mm"),
  heatmap_legend_param=legp())
save_heatmap(ht, file.path(out,"ref"), width_mm=120, height_mm=150)
cat("done:", file.path(out,"ref.png"), "\n")
