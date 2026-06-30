# Archetype ⑮ — 森林图（Cox 多变量 HR）

## 结论一句话
多变量 Cox 模型中各协变量的 HR 及 95% CI，一图展示哪些因素显著（红点）与哪些不显著（灰点），并附数值标注。

## 调用方式

```r
source("archetypes/_lib/figure_setup.R")
source("archetypes/_lib/synth_data.R")
df <- synth_forest(seed = 31)   # data.frame(term, HR, lo, hi, p, n)

p <- nature_forest(df, title = "Multivariable Cox forest (synthetic demo)") +
  labs(caption = "Synthetic data, style demo only (not real results). set.seed(31); HR with 95% CI.") +
  theme(plot.caption = element_text(size = 6, colour = "grey45", hjust = 0, family = NATURE_FONT))

save_nature(p, file.path(out, "ref"), width_mm = 120, height_mm = 100)
```

## 关键参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `order_by_hr` | `TRUE` | 按 HR 从小到大排序；改 `FALSE` 则保持输入顺序 |
| `sig_level` | `0.05` | p 阈值，低于此值点着红色 |
| `xlim` | `NULL` | 自动 range(lo, hi, 1)；手动限制可截断超长 CI |
| `show_label` | `TRUE` | 右侧显示 "HR (lo–hi)" 数值标注 |
| `xlab` | `"Hazard ratio (95% CI)"` | x 轴标签 |

## 常见翻车点

### 渲染陷阱

1. **x 轴是 log10 刻度，非线性**：CI 在 log 轴上左右不对称属正常；若强制线性轴（`trans="identity"`），视觉上会严重扭曲小 HR 的间距，误导读者。
2. **HR=1 参考线必须存在**：虚线标注"无效应"基准线，缺失则读者无法判断方向（保护 vs. 风险）。
3. **CI 越界截断**：当个别 CI 极宽时，`xlim` 裁切会隐去部分须线端点——务必在 caption 注明截断范围（如 "CI truncated at x=0.1/10"），不能静默截断。
4. **图宽不足，数值标注被压**：`show_label=TRUE` 时右侧数值标注需要额外空间；`width_mm` 过窄会导致标注与图形重叠——建议 ≥120 mm（单栏），大型 forest 用双栏 183 mm。
5. **图例颜色与术语不对应**：`sig/ns` 标签务必与论文方法中的显著性定义一致；修改 `sig_level` 后须同步更新 `scale_colour_manual` 的 `labels`（`nature_forest` 内部已自动格式化，但手动覆盖时需注意）。

### 分析严谨陷阱

6. **多变量校正与否，结论可能相反**：单变量 Cox 中 HR 显著的变量，进入多变量模型后可能因与其他协变量的混淆而变为 ns，反之亦然。森林图必须在标题/方法中注明是"单变量"还是"多变量"模型，以及纳入的协变量列表（如 Age + Stage + Grade），不能只写"Cox 分析"。
7. **宽 CI（小 n）的 HR 点估计不稳定**：CI 极宽的变量（如 n<30 的亚组）其 HR 置信度极低，不应只报 HR 点估计或仅依据 p 值下结论——应同时展示 n 或在图注警告小样本不稳定性。
8. **多重比较未校正时 p 值偏乐观**：同时检验多个协变量（如本例 9 个），原始 p 值存在 I 型错误膨胀；若未做 Bonferroni/FDR 校正，红色"显著"点数量可能虚高——需在 caption 或方法节注明是否校正。

## 参考输出

- `out/ref.png` — 2834×2362 px（600 dpi，白底），QA PASS
- `out/ref.pdf` — 矢量版，可投稿/Illustrator 再编辑
