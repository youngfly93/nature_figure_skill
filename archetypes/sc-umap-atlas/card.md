# 单细胞 UMAP atlas（聚类 + marker 分面）

- **何时用**：scRNA/snRNA 降维后，一图展示细胞类型图谱 + 关键 marker 的表达分布。单细胞 Main Figure 标配。
- **数据形状**：embedding 坐标(UMAP1/2) + celltype/cluster + marker 基因 × 细胞表达矩阵。
- **核心依赖**：ggplot2、ggrastr（栅格化大点云）、patchwork、figure_setup.R。
- **配色规则**：celltype 离散用 nature_pal_anno；表达连续用 grey→蓝→红 渐变（取自 theme）。
- **常见翻车点（渲染）**：① 上千点不栅格化 → PDF/SVG 巨大、卡死 → `ggrastr::rasterise(...)`；② UMAP 不 `coord_fixed()` → 簇形变形；③ 用图例认 celltype → 改直接标签(簇中心 geom_text)，省眼动；④ feature plot 表达 0 用亮色 → 0 用灰、高表达才上色。
- **常见翻车点（分析严谨）**：⑤ **UMAP 距离不可定量解读**——簇间距离/密度是非线性嵌入产物，别说"A 比 B 更接近 C"；⑥ **marker 表达受测序深度/dropout 影响**，"未检出"≠"不表达"，应说明是否做了归一化/imputation；⑦ **聚类数依赖分辨率参数**，celltype 标注需 marker 证据支撑，别把算法簇直接当生物学类型。
- **参考实现**：`archetypes/sc-umap-atlas/`
