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
  - **后续 clinical 小集**：forestploter（森林图，可用 theme nature_forest 无需额外装包）+ ggpubr stat_compare_means（带 * 箱线）归入后续 Phase；本期未触发缺包阻塞。
- [ ] Phase 4（收口）：野心阶梯写入 SKILL.md 主流程 · 全库回归 · 文档索引
  - 收口重点：SKILL.md 主流程补全 14-archetype 引导 + advanced-archetypes.md 索引；全库最终回归；文档 DOCS_INDEX 更新。

每个 Phase 各自展开成 docs/superpowers/plans/ 下独立详细计划,沿用 Phase 0 的"五件套 + QA 门禁"模式。

## 待决策项

- **ggsci 期刊配色是否折进共享 `nature_theme.R`（作为 house 选项）** —— 跨项目影响，需用户拍板；当前仅在 volcano archetype 内局部用。
