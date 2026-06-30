# Archetype ⑫ — Sankey/alluvial 流向图（ggalluvial）

## 图型简介

三阶段 alluvial 图，展示样本在 Tissue → Subtype → Response 三个属性之间的流向分布。
每条带（alluvium）宽度正比于样本数；每个矩形块（stratum）表示某轴上某类别的汇总。

## 关键接口

| 参数 | 说明 |
|------|------|
| `synth_flow(n, seed)` | 生成 `Tissue / Subtype / Response` 三列 data.frame（Subtype 4 水平：C1/C2/C3/Normal） |
| `aes(axis1=, axis2=, axis3=, y=Freq)` | ggalluvial 宽格式；Freq 来自 `table()` 聚合 |
| `geom_alluvium(fill=Subtype, alpha=0.7, width=0.32)` | 流带，fill 映射到 Subtype |
| `geom_stratum(width=0.32, fill="grey92")` | 矩形块，宽度需与 alluvium 一致 |
| `geom_text(stat="stratum", aes(label=after_stat(stratum)))` | 在 stratum 内打标签 |
| `scale_x_discrete(limits=c("Tissue","Subtype","Response"))` | 三阶段顺序（必须显式指定，否则 ggalluvial 依变量名排序） |
| `nature_pal_anno[seq_along(sub_lv)]` | Subtype 配色来自 house 统一色板，不硬编 |

## 常见翻车点

### 渲染层面

1. **stratum 宽度与 alluvium 宽度不一致**
   `geom_alluvium(width=W)` 和 `geom_stratum(width=W)` 必须用同一个 `W`（默认均为 `1/3`）。
   不一致时流带会"戳出"或"缩进"矩形块，外观混乱。

2. **`after_stat(stratum)` 与 `stat(stratum)` 写法差异**
   ggplot2 ≥ 3.3 起推荐 `after_stat(stratum)`；旧代码若写 `stat(stratum)` 在新版会触发 deprecated 警告或报错。
   检查 ggplot2 版本，统一用 `after_stat()` 形式。

3. **阶段顺序未显式锁定**
   `scale_x_discrete(limits=c("Tissue","Subtype","Response"))` 必须写；
   省略时 ggalluvial 按变量名字母序排列，三列顺序可能变错，视觉叙事完全改变。

4. **`factor` 水平顺序影响 stratum 内堆叠顺序**
   `Subtype` 用 `factor(..., levels=c("C1","C2","C3","Normal"))` 固定；
   不锁定则每次 R 运行结果一致但不符合业务期望（如 Normal 可能排到最上面）。

5. **"Some strata appear at multiple axes" 警告**
   当某个字符串同时出现在多个轴（如 `Tissue="Normal"` 与 `Subtype="Normal"`），ggalluvial 会发出此警告但不报错。
   这是数据设计问题（两列共享同名类别），可通过改名（如 `Subtype="Normal_subtype"`）消除，或选择忽略（不影响渲染）。

6. **stratum 标签遮挡（字号过大/stratum 过窄）**
   在 height_mm 较小或 stratum 较多时，`size=2` 的标签可能重叠。
   解决方法：缩小 `size`，或用 `geom_label` 带白底，或只标注主要类别。

### 分析严谨性层面

7. **流宽 = 样本数，不等于概率或因果**
   alluvium 宽度仅反映样本计数（`Freq`）。
   **不可**将"C1→Responder 流最宽"解读为"C1 更可能应答"（需看条件比例）；
   **更不可**解读为 Subtype 导致了 Response（这是横截面分类，无干预设计）。

8. **阶段顺序是人为排列，换顺序会改变视觉叙事**
   `Tissue → Subtype → Response` 是作者选择的叙述逻辑，不代表真实时序或因果链。
   若改为 `Subtype → Tissue → Response`，同一数据呈现完全不同的"故事"。
   必须在图说/正文中如实说明各轴含义与排列依据。

9. **小流（低 n）在视觉上易被忽略但可能重要**
   少样本的 alluvium 宽度极细，容易被读者跳过。
   若某类别（如罕见亚型）的流向有临床意义，需在图注或标注中明确 n，
   必要时用 `geom_text` 或表格补充绝对计数，防止重要信息被视觉压制。

## QA 检查清单

- [ ] `done:` 行打印 → 脚本无报错退出
- [ ] `Rscript tools/qa_check.R out/ref.png 1200` → QA PASS（≥1200 px，白底）
- [ ] 图内文字均为英文
- [ ] Subtype 配色来自 `nature_pal_anno`（不硬编 hex）
- [ ] stratum/alluvium 宽度一致（均为 0.32）
- [ ] `scale_x_discrete(limits=...)` 显式锁定三阶段顺序
- [ ] caption 含分析诚实声明（流宽≠概率/因果，顺序人为，小流注意）
- [ ] `nature_theme.R` 未被修改
