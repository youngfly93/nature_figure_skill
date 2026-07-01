# 高级 Archetype 索引与图型野心阶梯

> **核心规则**：拿到任务时先问"这个结论能不能用更高级、更贴切的图讲"，评估完毕再落到具体 archetype 或基础函数。基础图快交差，高级图传递信息密度——科研图该往高处走。

---

## ① 图型野心阶梯

| 分析场景 | 基础（能用但浪费） | 中级（合格） | **高级（优先目标）** |
|---|---|---|---|
| **两组差异表达** | 分组柱状图（均值±SD） | 带统计标注箱线图（ggpubr）✅就绪 | **多注释差异热图**（ComplexHeatmap，带样本亚型/分期注释轨道）✅就绪；或**带注释火山图**（ggplot2+ggrepel，ggsci NPG 配色，FDR 阈值线 + 关键基因标注）✅就绪 |
| **生存分析** | 单条 KM 曲线 | **分层 KM + log-rank + 风险表**（clinical-km，复用 nature_km）✅就绪 | **多组学复合叙事大图**（KM + 热图 + 富集 + PCA 拼版，patchwork hero 布局，故事完整）✅就绪；或 **多变量 Cox 森林图**（nature_forest，HR+95%CI 临床 Main 常客）✅就绪 |
| **临床预测模型** | 一句"HR 显著" | 单条 ROC / 单表 | **列线图 nomogram**（rms，各变量打分尺 → 1/3/5 年生存预测，须配 calibration）✅就绪；或 **多模型 ROC 对比**（pROC，AUC+DeLong CI，模型区分度对比）✅就绪 |
| **免疫微环境/去卷积** | 单细胞型柱状图 | 分组箱线比较 | **免疫浸润组成图**（堆叠占比条 + 关键 TME 细胞型组间比较双面板，immune-infiltration）✅就绪 |
| **聚类/降维结构** | PCA 散点（默认颜色） | 带置信椭圆 PCA（ggplot2 stat_ellipse） | **多注释 ComplexHeatmap**（行/列聚类 + 多轨道样本注释，展现亚群结构与生物学意义）✅就绪 |
| **富集/通路分析** | 条形图（Top 10 条） | dotplot（ggplot2，气泡=基因数，颜色=p） | **通路网络图**（ggraph 二部图，cnetplot 风格）✅就绪；canonical 替代：enrichplot::cnetplot / emapplot；或**ridge plot**（enrichplot::ridgeplot，展示全基因集分布）⏳预留（Phase 1+，暂无就绪脚本） |
| **多组学整合** | 逐个出图拼 PPT | 相关性热图（Hmisc + corrplot） | **复合多面板叙事大图**（表达/生存/通路/基因组四象限，cowplot 拼装，逻辑链完整）✅就绪 |
| **单细胞/UMAP** | 单色 UMAP 散点 | 分组着色 UMAP（Seurat DimPlot） | **UMAP Atlas 复合图**（细胞类型 + marker 热图 + 差异气泡图多面板，展示生物学结构）✅就绪 |
| **癌症基因组/突变全景** | 突变频率条形图或简单矩阵 | 热图展示突变类型 | **oncoprint 突变全景图**（ComplexHeatmap::oncoPrint，变异类型分层 + 临床注释轨道，Main Figure 常客）✅就绪 |
| **突变过程/signature** | 突变类型计数柱 | 6 类替换型堆叠柱 | **SBS-96 突变 signature**（96 通道 COSMIC 谱，突变过程分解，mut-signature）✅就绪 |
| **基因组结构/SV/泛基因组** | 逐染色体条形图 | 分染色体散点/折线 | **基因组圈图**（circlize，CNV/表达/突变密度/结构变异连线多轨道圆形布局）✅就绪 |
| **拷贝数 landscape（队列）** | 逐染色体 CNV 柱 | 单样本 CNV 折线 | **全基因组 CNV 频率谱**（GISTIC 样，gain 上/loss 下线性谱，cnv-gistic）✅就绪 |
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

## ①·6 设计克制护栏（视觉设计原则——与分析护栏同等优先级）

> 分析护栏保证"数对"；设计护栏保证"图不骗人、不啰嗦"。漂亮但 misleading 的图和丑图一样不能发。落笔前逐条自检：

1. **≤ 3 主色**：优先 `ggsci` 期刊配色（`pal_npg("nrc")`、`scale_color_lancet()`、`scale_color_nejm()`）；禁用彩虹色 / 默认 ggplot2 色板。颜色数量超过 3 个时，多出来的是噪声，不是信息。（现已并入 nature_theme.R：可直接 `nature_journal_pal(journal,n)` / `scale_color_journal()` / `scale_fill_journal()`，缺包优雅回退）
2. **统一字体层级**：一套字体（Arial / Helvetica），靠**字号 + 字重**区分层级（标题 > 坐标轴标题 > 刻度标签 > 图注）；不混用字体，不靠颜色区分层级。
3. **去 chartjunk**：删灰底、多余网格线、冗余边框、重复图例。每个视觉元素都要问"去掉它信息会丢吗？"——答案是"不会"则删。
4. **留白**：图元之间给呼吸空间，不塞满画布；标注/标签拥挤是信息过载，不是解决方案。
5. **对齐到网格**：面板标签、坐标轴、文字左对齐 / 基线对齐；子图行列边距保持一致。
6. **数据-墨水比高**：每一滴墨水服务于信息传达，装饰性元素归零。
7. **多面板用 patchwork**：`plot_annotation(tag_levels = "A")` 自动添加大写面板标签；`plot_layout(design = "AB\nAC")` 或 `plot_layout(widths = ...)` 控制比例；非 ggplot 对象（ComplexHeatmap / circos）先用 `grid.grabExpr() + wrap_elements(full = grob)` 封装后再拼。
8. **精修感靠矢量导出，不靠代码堆**：R 代码出"毛坯" → 导出 PDF/SVG → Inkscape（免费）/ Illustrator 手工对齐字距、拼面板、加注释——那层"顶刊感"是矢量软件完成的，代码只做到 80 分。

**诚实 caption 约定**：演示图 / 合成数据图的 caption 必须注明 `set.seed` 值、关键阈值（FDR 截断 / |log2FC| 截断）及 `"synthetic demo, not real results"`——数字可溯源，不夸大置信度，不以演示输出冒充真实结果。

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
| **何时用** | 一张 Figure 要把多个证据（表达/生存/通路/PCA）串成完整论证；靠**构图与叙事**而非单图复杂度，适用于文章 Main Figure |
| **数据形状** | 每个面板各自数据（矩阵 / 生存 Surv 对象 / 富集结果 data.frame / PCA 矩阵），不需要合并成一个大表 |
| **核心依赖** | `ComplexHeatmap`、`grid`、`patchwork`、`ggplot2`、`survival`、`ragg`、`svglite`、`nature_theme.R` |
| **Hero 布局（patchwork design）** | 面板 A（热图）经 `grid.grabExpr(ComplexHeatmap::draw(...))` 转 grob 后用 `patchwork::wrap_elements(full = ht_grob)` 封装；面板 B/C/D 为 house 函数直接返回的 ggplot 对象；全部 4 面板用 `plot_layout(design = "AB\nAC\nAD", widths = c(1.25, 1))` 拼合（A 跨左列 3 行，B/C/D 右侧垂直堆叠）；`plot_annotation(tag_levels = "A")` 自动添加大写面板标签 |
| **House 函数（4 面板）** | `nature_hm_anno + nature_heatmap + nature_hm_gp` → 面板 A（带注释轨道、按亚型列分割的热图，须向 `nature_hm_anno()` 传入 `col = list(Subtype = sub_cols)` 以统一亚型颜色）；`nature_pca` → 面板 B；`nature_enrich_dot` → 面板 C（列名非"Description"时须显式传 `term=` 参数）；`nature_km(risk_table = FALSE)` → 面板 D（直接返回 ggplot，无需提取 `$plot`） |
| **跨面板统一配色** | 调用一次 `nature_group_cols(levels)` 生成亚型调色板，同时传入热图注释轨道、`nature_pca(cols=sub_cols)` 和 `nature_km(cols=sub_cols)`，确保面板 A/B/D 同一亚型颜色完全一致 |
| **白底保障** | `save_all()` 使用 `ragg::agg_png(..., bg = "white")` 和 `cairo_pdf(..., bg = "white")`；设备调用内部执行 `print(p)` 以正确渲染 patchwork；`unlink("Rplots.pdf")` 清理残留 |
| **常见翻车点** | ① ComplexHeatmap 非 ggplot → 必须先 `grid.grabExpr + wrap_elements(full=...)` 转换再拼入 patchwork；② 字号各自定义 → 热图用 `nature_hm_gp()`，ggplot 面板靠 `theme_nature()` 统一；③ 各面板配色各自为政 → 全部通过 `nature_group_cols()` 统一；④ 面板太多/留白不足 → 控制子图 ≤ 6；⑤ 只导出 PNG → 同时导出 PDF/SVG |
| **分析严谨翻车点** | ⑥ **PCA 分离 ≠ 因果**：无监督聚类描述结构，无法推断亚型差异是否导致表型；⑦ **KM 需排除混杂**：log-rank p 值反映关联，不代表独立预后意义，主张前须多变量 Cox；⑧ **富集须报 FDR**：始终经 BH 校正并注明阈值；⑨ **合成数据不是证据**：caption 必须注明 `synthetic demo, not real results` |
| **参考实现** | `archetypes/composite-cancer-multiomics/` |

---

### C. oncoprint 突变全景图（ComplexHeatmap::oncoPrint）

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

### F. 带注释火山图（差异表达，ggplot2 + ggrepel + ggsci NPG）

**参考图**：`assets/advanced-archetypes/volcano.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 双组差异表达 / 蛋白 / 甲基化，想一图展示效应量（log2FC）× 显著性（-log10 adjP）并标注关键基因；差异分析 Main / 补充图常客 |
| **数据形状** | data.frame（基因名、logFC、校正 P 值 adj.P.Val）；阈值 \|log2FC\| 与 FDR 自定 |
| **核心依赖** | `ggplot2`、`ggrepel`、`ggsci`、`patchwork`、`figure_setup.R`（`nature_theme.R` 入口） |
| **配色规则** | `pal_npg("nrc")` 红（Up）/ 深蓝（Down）；ns 点浅灰，透明度 0.3–0.4 降噪；≤ 3 主色 |
| **渲染翻车点** | ① ns 点不降透明 / 不缩点径 → 糊成一团遮住信号；② 标签不用 `ggrepel` → 互相重叠；③ 标注全部显著基因 → 太挤，只标 top N（按 \|log2FC\| 或 -log10P 排序，数量写死说明）；④ 坐标轴用纯文本 → 用 `expression(log[2]~FC, -log[10]~italic(P[adj]))` 排版；⑤ 灰底 + 默认配色 + 大图例 = chartjunk → 用 `theme_nature()` + 图例内嵌 |
| **分析严谨翻车点** | ⑥ **必须用 FDR / adjP，不是原始 p 值**——12000 基因多重检验，原始 p<0.05 假阳性成片，纵轴须标注 `-log10(adjusted P)` 而非 `-log10(P)`；⑦ **高 -log10P ≠ 生物学重要**：极小 p 值可能来自高表达 / 低方差基因，需结合效应量（log2FC）与表达量综合判断，不能只看 y 轴；⑧ **标注基因不得 cherry-pick**——只挑"故事好"的标注会误导读者，须按统一规则（top \|log2FC\| 或 top 显著）选取并在 caption 中说明选取依据 |
| **参考实现** | `archetypes/volcano-deg/` |

---

---

### G. 单细胞 UMAP Atlas 复合图（ggplot2 + ggrastr + patchwork）

**参考图**：`assets/advanced-archetypes/sc_umap.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | scRNA/snRNA 降维后，一图展示细胞类型图谱 + 关键 marker 的表达分布；单细胞 Main Figure 标配 |
| **数据形状** | embedding 坐标（UMAP1/UMAP2）+ celltype/cluster 注释 + marker 基因 × 细胞表达矩阵 |
| **核心依赖** | `ggplot2`、`ggrastr`（栅格化大点云）、`patchwork`、`figure_setup.R` |
| **配色规则** | celltype 离散用 `nature_pal_anno`；表达连续用 grey→蓝→红渐变（取自 theme）；0 表达用灰色，高表达才上色 |
| **渲染翻车点** | ① 上千点不栅格化 → PDF/SVG 巨大、卡死 → `ggrastr::rasterise(..., dpi=300)`；② UMAP 不 `coord_fixed()` → 簇形变形；③ 用图例认 celltype → 改直接标签（簇中心 `geom_text`），省眼动；④ feature plot 表达 0 用亮色 → 0 用灰、高表达才上色 |
| **分析严谨翻车点** | ⑤ **UMAP 距离不可定量解读**——簇间距离/密度是非线性嵌入产物，不能说"A 比 B 更接近 C"，该说法无数学依据；⑥ **marker 表达受测序深度/dropout 影响**——"未检出"≠"不表达"，应说明是否做了归一化/imputation，不得凭 UMAP 颜色断言基因沉默；⑦ **聚类数依赖分辨率参数**——celltype 标注须有 marker 证据支撑，不得把算法簇直接等同于生物学细胞类型 |
| **参考实现** | `archetypes/sc-umap-atlas/` |

---

### H. 单细胞 marker dotplot（ggplot2 双编码气泡图）

**参考图**：`assets/advanced-archetypes/sc_dotplot.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 展示一组基因（marker）在各细胞类型的表达特异性；点大小=该类型表达该基因的细胞比例（pct），颜色=基因均值 z-score；单细胞注释 Figure 标配 |
| **数据形状** | 聚合后的 data.frame（celltype × gene，含 pct_expressing 与 mean_expr）；celltype 须显式 factor 控制顺序 |
| **核心依赖** | `ggplot2`、`figure_setup.R`（`rev(nature_div)` 配色） |
| **配色规则** | z-score 色谱取 `rev(nature_div)`（红→高/蓝→低），与库内其他热图色向一致；≤3 主色原则 |
| **渲染翻车点** | ① 点大小（pct）与颜色（z-score）须独立编码不同变量，不得绑定同一列；② 须按基因内跨 celltype z-score 着色，原始均值会被高表达基因吃掉动态范围；③ celltype 因子顺序若依赖字母序，对角块结构会被打乱；④ `axis.text.y` 字号 ≥ 4.5 pt，24 基因图内否则不可读；⑤ 须套 `theme_nature()` 保证白底（默认 `theme_classic()` 不达标） |
| **分析严谨翻车点** | ⑥ **pct 与 mean 双指标必须结合读**——高 pct + 低 mean 可能是本底表达而非真 marker；低 pct + 高 mean 可能是亚群特异，仅凭颜色或点大小单维判断会误导结论；⑦ **z-score 反映"相对特异"而非"绝对高表达"**——若某基因全 celltype 均低表达，z-score 仍会出现红色峰值（相对最高列），须同时注明绝对均值范围避免将背景噪音误读为特异高表达；⑧ **marker 选择的循环论证风险**——若 marker 来源于对同一批数据做差异分析，再用 dotplot 展示等于在训练集上评估，须用独立数据集、文献已知 marker 或蛋白层面验证打破循环 |
| **参考实现** | `archetypes/sc-marker-dotplot/` |

---

### I. 单细胞拟时序轨迹图（slingshot + ggplot2 + ggrastr）

**参考图**：`assets/advanced-archetypes/sc_trajectory.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | scRNA 数据中推断细胞分化/状态转变的发育轨迹；UMAP 散点按拟时序连续着色，叠加 slingshot 拟合的轨迹曲线 |
| **数据形状** | UMAP embedding（UMAP1/UMAP2）+ cluster 标签 + slingshot 拟合的 pseudotime 值 + 曲线坐标（`slingCurves()` 返回矩阵） |
| **核心依赖** | `slingshot`（Bioconductor，Street et al. 2018）、`ggplot2`、`ggrastr`、`figure_setup.R`（monocle3 因系统缺 GDAL/GEOS 无法安装，本库采用 slingshot 兜底） |
| **配色规则** | pseudotime 连续色用 `nature_seq`（淡蓝→深蓝）；0 = 起点/早期，最大值 = 终点 |
| **渲染翻车点** | ① `start.clus` 须与聚类因子水平完全一致（字符串），传整数会静默错误；② `slingCurves()[[1]]$s` 返回列名是位置索引而非 `UMAP1/UMAP2`，须手动 `colnames(crv_df) <- c("UMAP1","UMAP2")` 再传 `geom_path()`；③ 点云用 `ggrastr::rasterise(dpi=300)`，轨迹曲线保持 `geom_path()`（矢量）不栅格化；④ UMAP 须 `coord_fixed()` 否则簇形失真、轨迹方向误导；⑤ 须 `theme_nature()` 保证白底 |
| **分析严谨翻车点** | ⑦ **拟时序是模型推断的"假定"轨迹，不是真实时间**——pseudotime 是算法基于细胞在降维空间分布拟合的概率/几何顺序，不应解读为"某细胞在第 X 天"；⑧ **轨迹方向完全依赖 root 选择**——`start.clus` 是研究者主观先验，root 选错则整个轨迹方向倒置，须用已知时序标记基因或分裂指数进行验证；⑨ **拓扑结论应稳健于工具选择**——slingshot（最小生成树+主曲线）与 monocle3（DDRTree/principal graph）算法不同，分支数量和走向可能差异；若得出"A→B→C"分化轴结论，须说明工具局限或在两种工具下均验证；⑩ **pseudotime 不可跨批次/跨实验比较**——不同实验批次的 pseudotime 值只代表相对排序，须归一化对齐后才能纵向比较 |
| **参考实现** | `archetypes/sc-trajectory/` |

---

### J. 空间组学 feature 叠图（ggplot2 + ggrastr + patchwork 双面板）

**参考图**：`assets/advanced-archetypes/spatial.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 空间转录组（Visium/Slide-seq 等）数据，一图展示空间域（cell type annotation）与连续 feature 梯度（基因表达/信号通路活性）的空间分布 |
| **数据形状** | data.frame（x, y 空间坐标 + celltype [factor] + feature [numeric]）；Visium 每 spot 1–10 个细胞混合 |
| **核心依赖** | `ggplot2`、`ggrastr`、`patchwork`、`figure_setup.R`（`viridis/magma` 连续色谱 + `nature_pal_anno` 离散域色） |
| **配色规则** | 域（celltype）用 `scale_colour_manual(nature_pal_anno)`（离散）；feature 梯度用 `scale_colour_viridis_c`（连续）；两者不可共用同一色谱，否则读者无法区分域归属与梯度高低 |
| **渲染翻车点** | ① 必须 `coord_fixed()` 否则空间 x/y 比例失真，域形状与真实切片不符；② 1500+ spot 必须 `ggrastr::rasterise(dpi=300)` 否则 PDF 体积超 50 MB 且卡顿；③ 离散域与连续 feature 分别用 `scale_colour_manual` / `scale_colour_viridis_c`，不得共用；④ 注意 `ggrastr` 版本差异：旧版函数名为 `rasterize()`（无 s），新版为 `rasterise()`；⑤ `figure_setup.R` 路径写错会导致灰底 QA 失败 |
| **分析严谨翻车点** | ⑥ **空间自相关——相邻 spot 不独立**——标准 t-test/线性回归假设观测值独立，但空间组学相邻 spot 表达高度相关（Moran's I 常 > 0.3），直接用非空间模型检验 feature 与域的关联会显著膨胀 I 类错误，须用 NNSVG、spatialDE 或 SPARK 等空间统计模型；⑦ **spot 多细胞混合（非单细胞分辨率）**——Visium spot 直径 ~55 µm，覆盖 1–10 个细胞，"域"标签实为混合信号，不得将 spot 域等同于纯净单细胞类型注释，建议结合 RCTD/SPOTlight/cell2location 解卷积并注明是"spot-level domain"而非"cell-level annotation"；⑧ **切片伪影与批次效应**——不同切片/捕获区域间存在库深度、RNA 降解、背景荧光等技术批次，易被误读为生物学 feature 梯度，多切片整合须 harmony/Seurat 批次校正并在图注中明确标注是否已批次校正 |
| **参考实现** | `archetypes/spatial-feature/` |

---

---

### K. 富集通路网络图（ggraph 二部图，cnetplot 风格）

**参考图**：`assets/advanced-archetypes/enrich_network.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 基因集富集分析（GSEA/ORA）结果，展示通路与基因的双层关系网络；多条通路共享基因时，揭示核心调控基因及通路间交叉关系；适用于 Main Figure 富集结果展示 |
| **数据形状** | edges data.frame（from=通路名, to=基因名）+ terms data.frame（name, p.adjust 显著性）；`synth_network()` 返回此结构；通路节点按基因数sizing，按 -log10(p.adjust) 着色，基因节点小灰 |
| **核心依赖** | `ggraph`、`igraph`、`ggrepel`、`figure_setup.R`；canonical 替代：`enrichplot::cnetplot()`（直接接受 clusterProfiler enrichResult 对象）/ `enrichplot::emapplot()`（通路-通路相似度布局） |
| **配色规则** | 通路节点用 `nature_seq[-1]`（浅蓝→深蓝，深蓝=更显著）；基因节点小灰；边细灰半透明（edge_width=0.25） |
| **渲染翻车点** | ① `layout="fr"`（Fruchterman-Reingold）含随机→必须在 `ggraph()` 之前 `set.seed()` 否则图无法复现；② `geom_node_text` 对基因节点传 `NA_character_` 会触发 ggrepel "Removed N rows" 警告，属正常行为；③ 每条通路基因数有随机 jitter，degree 须从 graph 实际读取，不可硬编码；④ ggraph ≥2.x `geom_node_text(repel=TRUE)` 需 ggrepel，报错时改用 `check_overlap=TRUE`（但后者不推开标签，只消隐）；⑤ `theme_void()` 背景默认透明，须显式 `theme(plot.background=element_rect(fill="white"))` |
| **分析严谨翻车点** | ⑥ **力导向布局节点距离是美学排布，不代表生物学相似性**——不得在正文描述"距离近的通路相关性强"，节点间距无定量意义；⑦ **边来自注释库，结论受版本影响**——通路-基因归属依赖 KEGG/MSigDB/GO 特定版本，不同版本同一基因的通路归属可能不同，图注须注明数据库及版本号；⑧ **通路冗余使网络虚胖**——高重叠通路（如"Cell cycle"与"G2M checkpoint"）会产生大量共享基因节点导致网络膨胀、视觉混乱，建议先 `clusterProfiler::simplify()` 或按相似度阈值去冗再出图；⑨ **基因节点标注过密**——若对基因节点也标名称，小图将不可读，只标通路名或配合 `max.overlaps` 限制密度 |
| **参考实现** | `archetypes/enrich-network/` |

---

### L. Sankey / alluvial 流向图（ggalluvial）

**参考图**：`assets/advanced-archetypes/alluvial.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 展示样本在多个离散属性（如 Tissue → Subtype → Response）之间的流向分布与构成比例；揭示类别交叉模式；≥3 个分类轴时优于堆叠柱图 |
| **数据形状** | data.frame（各轴分类列 + `Freq` 聚合计数）；经 `table()` 聚合为宽格式，`aes(axis1=, axis2=, axis3=, y=Freq)`；各轴类别须显式 `factor` 锁定水平顺序 |
| **核心依赖** | `ggalluvial`、`ggplot2`、`figure_setup.R` |
| **配色规则** | 流带（alluvium）fill 映射到中间分类轴（如 Subtype），颜色取 `nature_pal_anno[seq_along(levels)]`；stratum 用 `grey92` 中性色；≤3 主色原则 |
| **渲染翻车点** | ① `geom_alluvium(width=W)` 与 `geom_stratum(width=W)` 必须传同一 `W`（默认 1/3），不一致时流带"戳出"矩形块；② ggplot2 ≥3.3 用 `after_stat(stratum)`，旧代码 `stat(stratum)` 在新版报 deprecated 警告或错误；③ `scale_x_discrete(limits=c(...))` 必须显式锁定阶段顺序，省略时按字母序排列，叙事完全改变；④ 各轴因子水平顺序控制 stratum 内堆叠顺序，务必显式 `factor(..., levels=...)`；⑤ 同名类别出现在多轴（如两列都含 "Normal"）会触发 "Some strata appear at multiple axes" 警告，需改名消除歧义；⑥ stratum 过多时 `size=2` 标签重叠，可缩小字号或只标主要类别 |
| **分析严谨翻车点** | ⑦ **流带宽度=样本计数，不等于概率或因果**——"C1→Responder 流最宽"只反映样本数多，不代表 C1 更可能应答（需看条件比例），更不能解读为 Subtype 导致了 Response（横截面分类，无干预设计）；⑧ **阶段顺序是人为排列，换顺序改变视觉叙事**——同一数据改为 `Subtype → Tissue → Response` 会呈现完全不同"故事"，须在图注说明各轴含义与排列依据，不得暗示因果时序；⑨ **小流（低 n）视觉上易被忽略但可能重要**——罕见亚型的 alluvium 极细，需在图注明确注明绝对 n，必要时补表格，防止临床重要信息被视觉压制 |
| **参考实现** | `archetypes/flow-alluvial/` |

---

### M. chord 弦图（circlize chordDiagram）

**参考图**：`assets/advanced-archetypes/chord.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 展示两两类别间互作强度（细胞间通讯 CellChat/NicheNet 输出、组学间关联频次）；弦宽正比于互作计数；有向/无向均可；适用于细胞通讯 Figure |
| **数据形状** | 命名方阵（行=发送方，列=接收方，值=互作强度/计数，对角可设 0 排除自互作）；`synth_chord(n, seed)` 返回 n×n Poisson 矩阵示例 |
| **核心依赖** | `circlize`、`ragg`、`figure_setup.R`；base 图，非 ggplot |
| **配色规则** | 扇区颜色 `grid.col = nature_pal_anno[1:n]`，名称须与 rownames 对应；弦透明度 0.35 |
| **渲染翻车点** | ① `circos.clear()` 必须在 `draw_chord()` 开头与结尾各调一次，否则全局状态泄漏导致第二次渲染（PDF）叠加到第一次；② sector label 需 `preAllocateTracks=1` 配合 `circos.trackPlotRegion()` 自定义文本，才能控制 `facing="clockwise"+niceFacing=TRUE`；③ `chordDiagram` 是 base graphics，**不可用 `save_nature()`**，须 `agg_png(...); draw_chord(); dev.off()` 显式设备流程；④ 脚本末尾必须 `unlink("Rplots.pdf")` 清除残留；⑤ 旧版 `annotationTrackHeight`、新版 `direction.type="arrows"` 需搭配 `link.arr.type`，遇 "unused argument" 须核对当前 `?chordDiagram` 文档 |
| **分析严谨翻车点** | ⑥ **弦宽=互作强度统计推断，不等于已验证的因果互作**——CellChat 等工具输出的通讯概率本质是配体-受体共表达相关性，弦图可视化数值但无法证明信号真正从 A 传到 B，图注须写"潜在互作强度"而非"A 激活 B"；⑦ **有向箭头（directional=1）需数据本身支持方向性**——若原始矩阵是对称的（如皮尔逊相关），强加 `directional=1` 会产生误导性箭头，仅当矩阵代表真正有方向意义（发送方→接收方计数不对称）时才启用；⑧ **对角置 0 须在图注说明**——`diag(m)<-0` 排除自互作连线，若研究问题本身含自分泌（autocrine），须明确注明"自互作未展示"，避免读者误以为无自分泌信号 |
| **参考实现** | `archetypes/chord-diagram/` |

---

### N. UpSet 集合交集图（UpSetR）

**参考图**：`assets/advanced-archetypes/upset.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | ≥4 个集合（多组学 overlap：差异基因×甲基化×CNV×蛋白组等）的交集模式可视化，替代 Venn 图；顶部交集大小柱图+点矩阵+左侧集合大小柱图，清晰展示复杂交集结构 |
| **数据形状** | 命名列表（各元素为集合成员字符向量），须先 `fromList(sets)` 转二进制 0/1 矩阵（各列=集合，各行=元素），再传入 `UpSetR::upset()` |
| **核心依赖** | `UpSetR`、`ragg`、`figure_setup.R`；更美替代：`ComplexUpset`（底层全 ggplot2，支持自定义 panel、完整 theme 系统——**本机当前未安装**，投稿级图可 `install.packages("ComplexUpset")` 升级） |
| **配色规则** | 顶部交集柱用 `nature_seq[5]`；左侧集合大小柱用 `nature_pal_anno[1]`；矩阵点/连线用 `nature_div[1]`；底纹 `grey85` |
| **渲染翻车点** | ① `fromList()` 不可跳过——直接传命名列表会报 `Error in data[, i]`（无法定位），必须先转二进制矩阵；② `text.scale` 必须为 scalar 或长度恰好 6 的向量（槽位依次：交集大小标题/刻度、集合大小标题/刻度、集合名称、柱顶数字），传错长度会 `subscript out of bounds` 或静默截断；③ `UpSetR::upset()` 返回 grid 对象，脚本模式下不自动绘制——必须 `print(upset(...))` 才能渲染到打开的设备；④ 不可用 `save_nature()`（内部调 `ggsave`，UpSetR 非 ggplot），须 `agg_png(...)` + `print(upset(...))` + `dev.off()`；⑤ 脚本末尾必须 `unlink("Rplots.pdf")`；⑥ `order.by="freq"` 按交集元素数降序（最大交集在左）、`"degree"` 按参与集合数升序，两种排序叙事不同，投稿前须确认与图注一致 |
| **分析严谨翻车点** | ⑦ **各集合定义阈值必须统一**——若 DEG_up 用 FDR<0.05+\|logFC\|>1 而 Methylated 用 p<0.1，阈值严格程度不同会人为放大/缩小交集，须在图注明确各集合的入选标准；⑧ **大交集不等于生物学显著**——若 DEG_up 有 85 个基因、CNV_gain 有 50 个，在 200 基因池中随机交集期望约 21 个，观察值若未远超期望，overlap 可能只是大集合的必然结果而非真实生物学关联，须补做**超几何检验**（`phyper()`）或 Fisher 精确检验并在图注报 p 值；⑨ **集合来源平台不同须说明并经批次矫正**——DEG 来自 RNA-seq、Methylated 来自 RRBS、CNV 来自 SNP array 若各批次未批次矫正，共同批次效应可能高估 overlap，而不同平台基因覆盖差异可能低估，须注明数据来源并说明是否已矫正 |
| **参考实现** | `archetypes/upset-sets/` |

---

### O. 多变量 Cox 森林图（theme nature_forest）

**参考图**：`assets/advanced-archetypes/forest.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 多变量 Cox 模型中各协变量的 HR 及 95% CI，一图展示哪些因素显著（红点）与哪些不显著（灰点），并附数值标注；临床预后 Main Figure 常客 |
| **数据形状** | data.frame（term, HR, lo, hi, p, n）；`synth_forest(seed=31)` 返回示例 |
| **核心依赖** | `nature_forest()`（nature_theme.R 内置，无需装包）、figure_setup.R |
| **配色规则** | 显著(p<0.05)=`nature_sig_col` 红，ns=灰；HR=1 处虚线参考；x 轴 log10 |
| **渲染翻车点** | ① x 轴是 log10 刻度，CI 在 log 轴上左右不对称属正常；若强制线性轴（`trans="identity"`），视觉上会严重扭曲小 HR 的间距，误导读者；② HR=1 参考线必须存在，虚线标注"无效应"基准线，缺失则读者无法判断方向（保护 vs. 风险）；③ 最宽 CI 标签易与须线重叠——传 `xlim` 留头部空间，`xlim` 裁切须在 caption 注明截断范围（如 "CI truncated at x=0.1/10"），不能静默截断；④ `show_label=TRUE` 时右侧数值标注需要额外空间，`width_mm` 过窄会导致标注与图形重叠——建议 ≥120 mm（单栏），大型 forest 用双栏 183 mm；⑤ 修改 `sig_level` 后须同步更新 `scale_colour_manual` 的 `labels`（`nature_forest` 内部已自动格式化，手动覆盖时需注意） |
| **分析严谨翻车点** | ⑥ **多变量校正与否，结论可能相反**：单变量 Cox 中 HR 显著的变量，进入多变量模型后可能因与其他协变量的混淆而变为 ns，反之亦然——须注明是"单变量"还是"多变量"模型及纳入的协变量列表（如 Age + Stage + Grade），不能只写"Cox 分析"；⑦ **宽 CI（小 n）点估计不稳定**：CI 极宽的变量（如 n<30 的亚组）其 HR 置信度极低，不应只报 HR 点估计或仅依据 p 值下结论——应同时展示 n 或在图注警告小样本不稳定性；⑧ **多重比较 p 偏乐观**：同时检验多个协变量，原始 p 值存在 I 型错误膨胀；若未做 Bonferroni/FDR 校正，红色"显著"点数量可能虚高——须在 caption 或方法节注明是否校正 |
| **参考实现** | `archetypes/clinical-forest/` |

---

### P. 带显著性标注箱线图（ggpubr stat_compare_means）

**参考图**：`assets/advanced-archetypes/boxsig.png`（部署后路径，相对于 skill 根目录）

| 项目 | 详情 |
|---|---|
| **何时用** | 多组（≤4 组）连续变量比较，叠加 jitter 散点，标注全局 KW p 值及两两 Wilcoxon vs Ctrl 星号；临床/实验分组 Figure 常客 |
| **数据形状** | data.frame（group [factor], value [numeric]）；须显式 factor 锁定组顺序；`synth_box(seed=32)` 返回 n=160 4 组示例 |
| **核心依赖** | `ggpubr`、`ggsci`（经 ggpubr `palette="npg"` 局部使用）、figure_setup.R |
| **配色规则** | ggsci npg ≤4 组；jitter 透明 0.5；全局 KW + 两两 Wilcoxon vs Ctrl |
| **渲染翻车点** | ① `comparisons` 配对顺序：每个元素必须是长度为 2 的字符向量，且组名须与 `x` 轴 factor levels 完全匹配（大小写/空格敏感）；若组名不一致会静默跳过或报错，导致括号消失；② `label.y` 防与须状（bracket）重叠：全局 KW 的 `label.y` 应设为 `max(d$value) + 足够偏移量`（本例 +2.2），偏移量不足时 KW 标签会压在最高一个显著性括号上，偏移量过大会超出图框；③ jitter 透明度遮箱体：`add.params=list(size=0.6, alpha=0.5)` 控制散点大小与透明度，size 过大或 alpha 过高会遮住箱体四分位线，alpha 过低则散点消失；④ **长 caption 须换行（`sep="\n"`）防右侧截断**；⑤ ggpubr 与 ggplot2 4.x 偶有内部 layer 接口变更警告，建议显式指定 `method="wilcox.test"`（两组）或 `method="kruskal.test"`（多组）而非依赖默认值 |
| **分析严谨翻车点** | ⑥ **`*` 只表 p 阈值不表效应量**：`****`（p<0.0001）不意味着临床意义显著；须并报效应量（如 Cohen's d、rank-biserial r）和置信区间，不能仅凭星号得出结论；⑦ **默认非参检验（Wilcoxon/KW）假设须核对**：均假设分布形态相同（仅位置参数不同）；若各组分布形态差异较大，Wilcoxon 的原假设是"分布相同"而非"中位数相同"，解读需注意；数据正态时应优先考虑 t 检验（两组）或单因素 ANOVA（多组）以获得更高检验效能；⑧ **多两两比较未校正假阳性须 p.adjust**：若同时做 k(k-1)/2 对全排列比较，假阳性概率急剧上升；正式分析须指定 `p.adjust.method`（如 `"BH"`），或改用 Dunnett's test |
| **参考实现** | `archetypes/box-compare/` |

---

### Q. KM 生存曲线 + number-at-risk 表（nature_km）

| 项目 | 详情 |
|---|---|
| **何时用** | 分组/biomarker 二分后的生存曲线，展示各组随时间生存概率差异 + log-rank/Cox + HR + 底部风险表；临床癌症报告第一高频图，与 O 森林图（讲"哪些因素"）互补讲"生存本体" |
| **数据形状** | data.frame（time, status[1=事件/0=删失], group 或连续 value）；`synth_km(seed=51)` 返回 biomarker High/Low 示例 |
| **核心依赖** | `nature_km()`（nature_theme.R 内置）、`survival`、`patchwork`（风险表拼装） |
| **配色规则** | High/Low 语义色；多组用 `nature_group_cols(levels)`；删失点 `shape=3` 竖线 |
| **渲染翻车点** | ① 删失标记必须在，否则"曲线走平"被误读为无退出；② >2 组无 HR（`nature_km` 仅 2 组算 Cox/HR）；③ 曲线与风险表 x 刻度须对齐（内部同 `breaks`）；④ 返回 patchwork，加 caption 用 `+ plot_annotation()` 非 `+ labs()` |
| **分析严谨翻车点** | ⑤ **log-rank 只反映关联，非独立预后**——主张独立预后须多变量 Cox；⑥ **分组切点不能数据驱动后不报**——median/maxstat 最优切点抬高假阳性，切点方法与阈值必须写明并校正；⑦ **随访不足/informative censoring**——末端曲线由极少数决定、因病重退出偏倚估计，须报中位随访时间与删失比例 |
| **参考实现** | `archetypes/clinical-km/` |

---

### R. 列线图 nomogram（rms::cph 多变量 Cox 预测）

| 项目 | 详情 |
|---|---|
| **何时用** | 把多变量 Cox/logistic 模型转成可手动累加的"打分尺"，读者据各变量得分 → Total Points → 读 1/3/5 年生存概率；临床预测模型 Main Figure |
| **数据形状** | 生存结局（time, status）+ 连续/分类协变量 data.frame；`synth_nomogram_cohort(seed=52)`（Age/Stage/Grade/Biomarker） |
| **核心依赖** | `rms`（datadist + cph + nomogram）、`ragg`；**base graphics 非 ggplot** |
| **配色规则** | 以清晰刻度为先，`col.grid` 浅灰参考网格；base 图设 `par(family=NATURE_FONT)` |
| **渲染翻车点** | ① **必须先 `datadist` + `options(datadist=)`** 否则报错找不到分布；② `cph(x=T,y=T,surv=T)` 保存设计矩阵供 Survival/calibrate；③ base 图**不用 save_nature**，显式 `agg_png/cairo_pdf`；④ `fun.at` 超出可达概率范围会被截断属正常；⑤ 末尾 `unlink("Rplots.pdf")` |
| **分析严谨翻车点** | ⑥ **nomogram 不能单独出——必须配 calibration + C-index**（`rms::calibrate` bootstrap 校准曲线 + `validate` optimism-corrected C-index），只画预测尺不报区分度/校准是高频拒稿点；⑦ **过拟合**：EPV<10 时点估计不稳，须 bootstrap 报校正后 C-index；⑧ **外部验证缺失**：内部 bootstrap ≠ 外部队列；⑨ **连续变量线性假设**：非线性关系须 `rcs()` 样条 |
| **参考实现** | `archetypes/clinical-nomogram/` |

---

### S. SBS-96 突变 signature（COSMIC 96 通道谱）

| 项目 | 详情 |
|---|---|
| **何时用** | 展示样本/队列的单碱基替换突变谱（6 替换型 × 16 三核苷酸上下文 = 96 通道），用于 COSMIC signature 分解、突变过程推断（SBS1 老化/SBS4 吸烟等）；癌症基因组 Figure |
| **数据形状** | 96 行 data.frame（substitution, context, fraction），须为 **COSMIC 顺序**；`synth_sbs96(seed=53)` 生成（真实数据换 MutationalPatterns/maftools 的 96 向量） |
| **核心依赖** | `ggplot2`（原生实现，6 分面 + 官方色码，无重 Bioc 依赖，便于移植） |
| **配色规则** | **领域约定优先于 ≤3 色通则**：COSMIC 官方 6 色（C>A 蓝/C>G 黑/C>T 红/T>A 灰/T>C 绿/T>G 粉），改色则不可辨认——与 circos 多轨、oncoprint 变异类型同为合法例外 |
| **渲染翻车点** | ① **96 通道须 COSMIC 顺序**（6 替换型内按三核苷酸、5' 变化最慢），错序则与文献图/分解对不上；② x 轴 96 标签太密→只显三核苷酸（`mono` 字体 size≈2.4）靠 strip 标替换型；③ 纯 ggplot 无法按分面上不同色 strip 顶条，要完全复刻用 `ggh4x::strip_themed` 或 `MutationalPatterns::plot_96_profile`；④ 多样本比较用 fraction 归一化，别用原始计数 |
| **分析严谨翻车点** | ⑤ **signature ≠ 病因**——"检出 SBS4"≠"吸烟"，措辞用 consistent with；⑥ **低突变负荷样本谱不可信**——突变数<数十时噪声极大，须报负荷、过滤；⑦ **de novo 提取 vs refit 是两回事**——k 选择、cosine 阈值须报告，别把 refit 说成"发现新 signature"；⑧ **FFPE/氧化 artifact**（C>T/G>T）污染谱，须说明是否过滤 |
| **参考实现** | `archetypes/mut-signature/` |

---

### T. 免疫浸润组成（堆叠占比 + 组间比较）

| 项目 | 详情 |
|---|---|
| **何时用** | 免疫去卷积（CIBERSORT/xCell/EPIC/quanTIseq）结果，一图展示各样本免疫细胞占比构成 + 关键 TME 细胞型组间差异；肿瘤微环境 Figure |
| **数据形状** | 样本×细胞型占比矩阵（**行和=1**）+ 分组向量；`synth_immune(seed=54)` 返回 Tumor/Normal 10 细胞型示例 |
| **核心依赖** | `ggplot2`、`patchwork`（双面板）、`ggpubr`（组间 Wilcoxon 标注） |
| **配色规则** | **领域必需 >3 色**（10~22 细胞型）：`colorRampPalette(nature_pal_anno)` 插值定性色板，固定顺序跨图同色——与 alluvial 多类别同为合法例外 |
| **渲染翻车点** | ① 占比须归一化（行和=1），否则堆叠条高低不齐；② 组内按某关键细胞型占比排序更可读；③ 10+ 色相邻块须拉开、固定顺序；④ p 值标注用 `scale_y_continuous(expand=expansion(mult=c(.05,.15)))` 留上方空间防压须线/离群点 |
| **分析严谨翻车点** | ⑤ **relative mode 占比是"相对比例"非绝对细胞数**——某型升高可能是别的降了，须说明 relative/absolute mode；⑥ **检验匹配设计**——同患者配对样本用配对 Wilcoxon，多细胞型多组须 `p.adjust`（BH）；⑦ **去卷积依赖 signature matrix 与平台**——LM22 基于外周血用于实体瘤可能不准，方法间差异大，关键结论多方法交叉/单细胞验证；⑧ **批次效应**——不同深度/批次占比不可直接比 |
| **参考实现** | `archetypes/immune-infiltration/` |

---

### U. 多模型 ROC 曲线 + AUC（pROC）

| 项目 | 详情 |
|---|---|
| **何时用** | 同图叠加多个诊断/预后模型的 ROC，图例标各自 AUC+95% CI，对比模型区分能力；诊断标志物/预测模型 Figure |
| **数据形状** | data.frame（label[0/1] + 各模型预测分数列）；`synth_roc(seed=55)` 返回强/中/弱三模型示例 |
| **核心依赖** | `pROC`（roc + ci.auc DeLong）、`ggplot2`、`ggsci`（NPG ≤3 主色） |
| **配色规则** | ≤3 模型用 ggsci NPG；对角随机基线虚灰线；图例内嵌右下 |
| **渲染翻车点** | ① **`direction="<"` 显式指定**方向，避免 pROC 自动翻转出 AUC<0.5；② 曲线按 (model, fpr, tpr) 排序否则 geom_path 乱连；③ `coord_equal()` 保 1:1 正方形；④ 对角线必须在（随机基线）；⑤ AUC 须带 CI，不能只报点值 |
| **分析严谨翻车点** | ⑥ **训练集 ROC 虚高**——须交叉验证/独立测试/bootstrap 校正，注明来自训练还是验证；⑦ **AUC 高 ≠ 临床有用**——类别不平衡时掩盖低 PPV，须并报 敏感度/特异度/PPV，罕见事件补 PR 曲线；⑧ **模型比较须配对检验**（`roc.test` DeLong），不能仅凭 AUC 数值或 CI 是否重叠；⑨ **阈值须预先声明**——同数据选 Youden 又评估=数据窥探 |
| **参考实现** | `archetypes/roc-multi/` |

---

### V. 全基因组 CNV 频率谱（GISTIC 样）

| 项目 | 详情 |
|---|---|
| **何时用** | 沿基因组线性坐标展示队列中各位点的扩增频率（红上）/缺失频率（蓝下），看哪些染色体臂/区段反复改变；癌症 CNV landscape。与 D 圈图（单样本多轨圆形）互补 |
| **数据形状** | data.frame（chr, bin/位置, gain, loss[频率 0–1]）；`synth_cnv_freq(seed=56)` 生成（真实数据换 GISTIC2 的 amplification/deletion frequency 或 G-score） |
| **核心依赖** | `ggplot2`（原生实现，累积坐标 + 交替底带 + 边界线，无重依赖） |
| **配色规则** | gain 红 / loss 蓝（`nature_sig_col` Up/Down），2 色符合 ≤3 通则；奇数染色体浅灰底带 |
| **渲染翻车点** | ① 染色体 offset/cumsum/center 三者须一致，错位则标签飘；② **loss 须取负**（`freq=-loss`）向下画，否则失去 gain/loss 对称语义；③ 下半轴用 `labels=percent(abs(v))` 显正百分比；④ `geom_col(width=1)` 紧贴不留缝 |
| **分析严谨翻车点** | ⑤ **须先 purity/ploidy 校正**——未校正拷贝数受肿瘤纯度稀释，跨样本频率系统偏差，须说明是否 ABSOLUTE/校正；⑥ **频率 ≠ GISTIC 显著峰**——G-score/q 值已校正基因组长度与背景，只画频率别称"significant peak"（那是 GISTIC 统计结论）；⑦ **focal vs arm-level 分清**——focal 高幅峰更可能含 driver；⑧ **参考基因组版本**（hg19/hg38）须与注释一致 |
| **参考实现** | `archetypes/cnv-gistic/` |

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

*Phase 0 两个 archetype 就绪（A、B）；Phase 1 新增三个（C oncoprint、D circos、E ggtree+heatmap）；Phase 1.5 新增 F 火山图、①·6 设计克制护栏、诚实 caption 约定，B composite 更新为 hero 布局；Phase 2 新增四个单细胞/空间组学 archetype（G UMAP Atlas、H marker dotplot、I 拟时序/slingshot、J 空间 feature 叠图），各含分析严谨翻车点；野心阶梯"单细胞/UMAP"条目更新为 ✅就绪；Phase 3 新增四个关系/网络/集合 archetype（K 富集通路网络 ggraph、L Sankey/alluvial 流向图、M chord 弦图、N UpSet 集合交集图），各含分析严谨翻车点；野心阶梯"富集/通路分析"高级项通路网络更新为 ✅就绪；后续 Phase 追加新条目到「已就绪 Archetype 清单」，更新本文件。Phase 4 新增两个 clinical archetype（O 多变量 Cox 森林图 nature_forest、P ggpubr 带*箱线 stat_compare_means），各含分析严谨翻车点；阶梯"两组差异/生存分析"相应项标 ✅就绪；ggsci 期刊配色已并入 nature_theme.R（nature_journal_pal/scale_*_journal）。Phase 5 新增六个临床/基因组高频 archetype（Q KM 生存曲线+风险表 nature_km、R nomogram 列线图 rms、S SBS-96 突变 signature、T 免疫浸润组成、U 多模型 ROC pROC、V 全基因组 CNV 频率谱 GISTIC 样），各含分析严谨翻车点；阶梯新增"临床预测模型/免疫微环境/突变过程/拷贝数 landscape"四场景行，"生存分析"中级项（分层 KM+风险表）标 ✅就绪；S 与 T 显式声明"领域色码/维度决定 >3 色"为覆盖 ≤3 色通则的合法例外；库共 22 个 archetype。*
