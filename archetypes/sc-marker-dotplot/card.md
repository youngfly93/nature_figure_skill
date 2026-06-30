# Archetype: 单细胞 marker dotplot

## 图形说明

基因（行）× 细胞类型（列）点图：
- **点大小** = 该细胞类型中表达该基因的细胞比例（% expressing，>0 计数）
- **点颜色** = 该基因在各细胞类型的平均表达 z-score（跨细胞类型归一化，**红→高、蓝→低**，配色来自 `rev(nature_div)`，与库内其它热图色向一致）
- 基因顺序按 marker 定义排列；同一 celltype 的 marker 相邻，呈对角块状结构。

## 数据来源

`synth_scrna(seed=11)`（`_lib/synth_data.R`）：合成单细胞数据，每 celltype 4 个 marker 基因，log1p 计数矩阵。

---

## 常见翻车点

### 渲染陷阱

1. **点大小与颜色双编码需独立**：`size=pct` 与 `colour=z` 各自独立传达信息——不要将两者绑定同一变量（否则就是冗余编码），也不要用 `fill` 替代 `colour`（实心点 `geom_point` 不响应 `fill`）。

2. **按基因 z-score 才能显特异性**：若用原始均值着色，高表达基因会抢占颜色动态范围，低表达 marker 完全失色。`ave(..., FUN=scale)` 在基因内跨 celltype 做 z-score，才能看到每个 marker 的相对特异性。

3. **celltype 顺序控制**：`factor(celltype, levels=levels(ct))` 必须在 `agg` 构建后显式设定；若依赖字母序，对角块结构会被打乱，难以识别 marker 归属。

4. **axis.text.y 字号**：24 个 marker 基因在 150 mm 高图内，`size=4.5` 是下限；更小则不可读，更大则行距拥挤。不要用默认 `base_size`（8 pt）——会溢出图框。

5. **白底检查**：`theme_nature()` 已设 `plot.background=element_rect(fill="white")`，但若用 `theme_classic()` 不套 `theme_nature()`，默认灰底会导致 QA FAIL（角亮度 < 0.9）。

---

### 分析严谨陷阱

6. **pct 与 mean 双指标不可只看一个**：高 pct + 低 mean → 大量细胞有低水平"本底"表达，未必是真实 marker；低 pct + 高 mean → 少数细胞高度富集，可能是亚群特异。两个维度必须结合读图，不能只凭颜色（mean z）或只凭点大小（pct）下结论。

7. **z-score 反映"相对特异"而非"绝对高表达"**：一个基因在所有 celltype 均低表达时，z-score 仍会有红色峰值（相对最高那列），但绝对均值可能接近于 0（log1p 接近 0.4 本底）。报告时务必同时注明绝对均值范围，避免将背景噪音误读为特异高表达。

8. **marker 选择的循环论证风险**：若 marker 基因来源于对同一批数据做差异分析后再用 dotplot 展示，验证等同于在训练集上评估，无法说明特异性。需用独立数据集、文献已知 marker 或蛋白层面验证来打破循环。
