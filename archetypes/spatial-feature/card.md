# 原型卡：空间组学 feature 叠图（Archetype ⑩）

## 图例说明

| 面板 | 内容 | 关键设计 |
|------|------|----------|
| **A** | 空间域（Spatial domains）—— 每个 spot 按 celltype 着色 | 离散配色（`nature_pal_anno`）+ `coord_fixed()` |
| **B** | 连续 feature 空间梯度（Spatial feature gradient） | 连续色谱（`viridis/magma`）+ `coord_fixed()` |

两面板 `patchwork` 横排，`tag_levels="A"` 自动标注面板字母，`caption` 声明合成数据。

---

## 数据接口

```r
sp <- synth_spatial(n_spots = 1500, seed = 12)
# 返回: data.frame(x, y, celltype[factor], feature[numeric])
```

---

## 常见翻车点

### 渲染层面

1. **纵横比变形**：空间坐标必须 `coord_fixed()`，否则 x/y 比例失真，域的形状与真实切片不符。漏写会导致圆形域被拉成椭圆，读者误判空间结构。

2. **点云未栅格化导致体积爆炸**：1500 个 spot 用矢量 `geom_point` 写入 PDF 时，每个点都是独立矢量路径，PDF 体积可轻松超 50 MB 且渲染卡顿。务必 `ggrastr::rasterise(geom_point(...), dpi=300)` — 点云变位图嵌入，矢量坐标/文字保留。

3. **离散域与连续 feature 共用同一色谱**：域（celltype）必须用离散调色板（`scale_colour_manual`），feature 必须用连续渐变（`scale_colour_viridis_c`）。若两者都用 `scale_colour_gradient` 或都用分类色，读者无法区分"属于哪个域"与"梯度高低"。

4. **`ggrastr::rasterise` 版本差异**：旧版本签名为 `rasterize()`（不含字母 s），新版为 `rasterise()`。在不同 R 环境中需确认安装版本，否则报 `could not find function` 错误。

5. **白底检查失败**：若 `theme_nature()` 未正确 source（`figure_setup.R` 路径写错），ggplot2 默认灰底 `theme_gray()` 会使 QA 门禁白底检测失败（角亮度 < 0.9）。

---

### 分析严谨性层面（空间组学特有）

6. **空间自相关——相邻 spot 不独立**：标准统计检验（t-test、线性回归）假设观测值独立，但空间组学数据中相邻 spot 表达量高度相关（Moran's I 常 > 0.3）。若直接用非空间模型检验 feature 与域的关联，I 类错误显著膨胀。应使用空间统计模型（如 NNSVG、spatialDE、SPARK）或在检验中加入空间邻接矩阵作为协变量。

7. **Spot 多细胞混合（非单细胞分辨率）**："域"标签实为混合信号而非单细胞注释。Visium 每个 spot 直径 ~55 µm，覆盖 1–10 个细胞。若将 spot 域等同于纯净细胞类型标签，可能高估某 celltype 的空间特异性。建议结合解卷积（RCTD、SPOTlight、cell2location）注明混合比例，或标注"spot-level domain"而非"cell-level annotation"。

8. **切片伪影与批次效应需显式标注**：不同切片（样本）、不同捕获区域（array）之间存在技术批次（库深度、RNA 降解、背景荧光等），会在空间上呈现系统性梯度，易被误读为生物学 feature 梯度。多切片整合分析需 harmony/Seurat 批次矫正，并在图注中明确标注是否已批次校正以及使用的参考切片/对照。
