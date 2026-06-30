# 多注释轨道差异热图 (ComplexHeatmap)

- **何时用**：基因×样本表达矩阵 + 多个样本注释（亚型/分期/组织），想一图展示聚类结构与注释关系。
- **数据形状**：数值矩阵（行=特征，列=样本，建议行 z-score）+ 样本注释 data.frame。
- **依赖**：ComplexHeatmap、circlize、nature_theme.R。
- **配色**：主体 `nature_heatmap_col()`（蓝-白-红发散）；注释 `nature_pal_anno` / `nature_seq`。
- **常见翻车点**：① 不做行 z-score → 颜色被极值吃掉；② 注释色用默认彩虹色 → 俗；③ 列名挤成黑条 → `show_column_names=FALSE`；④ 字号过大 → 5–6 pt；⑤ 多图例不合并 → `merge_legend`/统一 `legp()`。
- **参考图**：`out/ref.png`
