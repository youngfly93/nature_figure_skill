#!/usr/bin/env Rscript
# Archetype: Composite multi-panel narrative figure (molecular subtyping story)
# Hero layout — A heatmap (hero, spans left) + B PCA + C enrichment + D KM (stacked right)
# All panels via nature_theme house functions; patchwork hero design.
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])),
                   "..", "_lib", "figure_setup.R"))
  library(ComplexHeatmap); library(grid); library(ggplot2); library(patchwork)
  library(survival)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here == "") here <- "archetypes/composite-cancer-multiomics"
source(file.path(here, "..", "_lib", "synth_data.R"))
out <- file.path(here, "out"); dir.create(out, showWarnings = FALSE, recursive = TRUE)

## ---- data ---------------------------------------------------------------
d   <- synth_expr(n_genes = 40, n_samples = 80, seed = 1)
grp <- d$col_anno$Subtype                          # Basal / LumA / LumB
sv  <- synth_survival(d$col_anno, seed = 3)        # time, status, group
en  <- synth_enrich(seed = 4, n = 10)              # Term, Count, GeneRatio, p.adjust

## ---- subtype colours (shared across panels) -----------------------------
sv_levs  <- levels(droplevels(grp))
sub_cols <- nature_group_cols(sv_levs)             # auto from nature_pal_6

## ===== Panel A : heatmap hero (ComplexHeatmap -> grob -> patchwork) ======
ha <- nature_hm_anno(
  Subtype = d$col_anno$Subtype,
  Stage   = d$col_anno$Stage,
  Tissue  = d$col_anno$Tissue)

ht <- nature_heatmap(
  d$mat, name = "Z-score",
  top_annotation    = ha,
  column_split      = grp,
  show_column_names = FALSE,
  column_title_gp   = nature_hm_gp(7, "bold"),
  row_names_gp      = nature_hm_gp(4.4))

ht_grob <- grid::grid.grabExpr(
  ComplexHeatmap::draw(ht,
    heatmap_legend_side    = "right",
    annotation_legend_side = "bottom",
    merge_legend = FALSE,
    padding = unit(c(2, 8, 2, 6), "mm")),
  width  = unit(95, "mm"),
  height = unit(150, "mm"))
gA <- patchwork::wrap_elements(full = ht_grob)

## ===== Panel B : PCA subtype separation ==================================
pca    <- prcomp(t(d$mat))
ve     <- 100 * pca$sdev^2 / sum(pca$sdev^2)
pca_df <- data.frame(PC1 = pca$x[, 1], PC2 = pca$x[, 2], group = grp)
gB <- nature_pca(pca_df, group = "group", cols = sub_cols,
                 var_explained = c(PC1 = ve[1], PC2 = ve[2]),
                 title = "Subtype separation (PCA)")

## ===== Panel C : pathway enrichment dotplot ==============================
# synth_enrich columns: Term / Count / GeneRatio / p.adjust
# nature_enrich_dot auto-detects GeneRatio->score, p.adjust->p, Count->count
# term column is "Term" (not default "Description") — pass explicitly
gC <- nature_enrich_dot(en, term = "Term", top_n = 10,
                        title = "Pathway enrichment")

## ===== Panel D : KM survival curve ======================================
# nature_km with risk_table=FALSE returns a ggplot directly
gD <- nature_km(sv, time = "time", status = "status", group = "group",
                cols = sub_cols,
                risk_table = FALSE, show_cox_p = FALSE,
                title = "Overall survival (OS)",
                time_lab = "Time (months)",
                surv_lab = "Survival probability")

## ===== Assemble : patchwork hero layout ==================================
# A spans the left column across all 3 rows; B/C/D stack on the right
fig <- gA + gB + gC + gD +
  plot_layout(design = "AB\nAC\nAD", widths = c(1.25, 1)) +
  plot_annotation(
    tag_levels = "A",
    title   = "Molecular subtyping integrative figure (synthetic demo)",
    caption = paste0("Synthetic data — style demo only (not real results). ",
                     "set.seed(1/3/4); n=80 samples; 3 subtypes (Basal/LumA/LumB). ",
                     "PCA separation does not imply causation; ",
                     "KM differences require confounder adjustment; ",
                     "enrichment p-values are FDR-corrected."),
    theme = theme(
      plot.title   = element_text(size = 10, face = "bold",  family = NATURE_FONT),
      plot.caption = element_text(size = 5.5, colour = "grey45",
                                  hjust = 0, family = NATURE_FONT)))

## ===== Export : PNG + PDF + SVG ==========================================
save_all <- function(p, base, w_mm = 183, h_mm = 178, dpi = 300) {
  w <- w_mm / 25.4; h <- h_mm / 25.4
  ragg::agg_png(paste0(base, ".png"), width = w, height = h,
                units = "in", res = dpi, bg = "white")
  print(p); dev.off()
  grDevices::cairo_pdf(paste0(base, ".pdf"), width = w, height = h,
                       family = NATURE_FONT, bg = "white")
  print(p); dev.off()
  if (requireNamespace("svglite", quietly = TRUE)) {
    svglite::svglite(paste0(base, ".svg"), width = w, height = h, bg = "white")
    print(p); dev.off()
  }
  invisible(base)
}

save_all(fig, file.path(out, "ref"))
unlink("Rplots.pdf")
cat("done:", file.path(out, "ref.png"), "\n")
