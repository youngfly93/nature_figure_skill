# Archetype ⑪ — 富集通路网络（ggraph 二部图，cnetplot 风格）

## 图型定位

展示基因集富集分析（GSEA/ORA）结果中**通路与基因的双层关系网络**。通路节点大、按显著性着色，基因节点小灰，边代表基因在通路中的归属。适用于展示多条通路共享基因的交叉关系，揭示核心调控基因。

## 接口

```r
source("archetypes/_lib/figure_setup.R")
source("archetypes/_lib/synth_data.R")
nw <- synth_network()   # list(edges=data.frame(from=term,to=gene), terms=data.frame(name,p.adjust))
```

## 规格

| 要素       | 规格                                         |
|------------|----------------------------------------------|
| 节点类型   | Pathway（大，按基因数sizing，按 -log10 p.adjust 着色）+ Gene（小灰）|
| 边         | 细灰（edge_width=0.25），半透明               |
| 颜色       | `rev(nature_seq[-1])`（深蓝→浅蓝，深=显著）  |
| 布局       | Fruchterman-Reingold（`layout="fr"`）        |
| 标签       | 仅通路节点标注，`repel=TRUE` 防重叠          |
| 尺寸       | 150×130 mm，300 dpi PNG + PDF                |
| 背景       | 白色（theme_void + 显式 plot.background）    |

## 复现要点

```r
set.seed(21)   # fr 布局含随机 → 必须固定种子才可复现
```

## 常见翻车点

### 渲染层

1. **布局未设种子** — `layout="fr"`（力导向布局）每次运行结果不同，图无法复现。**必须** `set.seed()` 在 `ggraph()` 之前调用。
2. **NA label 警告** — `geom_node_text` 对基因节点传 `NA_character_`，ggrepel 会 warning "Removed N rows"，属正常行为，不是错误。
3. **degree 不可假设固定** — `synth_network()` 中每条通路的基因数有随机 jitter（`genes_per_term + sample(0:4,1)`），**必须从 graph 实际读 degree**，不能硬编码。
4. **repel 参数版本差异** — ggraph ≥2.x `geom_node_text` 支持 `repel=TRUE`（需 ggrepel）；若报错改用 `check_overlap=TRUE`，但后者不会推开重叠标签，只消隐。
5. **白底需显式设置** — `theme_void()` 默认背景透明，保存 PNG/PDF 可能出现灰/黑背景；需在 `theme()` 中显式 `plot.background=element_rect(fill="white")`.

### 分析严谨性

6. **网络布局是美学排布，不是定量距离** — 力导向布局（fr/kk）将边少的节点推远，节点间距离**不代表**生物学相似性或任何定量关系；不得在正文中描述"距离近的通路相关性强"。
7. **边来自注释库，结论受版本影响** — 通路-基因归属依赖 KEGG/MSigDB/GO 等特定版本；同一基因在不同版本中的通路归属可能不同，**结论必须注明数据库及版本号**。
8. **通路冗余使网络虚胖** — 高度基因集重叠的通路（如 "Cell cycle" 与 "G2M checkpoint"）会产生大量共享基因节点，网络膨胀、视觉混乱。建议先 `clusterProfiler::simplify()` 或按相似度阈值去冗余再出图。
9. **基因标注过密** — 若基因节点也标注名称，小图将不可读；只标通路名，或配合 `max.overlaps` 参数控制密度。

## 替代方案（Canonical）

- **`enrichplot::cnetplot()`** — clusterProfiler 生态的标准实现，自动处理通路-基因映射、着色、标注，无需手动构图。
- **`enrichplot::emapplot()`** — 通路-通路富集地图，按共享基因集相似度布局，用于展示通路间关系而非通路-基因关系。
- 上述两者直接接受 `clusterProfiler` 的 `enrichResult` 对象，适合正式分析流程；本 archetype 适合**自定义网络**或**整合多来源边**的场景。

## 参考图

`out/ref.png` / `out/ref.pdf` — 8 条合成通路 × 6–10 个基因/通路的二部图示例。
