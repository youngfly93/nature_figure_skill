#!/usr/bin/env Rscript
# Archetype: 独立基因组圈图 (circlize) —— 多轨道 + 连线
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(circlize); library(ragg)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/genome-circos"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

gn <- synth_genome(seed=5, n_chr=12, per=60)
tr <- gn$track

draw_circos <- function() {
  circos.clear()
  circos.par(gap.degree=2, cell.padding=c(0,0,0,0), track.margin=c(0.004,0.004),
             start.degree=90)
  circos.initialize(factors=factor(tr$chr, levels=gn$chromosomes), x=tr$start)
  # 轨1：扇区标签 + 外圈刻度块
  circos.track(factors=tr$chr, ylim=c(0,1), track.height=0.06, bg.border=NA,
    panel.fun=function(x,y){
      circos.rect(CELL_META$cell.xlim[1], 0, CELL_META$cell.xlim[2], 1,
                  col=nature_seq[4], border=NA)
      circos.text(CELL_META$xcenter, 1.8, CELL_META$sector.index,
                  cex=0.5, niceFacing=TRUE, facing="bending.inside")})
  # 轨2：CNV 线
  cnv_range <- range(tr$cnv)
  circos.track(factors=tr$chr, x=tr$start, y=tr$cnv, ylim=cnv_range, track.height=0.20, bg.border=NA,
    panel.fun=function(x,y){
      circos.lines(c(CELL_META$cell.xlim[1],CELL_META$cell.xlim[2]), c(0,0),
                   col="#CCCCCC", lwd=0.5)
      circos.lines(x, y, col=nature_div[7], lwd=1, area=FALSE)})
  # 轨3：表达点
  circos.track(factors=tr$chr, x=tr$start, y=tr$expr, track.height=0.16, bg.border=NA,
    panel.fun=function(x,y) circos.points(x, y, pch=16, cex=0.18,
                                          col=scales::alpha(nature_div[1], .5)))
  # 中心连线
  lk <- gn$links
  for (i in seq_len(nrow(lk)))
    circos.link(lk$chr1[i], lk$pos1[i], lk$chr2[i], lk$pos2[i],
                col=scales::alpha(nature_div[2], .35), lwd=0.9)
  circos.clear()
}

w <- 150/25.4; h <- 150/25.4
agg_png(file.path(out,"ref.png"), width=w, height=h, units="in", res=600, background="white")
draw_circos(); title(main="Genome-wide circos: CNV + expression + interchromosomal links",
                     cex.main=0.8, font.main=2); dev.off()
cairo_pdf(file.path(out,"ref.pdf"), width=w, height=h, family="Helvetica")
draw_circos(); title(main="Genome-wide circos: CNV + expression + interchromosomal links",
                     cex.main=0.8, font.main=2); dev.off()
unlink("Rplots.pdf")
cat("done:", file.path(out,"ref.png"), "\n")
