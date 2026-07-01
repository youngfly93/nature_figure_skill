# Archetype ⑲ — SBS-96 突变 signature

## 结论一句话
单碱基替换（SBS）突变谱：6 种替换型（C>A/C>G/C>T/T>A/T>C/T>G）× 16 种三核苷酸上下文 = 96 通道条形图；癌症基因组展示突变过程（COSMIC signature 分解、SBS1 老化/SBS4 吸烟等）的标准图。

## 调用方式

```r
source("archetypes/_lib/figure_setup.R")
source("archetypes/_lib/synth_data.R")
sig <- synth_sbs96(seed = 53)   # 96 行：substitution / context / tri / fraction
# 真实数据：把 fraction 换成 MutationalPatterns/maftools 提取的 96-通道向量（顺序须为 COSMIC 顺序）
```
详见 `plot.R`（ggplot 原生实现，6 分面 + COSMIC 色码）。

## 配色规则（**领域约定优先于 house「≤3 色」通则**）
SBS-96 有**国际公认的 6 色码**（读者靠色码认替换型）：C>A `#02BCED`（蓝）· C>G `#010101`（黑）· C>T `#E32926`（红）· T>A `#CBCACB`（灰）· T>C `#A1CE63`（绿）· T>G `#EDC8C4`（粉）。**这是刻意覆盖 ≤3 色通则**，与 circos 多轨道、oncoprint 变异类型同理——改用 theme 色会让图不可辨认。此例是"领域标准 > 通用设计规则"的合法例外，已在此显式标注。

## 常见翻车点

### 渲染陷阱
1. **96 通道顺序必须是 COSMIC 顺序**：先按 6 替换型，型内按三核苷酸（5' 碱基变化最慢：ACA,ACC,ACG,ACT,CCA...）。顺序错则与文献图对不上、signature 分解错位。`synth_sbs96` 用 `expand.grid(three, five)` 保证此顺序。
2. **x 轴 96 标签太密**：只显三核苷酸（`family="mono"`, size≈2.4），靠分面 strip 标替换型；别把 `C[C>T]G` 全名塞进 x 轴。
3. **纯 ggplot 无法按分面上不同颜色 strip 条**：本库用"条形本身着 6 色 + strip 标签"实现，已足够可辨；要完全复刻 COSMIC 的"彩色 strip 顶条"需 `ggh4x::strip_themed` 或 `MutationalPatterns::plot_96_profile()`。
4. **y 轴用计数还是占比**：多样本对比须用 fraction（归一化），否则突变负荷高的样本通吃。

### 分析严谨陷阱
5. **signature ≠ 病因**：从 96 谱 refit 到 COSMIC signature 只是数学分解，"检出 SBS4"不等于"该患者吸烟"，须结合临床，措辞用"consistent with"。
6. **低突变负荷样本 signature 不可信**：突变数 < 数十时，96 谱统计噪声极大，refit 的 signature 贡献置信度低，须报每样本突变数、过滤低负荷样本。
7. **de novo 提取 vs refit**：`extractSignatures`（NMF de novo）与"往已知 COSMIC 上 refit"是两回事；signature 数目 k 的选择、cosine similarity 阈值须报告，别把 refit 说成"发现新 signature"。
8. **测序/建库偏好**：FFPE 样本的 C>T artifact、氧化损伤 G>T artifact 会污染谱，须说明是否做 artifact 过滤。

## 参考输出
- `out/ref.png` — 4322×1606 px（600 dpi，白底），QA PASS（0 flags）
- `out/ref.pdf` — 矢量版
