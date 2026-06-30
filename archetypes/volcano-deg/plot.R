#!/usr/bin/env Rscript
# Archetype: 火山图 —— 默认风格 vs 应用参考原则（ggsci NPG + ggrepel + 去 chartjunk）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(ggrepel); library(ggsci); library(patchwork); library(scales)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/volcano-deg"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

df <- synth_deg(seed=42)
fc_th <- 1; p_th <- 0.05
n_up <- sum(df$sig=="Up"); n_dn <- sum(df$sig=="Down")

## A) 默认风格（典型未优化生信图）
pA <- ggplot(df, aes(logFC, y, colour=sig)) +
  geom_point(size=1.0) +
  labs(x="log2FC", y="-log10(adjP)", title="Default (unoptimized)", colour="sig") +
  theme_gray(base_size=8, base_family=NATURE_FONT)

## B) 应用参考原则：ggsci NPG + ggrepel + 去 chartjunk
npg <- ggsci::pal_npg("nrc")(9)
col <- c(Up=npg[1], Down=npg[4], ns="grey82")            # NPG 红/深蓝
lab <- rbind(utils::head(df[order(-df$logFC),][df$sig[order(-df$logFC)]=="Up",   ], 10),
             utils::head(df[order( df$logFC),][df$sig[order( df$logFC)]=="Down", ], 10))
pB <- ggplot(df, aes(logFC, y, colour=sig)) +
  geom_vline(xintercept=c(-fc_th,fc_th), linetype="dashed", linewidth=0.25, colour="grey60") +
  geom_hline(yintercept=-log10(p_th),    linetype="dashed", linewidth=0.25, colour="grey60") +
  geom_point(data=subset(df, sig=="ns"), size=0.5, alpha=0.35) +
  geom_point(data=subset(df, sig!="ns"), size=0.9, alpha=0.85) +
  scale_color_manual(values=col, breaks=c("Up","Down"),
                     labels=c(sprintf("Up (n=%d)",n_up), sprintf("Down (n=%d)",n_dn)), name=NULL) +
  ggrepel::geom_text_repel(data=lab, aes(label=gene), size=2.0, fontface="italic",
                           max.overlaps=30, segment.size=0.18, segment.colour="grey70",
                           min.segment.length=0, box.padding=0.25, force=1.5,
                           colour="grey15", show.legend=FALSE) +
  scale_x_continuous(expand=expansion(mult=c(0.02,0.02))) +
  labs(x=expression(log[2]~"fold change"), y=expression(-log[10]~adjusted~italic(P)),
       title="Reference principles applied", subtitle="ggsci NPG · ggrepel · de-chartjunk") +
  theme_nature() +
  theme(legend.position="inside", legend.position.inside=c(0.99,0.99),
        legend.justification=c(1,1),
        legend.background=element_rect(fill=scales::alpha("white",0.7), colour=NA))

fig <- pA + pB + plot_layout(ncol=2) +
  plot_annotation(tag_levels="A",
    caption="Synthetic data, style demo only (not real results). set.seed(42); FDR<0.05 & |log2FC|>=1.",
    theme=theme(plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT)))

save_nature(fig, file.path(out,"ref"), width_mm=183, height_mm=92)
cat("done:", file.path(out,"ref.png"), "\n")
