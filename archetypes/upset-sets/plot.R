#!/usr/bin/env Rscript
# Archetype: UpSet 集合交集（UpSetR）——多组学/多比较的集合 overlap
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(UpSetR); library(ragg); library(grid)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/upset-sets"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

sets <- synth_sets(seed=23)
mat  <- UpSetR::fromList(sets)

draw_upset <- function()
  print(UpSetR::upset(mat, nsets=length(sets), order.by="freq",
                      main.bar.color=nature_seq[5], sets.bar.color=nature_pal_anno[1],
                      matrix.color=nature_div[1], shade.color="grey85",
                      text.scale=c(1.1,1.0,1.0,0.9,1.0,0.9),
                      mainbar.y.label="Intersection size", sets.x.label="Set size"))

w <- 160/25.4; h <- 110/25.4
agg_png(file.path(out,"ref.png"), width=w, height=h, units="in", res=600, background="white")
draw_upset(); dev.off()
cairo_pdf(file.path(out,"ref.pdf"), width=w, height=h, family="Helvetica")
draw_upset(); dev.off()
unlink("Rplots.pdf")
cat("done:", file.path(out,"ref.png"), "\n")
