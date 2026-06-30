# 设计文档：Nature 级高级图型 archetype 库 + 野心阶梯

- 日期：2026-06-30
- 状态：设计待用户复核
- 工作目录：`/mnt/f/work/research/nature_figure_skill/`（开发）
- 成品落点：`~/.claude/skills/nature-figure/`（既有 skill，不另造新 skill）
- 配色真源：`~/.claude/assets/figure-style/nature_theme.R`（唯一，不复制不重定义）

---

## 1. 问题与诊断

用户（生信工程师）反馈：agent 画的图**不是丑，而是只会画基础款**（柱状/箱线/散点），
画不出 Nature 上那种**复杂、信息密集、一看就高级**的图。

诊断拆成两个独立问题：

| 问题 | 本质 | 解法 |
|---|---|---|
| **不会画**复杂图 | 缺可跑的范例模板 | archetype 库（内容） |
| **不敢画** / 总退回基础款 | agent 默认行为太保守 | 图型「野心阶梯」（行为） |

只补素材：agent 仍会默认画柱状图。只改行为：agent 想画 circos 也无从下手。**两者必须一起做。**

### 诚实边界（不可代码复刻的部分）

Nature 里大量「高大上」图是 **Illustrator / BioRender 拼的机制示意图、解剖卡通、美工拼版**，
每个子图本身简单，是**排版+示意画+打磨**让整图显高级。这部分**代码复刻不了**。
skill 中明确标注「这类走 BioRender/Illustrator，别硬画」，不假装能出。

---

## 2. 目标 / 非目标

### 目标
- 建一套**可跑、出真图**的高级图型 archetype 库，覆盖癌症基因组/多组学、单细胞/空间、关系网络、复合大图。
- 给 agent 一个「野心阶梯」路由：拿到分析任务时，主动评估「能不能上更高级、更合适的图型」，而非默认基础款。
- 全部由 `nature_theme.R` 统一配色/主题/导出，一交付一套风格。

### 非目标（YAGNI）
- 不做机制示意图/解剖卡通/美工拼版（→ BioRender/Illustrator）。
- 不扒论文私有源码（少、强耦合、授权不清）。
- 不另造新 skill；不重复 `nature_theme.R` 已覆盖的基础图（volcano/KM/PCA/box/forest/基础 heatmap/oncoprint/enrich dot）。
- 不做交互式/HTML 图（如 networkD3）——投稿要静态矢量。

---

## 3. 方案：内容 + 行为，双管齐下

### 3.1 开发在项目目录，成品蒸馏进 skill
- **开发**：`/mnt/f/work/research/nature_figure_skill/` 当真·R 工程，每个脚本**真跑出真图**，绝不放占位/编造示意。
- **蒸馏**：验证通过的范例进 `~/.claude/skills/nature-figure/`（脚本 + 参考图 + 路由条目）。
- **理由**：单一 skill 真源（守文档卫生纪律，不造 `_v2`/不让 skill 路由打架）；配色只认一个 theme。

### 3.2 archetype = 五件套（可复用最小单元）
每种高级图做成自洽单元：
1. **可跑 R 脚本**：自带**合成 demo 数据**、`source(nature_theme.R)`、neutral 函数名，不依赖任何论文私有数据。
2. **渲染参考图**：真跑出来的 PNG（不是占位）。
3. **元数据卡**：何时用 / 需要的数据形状 / 依赖包 / **常见翻车点** / 配色。
4. **Nature 级取舍要点**：克制、留白、标注规范。
5. **skill 路由条目**：进 `references/r-template-index.md` 的图型家族表。

agent 用法：任务 →（数据形状 + 结论）匹配 archetype → 改数据适配，而非从零想。

### 3.3 图型「野心阶梯」（行为修正）
在 skill 里加一份「升级路由」：对常见分析场景，列出 基础 → 中级 → **高级** 三档选项，
让 agent 默认**先问「这个结论能不能用更高级、更贴切的图讲」**，再落到具体 archetype。
例：「两组差异」基础=分组柱状图 → 中级=带统计箱线 → 高级=带边际分布的火山图 / 多注释差异热图。

### 3.4 源头：权威包图库，不是论文源码
从作者级、可复用、授权干净的来源蒸馏，改写为 neutral 自洽脚本：
ComplexHeatmap / circlize 官方电子书、ggtree book、各包 vignette、R Graph Gallery。

---

## 4. 环境现状（2026-06-30 实测，R 4.4.3）

**已装（覆盖绝大部分）**：ggplot2, patchwork, cowplot, scales, ggrepel, svglite,
ComplexHeatmap, circlize, ggtree, treeio, Gviz, Seurat, ggridges, scattermore,
SingleCellExperiment, ggraph, igraph, ggalluvial, UpSetR, survminer, survival,
clusterProfiler, enrichplot, corrplot, ragg, Cairo。

**缺失及处置**：

| 缺失包 | 用途 | 处置 |
|---|---|---|
| `monocle3` | 拟时序轨迹 | **已定：装 monocle3**（Phase 2 开始时后台试装；依赖重、可能报错，卡住即停下报告，不静默降级）。 |
| `maftools` | oncoprint 便捷 | 不装，用 theme 已有 `nature_oncoprint()` + `ComplexHeatmap::oncoPrint` |
| `forestplot` | 森林图 | 不装，用 theme 已有 `nature_forest()` |
| `karyoploteR` | 基因组轨道 | 用已装 Gviz / circlize |
| `networkD3` | 交互 Sankey | 不装，静态投稿用已装 ggalluvial |
| `ComplexUpset` | 更美 UpSet | 先用已装 UpSetR，必要时再装 |
| `showtext/sysfonts` | 字体 | 不动，theme 用 ragg/Cairo 解析字体 |

> 纪律：缺包**先停下商量**（`monocle3` 是唯一真需决策的），绝不静默降级成简单图蒙混。

---

## 5. `nature_theme.R` 已覆盖 vs 本库新增

**theme 已内置（基础~中级，不重做）**：`nature_volcano`, `nature_km`, `nature_pca`,
`nature_box_sig`, `nature_forest`, `nature_heatmap`(基础), `nature_oncoprint`, `nature_enrich_dot`；
配色 `nature_palette/seq/div/pal_anno/sig_col`；`theme_nature`, `save_nature`, `save_heatmap`, 版心宽度常量。

**本库新增（高级/复合档）≈14 个 archetype**：

- **组学硬核**：① ComplexHeatmap 多注释轨道热图（在 `nature_heatmap` 上扩展多 annotation）
  ② oncoprint 突变全景（封装/美化现有 `nature_oncoprint`）
  ③ circlize 基因组圈图 ④ ggtree 进化树 + 热图联排
- **单细胞/空间**：⑤ UMAP atlas（聚类 + 密度 + marker 分面）⑥ dotplot 矩阵
  ⑦ 拟时序轨迹（依赖第 4 节决策）⑧ 空间 feature 叠加
- **关系/流向/网络**：⑨ ggalluvial / Sankey ⑩ ggraph 网络 ⑪ chord 弦图（circlize）⑫ UpSet
- **复合大图**：⑬ patchwork 多面板叙事拼图（子图标号/对齐/inset）——**「高大上」最大来源**
  ⑭ 1 个「混合 Figure」示范：**癌症多组学场景**——突变热图 + 生存 + 通路富集 + circos 拼成一张投稿级 Figure

> 通用优先：用户三组学方向都做 → 按跨项目复用频率排，先做 ①⑬⑤（热图/复合大图/UMAP）打通模式。

---

## 6. 验证纪律（用户底线）

- 每个脚本必须在**真实 R 4.4.3 环境**跑通、出真图才算数；参考图来自真跑，不编造。
- 合成 demo 数据**设种子**、可复现；记录关键参数。
- 缺包先商量，不擅自降级。
- 改既有 skill 文件前 `git status` / `diff` 展示差异，确认后再动；本项目目录 **已定 `git init`** 做版本管理。

---

## 7. 分阶段（避免范围炸）

- **Phase 0｜骨架 + 模式验证**：建工程目录结构；写环境探测脚本；把 **archetype ①（多注释热图）+ ⑬（复合大图）** 端到端打通（脚本→真图→元数据卡→skill 路由条目），用户确认「五件套」模式 OK。
- **Phase 1｜组学硬核**：②③④。
- **Phase 2｜单细胞/空间**：开始时后台试装 monocle3（卡住即停报告）；⑤⑥⑦⑧。
- **Phase 3｜关系/网络**：⑨⑩⑪⑫。
- **Phase 4｜复合大图收口 + skill 集成**：⑭ + 写「野心阶梯」路由 + 更新 skill `references` + 跑一遍回归。

每个 Phase 产出可独立验收；先做 Phase 0 给用户看效果，满意再批量铺。

---

## 8. 决策记录（已定，2026-06-30）

1. **monocle3**：装（Phase 2 后台试装，卡住即停报告，不静默降级）。
2. **git init**：是，项目目录做版本管理。
3. **复合大图 ⑭ 示范场景**：癌症多组学（突变热图 + 生存 + 通路富集 + circos）。
