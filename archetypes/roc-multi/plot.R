#!/usr/bin/env Rscript
# Archetype: 多模型 ROC 曲线 + AUC（pROC，DeLong 95% CI）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(pROC)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/roc-multi"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d <- synth_roc(seed = 55)   # label + 三个模型分数
models <- c("Model A (genomic)","Model B (clinical)","Model C (single gene)")

roc_df <- do.call(rbind, lapply(models, function(m) {
  r  <- pROC::roc(d$label, d[[m]], quiet = TRUE, direction = "<")
  ci <- as.numeric(pROC::ci.auc(r))               # c(low, auc, high)
  data.frame(fpr = 1 - r$specificities, tpr = r$sensitivities,
             model = sprintf("%s — AUC %.2f (%.2f–%.2f)", m, ci[2], ci[1], ci[3]),
             stringsAsFactors = FALSE)
}))
roc_df <- roc_df[order(roc_df$model, roc_df$fpr, roc_df$tpr), ]   # geom_path 顺滑
roc_df$model <- factor(roc_df$model, levels = unique(roc_df$model))

cols <- ggsci::pal_npg("nrc")(length(models))
p <- ggplot(roc_df, aes(fpr, tpr, colour = model)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", linewidth = 0.25, colour = "grey60") +
  geom_path(linewidth = 0.7) +
  scale_colour_manual(values = cols, name = NULL) +
  coord_equal() +
  scale_x_continuous("False positive rate (1 - specificity)", expand = expansion(mult = c(0.01, 0.02))) +
  scale_y_continuous("True positive rate (sensitivity)", expand = expansion(mult = c(0.01, 0.02))) +
  labs(title = "Multi-model ROC comparison (synthetic demo)",
       caption = "Synthetic data, style demo only (not real results). set.seed(55); AUC with DeLong 95% CI (pROC).") +
  theme_nature() +
  theme(legend.position = "inside", legend.position.inside = c(0.98, 0.02),
        legend.justification = c(1, 0), legend.text = element_text(size = 5.6),
        legend.key.height = unit(9, "pt"),
        legend.background = element_rect(fill = scales::alpha("white", 0.7), colour = NA),
        plot.caption = element_text(size = 6, colour = "grey45", hjust = 0, family = NATURE_FONT))

save_nature(p, file.path(out,"ref"), width_mm = 110, height_mm = 110)
cat("done:", file.path(out,"ref.png"), "\n")
