# Archetype ⑯ — ggpubr 带*箱线（stat_compare_means）

**参考图：** `out/ref.png` / `out/ref.pdf`
**数据：** `synth_box(seed=32)`，n=160，4组（Ctrl / LowDose / HighDose / Combo）
**配色：** ggsci npg（经 ggpubr `palette="npg"` 局部使用；不改 nature_theme.R 默认配色）

---

## 图型说明

箱线图展示4个治疗组（Ctrl / LowDose / HighDose / Combo）的表达量分布，叠加 jitter 散点。
两两比较（vs Ctrl）用 Wilcoxon 秩和检验，显著性以星号标注（`stat_compare_means`，`label="p.signif"`）；
全局多组差异用 Kruskal-Wallis 检验，p 值标注在图顶（`label.y = max(d$value) + 2.2`）。

**本次合成数据结果：**
- Ctrl vs LowDose：ns（p ≥ 0.05，本 seed 抽样下未达显著——见分析翻车点④，勿过度解读单次抽样）
- Ctrl vs HighDose：\*\*\*\*（p < 0.0001）
- Ctrl vs Combo：\*\*\*\*（p < 0.0001）
- 全局 Kruskal-Wallis：p < 2.2e-16

---

## 常见翻车点（渲染 + 分析，双重）

### 渲染翻车点

1. **`comparisons` 列表配对顺序**：每个元素必须是长度为2的字符向量，且组名须与 `x` 轴 factor levels 完全匹配（大小写/空格敏感）。若组名不一致会静默跳过或报错，导致括号消失。

2. **`label.y` 与须状（bracket）重叠**：全局 KW 的 `label.y` 应设为 `max(d$value) + 足够的偏移量`（本例 +2.2）。偏移量不足时 KW 标签会压在最高一个显著性括号上；偏移量过大会超出图框。建议先跑后目检，必要时手动调整或配合 `scale_y_continuous(expand=...)`。

3. **jitter 透明度遮箱体**：`add.params=list(size=0.6, alpha=0.5)` 控制散点大小与透明度。size 过大或 alpha 过高会遮住箱体的四分位线；alpha 过低则散点消失。建议 size ≤ 1、alpha 0.4-0.6。

4. **ggpubr 与 ggplot2 版本兼容**：`stat_compare_means` 在 ggplot2 4.x 下偶有内部 layer 接口变更警告，但通常不影响渲染。若出现 `method` 参数报错，应显式指定 `method="wilcox.test"`（两组）或 `method="kruskal.test"`（多组），而不是依赖默认值。

5. **`ggboxplot` 输出为 ggplot 对象**：可直接叠加 `+` ggplot2/ggpubr 图层，但不能传入 `patchwork` 的 `wrap_plots`（需先转换）。`theme_nature()` 覆盖后部分 ggpubr 内置主题样式（如轴线粗细）会被重置，须在 `+theme_nature()` 之后追加微调。

6. **配色冗余（设计克制权衡）**：本图 `color="group"` 给 4 组各上一色，但组别已在 x 轴标注、图例也关了——颜色此处**纯装饰、不携带额外信息**，严格按设计克制护栏（①·6「≤3 主色」）应只用单色或按剂量做有序渐变。这里**有意保留** ggsci npg 四色，因本 archetype 的目的之一是演示期刊调色板用法；真实交付中，若颜色不编码第二个变量（如批次/亚型），优先单色箱体或 `scale_fill_journal()` 做有序映射，把颜色额度留给真正承载信息的维度。

---

### 分析翻车点（严谨性）

1. **`*` 只表示 p 值阈值，不代表效应量**：`****` (p<0.0001) 不意味着临床意义显著；组间差异可能在统计上极显著但效应量极小（如 Cohen's d < 0.2）。在论文中必须同时报告效应量（如 Cohen's d、rank-biserial r）和置信区间，不能仅凭星号得出结论。

2. **默认非参检验的假设须核对**：`stat_compare_means` 两组默认 Wilcoxon 秩和检验、多组默认 Kruskal-Wallis，均假设分布形态相同（仅位置参数不同）。若各组分布形态差异较大（如方差不等），Wilcoxon 的原假设是"分布相同"而非"中位数相同"，解读需注意。数据正态时应优先考虑 t 检验（两组）或单因素 ANOVA（多组），以获得更高检验效能。

3. **多重两两比较未校正假阳性风险**：本图对3对比较（vs Ctrl）未做多重校正（如 Bonferroni、BH）。若同时做 k(k-1)/2 对全排列比较，假阳性概率急剧上升。在正式分析中须指定 `p.adjust.method`（如 `p.adjust.method="BH"`），或改用对比检验（Dunnett's test）。本例仅做 vs Ctrl 的3对比较，属于预设对比（planned comparisons），假阳性风险相对较低，但仍建议报告未校正/已校正两套结果。

4. **合成数据的代表性局限 + 别把单次抽样当定论**：本图用 `synth_box(seed=32)` 构造，组间差异由 `base` 偏移量硬编码，不反映真实生物变异。注意 LowDose 的 ns **不是因为效应本身不可检测**——设定偏移 0.6 / σ=0.8 对应名义 Cohen's d≈0.75（大效应），n=40/组下 power 实际 >0.9，理论上应当显著；这里 ns 是**该 seed 的一次抽样实现**（realized d 恰好偏小）。教训：单次实验/单个 seed 的"显著与否"有抽样波动，**不能据一次 ns 断言"无效应"**，须看效应量点估计 + CI + 必要的重复/power 分析，而非只读星号。

---

## 关键参数速查

```r
ggpubr::ggboxplot(d, x="group", y="value",
                  color="group", palette="npg",        # ggsci npg（局部）
                  add="jitter", add.params=list(size=0.6, alpha=0.5))

stat_compare_means(comparisons=cmp, label="p.signif",
                   method="wilcox.test", size=2.4)     # 两两 vs Ctrl

stat_compare_means(method="kruskal.test",
                   label.y=max(d$value)+2.2, size=2.4) # 全局 KW
```

**显著性阈值（ggpubr 默认）：** ns p≥0.05 · \* p<0.05 · \*\* p<0.01 · \*\*\* p<0.001 · \*\*\*\* p<0.0001
