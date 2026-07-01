# Archetype ㉑ — 多模型 ROC 曲线 + AUC

## 结论一句话
在同一张图叠加多个诊断/预后模型的 ROC 曲线，图例标各自 AUC + 95% CI；对比"基因组模型 vs 临床模型 vs 单基因"的区分能力。临床/诊断标志物 Figure 常客。

## 调用方式

```r
source("archetypes/_lib/figure_setup.R")
source("archetypes/_lib/synth_data.R")
library(pROC)
d <- synth_roc(seed = 55)   # data.frame(label, 三个模型分数)
r <- pROC::roc(d$label, d[["Model A (genomic)"]], direction = "<")
ci <- pROC::ci.auc(r)       # DeLong 95% CI
# 详见 plot.R：多模型循环 → 1-spec vs sens 用 geom_path，图例带 AUC(CI)
```

## 关键点

| 项 | 说明 |
|---|---|
| **`direction = "<"`** | 显式指定"分数越高越可能为阳性"，避免 pROC 自动翻转导致 AUC<0.5 的诡异结果 |
| **AUC 95% CI** | `ci.auc()` 返回 `c(low, auc, high)`（DeLong 法）；图例应带 CI，不能只报点估计 |
| **`coord_equal()`** | ROC 必须正方形（1:1），否则视觉扭曲对角线与曲线关系 |
| **对角参考线** | `geom_abline(slope=1)` = 随机分类基线，必须在 |

## 常见翻车点

### 渲染陷阱
1. **曲线不排序 → geom_path 乱连**：按 (model, fpr, tpr) 排序后再画，否则折线来回穿插。
2. **省了对角线**：无 0.5 基线读者无法判断模型是否优于随机。
3. **AUC 只报点值**：不带 CI 时无法判断两模型 AUC 差异是否显著（须 `roc.test` DeLong 检验）。
4. **图例过长压图**：AUC(CI) 文字长，图例内嵌右下角 + 缩字号，别占正图。

### 分析严谨陷阱
5. **训练集 ROC 虚高**：在建模同一批数据上画 ROC 是乐观估计；须交叉验证 / 独立测试集 / bootstrap 校正，注明 AUC 来自训练还是验证。
6. **AUC 高 ≠ 临床有用**：类别不平衡时 AUC 掩盖低阳性预测值；须并报敏感度/特异度/PPV 在选定阈值下的表现，必要时补 PR 曲线（precision-recall，罕见事件更诚实）。
7. **模型比较要配对检验**：两条 ROC 谁更好须 `pROC::roc.test()`（DeLong）报 p，不能仅凭 AUC 数值大小或 CI 是否重叠下结论。
8. **阈值选取须预先声明**：Youden 最优切点若在同一数据上选又评估，等于数据窥探；切点选取方法须报告并在独立数据验证。

## 参考输出
- `out/ref.png` — 2598×2598 px（600 dpi，白底），QA PASS（0 flags）
- `out/ref.pdf` — 矢量版
