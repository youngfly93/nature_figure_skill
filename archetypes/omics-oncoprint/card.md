# oncoprint 突变全景 (ComplexHeatmap::oncoPrint)

- **何时用**：基因×样本的突变/CNV 矩阵，想一图展示哪些基因在哪些样本被改变、变异类型构成、与临床注释的关系。癌症基因组 Main Figure 常客。
- **数据形状**：字符矩阵（行=基因，列=样本，元素为分号分隔的变异类型，如 "Missense;Amp"，无变异为 ""）+ 样本临床注释 data.frame。
- **核心依赖**：ComplexHeatmap（oncoPrint）、figure_setup.R。
- **配色规则**：变异类型色取自 theme（nature_pal_anno/nature_div/nature_sig_col），不硬编彩虹。
- **常见翻车点（渲染）**：① get_type 拆分符与数据里的分隔符不一致 → 变异丢失；② alter_fun 的 key 和 col 命名不一致 → 报错或漏画；③ heatmap_legend_param 缺 at/labels → "Length of 'at' should be same as length of 'labels'" 报错（ComplexHeatmap 内部断言，不传 at/labels 则报错）；④ 样本太多列名挤 → 关列名、靠 top 注释；⑤ Amp/Del 用满格矩形会盖住点突变 → 用半高条分层。
- **常见翻车点（分析严谨）**：⑥ **基因排序默认按改变频率，会让"高频=重要"产生暗示**——若高频基因是大基因/已知 hypermutation 热点，需说明排序依据、必要时按驱动证据而非频率；⑦ **样本若来自不同测序 panel/深度，突变检出率不可直接比**，先说明 panel 一致性，否则"某亚型突变多"可能只是测得深。
- **参考实现**：`archetypes/omics-oncoprint/`
