# Phase 2 Final Review Fixes

Date: 2026-06-30  
Branch: `feat/phase2-singlecell-spatial`

## FIX 1 — UMAP feature-plot 色阶改 grey→蓝 序列

**文件**: `archetypes/sc-umap-atlas/plot.R`

- 移除未使用的 `library(viridisLite)` import（line 5）
- 将 `scale_colour_gradientn(colours=c("grey88", nature_seq[4], nature_div[1]), ...)` 改为 `colours=c("grey88", nature_seq[4], nature_seq[6])`：grey → 中蓝 → 深蓝，纯序列渐变，与 trajectory archetype 及 nature_seq 库内一致，消除误用 `nature_div[1]`（红）作非负量高端色的问题。
- `archetypes/sc-umap-atlas/card.md` 配色规则说明从"grey→蓝→红"更新为"grey→蓝 序列（grey→中蓝→深蓝，取自 nature_seq）"。

验证：
- `grep -n 'nature_seq[6]'` ✓ line 31
- `nature_div[1]` 已不存在于梯度 ✓
- `viridisLite` import 已删除 ✓
- `Rscript archetypes/sc-umap-atlas/plot.R` → `done: ...ref.png` ✓
- `Rscript tools/qa_check.R archetypes/sc-umap-atlas/out/ref.png 1800` → `QA PASS: ref.png — 4322 x 2598 px` ✓
- 目视 PNG：4 个 marker feature 面板（M01/M05/M09/M13）色条均为 grey→深蓝，无任何红色极点。✓

## FIX 2 — dotplot 补诚实 caption

**文件**: `archetypes/sc-marker-dotplot/plot.R`

- 在 `labs()` 中添加 `caption="Synthetic scRNA-seq, style demo only (not real results). set.seed(11)."`
- 在 `theme()` 中添加 `plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT)`，与其他 archetype 的 caption 样式一致。

验证：
- `grep -n 'caption'` ✓ lines 31, 36
- `Rscript archetypes/sc-marker-dotplot/plot.R` → `done: ...ref.png` ✓
- `Rscript tools/qa_check.R archetypes/sc-marker-dotplot/out/ref.png 1200` → `QA PASS: ref.png — 2834 x 3543 px` ✓
