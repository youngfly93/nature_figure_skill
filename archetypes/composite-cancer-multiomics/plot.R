#!/usr/bin/env Rscript
# Archetype: 复合多面板叙事大图(癌症多组学)
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ComplexHeatmap); library(circlize); library(grid)
  library(ggplot2); library(survival); library(survminer); library(cowplot); library(scales)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/composite-cancer-multiomics"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d  <- synth_expr(n_genes=24, n_samples=48, seed=1)
sv <- synth_survival(d$col_anno, seed=3)
en <- synth_enrich(seed=4, n=8)
gn <- synth_genome(seed=5)

## a) 表达热图 -> grob
ht <- Heatmap(d$mat, name="Z-score", col=nature_heatmap_col(), show_column_names=FALSE,
  row_names_gp=gpar(fontsize=4.5,fontfamily=NATURE_FONT),
  column_dend_height=unit(4,"mm"), row_dend_width=unit(4,"mm"),
  heatmap_legend_param=list(title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT),
                            labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT)))
gA <- grid.grabExpr(draw(ht, merge_legend=TRUE))

## b) 生存曲线
fit <- survfit(Surv(time, status) ~ group, data=sv)
pal <- unname(nature_group_cols(levels(sv$group)))
gB <- ggsurvplot(fit, data=sv, palette=pal, conf.int=FALSE, censor.size=2,
                 legend.title="", legend="right",
                 legend.labs=levels(sv$group),
                 ggtheme=theme_nature(base_size=7))$plot +
      labs(x="Time (months)", y="Survival probability")

## c) 富集 dotplot
gC <- ggplot(en, aes(GeneRatio, Term)) +
  geom_point(aes(size=Count, color=p.adjust)) +
  scale_color_gradientn(colours=rev(nature_seq[-1]), trans="log10",
                        name=expression(italic(p)[adj])) +
  scale_size_continuous(range=c(1.5,5), name="Count") +
  labs(x="Gene ratio", y=NULL) + theme_nature(base_size=7)

## d) 基因组圈图 -> grob(base 图经 cowplot 捕获)
draw_circos <- function() {
  circos.clear()
  circos.par(gap.degree=2, cell.padding=c(0,0,0,0), track.margin=c(0.005,0.005))
  tr <- gn$track
  circos.initialize(factors=factor(tr$chr, levels=gn$chromosomes), x=tr$start)
  circos.track(factors=tr$chr, y=tr$cnv, track.height=0.18, bg.border=NA,
    panel.fun=function(x,y) circos.text(CELL_META$xcenter,
        CELL_META$cell.ylim[2]+mm_y(2), CELL_META$sector.index,
        cex=0.4, niceFacing=TRUE))
  for (cn in gn$chromosomes) { s <- tr[tr$chr==cn,]
    circos.lines(s$start, s$cnv, sector.index=cn, col=nature_seq[5], lwd=1) }
  lk <- gn$links
  for (i in seq_len(nrow(lk)))
    circos.link(lk$chr1[i], lk$pos1[i], lk$chr2[i], lk$pos2[i],
                col=alpha(nature_div[1], .4), lwd=0.8)
  circos.clear()
}

# Primary path: cowplot::as_grob captures base graphics function
gD <- tryCatch({
  as_grob(draw_circos)
}, error = function(e) {
  message("as_grob failed: ", conditionMessage(e))
  message("Trying ggplotify::as.grob fallback...")
  tryCatch({
    ggplotify::as.grob(draw_circos)
  }, error = function(e2) {
    message("ggplotify failed: ", conditionMessage(e2))
    message("Using magick/temp-PNG fallback...")
    tmp <- tempfile(fileext=".png")
    ragg::agg_png(tmp, width=6, height=6, units="in", res=150, bg="white")
    draw_circos()
    dev.off()
    img <- magick::image_read(tmp)
    cowplot::ggdraw() + cowplot::draw_image(img)
  })
})

fig <- plot_grid(gA, gB, gC, gD, labels=c("a","b","c","d"),
  label_fontface="bold", label_size=9, label_fontfamily=NATURE_FONT,
  ncol=2, rel_heights=c(1,0.95)) +
  theme(plot.background=element_rect(fill="white", colour=NA),
        panel.background=element_rect(fill="white", colour=NA))

ggsave(file.path(out,"ref.png"), fig, width=183, height=160, units="mm",
       dpi=300, device=ragg::agg_png, bg="white")
ggsave(file.path(out,"ref.pdf"), fig, width=183, height=160, units="mm",
       device=cairo_pdf, bg="white")
cat("done:", file.path(out,"ref.png"), "\n")
unlink("Rplots.pdf")
