#!/usr/bin/env Rscript
# Archetype: 单细胞拟时序轨迹（slingshot，Path B）
#
# 工具选择说明：
#   monocle3 因依赖系统库 GDAL/GEOS（terra/spdep 传递依赖）无法在当前机器安装，
#   故改用 slingshot（已装，mainstream Bioconductor 包），实现相同的 UMAP 着色 + 轨迹曲线。
#   slingshot 在合成线性结构数据上拟合稳定，无额外系统库依赖。
#
# 输出：archetypes/sc-trajectory/out/ref.{png,pdf}
#   • 点云：ggrastr::rasterise(geom_point(...), dpi=300)（2000 细胞，硬约束）
#   • 轨迹曲线：geom_path（矢量，不栅格化）
#   • 着色：连续 pseudotime，用 nature_seq（唯一真源，来自 figure_setup.R）
#   • 坐标：coord_fixed()；文字英文；白底
suppressPackageStartupMessages({
  here_self <- local({
    ofile <- NA_character_
    for (i in seq_len(sys.nframe())) {
      f <- tryCatch(sys.frame(i)$ofile, error = function(e) NULL)
      if (!is.null(f) && length(f) == 1 && !is.na(f) && nzchar(f)) {
        ofile <- normalizePath(f); break
      }
    }
    # fallback: --file= arg
    if (is.na(ofile)) {
      farg <- grep("--file=", commandArgs(FALSE), value = TRUE)
      if (length(farg)) ofile <- normalizePath(sub("--file=", "", farg[1]))
    }
    if (is.na(ofile)) ofile <- "archetypes/sc-trajectory/plot.R"
    dirname(ofile)
  })
  source(file.path(here_self, "..", "_lib", "figure_setup.R"))
  library(slingshot)
  library(ggplot2)
  library(ggrastr)
})

here <- here_self
source(file.path(here, "..", "_lib", "synth_data.R"))
out <- file.path(here, "out"); dir.create(out, showWarnings = FALSE, recursive = TRUE)

# ------------------------------------------------------------------
# 1. 生成合成单细胞数据
# ------------------------------------------------------------------
s    <- synth_scrna(n_cells = 2000, n_types = 6, n_markers = 4, seed = 11)
emb  <- s$emb   # columns: UMAP1, UMAP2, celltype, cluster (factor "1".."6")

# ------------------------------------------------------------------
# 2. 确定 slingshot 起点簇
#    root = 潜在连续变量 s$lineage 最小值对应的细胞所属簇
# ------------------------------------------------------------------
root_clus <- as.character(emb$cluster[which.min(s$lineage)])
cat("slingshot root cluster:", root_clus, "\n")

# ------------------------------------------------------------------
# 3. 拟合 slingshot 拟时序
# ------------------------------------------------------------------
umap_mat <- as.matrix(emb[, c("UMAP1", "UMAP2")])
sds <- slingshot(umap_mat,
                 clusterLabels = emb$cluster,
                 start.clus    = root_clus)

# 第一条谱系的 pseudotime（所有细胞）
pt <- slingPseudotime(sds)[, 1]
cat("pseudotime range:", round(min(pt, na.rm=TRUE),2), "–",
    round(max(pt, na.rm=TRUE),2), "\n")

# 轨迹曲线（有序曲线坐标）
crv_obj <- slingCurves(sds)[[1]]
crv_df  <- as.data.frame(crv_obj$s[crv_obj$ord, ])
colnames(crv_df) <- c("UMAP1", "UMAP2")

# ------------------------------------------------------------------
# 4. 绘图
# ------------------------------------------------------------------
d <- data.frame(emb, pt = pt)

p <- ggplot(d, aes(UMAP1, UMAP2)) +
  # 点云：栅格化（2000 细胞，硬约束）
  ggrastr::rasterise(
    geom_point(aes(colour = pt), size = 0.4, na.rm = TRUE),
    dpi = 300
  ) +
  # 轨迹曲线：矢量路径（不栅格化）
  geom_path(data = crv_df, aes(UMAP1, UMAP2),
            linewidth = 0.7, colour = "black", lineend = "round") +
  # 配色：nature_seq（唯一真源）
  scale_colour_gradientn(
    colours = nature_seq[-1],   # 去掉第一个白色，让低端有淡蓝
    name    = "pseudotime",
    na.value = "grey80"
  ) +
  coord_fixed() +
  labs(
    title   = "Pseudotime trajectory (slingshot, synthetic demo)",
    caption = "Synthetic scRNA-seq, style demo only (not real results). set.seed(11); n=2000 cells."
  ) +
  theme_nature() +
  theme(
    axis.text  = element_blank(),
    axis.ticks = element_blank(),
    plot.caption = element_text(size = 6, colour = "grey45", hjust = 0, family = NATURE_FONT)
  )

# ------------------------------------------------------------------
# 5. 导出
# ------------------------------------------------------------------
save_nature(p, file.path(out, "ref"), width_mm = 120, height_mm = 110)
cat("done:", file.path(out, "ref.png"), "\n")
