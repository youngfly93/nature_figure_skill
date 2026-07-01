#!/usr/bin/env Rscript
# Archetype: SBS-96 突变 signature（COSMIC 6 替换型 × 16 三核苷酸上下文，官方色码）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/mut-signature"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

sig <- synth_sbs96(seed = 53)   # 96 行：substitution / context / tri / fraction

# COSMIC 官方 6 色（领域约定：读者靠色码认替换型，覆盖 house「≤3 色」通则——见 card.md）
sbs_cols <- c("C>A"="#02BCED","C>G"="#010101","C>T"="#E32926",
              "T>A"="#CBCACB","T>C"="#A1CE63","T>G"="#EDC8C4")
lab <- setNames(sig$tri, as.character(sig$context))   # x 轴只显三核苷酸，靠 strip 标替换型

p <- ggplot(sig, aes(context, fraction, fill = substitution)) +
  geom_col(width = 0.7) +
  facet_grid(~ substitution, scales = "free_x", space = "free_x") +
  scale_fill_manual(values = sbs_cols, guide = "none") +
  scale_x_discrete(labels = lab) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  labs(x = NULL, y = "Mutation fraction",
       title = "Single base substitution signature (SBS-96, synthetic demo)",
       caption = "Synthetic data, style demo only (not real results). set.seed(53); COSMIC 96-channel order & colour code.") +
  theme_nature() +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 2.4,
                                   family = "mono", colour = "grey35"),
        panel.spacing = unit(1.2, "pt"),
        strip.text = element_text(size = 7, face = "bold", colour = "white"),
        strip.background = element_rect(fill = "grey30", colour = NA),
        plot.caption = element_text(size = 6, colour = "grey45", hjust = 0, family = NATURE_FONT))

save_nature(p, file.path(out,"ref"), width_mm = 183, height_mm = 68)
cat("done:", file.path(out,"ref.png"), "\n")
