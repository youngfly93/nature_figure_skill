# Archetype ⑳ — 免疫浸润组成（堆叠占比 + 组间比较）

## 结论一句话
双面板：A) 每样本免疫细胞占比堆叠条（CIBERSORT/xCell/EPIC 等去卷积输出，Tumor/Normal 分面）；B) 关键 TME 细胞型（CD8 T / Treg / M2 巨噬）的组间 Wilcoxon 比较。肿瘤微环境（TME）Figure 常客。

## 调用方式

```r
source("archetypes/_lib/figure_setup.R")
source("archetypes/_lib/synth_data.R")
im <- synth_immune(seed = 54)   # list(fractions=样本×细胞型矩阵[行和=1], group, cells)
# 真实数据：fractions 换成 CIBERSORTx/immunedeconv 的占比矩阵；group 换成分组向量
```
详见 `plot.R`（A 堆叠 `geom_col` 分面 + B `ggpubr::stat_compare_means` 组间检验，`patchwork` 上下拼）。

## 配色规则（**领域必需 >3 色**）
免疫去卷积通常 10~22 个细胞型，**必然超过 house「≤3 色」通则**——用 `colorRampPalette(nature_pal_anno)` 插值出可区分的定性色板。这是"数据维度决定"的合法例外（与 alluvial 多类别同理）。堆叠顺序固定（`factor levels`），跨图保持同色同序。

## 常见翻车点

### 渲染陷阱
1. **占比未归一化**：堆叠条要求每样本行和=1（100%）；直接堆原始丰度/绝对分数会高低不齐、无法跨样本读构成。
2. **样本排序影响可读性**：组内按某关键细胞型占比排（本例按 M2）比乱序清晰得多。
3. **10+ 色难分辨**：相邻堆叠块颜色须拉开；`nature_pal_anno` 插值 + 固定顺序，别用彩虹或随机色。
4. **p 值标注压线**：`stat_compare_means` 默认标在顶端，`scale_y_continuous(expand=expansion(mult=c(.05,.15)))` 留上方空间防与离群点/须线重叠。

### 分析严谨陷阱
5. **去卷积占比是"相对比例"不是"绝对细胞数"**：CIBERSORT relative mode 各细胞型和为 1，"Treg 占比升高"可能只是别的细胞降了；须说明用 relative 还是 absolute mode，跨样本比较慎重。
6. **组间检验要匹配设计**：配对样本（同患者 Tumor/Normal）须用配对 Wilcoxon；多细胞型多组比较须 `p.adjust`（BH），否则假阳性膨胀。
7. **去卷积依赖 signature matrix 与平台**：LM22 基于外周血，用在实体瘤/单细胞平台可能不准；不同去卷积方法结果差异大，关键结论建议多方法交叉或单细胞验证。
8. **批次效应**：不同批次/测序深度的样本占比不可直接比，须说明是否批次校正。

## 参考输出
- `out/ref.png` — 4322×3118 px（600 dpi，白底），QA PASS（0 flags）
- `out/ref.pdf` — 矢量版
