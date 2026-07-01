# Archetype ㉒ — 全基因组 CNV 频率谱（GISTIC 样）

## 结论一句话
沿基因组线性坐标展示各位点的拷贝数扩增频率（红，向上）与缺失频率（蓝，向下）；一图看清哪些染色体臂/区段在队列中反复扩增或缺失。癌症基因组 CNV landscape 常客（与 `genome-circos` 圈图互补：圈图是单样本多轨圆形，此图是队列频率线性谱）。

## 调用方式

```r
source("archetypes/_lib/figure_setup.R")
source("archetypes/_lib/synth_data.R")
cnv <- synth_cnv_freq(seed = 56)   # data.frame(chr, bin, gain, loss)——各 bin 的 gain/loss 频率(0–1)
# 真实数据：把 gain/loss 换成 GISTIC2 的 amplification/deletion frequency（或 G-score）；bin 换成基因组位置
```
详见 `plot.R`（累积 x 坐标 + 染色体交替底带 + 边界线 + 居中标签）。

## 关键点

| 项 | 说明 |
|---|---|
| **gain 上 / loss 下** | loss 频率取负值向下画（`freq = -loss`），0 线分隔；y 轴用 `abs()` 显示两向都为正百分比 |
| **累积 x 坐标** | 各染色体 bin 数累加得 offset，边界画竖线、中心放标签（1–22） |
| **交替底带** | 奇数染色体加浅灰 `geom_rect` 底带，帮助区分相邻染色体 |
| **红/蓝双色** | `nature_sig_col[["Up"]]`/`[["Down"]]`——2 色即够，符合 house ≤3 色 |

## 常见翻车点

### 渲染陷阱
1. **染色体边界/标签错位**：offset 与 cumsum 要一致（offset=前缀和、bounds=cumsum、center=offset+size/2）；错一位则标签飘。
2. **loss 忘了取负**：两向都画向上就成了普通柱图，失去"gain/loss 对称"的 GISTIC 语义。
3. **y 轴负值显示为负**：用 `labels=function(v) percent(abs(v))` 让下半轴也显正百分比。
4. **bin 太密无边框**：`geom_col(width=1)` 紧贴，别留白缝。

### 分析严谨陷阱
5. **频率谱须先按 purity/ploidy 校正**：未校正的原始拷贝数受肿瘤纯度稀释，跨样本频率会系统性偏低/偏高；须说明是否 ABSOLUTE/校正。
6. **GISTIC G-score vs 单纯频率**：GISTIC2 的 q 值/G-score 已校正基因组长度与背景，比单纯"出现频率"更能定位显著 driver 区段；若只画频率，别把高频区直接称"显著扩增峰（significant peak）"——那是 GISTIC 统计结论。
7. **focal vs arm-level 要分清**：宽区段（臂级）与窄峰（focal）生物学意义不同，focal 高幅峰更可能含 driver；结论须区分尺度。
8. **参考基因组版本**：位点坐标依赖 hg19/hg38，注释 driver 基因时须版本一致，否则区段-基因对应错位。

## 参考输出
- `out/ref.png` — 4322×1795 px（600 dpi，白底），QA PASS（0 flags）
- `out/ref.pdf` — 矢量版
