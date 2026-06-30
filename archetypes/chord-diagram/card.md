# Archetype: Chord Diagram (circlize)

## 一句话结论
用弦图展示 6 种细胞类型间两两互作强度（计数矩阵），弦宽正比于互作数量，扇区色来自 `nature_pal_anno`。

## 适用场景
- 细胞间通讯（CellChat/NicheNet 输出矩阵）
- 组学间关联（两类别交叉频次）
- 集合交叉可视化（有向 / 无向均可）

## 关键参数
| 参数 | 本例设定 | 说明 |
|------|----------|------|
| `m` | `synth_chord(6, 24)` — 6×6 Poisson 矩阵，对角=0 | 输入必须为命名方阵 |
| `grid.col` | `nature_pal_anno[1:6]` | 扇区颜色；名称与 rownames 对应 |
| `transparency` | 0.35 | 弦透明度；0=不透明 |
| `directional` | 1 | 1=有向（行→列），0=无向 |
| `direction.type` | `c("diffHeight","arrows")` | 同时用高度差 + 大箭头标示方向 |
| `link.arr.type` | `"big.arrow"` | 箭头样式 |
| `preAllocateTracks` | 1 | 为 sector label 预留轨道 |
| `gap.degree` | 3 | 扇区间隙（度） |

## 渲染常见翻车点

1. **circos.clear() 必须在首尾各调一次**：`draw_chord()` 开头 `circos.clear()` 重置全局状态；结尾再次 `circos.clear()` 释放，否则第二次渲染（PDF）会叠加到第一次状态上。

2. **sector label 需 preAllocateTracks=1 配合 circos.trackPlotRegion**：若只用 `annotationTrack="name"` 则标签被 chordDiagram 默认放在网格内侧，无法控制 facing/cex；改为先预留一条空轨道、再 `circos.trackPlotRegion(track.index=1, …)` 自定义文本，才能 `facing="clockwise" + niceFacing=TRUE`。

3. **base 图直接用 agg_png / cairo_pdf 导出，不走 save_nature()**：`chordDiagram` 是 base graphics，`save_nature()` 内部假设 ggplot 对象，不可混用。务必用 `agg_png(…); draw_chord(); dev.off()` 的显式设备模式。

4. **Rplots.pdf 残留**：base 图在交互/批处理 R 会话中可能自动创建 `Rplots.pdf`；脚本末尾必须 `unlink("Rplots.pdf")` 清除，否则触发 QA 残留检查失败。

5. **参数名变更**：旧版 circlize 用 `annotationTrackHeight`；新版 `chordDiagram` 的 `direction.type="arrows"` 需搭配 `link.arr.type`；如报 "unused argument"，参照 `?chordDiagram` 当前文档逐参数确认。

## 分析严谨陷阱（翻车点 · 解读层）

6. **弦宽 = 互作强度/计数，不等于已验证的因果互作**：CellChat 等工具输出的通讯概率是统计推断，本质是配体-受体共表达的相关性；弦图可视化这一数值，但无法证明信号真正从 A 传到 B，解读时应写"潜在互作强度"而非"A 激活 B"。

7. **有向箭头（directional=1）需数据真正支持方向性**：若原始矩阵是对称的（如皮尔逊相关），强加 `directional=1` 会产生误导性箭头；仅当矩阵本身代表有方向意义（发送方→接收方、配体→受体计数不对称）时才启用箭头。本例 Poisson 矩阵非对称，有方向标注属展示性 demo，论文中需真实数据支撑。

8. **对角线已置 0，真实数据需说明是否计入自互作**：`diag(m) <- 0` 排除自身到自身的连线；若研究问题本身含自分泌（autocrine），应在图注中明确说明"自互作未展示"或"对角项已置零"，避免读者误以为无自分泌。

## 导出规格
- PNG 600 dpi, 130×130 mm → 约 3070×3070 px（QA 门槛 ≥1200 px）
- PDF via cairo_pdf，Helvetica 字体，可在 Illustrator 编辑
- 背景白色（`background="white"` + QA 角亮度 1.0）
