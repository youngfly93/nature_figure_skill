# 复合多面板叙事大图(癌症多组学)

- **何时用**:一张 Figure 要把多个证据(表达/生存/通路/基因组)串成一个论证。这是"高大上"最大来源——靠**构图与叙事**,不是单图复杂。
- **数据形状**:每个面板各自的数据(矩阵 / 生存表 / 富集表 / 基因组段)。
- **依赖**:ComplexHeatmap、circlize、cowplot、survminer、ggplot2、nature_theme.R。
- **拼装机制**:非 ggplot 面板(热图/圈图)经 `grid.grabExpr` / `cowplot::as_grob` 转 grob,再与 ggplot 面板一起 `cowplot::plot_grid`。子图标号 a/b/c/d 用 `label_*` 参数,粗体 8–9 pt。
- **白底保障**:plot_grid 输出须追加 `+ theme(plot.background=element_rect(fill="white", colour=NA))` 并在 ggsave 传 `bg="white"`,否则四角亮度可能 <0.9 导致 QA FAIL。
- **常见翻车点**:① ComplexHeatmap/circos 不是 ggplot,直接 patchwork 会失败 → 必须转 grob;② 子图字号不统一 → 全用 7 pt;③ 面板配色各自为政 → 全部走 theme;④ 留白不足、排版挤 → 控制面板数(≤6)、留 gap;⑤ 只导 PNG → 同时出 PDF 矢量。
- **参考图**:`out/ref.png`
