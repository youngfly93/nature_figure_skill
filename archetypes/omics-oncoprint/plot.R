#!/usr/bin/env Rscript
# Archetype: oncoprint 突变全景 (ComplexHeatmap::oncoPrint)
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ComplexHeatmap); library(grid)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/omics-oncoprint"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d <- synth_mutations(n_genes=20, n_samples=40, seed=7)
mat <- d$mat; clin <- d$clin

# 变异类型配色（取自 theme 调色板，不硬编）
vcol <- c(Missense   = nature_pal_anno[4],
          Truncating = nature_div[1],
          Amp        = nature_sig_col[["Up"]],
          Del        = nature_sig_col[["Down"]])
# alter_fun：每种变异画一个矩形/条
alter_fun <- list(
  background = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.85, gp=gpar(fill="#EEEEEE", col=NA)),
  Missense   = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.85, gp=gpar(fill=vcol["Missense"], col=NA)),
  Truncating = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.85, gp=gpar(fill=vcol["Truncating"], col=NA)),
  Amp        = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.40, gp=gpar(fill=vcol["Amp"], col=NA)),
  Del        = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.40, gp=gpar(fill=vcol["Del"], col=NA)))

top_anno <- HeatmapAnnotation(
  Subtype = clin$Subtype, Stage = clin$Stage,
  col = list(Subtype = setNames(nature_pal_anno[1:3], levels(clin$Subtype)),
             Stage   = setNames(nature_seq[c(2,4,6)], levels(clin$Stage))),
  annotation_name_gp = gpar(fontsize=6, fontfamily=NATURE_FONT),
  simple_anno_size = unit(2.5,"mm"),
  annotation_legend_param = list(
    Subtype=list(title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT), labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT)),
    Stage  =list(title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT), labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT))))

ht <- oncoPrint(mat, get_type = function(x) strsplit(x, ";")[[1]],
  alter_fun = alter_fun, col = vcol, top_annotation = top_anno,
  row_names_gp = gpar(fontsize=5.5, fontfamily=NATURE_FONT),
  pct_gp = gpar(fontsize=5, fontfamily=NATURE_FONT),
  column_title = "Mutation landscape (synthetic demo)",
  column_title_gp = gpar(fontsize=7, fontfamily=NATURE_FONT, fontface="bold"),
  heatmap_legend_param = list(title="Alteration",
    at=names(vcol), labels=names(vcol),
    title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT), labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT)))

save_heatmap(ht, file.path(out,"ref"), width_mm=150, height_mm=120)
cat("done:", file.path(out,"ref.png"), "\n")
