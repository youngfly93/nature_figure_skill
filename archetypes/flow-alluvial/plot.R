#!/usr/bin/env Rscript
# Archetype: Sankey/alluvial 流向图（ggalluvial）
# Three-stage flow: Tissue -> Subtype -> Response
# House style: figure_setup.R (Helvetica + theme_nature + save_nature + nature_pal_anno)
suppressPackageStartupMessages({
  # Resolve script directory robustly (works inside suppressPackageStartupMessages)
  .plot_file <- local({
    f <- grep("--file=", commandArgs(FALSE), value = TRUE)
    if (length(f)) normalizePath(sub("--file=", "", f[1])) else NA_character_
  })
  source(file.path(
    if (!is.na(.plot_file)) dirname(.plot_file) else "archetypes/flow-alluvial",
    "..", "_lib", "figure_setup.R"
  ))
  library(ggplot2)
  library(ggalluvial)
})

here <- if (!is.na(.plot_file)) dirname(.plot_file) else "archetypes/flow-alluvial"
source(file.path(here, "..", "_lib", "synth_data.R"))
out <- file.path(here, "out")
dir.create(out, showWarnings = FALSE, recursive = TRUE)

# ── Data ────────────────────────────────────────────────────────────────────
df  <- synth_flow(n = 300, seed = 22)
agg <- as.data.frame(table(df))            # Tissue, Subtype, Response, Freq
agg <- agg[agg$Freq > 0, ]

sub_lv <- levels(df$Subtype)              # C1, C2, C3, Normal
cols   <- setNames(nature_pal_anno[seq_along(sub_lv)], sub_lv)

# ── Plot ─────────────────────────────────────────────────────────────────────
p <- ggplot(agg,
            aes(axis1 = Tissue, axis2 = Subtype, axis3 = Response, y = Freq)) +
  geom_alluvium(aes(fill = Subtype), alpha = 0.7, width = 0.32) +
  geom_stratum(width = 0.32, fill = "grey92", colour = "grey55", linewidth = 0.3) +
  geom_text(stat = "stratum",
            aes(label = after_stat(stratum)),
            size = 2, family = NATURE_FONT) +
  scale_x_discrete(limits  = c("Tissue", "Subtype", "Response"),
                   expand  = c(0.05, 0.05)) +
  scale_fill_manual(values = cols, name = "Subtype") +
  labs(
    y       = "Samples",
    title   = "Sample flow: tissue → subtype → treatment response",
    caption = paste(
      "Synthetic demo (n = 300, seed = 22). Flow width = sample count; does NOT imply probability or causality.",
      "Stage order is author-defined (Tissue → Subtype → Response) — reordering axes would alter visual narrative.",
      "Small flows may carry clinical relevance despite low n; inspect absolute counts before interpretation.",
      sep = " "
    )
  ) +
  theme_nature() +
  theme(axis.title.x = element_blank(),
        plot.caption = element_text(hjust = 0, size = 5.5))

# ── Export ───────────────────────────────────────────────────────────────────
save_nature(p, file.path(out, "ref"), width_mm = 150, height_mm = 110)
cat("done:", file.path(out, "ref.png"), "\n")
