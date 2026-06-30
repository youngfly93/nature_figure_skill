#!/usr/bin/env Rscript
# Archetype: 富集通路网络（ggraph 二部图，cnetplot 风格）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggraph); library(tidygraph); library(igraph); library(ggplot2); library(dplyr)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/enrich-network"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

# ── Network layout requires seed for reproducibility ──────────────────────────
set.seed(21)

nw  <- synth_network()
g   <- igraph::graph_from_data_frame(nw$edges, directed=FALSE)
deg <- igraph::degree(g)                            # read ACTUAL degree from graph
padj <- setNames(nw$terms$p.adjust, nw$terms$name)

tg <- tidygraph::as_tbl_graph(g) |>
  tidygraph::activate(nodes) |>
  dplyr::mutate(
    type  = ifelse(name %in% nw$terms$name, "Pathway", "Gene"),
    deg   = deg[name],
    neglp = ifelse(type == "Pathway", -log10(padj[name]), NA_real_)
  )

# ── Build bipartite ggraph ────────────────────────────────────────────────────
# Pathway nodes: large, colored by -log10 p.adjust (nature_seq palette)
# Gene nodes:    small, grey
# Edges:         thin grey
p <- ggraph(tg, layout = "fr") +
  geom_edge_link(colour = "grey80", edge_width = 0.25, alpha = 0.6) +
  geom_node_point(
    aes(size   = ifelse(type == "Pathway", deg, 1.5),
        colour = neglp,
        shape  = type)
  ) +
  geom_node_text(
    aes(label  = ifelse(type == "Pathway", name, NA_character_)),
    size       = 2.2,
    fontface   = "bold",
    repel      = TRUE,
    family     = NATURE_FONT,
    max.overlaps = 20
  ) +
  scale_size_continuous(range = c(1.5, 8), name = "Gene count", guide = "none") +
  scale_shape_manual(values = c(Pathway = 16, Gene = 16), guide = "none") +
  scale_colour_gradientn(
    colours  = rev(nature_seq[-1]),
    na.value = "grey75",
    name     = expression(-log[10]~italic(p)[adj])
  ) +
  labs(title = "Pathway–gene enrichment network (synthetic demo)") +
  theme_void(base_family = NATURE_FONT) +
  theme(
    plot.title    = element_text(size = 8, face = "bold", hjust = 0.5),
    legend.title  = element_text(size = 6),
    legend.text   = element_text(size = 5),
    plot.background = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA)
  )

save_nature(p, file.path(out, "ref"), width_mm = 150, height_mm = 130)
cat("done:", file.path(out, "ref.png"), "\n")
