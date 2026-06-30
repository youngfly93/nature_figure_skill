# 进化树 + 热图联排 (ggtree::gheatmap)

- **何时用**：一组样本/物种/克隆有层级（系统发育、层次聚类树），想把树结构与每个叶子的特征矩阵（表达/丰度/基因型）对齐展示。微生物组、肿瘤克隆进化、菌株分型 Figure。
- **数据形状**：一棵树（ape::phylo / treedata）+ tip×feature 数值矩阵（行名=tip label，须与树叶标签一致）。
- **核心依赖**：ggtree、ggplot2、figure_setup.R。
- **配色规则**：clade/分组色取自 nature_pal_anno；热图用 nature_div。
- **常见翻车点（渲染）**：① 矩阵行名与 tip.label 不一致 → 热图错位/留白；② gheatmap 的 offset/width 没调 → 树和热图重叠或离太远；③ tip 标签字号过大挤成团 → ≤2 pt + align=TRUE；④ 列名角度默认 0 度会重叠 → colnames_angle=90；⑤ **ggplot2-4.0 / ggtree-3.14 兼容性**：gheatmap 把内部列位置数据写入 attr(p,'mapping')，覆盖 S7 @mapping 槽 → 后续 +theme() 报 S7 校验错；修复：保存 orig_mapping <- p$mapping，gheatmap 后恢复 attr(ph,'mapping') <- orig_mapping；⑥ **ggplot2-4.0 移除了 is.waive()**：ggtree::empty() 仍调用它 → draw_panel 报"找不到函数 is.waive"；修复：用 unlockBinding + assign 将 ggtree 命名空间中的 empty() 替换为调用 inherits(df,'waiver') 的版本。
- **常见翻车点（分析严谨）**：⑦ **树的拓扑会强烈暗示"亲缘/演化关系"**——若树其实是表达距离的层次聚类（非真系统发育），别用"进化/谱系"措辞，标注清楚是 clustering dendrogram 还是 phylogeny；⑧ **bootstrap/支持度未显示时，分支可信度被默认当成 100%**，关键分叉应标支持值（geom_nodepoint 或 geom_text 映射 label 列）；⑨ **随机树 ≠ 演化树**：合成数据 ape::rtree() 拓扑无生物学意义，投稿时必须用真正的系统发育分析（RAxML/IQ-TREE）或说明构树方法；⑩ **tip 排序误导**：ggtree 默认布局的 tip 顺序取决于树的 Newick 结构，不反映任何相似性排序，与分组注释颜色对照阅读时需格外注意。
- **参考实现**：`archetypes/phylo-tree-heatmap/`
