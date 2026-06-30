# Archetype 库路线图

- [x] Phase 0：脚手架 + QA 门禁 + 多注释热图 + 癌症多组学复合大图 + skill 集成
- [x] Phase 1（组学硬核）：oncoprint 突变全景 · circos 圈图(独立) · ggtree+heatmap 联排（oncoprint/circos/ggtree 已就绪，回归全 5 archetype QA PASS）
- [x] Phase 1.5（参考包学习）：复合图 hero 化 + volcano archetype + 设计克制护栏
- [x] Phase 2（单细胞/空间）：UMAP atlas + marker dotplot + 拟时序(slingshot) + 空间 feature 叠图
  - **注**：拟时序实际使用 slingshot（Bioconductor 主流包）；monocle3 因系统缺 GDAL/GEOS 无法安装，已在 sc-trajectory archetype 注释中说明。全部 4 个 Phase 2 archetype + 6 个 Phase 0/1/1.5 archetype 回归通过，Phase 2 REGRESSION OK (2026-06-30)。
  - **参考蓝本** `/mnt/f/work/research/nature_R/nature_figure_refs/05_singlecell`（scCustomize 一键发表级 UMAP/violin/dotplot；dittoSeq 色盲友好；Nebulosa 密度 UMAP）
- [x] Phase 3（关系网络）：富集通路网络 + Sankey/alluvial + chord 弦图 + UpSet 集合交集
  - **参考蓝本** `03_enrichment`（enrichplot cnetplot/emapplot/gseaplot2）+ ggraph 网络
  - **回归**：全 14 archetype QA PASS (2026-06-30)；非致命噪声：circos "out of plotting region"、ggtree aes_string 弃用警告、slingshot info、ggalluvial "strata at multiple axes"、UpSetR aes_string/size 弃用警告——均已在 task-7-brief 列为预期。
- [x] Phase 4（clinical 小集 + 收口）：森林图(O, theme nature_forest) + ggpubr 带*箱线(P, stat_compare_means) 两个 clinical archetype；野心阶梯接进 nature-figure SKILL.md 主流程（Default operating stance 出图前默认查阶梯 + 画前自检）；ggsci 期刊配色增量折进共享 nature_theme.R；advanced-archetypes.md 索引扩到 O/P。
  - **回归**：全 **16** archetype 渲染 + QA PASS (2026-06-30)；C1 theme 增量后既有 16 图零破坏。
  - **共享件改动（控制者亲做，纯增量+备份+diff+回归）**：① nature_theme.R 末尾追加 `nature_journal_pal(journal,n)` + `scale_color/colour/fill_journal()`（缺 ggsci 回退 nature_pal_anno），不改任何既有定义（备份 .bak_20260630，source-check 16 既有函数无缺失）；② SKILL.md Default operating stance 加阶梯指引 bullet + Related files 加 advanced-archetypes.md 行（备份 .bak_20260630）。

每个 Phase 各自展开成 docs/superpowers/plans/ 下独立详细计划,沿用 Phase 0 的"五件套 + QA 门禁"模式。

## 待决策项

- ~~**ggsci 期刊配色是否折进共享 `nature_theme.R`**~~ —— ✅ 已拍板并落地（Phase 4 控制者 C1，纯增量 `nature_journal_pal()` / `scale_*_journal()`，缺包优雅回退；既有调色板/默认零改动）。
