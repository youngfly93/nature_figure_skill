# 复合多面板叙事图（分子亚型故事）

- **适用场景**：需要在单张图中将多条证据链（表达量 / 生存 / 通路 / PCA）串联成一个完整论点。这是产生"高影响力"视觉冲击的最大来源——依靠**图面构图与叙事逻辑**，而非单个面板的复杂度。
- **数据形状**：每个面板使用各自的数据：表达矩阵 → 热图 + PCA；生存表 → KM 曲线；富集表 → 点图。
- **依赖包**：ComplexHeatmap、grid、ggplot2、patchwork、survival、ragg、svglite、nature_theme.R。
- **拼图机制——主图布局（patchwork design）**：
  - 面板 A（热图）通过 `grid.grabExpr(ComplexHeatmap::draw(...))` 转为 grob，再用 `patchwork::wrap_elements(full = ht_grob)` 封装。
  - 面板 B/C/D 均为 house 函数直接返回的 ggplot 对象。
  - 全部 4 个面板用 `plot_layout(design="AB\nAC\nAD", widths=c(1.25,1))` 拼合——A 跨越左列全部 3 行；B/C/D 在右侧垂直堆叠。
  - `plot_annotation(tag_levels="A")` 自动添加大写面板标签。
- **所用 house 函数（全部 4 个面板）**：
  - `nature_hm_anno` + `nature_heatmap` + `nature_hm_gp` → 面板 A（带列注释轨道、按亚型列分割的热图主角）。注意：必须向 `nature_hm_anno()` 传入 `col = list(Subtype = sub_cols)` 以确保热图注释条中的亚型颜色与其他面板一致。
  - `nature_pca` → 面板 B（带 95% 椭圆和方差贡献轴标签的 PCA 散点图）。
  - `nature_enrich_dot` → 面板 C（富集点图；当数据列名为 "Term" 而非 "Description" 时须显式传入 `term="Term"`）。
  - `nature_km(risk_table=FALSE)` → 面板 D（直接返回 ggplot；无需提取 `$plot`）。
- **白色背景保证**：`save_all()` 使用 `ragg::agg_png(..., bg="white")` 和 `cairo_pdf(..., bg="white")`；在设备调用内部执行 `print(p)` 以正确渲染 patchwork。
- **`nature_enrich_dot` 列名映射**：自动检测 `GeneRatio` 为评分列、`p.adjust` 为 p 值列、`Count` 为计数列——但若列名不是 "Description"，须显式传入 `term` 参数。
- **跨面板共享颜色**：调用一次 `nature_group_cols(levels)` 生成亚型调色板，并将其同时传入 `nature_hm_anno(..., col=list(Subtype=sub_cols))`、`nature_pca(..., cols=sub_cols)` 和 `nature_km(..., cols=sub_cols)`，确保热图注释条（面板 A）、PCA 散点（面板 B）和 KM 曲线（面板 D）中同一亚型颜色完全一致。

## 常见失误——渲染

1. ComplexHeatmap 不是 ggplot：直接用 patchwork 会报错 → 必须先通过 `grid.grabExpr` + `wrap_elements(full=...)` 转换。
2. 跨面板字体大小不一致 → 热图文字用 `nature_hm_gp()`，ggplot 面板通过 house 函数内的 `theme_nature()` 控制。
3. 白色背景未传递 → 每次设备调用都须传入 `bg="white"`；patchwork 的注释主题无法保证角落亮度。
4. `nature_km` 默认 `cols` 仅适合 2 组——有 3 组及以上时，须通过 `nature_group_cols(levels(grp))` 生成显式命名向量。
5. 仅导出 PNG → 务必同时导出 PDF（矢量图，可供印刷）和 SVG。
6. 残留 `Rplots.pdf` → 脚本末尾调用 `unlink("Rplots.pdf")` 清理。

## 常见失误——分析严谨性（亚型故事）

1. **PCA 分离 ≠ 因果**：无监督聚类在 PC 空间中的分离是描述性结果；没有因果证据，不能暗示亚型差异导致表型结局。
2. **KM 差异需排除混杂**：朴素 log-rank p 值反映的是亚型与生存的关联，而非独立预后意义——分期、年龄、治疗均为潜在混杂因素；提出临床主张前须进行多变量 Cox 分析。
3. **富集 FDR 须报告**：富集 p 值应始终经 FDR（BH 法）校正并注明阈值；原始 p 值会严重高估显著性。
4. **合成数据不是证据**：本原型使用 `synth_expr/synth_survival/synth_enrich` 生成——全为模拟数据。图注必须明确说明；切勿将此输出用作结果图。
5. **过度解读 PCA 椭圆**：95% 置信椭圆假设多元正态分布；在样本量小或各组不均衡时可能产生误导。

- **参考图**：`out/ref.png`
