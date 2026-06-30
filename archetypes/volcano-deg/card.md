# 火山图（差异表达，ggsci NPG + ggrepel）

- **何时用**：双组差异表达/蛋白/甲基化，想一图展示效应量(log2FC) × 显著性(-log10 adjP)并标注关键基因。差异分析 Main/补充图常客。
- **数据形状**：data.frame(基因, logFC, 校正 P(adj.P.Val))；阈值 |log2FC| 与 FDR 自定。
- **核心依赖**：ggplot2、ggrepel、ggsci、patchwork、figure_setup.R。
- **配色规则**：用 ggsci 期刊配色(`pal_npg("nrc")` 红/深蓝)做 Up/Down，ns 用浅灰；≤3 主色。
- **常见翻车点（渲染）**：① ns 点不降透明/不减小 → 糊成一团盖住信号；② 标签不用 ggrepel → 互相重叠；③ 标全部显著基因 → 太挤，应只标 top N；④ 坐标轴用纯文本 → 用 `expression(log[2]~..., -log[10]~italic(P))` 排版；⑤ 灰底+默认配色+大图例 = chartjunk → theme_nature + 图例内置。
- **常见翻车点（分析严谨）**：⑥ **必须用校正后 P(FDR/adjP)，不是原始 p**——12000 基因多重检验，原始 p<0.05 假阳性成片；⑦ **高 -log10P ≠ 生物学重要**：极小 p 可能来自高表达/低方差基因，需结合效应量(log2FC)与表达量；⑧ **标注基因别只挑"故事好"的**——cherry-pick 标注会误导，应按统一规则(top |log2FC| 或 top 显著)选并说明。
- **参考实现**：`archetypes/volcano-deg/`
