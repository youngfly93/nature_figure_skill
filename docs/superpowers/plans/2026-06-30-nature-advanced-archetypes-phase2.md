# Nature 高级图型 archetype 库 — Phase 2（单细胞 / 空间）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development。Steps use checkbox (`- [ ]`).

**Goal:** 新增四个单细胞/空间组学 archetype（UMAP atlas、marker dotplot、拟时序、空间 feature 叠图），全部走 ggplot-从-embedding（theme 驱动、ggrastr 栅格化大点云、不依赖 scCustomize），拟时序用 monocle3（slingshot 兜底）；每张卡片含分析严谨翻车点。

**Architecture:** 沿用"五件套 + QA 门禁"。合成单细胞/空间数据进 `_lib/synth_data.R`（工具中立：出 UMAP 坐标 + cluster/celltype + marker 表达 + 计数矩阵，monocle3/slingshot 都能吃）。绘图优先 ggplot2 + theme_nature；大点云用 `ggrastr::geom_point_rast` 或 `scattermore` 防 PDF 膨胀。

**Tech Stack:** R 4.4.3 · ggplot2 · ggrastr/scattermore · patchwork · viridisLite · **slingshot（拟时序——已定）** · SingleCellExperiment。

> **拟时序工具决策（2026-06-30，已定）**：monocle3 因依赖 terra/spdep 需系统 GDAL/GEOS（本机 conda-R 环境缺、装不上）而**安装失败**；用户决定用 **slingshot**（已装、主流、Bioconductor）。Task 4 直接走 slingshot 路径（路径 B），不再尝试 monocle3。

## Global Constraints

- 配色/主题/字体唯一真源：plot.R 顶部 source `_lib/figure_setup.R`；**不改 nature_theme.R**；连续量优先 theme `nature_seq`/viridis，离散 celltype 优先 `nature_pal_anno`/ggsci（局部）。
- 大点云（>1000 点）必须栅格化（`ggrastr::geom_point_rast` 或 `scattermore::geom_scattermore`），否则 PDF/SVG 巨大。
- 脚本真跑、出真图；参考图来自真跑，绝不编造/占位；合成数据设种子可复现。
- 图内文字英文；中文只在 card.md（用 Write 写，防乱码）。
- 每张 archetype 卡片含**渲染 + 分析严谨**双重翻车点。
- 拟时序：monocle3 为主（若安装成功）；**若 monocle3 不可用，用 slingshot 兜底**（Task 4 含两条路径，执行时按 `requireNamespace("monocle3")` 选择，不降级删面板）。
- 导出多格式；`coord_fixed()` 用于 UMAP/空间保持纵横比。

## 文件结构

```
archetypes/
├── _lib/synth_data.R                  # 改：+ synth_scrna() + synth_spatial()
├── sc-umap-atlas/                      # 新 ⑦
├── sc-marker-dotplot/                  # 新 ⑧
├── sc-trajectory/                      # 新 ⑨（monocle3 / slingshot）
├── spatial-feature/                    # 新 ⑩
│   （各 plot.R · card.md · out/ref.{png,pdf}）
skill-integration/advanced-archetypes.md  # 改：4 条新条目 + 阶梯 UMAP/空间 ✅就绪
docs/superpowers/plans/ROADMAP.md          # 改：勾掉 Phase 2
```

---

### Task 1: 合成单细胞 + 空间数据生成器

**Files:** Modify `archetypes/_lib/synth_data.R`（末尾追加）

**Interfaces:**
- `synth_scrna(n_cells=2000, n_types=6, n_markers=4, seed=11)` → `list(emb=data.frame(UMAP1,UMAP2,celltype(factor),cluster(factor)), expr=矩阵 (n_types*n_markers 个 marker 基因 × n_cells，已 0..~ 表达量), markers=data.frame(gene,celltype), counts=整数计数矩阵 同 expr 维度, lineage=每细胞一个连续潜变量(给拟时序根/排序参考))`。每个 celltype 在 UMAP 上形成一簇，其 marker 基因在该 celltype 高表达。
- `synth_spatial(n_spots=1500, seed=12)` → `data.frame(x, y, celltype(factor), feature(连续，空间平滑))`。celltype 形成空间域，feature 有空间梯度。

- [ ] **Step 1: 追加两个生成器**

```r
# —— Phase 2 追加：单细胞 + 空间 ——
synth_scrna <- function(n_cells = 2000, n_types = 6, n_markers = 4, seed = 11) {
  set.seed(seed)
  types <- paste0("CellType", seq_len(n_types))
  ct <- factor(sample(types, n_cells, TRUE), levels = types)
  # 每个 celltype 一个 UMAP 簇中心
  ctr <- matrix(runif(n_types * 2, -8, 8), n_types, 2, dimnames = list(types, c("U1","U2")))
  emb <- data.frame(
    UMAP1 = ctr[ct, 1] + rnorm(n_cells, 0, 1.1),
    UMAP2 = ctr[ct, 2] + rnorm(n_cells, 0, 1.1),
    celltype = ct,
    cluster  = factor(as.integer(ct)))
  # marker 基因：每 celltype n_markers 个，在该型高表达
  genes <- paste0("M", sprintf("%02d", seq_len(n_types * n_markers)))
  gmap  <- data.frame(gene = genes,
                      celltype = factor(rep(types, each = n_markers), levels = types))
  base <- matrix(rpois(length(genes) * n_cells, 0.4), length(genes), n_cells,
                 dimnames = list(genes, NULL))
  for (i in seq_along(genes)) {
    hit <- ct == gmap$celltype[i]
    base[i, hit] <- base[i, hit] + rpois(sum(hit), 6)
  }
  expr <- log1p(base)                                  # 表达量（log1p 计数）
  lineage <- as.integer(ct) + rnorm(n_cells, 0, 0.3)   # 连续潜变量（拟时序参考）
  list(emb = emb, expr = expr, markers = gmap, counts = base, lineage = lineage)
}

synth_spatial <- function(n_spots = 1500, seed = 12) {
  set.seed(seed)
  side <- ceiling(sqrt(n_spots))
  g <- expand.grid(x = seq_len(side), y = seq_len(side))[seq_len(n_spots), ]
  # 空间域：按 x 分三带 + 噪声
  dom <- cut(g$x + rnorm(n_spots, 0, 1.2), breaks = 3, labels = c("Domain1","Domain2","Domain3"))
  feature <- sin(g$x / side * pi) * 2 + g$y / side + rnorm(n_spots, 0, 0.25)  # 空间梯度
  data.frame(x = g$x, y = g$y, celltype = factor(dom), feature = feature)
}
```

- [ ] **Step 2: 验证形状**

Run:
```bash
Rscript -e 'source("archetypes/_lib/synth_data.R"); s<-synth_scrna(); stopifnot(nrow(s$emb)==2000, ncol(s$expr)==2000, nrow(s$markers)==24); sp<-synth_spatial(); stopifnot(nrow(sp)==1500, all(c("x","y","celltype","feature") %in% names(sp))); cat("synth phase2 OK\n")'
```
Expected: `synth phase2 OK`

- [ ] **Step 3: 提交**

```bash
git add archetypes/_lib/synth_data.R
git commit -m "feat(synth): 追加 synth_scrna + synth_spatial（Phase 2 单细胞/空间）"
```

---

### Task 2: Archetype ⑦ — UMAP atlas（聚类 + marker 分面）

**Files:** Create `archetypes/sc-umap-atlas/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_scrna()`；`figure_setup.R`；ggplot2/ggrastr/patchwork。多面板：A UMAP by celltype（直接标签）+ B-E 4 个 marker 的 feature plot（表达着色）。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: 单细胞 UMAP atlas（聚类着色 + marker feature 分面）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(ggrastr); library(patchwork); library(viridisLite)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/sc-umap-atlas"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

s <- synth_scrna(n_cells=2000, n_types=6, n_markers=4, seed=11)
emb <- s$emb
cols <- setNames(nature_pal_anno[seq_len(nlevels(emb$celltype))], levels(emb$celltype))
# 簇中心（放直接标签）
cen <- aggregate(cbind(UMAP1,UMAP2)~celltype, emb, median)

pMain <- ggplot(emb, aes(UMAP1, UMAP2, colour=celltype)) +
  ggrastr::rasterise(geom_point(size=0.35, alpha=0.8), dpi=300) +
  geom_text(data=cen, aes(label=celltype), colour="black", size=2.2, fontface="bold") +
  scale_colour_manual(values=cols, guide="none") +
  coord_fixed() + labs(title="Cell-type atlas (UMAP)") + theme_nature() +
  theme(axis.text=element_blank(), axis.ticks=element_blank())

# 4 个 marker feature plot
mk <- s$markers$gene[match(levels(emb$celltype), s$markers$celltype)][1:4]
feat_panel <- function(g) {
  d <- emb; d$expr <- s$expr[g, ]
  ggplot(d, aes(UMAP1, UMAP2, colour=expr)) +
    ggrastr::rasterise(geom_point(size=0.3), dpi=300) +
    scale_colour_gradientn(colours=c("grey88", nature_seq[4], nature_div[1]), name="expr") +
    coord_fixed() + labs(title=g) + theme_nature(base_size=6) +
    theme(axis.text=element_blank(), axis.ticks=element_blank(), axis.title=element_blank(),
          legend.key.width=unit(2,"mm"), legend.key.height=unit(4,"mm"))
}
feats <- lapply(mk, feat_panel)

fig <- pMain + (feats[[1]]+feats[[2]]+feats[[3]]+feats[[4]] + plot_layout(ncol=2)) +
  plot_layout(widths=c(1.3,1)) +
  plot_annotation(tag_levels="A",
    caption="Synthetic scRNA-seq, style demo only (not real results). set.seed(11); n=2000 cells.",
    theme=theme(plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT)))

save_nature(fig, file.path(out,"ref"), width_mm=183, height_mm=110)
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2-3: 跑 + QA**

Run: `Rscript archetypes/sc-umap-atlas/plot.R` → `done:`；`Rscript tools/qa_check.R archetypes/sc-umap-atlas/out/ref.png 1800` → `QA PASS`。

- [ ] **Step 4: 写 card.md（渲染 + 分析双重翻车点）**

```markdown
# 单细胞 UMAP atlas（聚类 + marker 分面）

- **何时用**：scRNA/snRNA 降维后，一图展示细胞类型图谱 + 关键 marker 的表达分布。单细胞 Main Figure 标配。
- **数据形状**：embedding 坐标(UMAP1/2) + celltype/cluster + marker 基因 × 细胞表达矩阵。
- **核心依赖**：ggplot2、ggrastr（栅格化大点云）、patchwork、figure_setup.R。
- **配色规则**：celltype 离散用 nature_pal_anno；表达连续用 grey→蓝→红 渐变（取自 theme）。
- **常见翻车点（渲染）**：① 上千点不栅格化 → PDF/SVG 巨大、卡死 → `ggrastr::rasterise(...)`；② UMAP 不 `coord_fixed()` → 簇形变形；③ 用图例认 celltype → 改直接标签(簇中心 geom_text)，省眼动；④ feature plot 表达 0 用亮色 → 0 用灰、高表达才上色。
- **常见翻车点（分析严谨）**：⑤ **UMAP 距离不可定量解读**——簇间距离/密度是非线性嵌入产物，别说"A 比 B 更接近 C"；⑥ **marker 表达受测序深度/dropout 影响**，"未检出"≠"不表达"，应说明是否做了归一化/imputation；⑦ **聚类数依赖分辨率参数**，celltype 标注需 marker 证据支撑，别把算法簇直接当生物学类型。
- **参考实现**：`archetypes/sc-umap-atlas/`
```

- [ ] **Step 5: 提交**

```bash
git add archetypes/sc-umap-atlas
git commit -m "feat(archetype): 单细胞 UMAP atlas + 真参考图(QA 通过)"
```

---

### Task 3: Archetype ⑧ — marker dotplot

**Files:** Create `archetypes/sc-marker-dotplot/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_scrna()`；ggplot2。dotplot：marker 基因 × celltype，点大小=表达比例(%)，颜色=按基因 scale 的平均表达。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: 单细胞 marker dotplot（基因×细胞类型；点大小=表达比例，色=平均表达 z）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/sc-marker-dotplot"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

s <- synth_scrna(seed=11); expr <- s$expr; ct <- s$emb$celltype
genes <- s$markers$gene
# 每 (gene, celltype): pct 表达(>0) + 平均表达
agg <- do.call(rbind, lapply(genes, function(g) {
  v <- expr[g, ]
  data.frame(gene=g, celltype=levels(ct),
             pct = tapply(v>0, ct, mean)*100,
             mean= tapply(v, ct, mean))
}))
# 按基因把平均表达 z-score（跨 celltype），更能显特异性
agg$z <- ave(agg$mean, agg$gene, FUN=function(x) as.numeric(scale(x)))
agg$gene <- factor(agg$gene, levels=rev(genes))
agg$celltype <- factor(agg$celltype, levels=levels(ct))

p <- ggplot(agg, aes(celltype, gene)) +
  geom_point(aes(size=pct, colour=z)) +
  scale_size_continuous(range=c(0.2,4.2), name="% expr") +
  scale_colour_gradientn(colours=rev(nature_div), name="mean expr (z)") +
  labs(x=NULL, y=NULL, title="Marker expression dotplot (synthetic demo)") +
  theme_nature() +
  theme(axis.text.x=element_text(angle=45, hjust=1),
        axis.text.y=element_text(size=4.5),
        panel.grid.major=element_line(linewidth=0.15, colour="grey92"))

save_nature(p, file.path(out,"ref"), width_mm=120, height_mm=150)
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2-3: 跑 + QA**（minwidth 1200）。

- [ ] **Step 4: card.md**（渲染翻车点：点大小/颜色双编码别冗余、按基因 z-score 才显特异、celltype 顺序；分析翻车点：⑤ pct 与 mean 双指标别只看一个——高 pct 低 mean 是广泛低表达；⑥ z-score 跨 celltype 显"相对特异"非绝对高；⑦ marker 选择有循环论证风险，应独立验证）。

- [ ] **Step 5: 提交** `feat(archetype): 单细胞 marker dotplot + 真参考图(QA 通过)`。

---

### Task 4: Archetype ⑨ — 拟时序（monocle3 / slingshot 兜底）

**Files:** Create `archetypes/sc-trajectory/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_scrna()`；拟时序工具按可用性选择。输出：UMAP 上着色 pseudotime + 轨迹/谱系线。

- [ ] **Step 1: 装包结果确认**

Run: `Rscript -e 'cat("monocle3:", requireNamespace("monocle3",quietly=TRUE), " slingshot:", requireNamespace("slingshot",quietly=TRUE), "\n")'`
据此选择路径：monocle3 可用→走 A；否则→走 B（slingshot，已装）。**不得因 monocle3 缺失而删拟时序面板。**

- [ ] **Step 2: 写 plot.R（按可用工具二选一；两条路径都给全代码）**

路径 A（monocle3）：
```r
suppressPackageStartupMessages({ source(.../figure_setup.R); library(monocle3); library(ggplot2); library(ggrastr) })
s <- synth_scrna(seed=11)
cds <- new_cell_data_set(s$counts,
         cell_metadata=data.frame(celltype=s$emb$celltype, row.names=colnames(s$counts)),
         gene_metadata=data.frame(gene_short_name=rownames(s$counts), row.names=rownames(s$counts)))
cds <- preprocess_cds(cds, num_dim=10)
# 用我们的合成 UMAP 作为 reducedDim，保证与其它 archetype 一致
reducedDims(cds)$UMAP <- as.matrix(s$emb[,c("UMAP1","UMAP2")])
cds <- cluster_cells(cds, reduction_method="UMAP")
cds <- learn_graph(cds)
root <- colnames(cds)[which.min(s$lineage)]
cds <- order_cells(cds, root_cells=root)
p <- plot_cells(cds, color_cells_by="pseudotime", label_branch_points=FALSE,
                label_leaves=FALSE, cell_size=0.4) +
     scale_colour_gradientn(colours=nature_seq[-1], name="pseudotime") +
     coord_fixed() + labs(title="Pseudotime trajectory (monocle3, synthetic demo)") + theme_nature()
save_nature(p, file.path(out,"ref"), width_mm=120, height_mm=110)
```

路径 B（slingshot 兜底）：
```r
suppressPackageStartupMessages({ source(.../figure_setup.R); library(slingshot); library(ggplot2); library(ggrastr) })
s <- synth_scrna(seed=11); umap <- as.matrix(s$emb[,c("UMAP1","UMAP2")])
sds <- slingshot(umap, clusterLabels=s$emb$cluster,
                 start.clus=as.character(s$emb$cluster[which.min(s$lineage)]))
pt <- slingPseudotime(sds)[,1]
crv <- slingCurves(sds)[[1]]$s[slingCurves(sds)[[1]]$ord, ]
d <- data.frame(s$emb, pt=pt)
p <- ggplot(d, aes(UMAP1, UMAP2)) +
  ggrastr::rasterise(geom_point(aes(colour=pt), size=0.4), dpi=300) +
  geom_path(data=as.data.frame(crv), aes(UMAP1, UMAP2), linewidth=0.6, colour="black") +
  scale_colour_gradientn(colours=nature_seq[-1], name="pseudotime") +
  coord_fixed() + labs(title="Pseudotime trajectory (slingshot, synthetic demo)") + theme_nature()
save_nature(p, file.path(out,"ref"), width_mm=120, height_mm=110)
```
执行者按 Step 1 的结果选 A 或 B，写进 plot.R（顶部注释说明用了哪个工具、为何）。

- [ ] **Step 3: 跑 + QA**（minwidth 1200）。若 monocle3 路径在本机报错（合成数据 learn_graph/order_cells 对噪声敏感），按 systematic-debugging 调参（如 close_loop=FALSE、调 root）；仍不行则切 slingshot 路径并在报告说明——不空面板。

- [ ] **Step 4: card.md**（渲染翻车点：root 选择、graph 学习参数、栅格化；**分析翻车点**：⑤ **拟时序是模型推断的"假定"轨迹，非真实时间**——分支/方向依赖 root 与算法，需生物学先验支撑；⑥ 合成/真实数据都不能把 pseudotime 当真实发育时间轴；⑦ 不同工具(monocle3/slingshot)拓扑可能不同，结论应稳健于工具选择）。注明本图用的工具。

- [ ] **Step 5: 提交** `feat(archetype): 单细胞拟时序(monocle3/slingshot) + 真参考图(QA 通过)`。

---

### Task 5: Archetype ⑩ — 空间 feature 叠图

**Files:** Create `archetypes/spatial-feature/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_spatial()`；ggplot2。两面板：A 空间域(celltype) + B 连续 feature 空间分布。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: 空间组学 feature 叠图（空间域 + 连续 feature）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(ggrastr); library(patchwork); library(viridisLite)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/spatial-feature"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

sp <- synth_spatial(n_spots=1500, seed=12)
cols <- setNames(nature_pal_anno[seq_len(nlevels(sp$celltype))], levels(sp$celltype))
pA <- ggplot(sp, aes(x, y, colour=celltype)) +
  ggrastr::rasterise(geom_point(size=0.9), dpi=300) +
  scale_colour_manual(values=cols, name="Domain") +
  coord_fixed() + labs(title="Spatial domains") + theme_nature() +
  theme(axis.text=element_blank(), axis.ticks=element_blank())
pB <- ggplot(sp, aes(x, y, colour=feature)) +
  ggrastr::rasterise(geom_point(size=0.9), dpi=300) +
  scale_colour_viridis_c(option="magma", name="feature") +
  coord_fixed() + labs(title="Spatial feature gradient") + theme_nature() +
  theme(axis.text=element_blank(), axis.ticks=element_blank())
fig <- pA + pB + plot_layout(ncol=2) +
  plot_annotation(tag_levels="A",
    caption="Synthetic spatial data, style demo only (not real results). set.seed(12); n=1500 spots.",
    theme=theme(plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT)))
save_nature(fig, file.path(out,"ref"), width_mm=183, height_mm=95)
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2-3: 跑 + QA**（minwidth 1800）。

- [ ] **Step 4: card.md**（渲染翻车点：coord_fixed 保形、栅格化、域离散 vs feature 连续配色分开；分析翻车点：⑤ 空间自相关→相邻 spot 不独立，统计检验需空间模型；⑥ spot 可能是多细胞混合(非单细胞分辨率)，"域"是混合信号；⑦ 切片伪影/批次需标注）。

- [ ] **Step 5: 提交** `feat(archetype): 空间 feature 叠图 + 真参考图(QA 通过)`。

---

### Task 6: 集成进 skill-integration

**Files:** Modify `skill-integration/advanced-archetypes.md`

- [ ] **Step 1:** ② 清单追加 4 条（UMAP atlas / dotplot / 拟时序 / 空间），每条含**分析严谨**翻车点 + 参考图相对路径（`assets/advanced-archetypes/sc_umap.png`/`sc_dotplot.png`/`sc_trajectory.png`/`spatial.png`）；拟时序条目注明所用工具(monocle3 或 slingshot)。
- [ ] **Step 2:** 野心阶梯"单细胞/UMAP"高级项从 ⏳预留 改 ✅就绪；空间组学若在表中同样标注。
- [ ] **Step 3:** 提交 `docs(skill-integration): 野心阶梯增单细胞/空间 4 archetype（带分析护栏）`。

---

### Task 7: ROADMAP + 部署 + 回归

- [ ] **Step 1: Phase 2 全回归**（env_check + test_qa + 全部 archetype 重渲 + QA；单细胞/空间 minwidth 见各 Task）。末行 `PHASE2 REGRESSION OK`。任一失败即停。
- [ ] **Step 2: 更新 ROADMAP.md**：勾掉 Phase 2；注明拟时序实际所用工具。
- [ ] **Step 3: 提交（项目侧）** `docs: Phase 2 回归通过 + 路线图勾掉 Phase 2`。
- [ ] **Step 4: 部署（控制者亲做）**：拷 4 张新参考图 + advanced-archetypes.md → `~/.claude/skills/nature-figure/`；展示 diff；assets 应 10 张。

---

## 自检（Self-Review 结果）

- **覆盖**：synth 生成器（T1）、UMAP atlas（T2）、dotplot（T3）、拟时序（T4，monocle3/slingshot 双路径）、空间（T5）、集成（T6）、部署回归（T7）——Phase 2 范围全覆盖。
- **缺包处置**：拟时序 monocle3 为主、slingshot 兜底，Task 4 Step 1 按 requireNamespace 选择，不空面板。
- **大点云**：所有 UMAP/空间散点用 ggrastr 栅格化（防 PDF 膨胀）——硬约束。
- **类型一致**：synth_scrna 返回 emb/expr/markers/counts/lineage，各 archetype 消费一致；synth_spatial 返回 x/y/celltype/feature。
- **占位**：无 TBD；拟时序两条路径都给全代码，按安装结果二选一。
