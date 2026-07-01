# Archetype ⑱ — 列线图 nomogram（多变量 Cox 预测）

## 结论一句话
把多变量 Cox（或 logistic）模型的各协变量转成"打分尺"，读者手动累加各变量得分 → Total Points → 读出 1/3/5 年生存概率；临床预测模型 Main Figure 标配。

## 调用方式

```r
source("archetypes/_lib/figure_setup.R")
source("archetypes/_lib/synth_data.R")
library(rms)
d <- synth_nomogram_cohort(seed = 52)         # 生存结局 + Age/Stage/Grade/Biomarker
dd <- datadist(d); options(datadist = "dd")
f  <- cph(Surv(time, status) ~ Age + Stage + Grade + Biomarker, data = d,
          surv = TRUE, x = TRUE, y = TRUE)
surv <- Survival(f)
nom  <- nomogram(f, fun = list(function(x) surv(12, x), function(x) surv(36, x), function(x) surv(60, x)),
                 funlabel = c("1-year survival","3-year survival","5-year survival"))
# base graphics → 不走 save_nature，用 agg_png/cairo_pdf 显式设备（见 plot.R），末尾 unlink("Rplots.pdf")
```

## 关键点

| 项 | 说明 |
|---|---|
| **必须先 `datadist`** | `options(datadist="dd")` 未设 → `cph`/`nomogram` 报错找不到分布 |
| **`cph(..., x=TRUE, y=TRUE, surv=TRUE)`** | 后续 `Survival()`、`calibrate()`、`validate()` 都依赖保存的设计矩阵 |
| **base 图不用 save_nature** | nomogram 是 base graphics，`save_nature` 内部 `print()` 不适用；显式 `agg_png(...); plot(nom); dev.off()` |
| **字体** | `par(family = NATURE_FONT)`（Helvetica，CJK 安全） |

## 常见翻车点

### 渲染陷阱
1. **忘设 `datadist`**：最常见报错 `dataset ... not found`——`nomogram` 需要每个预测变量的分布范围。
2. **`fun.at` 超出可达概率范围**：某些 Total Points 对应不到 0.95 生存概率时该刻度被截断，属正常；别硬填不可达值。
3. **`xfrac` 太小**：左侧变量名与刻度轴重叠——`xfrac=0.30~0.35` 给变量名留空间。
4. **Rplots.pdf 残留**：base 图脚本末尾必须 `unlink("Rplots.pdf")`。

### 分析严谨陷阱
5. **nomogram 不能单独出——必须配 calibration + C-index/AUC**：只画 nomogram 不报区分度（C-index）与校准（`rms::calibrate` bootstrap 校准曲线）是审稿高频拒稿点；预测模型三件套 = nomogram + calibration + (可选) DCA 决策曲线。
6. **过拟合**：变量数相对事件数过多（EPV<10）时点估计不稳；须 `validate(f, B=...)` bootstrap 报 optimism-corrected C-index，别只报表观值。
7. **外部验证缺失**：内部 bootstrap ≠ 外部队列验证；仅内部验证的模型泛化性存疑，须在讨论中说明。
8. **连续变量线性假设**：`cph` 默认线性，真实关系非线性时（如 Age）应考虑 `rcs()` 样条，否则打分尺失真。

## 参考输出
- `out/ref.png` — 4251×2834 px（600 dpi，白底），QA PASS（0 flags）
- `out/ref.pdf` — 矢量版
