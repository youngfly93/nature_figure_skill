#!/usr/bin/env Rscript
# Archetype: 进化树 + 热图联排 (ggtree::gheatmap)
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggtree); library(ggplot2)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/phylo-tree-heatmap"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

# ggplot2-4.0 / ggtree-3.14 compatibility shim:
# ggtree's empty() calls is.waive() which was removed in ggplot2-4.0; patch it.
local({
  ns <- loadNamespace("ggtree")
  unlockBinding("empty", ns)
  assign("empty",
    function(df) is.null(df) || nrow(df) == 0L || ncol(df) == 0L || inherits(df, "waiver"),
    envir = ns)
  lockBinding("empty", ns)
})

d <- synth_tree(n_tip=24, n_feat=6, seed=8)
grp_df <- data.frame(label=d$tree$tip.label, Clade=d$group)
gcol <- setNames(nature_pal_anno[1:nlevels(d$group)], levels(d$group))

p <- ggtree(d$tree, linewidth=0.4) %<+% grp_df +
  geom_tippoint(aes(color=Clade), size=1.1) +
  geom_tiplab(size=1.6, family=NATURE_FONT, align=TRUE, linesize=0.15) +
  scale_color_manual(values=gcol, name="Clade") +
  theme_tree2(base_family=NATURE_FONT) +
  theme(legend.position="left", legend.title=element_text(size=6),
        legend.text=element_text(size=5))

# Save before gheatmap: ggplot2-4.0 / ggtree-3.14 compat fix — gheatmap stores
# a data.frame in attr(,'mapping'), conflicting with the S7 @mapping slot.
# Restore the original ggplot2::mapping object after the call.
orig_mapping <- p$mapping

ph <- gheatmap(p, as.data.frame(d$mat), offset=0.6, width=0.6,
               colnames_position="top", font.size=1.8,
               colnames_angle=90, hjust=0)
attr(ph, "mapping") <- orig_mapping

ph <- ph +
  scale_fill_gradientn(colours=rev(nature_div), name="Row z",
                       guide=guide_colorbar(barwidth=0.4, barheight=3)) +
  # coord_cartesian(clip="off"): allow column label text to draw above the panel top edge.
  coord_cartesian(clip="off") +
  theme(legend.title=element_text(size=6), legend.text=element_text(size=5),
        plot.margin=margin(t=18, r=4, b=4, l=4, unit="mm"))

save_nature(ph, file.path(out,"ref"), width_mm=150, height_mm=130)
cat("done:", file.path(out,"ref.png"), "\n")
