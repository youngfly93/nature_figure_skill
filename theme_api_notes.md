# theme_api_notes.md — nature_theme.R 接口实测签名

> 真源文件：`~/.claude/assets/figure-style/nature_theme.R`
> 实测于：2026-06-30，R 4.4.3
> 用途：Task 3/4 构建 archetype 脚本时的权威引用；禁止凭记忆假设签名。

---

## save_heatmap

```r
save_heatmap <- function(ht, base_path, width_mm = 120, height_mm = 180,
                         dpi = 600, tiff = FALSE, family = NATURE_FONT,
                         legend_side = "right")
```

**参数说明**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `ht` | — | ComplexHeatmap 对象（Heatmap 或 HeatmapList） |
| `base_path` | — | 输出路径前缀（不含后缀），如 `"archetypes/foo/out/ref"` |
| `width_mm` | 120 | 图宽（mm） |
| `height_mm` | 180 | 图高（mm） |
| `dpi` | 600 | PNG/TIFF 分辨率 |
| `tiff` | FALSE | 是否额外输出 TIFF |
| `family` | NATURE_FONT | PDF 字体（CJK 安全字体，已在 source 时解析） |
| `legend_side` | "right" | 传给 ComplexHeatmap::draw() 的图例位置 |

**输出文件（实测）**

- `{base_path}.png` — 始终生成（ragg::agg_png，raster 预览，600 dpi）
- `{base_path}.pdf` — 始终生成（cairo_pdf，矢量，可编辑文字）
- `{base_path}.tiff` — 仅当 `tiff = TRUE` 时生成（ragg::agg_tiff，LZW 压缩）

> **Task 3 QA 关键**：`ref.png` 对应 `save_heatmap(ht, "archetypes/<name>/out/ref", ...)` 的 `.png` 产出。
> QA 路径写 `archetypes/<name>/out/ref.png`，始终存在（无需 tiff=TRUE）。

**返回值**：`invisible(base_path)`（字符串路径前缀）

---

## save_nature

```r
save_nature <- function(plot, base_path,
                        width_mm = NATURE_W_DOUBLE,
                        height_mm = 110,
                        dpi = 600,
                        tiff = FALSE,
                        bg = "white",
                        family = NATURE_FONT)
```

**参数说明**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `plot` | — | ggplot 对象 |
| `base_path` | — | 输出路径前缀（不含后缀） |
| `width_mm` | 183（NATURE_W_DOUBLE） | 图宽（mm）；单栏89mm，双栏183mm，全宽247mm |
| `height_mm` | 110 | 图高（mm） |
| `dpi` | 600 | PNG/TIFF 分辨率 |
| `tiff` | FALSE | 是否额外输出 TIFF |
| `bg` | "white" | 背景色 |
| `family` | NATURE_FONT | PDF 字体 |

**输出文件**

- `{base_path}.png` — 始终生成（ragg::agg_png）
- `{base_path}.pdf` — 始终生成（cairo_pdf）
- `{base_path}.tiff` — 仅 `tiff = TRUE`（ragg::agg_tiff）

**返回值**：`invisible(base_path)`

---

## nature_group_cols

```r
nature_group_cols <- function(levels)
```

**参数**：`levels` — 字符向量，组名列表（如 `c("Tumor","Normal","Stage I","Stage II")`）

**返回值**：具名字符向量，`levels` → hex 颜色字符串

**逻辑**：
1. 语义名（`Tumor/Normal/High/Low/Up/Down`）优先用 `nature_sig_col` 语义色
2. 其余按 `nature_pal_6`（6色循环）分配

**示例**：
```r
cols <- nature_group_cols(c("Tumor", "Normal", "Stage I"))
# Tumor="#D24B40", Normal="#3775BA", Stage I="#7FA6C9"（nature_pal_6[1]）
```

---

## nature_heatmap_col

```r
nature_heatmap_col <- function(breaks = c(-2, -1, 0, 1, 2),
                               colors = c("#2166AC", "#7FB0D5", "#F7F7F7", "#E89A8C", "#B2182B"))
```

**参数**：
- `breaks`：颜色断点，默认 z-score 范围 [-2, 2]
- `colors`：与 breaks 等长的颜色向量（蓝→白→红，RdBu 风格）

**返回值**：`circlize::colorRamp2(breaks, colors)` 返回的**颜色映射函数**（传给 Heatmap(col=...)）

**依赖**：`circlize` 包（若未安装则 stop）

---

## nature_km

```r
nature_km <- function(df, time = "time", status = "status", group = "group",
                      value = NULL, split = "median", levels = NULL,
                      title = NULL, time_lab = "Time", surv_lab = "Survival probability",
                      legend_title = NULL,
                      cols = c(High = nature_sig_col[["High"]], Low = nature_sig_col[["Low"]]),
                      risk_table = TRUE, show_cox_p = TRUE)
```

**参数**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `df` | — | 数据框，含 time/status/group 列（或 value 列） |
| `time` | "time" | 生存时间列名 |
| `status` | "status" | 事件状态列名（0/1） |
| `group` | "group" | 预分组列名（与 value 互斥） |
| `value` | NULL | 连续表达量列名；非 NULL 时按 split 切 High/Low |
| `split` | "median" | 切点：`"median"` 或 数值型 |
| `levels` | NULL | 手动指定分组因子顺序 |
| `cols` | High/Low 语义色 | 分组颜色（具名向量） |
| `risk_table` | TRUE | 是否在 KM 曲线下方拼 Number at risk 表 |
| `show_cox_p` | TRUE | 注释中是否显示 Cox p 值（仅双组时计算） |

**统计输出（自动内嵌图中）**：
- log-rank p 值
- Cox HR（95% CI）及 Cox p（仅二分组；subtitle 显示 HR）

**返回值**：
- `risk_table = FALSE` 或 patchwork 未安装：ggplot 对象
- `risk_table = TRUE` 且 patchwork 已安装：patchwork 复合图（KM + 风险表，比例 4:1）

**依赖**：`survival`（必须）；`patchwork`（风险表可选）

---

## 其他常用接口速查

| 函数 | 签名摘要 | 返回类型 |
|------|----------|----------|
| `theme_nature(base_size=8, base_family=NATURE_FONT, grid=FALSE)` | ggplot theme 对象 | theme |
| `nature_heatmap(mat, name="Row Z-score", col=nature_heatmap_col(), ...)` | ComplexHeatmap::Heatmap | Heatmap |
| `nature_hm_anno(..., col=NULL)` | HeatmapAnnotation，house 字体 | HeatmapAnnotation |
| `nature_volcano(df, lfc, p, label, fc_thresh=1, p_thresh=0.05, top_n=10, ...)` | ggplot 火山图 | ggplot |
| `nature_enrich_dot(df, term, score, p, count, top_n=10, ...)` | ggplot 富集 dotplot | ggplot |
| `nature_forest(df, term, hr, lo, hi, p, ...)` | ggplot 森林图 | ggplot |
| `nature_pca(df, x, y, group, ellipse=TRUE, ...)` | ggplot PCA 散点 | ggplot |
| `nature_box_sig(df, x, y, comparisons, ...)` | ggplot 箱线+显著性 | ggplot |
| `nature_oncoprint(mat, col, alter_fun, ...)` | ComplexHeatmap oncoPrint | HeatmapList |

## 常量速查

```r
NATURE_FONT        # 运行时解析的 CJK 安全字体（本机实测：SimHei）
NATURE_W_SINGLE    # 89  mm（单栏宽）
NATURE_W_DOUBLE    # 183 mm（双栏宽）
NATURE_W_FULL      # 247 mm（全版宽）
nature_palette     # 具名颜色向量（~20色）
nature_pal_anno    # 分组注释 pastel 配色（6色）
nature_seq         # 顺序色阶（蓝→白，6色）
nature_div         # 发散色阶（蓝→白→红，7色）
nature_sig_col     # 语义方向色（Up/Down/High/Low/Tumor/Normal）
```
