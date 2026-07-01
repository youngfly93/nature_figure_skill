# Archetype ⑰ — KM 生存曲线 + number-at-risk 表

## 结论一句话
分层 Kaplan–Meier 生存曲线 + 删失标记 + log-rank/Cox p + HR + 下方 number-at-risk 风险表；临床癌症报告第一高频图（与 `clinical-forest` 的 Cox HR 森林图互补：森林图讲"哪些因素"，KM 讲"生存本体"）。

## 调用方式

```r
source("archetypes/_lib/figure_setup.R")
source("archetypes/_lib/synth_data.R")
df <- synth_km(seed = 51)   # data.frame(time, status, group=High/Low)

# nature_km 已内置全套（分层曲线 + 删失 + log-rank/Cox + HR + 风险表）
fig <- nature_km(df, time = "time", status = "status", group = "group",
                 levels = c("High","Low"),
                 title = "Overall survival by biomarker",
                 time_lab = "Time (months)", surv_lab = "Overall survival",
                 legend_title = "Biomarker",
                 risk_table = TRUE, show_cox_p = TRUE)
save_nature(fig, file.path(out, "ref"), width_mm = 110, height_mm = 115)
```

## 关键参数（nature_km）

| 参数 | 默认 | 说明 |
|------|------|------|
| `group` / `value` | — | 二选一：`group` 传现成分组列；`value` 传连续 biomarker + `split="median"` 自动二分 |
| `levels` | `NULL` | 显式锁分组顺序（如 `c("High","Low")`） |
| `risk_table` | `TRUE` | 底部 number-at-risk 表（患者随时间流失，投稿必备） |
| `show_cox_p` | `TRUE` | 同时标 log-rank p 与 Cox p；2 组时附 HR(95% CI) |
| `cols` | High/Low 语义色 | 多组时传 `nature_group_cols(levels)` |

## 常见翻车点

### 渲染陷阱
1. **删失标记必须在**：`nature_km` 用 `shape=3` 竖线标删失点；缺了读者会把"曲线走平"误读为"无人退出"。
2. **>2 组无 HR**：`nature_km` 只在恰好 2 组时算 HR/Cox；≥3 组只给 log-rank，别在 caption 硬写 HR。
3. **风险表时间刻度要与曲线对齐**：内部已用同一 `breaks`，自改 x 轴范围时两块会错位。
4. **patchwork 拼装**：返回的是 KM+风险表的 patchwork 对象，加 caption 用 `+ plot_annotation(...)`，不是 `+ labs()`。

### 分析严谨陷阱
5. **log-rank p 只反映关联，不代表独立预后**：主张"独立预后因子"前必须多变量 Cox（见 `clinical-forest`），不能只凭 KM 分层显著下结论。
6. **分组切点不能数据驱动后不报**：median/最优切点（maxstat）会抬高假阳性；切点方法与阈值必须在方法中写明，最优切点须多重比较校正。
7. **随访不足 / 删失非随机**：随访时间短则末端曲线由极少数人决定，置信带极宽；informative censoring（因病重退出）会偏倚估计——须报中位随访时间与删失比例。

## 参考输出
- `out/ref.png` — 2598×2716 px（600 dpi，白底），QA PASS（0 flags）
- `out/ref.pdf` — 矢量版
