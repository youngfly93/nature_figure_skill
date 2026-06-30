# Archetype: UpSet 集合交集（UpSetR）

## 一句话结论
用 UpSet 图展示 4 个多组学集合（DEG_up/DEG_down/Methylated/CNV_gain）的交集模式，顶部交集大小柱图 + 点矩阵 + 左侧集合大小柱图，替代 Venn 图处理 ≥4 集合的 overlap 可视化。

## 适用场景
- 多组学 overlap：差异基因 × 甲基化 × CNV × 蛋白组等集合交叉
- 多比较组 DEG 重叠：不同处理/时间点的上调/下调基因共性
- 通路/基因集 overlap：≥4 个 gene set 间共有基因数量展示
- 代替 Venn 图（≥4 集合时 Venn 图严重重叠、不可读）

## 关键参数
| 参数 | 本例设定 | 说明 |
|------|----------|------|
| `data` | `fromList(sets)` — 4 集合转二进制矩阵 | 必须用 `fromList()` 预处理命名列表 |
| `nsets` | `length(sets)` = 4 | 显示全部集合；默认只显示 5 |
| `order.by` | `"freq"` | 按交集大小降序排列；可改 `"degree"` 按集合数 |
| `main.bar.color` | `nature_seq[5]` (#3B6BB0) | 顶部交集大小柱的颜色 |
| `sets.bar.color` | `nature_pal_anno[1]` (#7FA6C9) | 左侧集合大小柱的颜色 |
| `matrix.color` | `nature_div[1]` (#9B2E25) | 矩阵点和连线颜色（填充交集） |
| `shade.color` | `"grey85"` | 矩阵行交替底纹色 |
| `text.scale` | `c(1.1,1.0,1.0,0.9,1.0,0.9)` | 6 槽位（见下方翻车点） |
| `mb.ratio` | 默认 `c(0.7,0.3)` | 顶部柱图与矩阵的高度比 |

## 渲染常见翻车点

1. **fromList() 转换不可跳过**：`UpSetR::upset` 接受的是二进制 0/1 矩阵（各列=集合，各行=元素），不能直接传命名列表。必须先 `mat <- fromList(sets)`；若输入格式错误，报 `Error in data[, i]`（无法定位）。

2. **text.scale 必须是 scalar 或长度 6 的向量**：UpSetR 1.4.x 中 `text.scale` 的 6 个槽位依次为：①交集大小标题、②交集大小刻度、③集合大小标题、④集合大小刻度、⑤集合名称、⑥柱顶数字。传错长度（如 5 或 7）会导致 `subscript out of bounds` 或静默截断，图形文字异常。

3. **base/grid 图：必须用 print() 触发渲染**：`UpSetR::upset()` 返回 grid 对象，在脚本模式下不会自动绘制到当前设备——必须 `print(upset(...))` 才能渲染到 `agg_png` 或 `cairo_pdf` 打开的设备中。忘记 `print()` 会输出空白图或 0-byte 文件。

4. **不可用 save_nature() 导出**：`save_nature()` 内部调用 `ggplot2::ggsave`，只适用于 ggplot 对象。UpSetR 是 base/grid 混合图，必须用 `agg_png(...)` + `print(upset(...))` + `dev.off()` 的显式设备流程；或等价地用 `png()`/`cairo_pdf()`。

5. **Rplots.pdf 残留**：R 批处理模式下若当前目录可写，grid 图可能自动写出 `Rplots.pdf`。脚本末尾必须 `unlink("Rplots.pdf")`，否则触发 QA 残留检查失败。

6. **order.by="freq" vs "degree"**：`"freq"` 按交集元素数量降序（最大交集在左）；`"degree"` 按参与集合数升序（单集合交集在左）。两种排序传达不同叙事：前者强调"最多共有成员的组合"，后者强调"逐步增加集合的层级结构"。投稿前确认叙事与图注一致。

## 分析严谨陷阱（翻车点 · 解读层）

7. **交集大小受各集合定义阈值影响，必须统一**：若 DEG_up 用 FDR<0.05+|logFC|>1，而 Methylated 用 差异甲基化 p<0.1，两者阈值严格程度不同，交集大小会被阈值选择人为放大/缩小。正确做法是在同一分析语境下统一阈值，或在图注中明确各集合的入选标准。

8. **大交集不等于生物学显著**：若 DEG_up 有 85 个基因、CNV_gain 有 50 个，它们在 200 个池中的随机交集期望值已有约 21 个。观察到的交集若未远超此期望值，"overlap"可能只是大集合的必然结果，而非真实生物学关联。应补做**超几何检验**（`phyper()`）或 Fisher 精确检验，并在图注中报告 p 值。

9. **集合来源若 batch / 平台不同，overlap 不可直接比较**：若 DEG 来自 RNA-seq、Methylated 来自 RRBS、CNV_gain 来自 SNP array，且各批次未做批次矫正，那么集合成员中可能混入批次噪声导致的假阳性，overlap 可能高估（共同批次效应）或低估（不同平台基因覆盖差异）。需说明数据来源并经批次矫正。

## 更美替代方案（本机未装）
`ComplexUpset`（CRAN）是 UpSetR 的现代替代，底层全部 ggplot2，支持：
- 在交集柱图顶部叠加自定义 ggplot panel（散点图、箱线图等）
- 完整 ggplot2 主题系统（`theme_minimal()` 等直接生效）
- 更灵活的配色、分面、标注

安装：`install.packages("ComplexUpset")`。**本机当前未安装，本 archetype 使用 UpSetR 实现。**

## 导出规格
- PNG 600 dpi, 160×110 mm → 3779×2598 px（QA 门槛 ≥1800 px，通过）
- PDF via cairo_pdf，Helvetica 字体，可在 Illustrator 编辑
- 背景白色（background="white" + QA 角亮度 1.0）
