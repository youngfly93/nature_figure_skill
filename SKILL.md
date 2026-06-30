---
name: nature-figure-archetypes
description: Nature 级复杂/复合生信图的 archetype 库——oncoprint 突变全景、基因组 circos 圈图、临床 Cox 森林图、UMAP atlas、单细胞轨迹、多组学复合大图、富集网络、进化树+热图联排、多注释 ComplexHeatmap 等。Use when 要画或选型复杂/复合的生物信息学图(突变全景、基因组结构、生存森林、单细胞降维/轨迹、多组学整合、富集/通路、系统发育),或当用户问"这个结论用什么图讲更好/能不能画更高级的图"。配合 nature-figure 使用:本库提供"高级图型选型 + 可跑模板 + 分析严谨护栏",配色/主题仍走 nature_theme.R 单一真源。NOT for 基础单图(柱/箱/散点/单色 UMAP,用 nature-figure 基础函数)、Python 后端、通用非生信图。
---

# nature-figure-archetypes — Nature 级生信图谱库

让出图不停在基础款:先选**信息密度更高的高级图型**,用库里**可跑模板 + 真参考图**落地,且**落图前过分析严谨护栏**。配色/主题唯一真源仍是 `~/.claude/assets/figure-style/nature_theme.R`——本库只加"图型选择 + 复杂图脚手架",不重定义风格。

## 工作流（按序）

1. **选型 — 过图型野心阶梯**：先读 [`skill-integration/advanced-archetypes.md`](skill-integration/advanced-archetypes.md)，按"分析场景 → 高级图型"表选最贴切的 archetype；先问"这个结论能不能用更高级的图讲"。
   *完成判据*：选定一个 `archetypes/<name>/`（标 ✅就绪），或明确告知用户该场景暂无就绪模板、改走 `nature_theme.R` 基础函数——别默默退回柱状图。
2. **严谨自检 — 过分析严谨护栏**：动手画前，逐条过同文件 ①·5 的护栏（跨组可比性 / 标准化方向 / n 与置信 / 选型偏差 / 批次与证据级别）。
   *完成判据*：确认"这个值跨组真的可比、这张图不会让人得出比数据更强的结论"。
3. **出图**：`Rscript archetypes/<name>/plot.R`（脚本顶部已 source `figure_setup.R` → `nature_theme.R`）。换成自己的数据/参数，对照同目录 `out/ref.png` 核样式。
4. **环境自检（按需）**：`Rscript tools/env_check.R` 确认所需 R 包齐备；缺包先停下报"卡在哪 + 装什么"，不擅自降级换图型。

## 现成 archetypes（16 个，均 ✅就绪 — 选型菜单，免 `ls`）

按分析场景找 `archetypes/<name>/`（详细选型逻辑见 `advanced-archetypes.md`）：

- **差异表达/对比**：`volcano-deg`（火山图 log2FC×显著性）· `box-compare`（分组箱线+统计标注）
- **多组学整合**：`composite-cancer-multiomics`（表达/生存/通路/PCA 四象限叙事大图）· `omics-multiannot-heatmap`（多注释 ComplexHeatmap）· `upset-sets`（多集合交集 UpSet）
- **突变/基因组**：`omics-oncoprint`（突变全景 oncoPrint+临床轨道）· `genome-circos`（圈图 CNV/表达/突变密度/重排多轨道）
- **富集/通路**：`enrich-network`（通路-基因双层网络）
- **单细胞**：`sc-umap-atlas`（细胞图谱+marker）· `sc-marker-dotplot`（基因×细胞类型点图）· `sc-trajectory`（拟时序轨迹）
- **临床/生存**：`clinical-forest`（多变量 Cox 森林图 HR+95%CI）
- **系统发育/层级**：`phylo-tree-heatmap`（树+tip 特征热图联排）
- **关系/流向**：`chord-diagram`（互作弦图）· `flow-alluvial`（多阶段流向 alluvial）
- **空间组学**：`spatial-feature`（空间转录组特征多面板）

## 交付 QA 走 harness 的门，不用本库的 qa_check
`tools/qa_check.R` 只是**渲染 smoke**（白底/分辨率/非空），用于库自检。**交付图的权威 QA 仍是 `bio-fig-review` 的 `fig_check.py`**——别拿 qa_check.R 当交付门，避免两套标准。

## 边界
- **风格不在这里定义**：只 `source` `nature_theme.R`，绝不在 archetype 里重设配色/主题（一个交付一套风格）。
- 基础单图、Python 后端、非生信通用图 → 回 `nature-figure`。
- `archetypes/_lib/figure_setup.R` 是字体/主题的唯一收口点，新 archetype 顶部 source 它即可，别各自 `options(nature_font=...)`。
