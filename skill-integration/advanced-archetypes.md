# 高级 Archetype 索引与图型野心阶梯

> **核心规则**：拿到任务时先问"这个结论能不能用更高级、更贴切的图讲"，评估完毕再落到具体 archetype 或基础函数。基础图快交差，高级图传递信息密度——科研图该往高处走。

---

## ① 图型野心阶梯

| 分析场景 | 基础（能用但浪费） | 中级（合格） | **高级（优先目标）** |
|---|---|---|---|
| **两组差异表达** | 分组柱状图（均值±SD） | 带统计标注箱线图（ggpubr） | **多注释差异热图**（ComplexHeatmap，带样本亚型/分期注释轨道）✅就绪；或**带边际分布火山图**（ggside/ggExtra，展示整体分布与显著点）⏳预留（Phase 1+，暂无就绪脚本） |
| **生存分析** | 单条 KM 曲线 | 分层 KM + log-rank p 值（survminer） | **多组学复合叙事大图**（KM + 热图 + 富集 + 基因组证据拼版，cowplot 多面板，故事完整）✅就绪 |
| **聚类/降维结构** | PCA 散点（默认颜色） | 带置信椭圆 PCA（ggplot2 stat_ellipse） | **多注释 ComplexHeatmap**（行/列聚类 + 多轨道样本注释，展现亚群结构与生物学意义）✅就绪 |
| **富集/通路分析** | 条形图（Top 10 条） | dotplot（ggplot2，气泡=基因数，颜色=p） | **通路网络图**（enrichplot::cnetplot / emapplot）⏳预留（Phase 1+，暂无就绪脚本）；或**ridge plot**（enrichplot::ridgeplot，展示全基因集分布）⏳预留（Phase 1+，暂无就绪脚本） |
| **多组学整合** | 逐个出图拼 PPT | 相关性热图（Hmisc + corrplot） | **复合多面板叙事大图**（表达/生存/通路/基因组四象限，cowplot 拼装，逻辑链完整）✅就绪 |
| **单细胞/UMAP** | 单色 UMAP 散点 | 分组着色 UMAP（Seurat DimPlot） | **UMAP Atlas 复合图**（细胞类型 + marker 热图 + 差异气泡图多面板，展示生物学结构）⏳预留（Phase 1+，暂无就绪脚本） |
| **癌症基因组/突变全景** | 突变频率条形图或简单矩阵 | 热图展示突变类型 | **oncoprint 突变全景图**（ComplexHeatmap::oncoPrint，变异类型分层 + 临床注释轨道，Main Figure 常客）✅就绪 |
| **基因组结构/SV/泛基因组** | 逐染色体条形图 | 分染色体散点/折线 | **基因组圈图**（circlize，CNV/表达/突变密度/结构变异连线多轨道圆形布局）✅就绪 |
| **系统发育/克隆进化/菌株分型** | 单独进化树或单独热图 | 带分组着色的树（ggtree） | **进化树+热图联排**（ggtree::gheatmap，树结构与 tip 特征矩阵精确对齐）✅就绪 |

✅就绪=本库已有可跑参考脚本；⏳预留=后续 Phase 补，遇到时应明确告知用户尚无现成模板、按通用原则手写或走 nature_theme.R 基础函数。

**决策动词**：看到"差异/对比"→ 考虑热图；看到"整合/论证"→ 考虑复合拼版；看到"聚类"→ 考虑 ComplexHeatmap；看到"通路"→ 考虑网络/ridge。

---

## ①·5 画前自检：分析严谨护栏（图好看 ≠ 分析对）

> archetype 只保证"渲染质量"，**拦不住"分析错误"**——漂亮的容器会放大错误结论。选定图型、动手画之前，先逐条自检：

1. **跨组可比性（最常翻车）**：跨列/跨组比较前，值是否已按**组规模 / 测序深度 / 总量**归一？否则最大的组会"通吃"。
   - 真实教训：跨疾病比较氨基酸替换，用**原始 PSM** 行 z-score → 样本最多的 Cancer 整列**假性全红**；改成**疾病内占比**后才显出真实的疾病特异区块。
2. **标准化方向**：行 / 列 z-score 是在回答"谁绝对高"还是"谁相对特异"？选错方向，图会讲错故事。
3. **n 与置信**：小样本组的"特异"可能是噪声。标注每组 `n`，必要时过滤低 n 组/行。
4. **选型偏差**：top-N 按什么排？按总丰度选会**偏向大组**；按效应量 / 特异性 / FDR 选更公允——并说明排序依据。
5. **批次 / artifact / 证据级别**：测序深度差、批次效应、MS 候选 vs 已验证——结论口径如实标注（如"candidate-level, not validated"），别让漂亮图暗示过强的结论。

**一句话**：落到任何 archetype 前先问——"**这个值跨列/跨组真的可比吗？这张图会不会让人得出比数据更强的结论？**"

---

## ② 已就绪 Archetype 清单（Phase 0）

### A. 多注释轨道差异热图（ComplexHeatmap）

**参考图**：`assets/advanced-archetypes/heatmap.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 基因×样本表达矩阵 + 多个样本注释（亚型/分期/组织），想一图展示聚类结构与注释关系 |
| **数据形状** | 数值矩阵（行=特征，列=样本，建议提前行 z-score 标准化）+ 样本注释 data.frame（每列一个注释维度） |
| **核心依赖** | `ComplexHeatmap`、`circlize`、`nature_theme.R`（source 于脚本顶部） |
| **配色规则** | 主体用 `nature_heatmap_col()`（蓝-白-红发散）；注释轨道用 `nature_pal_anno` / `nature_seq`，不用默认彩虹 |
| **常见翻车点** | ① 不做行 z-score → 颜色被极值吃掉，热图失去分辨力；② 注释色用默认彩虹色 → 俗，不符合 nature 风格；③ 列名样本太多挤成黑条 → `show_column_names = FALSE`；④ 字号过大（目标 5–6 pt，>8 pt 会压主体）→ 图例/标签抢主体；⑤ 多图例不合并 → 务必用 `merge_legend = TRUE` 或统一 `legp()` 布局 |
| **参考实现** | `archetypes/omics-multiannot-heatmap/` |

---

### B. 复合多面板叙事大图（癌症多组学）

**参考图**：`assets/advanced-archetypes/composite.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 一张 Figure 要把多个证据（表达/生存/通路/基因组）串成完整论证；靠**构图与叙事**而非单图复杂度，适用于文章 Main Figure |
| **数据形状** | 每个面板各自数据（矩阵 / 生存 Surv 对象 / 富集结果 data.frame / 基因组注释段），不需要合并成一个大表 |
| **核心依赖** | `ComplexHeatmap`、`circlize`、`cowplot`、`survminer`、`ggplot2`、`nature_theme.R` |
| **拼装机制** | 非 ggplot 面板（热图/圈图）须先用 `grid.grabExpr()` / `cowplot::as_grob()` 转 grob，再与 ggplot 面板一起传入 `cowplot::plot_grid()`；子图标号 a/b/c/d 用 `label_*` 参数，粗体 8–9 pt |
| **白底保障** | `plot_grid` 输出须追加 `theme(plot.background = element_rect(fill = "white", colour = NA))`，并在 `ggsave()` 传 `bg = "white"`；否则四角可能透明/灰底导致 QA 失败 |
| **常见翻车点** | ① ComplexHeatmap / circos 不是 ggplot 对象，直接丢入 patchwork 或 ggpubr 会报错 → 必须转 grob 再拼；② 子图字号各自定义不一致 → 全部统一 7 pt base；③ 各面板配色各自为政 → 所有颜色走 `nature_theme.R` 调色板；④ 面板太多/留白不足 → 控制子图数 ≤ 6，`cowplot::plot_grid` 留合理 `rel_widths`/gap；⑤ 只导出 PNG → 同时导出 PDF 矢量（期刊投稿必需） |
| **参考实现** | `archetypes/composite-cancer-multiomics/` |

---

### C. oncoprint 突变全景图（ComplexHeatmap::oncoPrint）

**参考图**：`assets/advanced-archetypes/oncoprint.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 基因×样本的突变/CNV 矩阵，想一图展示哪些基因在哪些样本被改变、变异类型构成及与临床注释的关系。癌症基因组 Main Figure 常客 |
| **数据形状** | 字符矩阵（行=基因，列=样本，元素为分号分隔的变异类型，如 `"Missense;Amp"`，无变异为 `""`）+ 样本临床注释 data.frame |
| **核心依赖** | `ComplexHeatmap`（oncoPrint）、`figure_setup.R`（nature_theme.R 等价入口） |
| **配色规则** | 变异类型色取自 theme（`nature_pal_anno` / `nature_div` / `nature_sig_col`），不硬编彩虹 |
| **渲染翻车点** | ① `get_type` 拆分符与数据分隔符不一致 → 变异丢失；② `alter_fun` 的 key 与 `col` 命名不一致 → 报错或漏画；③ `heatmap_legend_param` 缺 `at`/`labels` → ComplexHeatmap 内部断言报错；④ 样本太多列名挤 → 关列名、靠 top 注释条；⑤ Amp/Del 用满格矩形会盖住点突变 → 用半高条分层绘制 |
| **分析严谨翻车点** | ⑥ **基因排序默认按改变频率，会让"高频=重要"产生暗示**——若高频基因是大基因/已知 hypermutation 热点，需说明排序依据，必要时按驱动证据（cancer driver score）而非频率排序；⑦ **样本若来自不同测序 panel 或测序深度，突变检出率不可直接比**——"某亚型突变多"可能只是测得深，图前须说明 panel 一致性或做敏感性分析 |
| **参考图** | `assets/advanced-archetypes/oncoprint.png` |
| **参考实现** | `archetypes/omics-oncoprint/` |

---

### D. 基因组圈图（circlize）

**参考图**：`assets/advanced-archetypes/circos.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 全基因组多维证据（CNV、表达、突变密度、染色体间重排/互作）想在一张圆图里同时展示；泛基因组/结构变异 Figure |
| **数据形状** | 每条染色体的位置 + 各轨道数值（CNV/表达等）+ 连线端点（chr1, pos1, chr2, pos2） |
| **核心依赖** | `circlize`、`ragg`、`figure_setup.R` |
| **配色规则** | 轨道/连线色取自 theme（`nature_seq` / `nature_div`），不硬编 |
| **渲染翻车点** | ① circos 是 base 图、非 ggplot → 出图用 `agg_png` / `cairo_pdf` 直接画，不经 `ggsave`；② 忘了 `circos.clear()` 两端包裹 → 状态泄漏导致下一张图叠加异常；③ 轨道太多挤成糊 → 控制 ≤4 轨、留 `track.margin`；④ 默认会写 `Rplots.pdf` → 末尾 `unlink` 清理；⑤ `circos.track` 传 y 漏传 x → "Length of x and y differ" 报错 |
| **分析严谨翻车点** | ⑥ **连线（links）极易过度解读**——视觉上"连起来"会暗示因果/互作，若只是共现/相关/预测，必须在图注写清是相关而非验证的互作，不得凭圈图连线直接得出功能关联结论；⑦ **CNV 轨用未按 ploidy/纯度校正的原始拷贝数会夸大幅度**——跨样本比较前须说明是否经 purity/ploidy 校正，未校正的相对拷贝数只能在同样本内比较方向；⑧ **合成/演示数据的 CNV 值可能超出生物合理范围**（正常 1–4 copy），替换真实数据须确认轴范围及参考线（diploid=0 或 log2ratio=0）语义一致 |
| **参考图** | `assets/advanced-archetypes/circos.png` |
| **参考实现** | `archetypes/genome-circos/` |

---

### E. 进化树+热图联排（ggtree::gheatmap）

**参考图**：`assets/advanced-archetypes/phylo_heatmap.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 一组样本/物种/克隆有层级关系（系统发育、层次聚类树），想把树结构与每个叶子的特征矩阵（表达/丰度/基因型）对齐展示。微生物组、肿瘤克隆进化、菌株分型 Figure |
| **数据形状** | 一棵树（`ape::phylo` / `treedata`）+ tip×feature 数值矩阵（行名=tip label，须与树叶标签严格一致） |
| **核心依赖** | `ggtree`、`ggplot2`、`figure_setup.R` |
| **配色规则** | clade/分组色取自 `nature_pal_anno`；热图用 `nature_div` |
| **渲染翻车点** | ① 矩阵行名与 `tip.label` 不一致 → 热图错位/留白；② `gheatmap` 的 `offset`/`width` 未调 → 树和热图重叠或离太远；③ tip 标签字号过大挤成团 → ≤2 pt + `align=TRUE`；④ 列名默认 0 度会重叠 → `colnames_angle=90`；⑤ **ggplot2-4.0 / ggtree-3.14 兼容性**：`gheatmap` 覆盖 S7 `@mapping` slot → 后续 `+theme()` 报 S7 校验错，需在 `gheatmap` 前后保存/恢复 `orig_mapping`；⑥ **ggplot2-4.0 移除了 `is.waive()`**，ggtree `empty()` 仍调用 → 报"找不到函数 is.waive"，修复：`unlockBinding` + `assign` 将 `empty()` 替换为调用 `inherits(df,'waiver')` 的版本（详见 card.md 兼容说明）；**升级提示**：若 ggtree 已更新到兼容 ggplot2-4.0 的版本，应删除 plot.R 中的两处补丁块 |
| **分析严谨翻车点** | ⑦ **树的拓扑会强烈暗示"亲缘/演化关系"**——若树其实是表达距离的层次聚类（非真系统发育），不得用"进化/谱系"措辞，须标注清楚是 clustering dendrogram 还是 phylogeny；⑧ **bootstrap/支持度未显示时，分支可信度被默认当成 100%**——关键分叉应标支持值（`geom_nodepoint` 或 `geom_text` 映射 label 列）；⑨ **合成树（`ape::rtree()`）无生物学意义**，投稿时必须用真正的系统发育分析（RAxML/IQ-TREE）或说明构树方法；⑩ **tip 排序误导**：ggtree 默认布局的 tip 顺序取决于 Newick 结构，不反映相似性排序，与分组注释颜色对照阅读时需格外注意 |
| **参考图** | `assets/advanced-archetypes/phylo_heatmap.png` |
| **参考实现** | `archetypes/phylo-tree-heatmap/` |

---

## ③ 诚实边界

以下类型图形**代码无法胜任**，不要尝试硬用 R/Python 画：

| 图型 | 正确工具 |
|---|---|
| 机制示意图（信号通路卡通） | BioRender / PowerPoint |
| 解剖结构/器官卡通 | BioRender / Illustrator |
| 实验流程示意图 | BioRender / Figma / Illustrator |
| 美工拼版/图文排版大图（带箭头文字框的 Graphical Abstract） | BioRender / Illustrator |
| 显微镜图像拼图（IHC/IF） | Fiji/ImageJ + Illustrator |

**规则**：如果结论是"需要上述图型"，应明确告知用户需用 BioRender 或 Illustrator，而非尝试用代码凑合——凑合的结果不能发表。

---

*Phase 0 两个 archetype 就绪（A、B）；Phase 1 新增三个（C oncoprint、D circos、E ggtree+heatmap）；后续 Phase 追加新条目到「已就绪 Archetype 清单」，更新本文件。*
