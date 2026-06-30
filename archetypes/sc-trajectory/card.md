# 卡片：单细胞拟时序（Archetype ⑨）

## 图示说明

UMAP 散点图，2 000 个合成单细胞细胞按拟时序（pseudotime）连续着色，叠加 slingshot 拟合的轨迹曲线（黑色矢量路径）。
颜色从淡蓝（早期/起点）→深蓝（终点），来自统一配色 `nature_seq`。

**使用工具**：[slingshot](https://bioconductor.org/packages/slingshot/)（Bioconductor，Street et al. 2018）

> monocle3 因系统缺少 GDAL/GEOS（terra/spdep 传递依赖）无法安装，故采用 slingshot（兜底路径 B）。

---

## 常见翻车点

### 渲染层面

1. **起点簇名大小写/类型不匹配**
   `slingshot()` 的 `start.clus` 必须与 `clusterLabels` 的因子水平完全一致（字符串）。
   本例 cluster 为因子 `"1"…"6"`，须用 `as.character(...)` 取值，不能传整数。

2. **曲线坐标列名错位**
   `slingCurves(sds)[[1]]$s` 返回的矩阵列名是位置索引，不是 `UMAP1/UMAP2`。
   必须手动 `colnames(crv_df) <- c("UMAP1","UMAP2")` 再传给 `geom_path()`，否则报 `object 'UMAP1' not found`。

3. **轨迹曲线被栅格化导致模糊**
   点云（2 000 细胞）须 `ggrastr::rasterise(geom_point(...), dpi=300)`；
   轨迹曲线为矢量，应保持 `geom_path()`（不栅格化），使曲线在放大后依然清晰。

4. **coord_fixed() 缺失导致比例变形**
   UMAP 两轴须等比例（`coord_fixed()`），否则簇形状失真，轨迹曲线走向误导。

5. **白底不达标**
   默认 ggplot2 灰底会导致 QA 四角亮度 < 0.9；须 `theme_nature()` 或 `theme(panel.background=element_rect(fill="white"))`。

6. **PDF 字体未嵌入**
   `save_nature()` 已统一处理 `cairo_pdf(family=NATURE_FONT)`；不要自行调用 `pdf()` 绕过此逻辑。

---

### 分析严谨性层面

7. **拟时序是模型推断的"假定"轨迹，非真实时间**
   pseudotime 是算法基于细胞在降维空间的分布拟合的**概率/几何**顺序，不是细胞实际经历的发育时间轴。
   分支走向和值域受算法假设（最小生成树/主曲线等）支配，不应解读为"某细胞在第 X 天"。

8. **方向完全依赖 root 选择**
   `start.clus` 的指定是**研究者主观先验**（本例用潜变量最小值簇作为代理）。
   若 root 选错，整个轨迹方向可能倒置；须用实验数据（标记基因时序、分裂指数等）验证。

9. **拓扑结论应稳健于工具选择**
   monocle3（DDRTree/principal graph）与 slingshot（minimum spanning tree + principal curves）拓扑算法不同，分支数量和走向可能存在差异。
   结论（如"A → B → C 的分化轴"）须在两种工具下均成立，或明确说明工具局限性。

10. **合成/真实数据均不能将 pseudotime 当绝对时间**
    即便在真实数据中，pseudotime 也仅代表细胞状态的**相对排序**；
    不同实验批次、不同采样时间点的 pseudotime 不可直接比较，须归一化或对齐处理。

---

## 技术参数

| 项 | 值 |
|---|---|
| 工具 | slingshot 2.x（Bioconductor） |
| 细胞数 | 2 000（合成，set.seed(11)） |
| 降维 | 合成 UMAP（`synth_scrna()` 内置） |
| 聚类数 | 6 |
| 起点簇 | 连续潜变量 `lineage` 最小值对应簇 |
| 配色 | `nature_seq`（唯一真源：figure_setup.R） |
| 点云渲染 | `ggrastr::rasterise(dpi=300)`（矢量输出内嵌光栅层） |
| 曲线渲染 | `geom_path()`（矢量） |
| 导出 | 120 × 110 mm，`save_nature()` |
| QA 门禁 | `qa_check.R minwidth=1200` ✓ |
