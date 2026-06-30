#!/usr/bin/env Rscript
# Archetype: chord 弦图（circlize）——类别间互作矩阵
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(circlize); library(ragg)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/chord-diagram"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

m <- synth_chord(n_cat=6, seed=24)
grid_col <- setNames(nature_pal_anno[seq_len(nrow(m))], rownames(m))

draw_chord <- function() {
  circos.clear()
  circos.par(gap.degree=3, start.degree=90)
  chordDiagram(m, grid.col=grid_col, transparency=0.35,
               annotationTrack=c("grid"), preAllocateTracks=1,
               directional=1, direction.type=c("diffHeight","arrows"),
               link.arr.type="big.arrow")
  circos.trackPlotRegion(track.index=1, panel.fun=function(x,y){
    circos.text(CELL_META$xcenter, CELL_META$ylim[1]+mm_y(3),
                CELL_META$sector.index, facing="clockwise", niceFacing=TRUE,
                adj=c(0,0.5), cex=0.5)
  }, bg.border=NA)
  circos.clear()
}

w <- 130/25.4; h <- 130/25.4
agg_png(file.path(out,"ref.png"), width=w, height=h, units="in", res=600, background="white")
draw_chord(); title(main="Cell–cell interaction chord (synthetic demo)", cex.main=0.8, font.main=2); dev.off()
cairo_pdf(file.path(out,"ref.pdf"), width=w, height=h, family="Helvetica")
draw_chord(); title(main="Cell–cell interaction chord (synthetic demo)", cex.main=0.8, font.main=2); dev.off()
unlink("Rplots.pdf")
cat("done:", file.path(out,"ref.png"), "\n")
