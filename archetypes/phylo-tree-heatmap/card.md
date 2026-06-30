# 进化树 + 热图联排 (ggtree::gheatmap)

- **何时用**：一组样本/物种/克隆有层级（系统发育、层次聚类树），想把树结构与每个叶子的特征矩阵（表达/丰度/基因型）对齐展示。微生物组、肿瘤克隆进化、菌株分型 Figure。
- **数据形状**：一棵树（ape::phylo / treedata）+ tip×feature 数值矩阵（行名=tip label，须与树叶标签一致）。
- **核心依赖**：ggtree、ggplot2、figure_setup.R。
- **配色规则**：clade/分组色取自 nature_pal_anno；热图用 nature_div。
- **常见翻车点（渲染）**：① 矩阵行名与 tip.label 不一致 → 热图错位/留白；② gheatmap 的 offset/width 没调 → 树和热图重叠或离太远；③ tip 标签字号过大挤成团 → ≤2 pt + align=TRUE；④ 列名角度默认 0 度会重叠 → colnames_angle=90；⑤ **ggplot2-4.0 / ggtree-3.14 兼容性**：gheatmap 把内部列位置数据写入 attr(p,'mapping')，覆盖 S7 @mapping 槽 → 后续 +theme() 报 S7 校验错；修复：保存 orig_mapping <- p$mapping，gheatmap 后恢复 attr(ph,'mapping') <- orig_mapping；⑥ **ggplot2-4.0 移除了 is.waive()**：ggtree::empty() 仍调用它 → draw_panel 报"找不到函数 is.waive"；修复：用 unlockBinding + assign 将 ggtree 命名空间中的 empty() 替换为调用 inherits(df,'waiver') 的版本。
- **常见翻车点（分析严谨）**：⑦ **树的拓扑会强烈暗示"亲缘/演化关系"**——若树其实是表达距离的层次聚类（非真系统发育），别用"进化/谱系"措辞，标注清楚是 clustering dendrogram 还是 phylogeny；⑧ **bootstrap/支持度未显示时，分支可信度被默认当成 100%**，关键分叉应标支持值（geom_nodepoint 或 geom_text 映射 label 列）；⑨ **随机树 ≠ 演化树**：合成数据 ape::rtree() 拓扑无生物学意义，投稿时必须用真正的系统发育分析（RAxML/IQ-TREE）或说明构树方法；⑩ **tip 排序误导**：ggtree 默认布局的 tip 顺序取决于树的 Newick 结构，不反映任何相似性排序，与分组注释颜色对照阅读时需格外注意。
- **参考实现**：`archetypes/phylo-tree-heatmap/`

## 兼容性说明（ggplot2 4.0 / ggtree 3.14）

### 问题根因

本机 ggplot2 4.0.2 与 ggtree 3.14.0 存在两处不兼容，直接使用 ggtree 会崩溃：

1. **`is.waive()` 被移除**：ggplot2-4.0 删除了 `is.waive()`，但 ggtree-3.14 的 `empty()` 仍调用它（其闭合环境指向 ggplot2 命名空间）。渲染时 `geom_segment2::draw_panel` 报 "could not find function 'is.waive'"。

2. **`gheatmap` 与 S7 `@mapping` slot 冲突**：`gheatmap` 在末尾执行 `attr(p2, "mapping") <- mapping`，其中 `mapping` 是列位置的 data.frame。ggplot2-4.0 S7 类系统将 `attr(obj, "mapping")` 映射到类型化的 `@mapping` slot（须为 `ggplot2::mapping` 对象），写入 data.frame 后 S7 校验失败，后续 `+theme()` 或 `+scale_*()` 报 "@mapping must be <ggplot2::mapping>, not S3<data.frame>"。

### plot.R 中的两处兼容补丁

`plot.R` 顶部用了两处一次性补丁绕过上述问题（代码注释标明）：

- **补丁①（empty 替换）**：用 `unlockBinding` + `assign` 将 ggtree 命名空间中的 `empty()` 替换为等价的新实现（把 `is.waive(df)` 改为 `inherits(df, "waiver")`）。
- **补丁②（mapping 保存/恢复）**：调用 `gheatmap` 前保存 `orig_mapping <- p$mapping`，调用后立即恢复 `attr(ph, "mapping") <- orig_mapping`，使后续 S7 校验通过。

### 重要限制与升级路径

- **补丁只在独立 `Rscript plot.R` 的一次性会话里生效**，不污染交互式 R 环境；但这意味着在本机**交互式直接使用 ggtree 出图会失败**——重新打开 R 控制台时补丁不自动加载。
- **根治方案**：等 ggtree 发布兼容 ggplot2-4.0 的更新版本（或临时降 ggplot2 到 3.5.x）。
- **复用本 archetype 时**：若 ggtree 已更新到兼容版（可用 `packageVersion("ggtree")` 确认），应删掉 plot.R 中的两处补丁块，避免不必要的命名空间修改。
