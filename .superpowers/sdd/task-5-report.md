# Task 5 Report — ggtree 进化树 + 热图联排 (Phase 1 Archetype ⑤)

**执行时间**：2026-06-30
**执行分支**：`feat/phase1-omics-hardcore`
**Commit SHA**：`3d96004`

---

## What the figure shows

24-tip random phylogenetic tree (ape::rtree, seed=8) with clade-colored tip points (3 clades from nature_pal_anno), aligned tip labels, and a 24x6 tip-by-feature heatmap on the right side (gheatmap, nature_div diverging palette). Tree displays clade legend on the left; heatmap fill legend (Row z) on the right. White background, Helvetica font.

---

## Script execution

```
done: archetypes/phylo-tree-heatmap/out/ref.png
```

## QA result

```
QA PASS: ref.png — 3543 x 2834 px, 角亮度 1
```

---

## Deviations from brief code (with reasons)

Two ggplot2-4.0 / ggtree-3.14 compatibility shims were added; the tree+gheatmap mechanism is fully intact.

### Compat fix 1: ggtree::empty() patch

Added before the tree build:

```r
local({
  ns <- loadNamespace("ggtree")
  unlockBinding("empty", ns)
  assign("empty",
    function(df) is.null(df) || nrow(df) == 0L || ncol(df) == 0L || inherits(df, "waiver"),
    envir = ns)
  lockBinding("empty", ns)
})
```

Root cause: ggplot2-4.0.2 removed `is.waive()`; ggtree-3.14 has a stale `empty()` in its namespace (whose enclosing environment IS the ggplot2 namespace) that still calls `is.waive`. This causes `geom_segment2::draw_panel` to crash at render time with "could not find function 'is.waive'". The patch replaces the `empty` binding in ggtree's namespace with an equivalent using `inherits(df, "waiver")` (ggplot2-4.0's internal replacement).

### Compat fix 2: orig_mapping restore after gheatmap

```r
orig_mapping <- p$mapping          # save before gheatmap
ph <- gheatmap(p, ...)
attr(ph, "mapping") <- orig_mapping  # restore after
```

Root cause: `gheatmap` ends with `attr(p2, "mapping") <- mapping` where `mapping` is a data.frame of column positions. In ggplot2-4.0's S7 class system, `attr(obj, "mapping")` maps to the `@mapping` S7 slot (typed as `ggplot2::mapping`). Overwriting it with a data.frame corrupts the slot; the next `+` operation (scale or theme) triggers S7 validation and fails with "@mapping must be <ggplot2::mapping>, not S3<data.frame>". Fix: save the original `ggplot2::mapping` (`aes(x=x, y=y)`) and restore it after gheatmap. Column label geom_text layers are already embedded by gheatmap before the attribute write, so rendering is unaffected.

---

## Self-review

- Renders real tree with clade-colored tip points + aligned tip-by-feature heatmap: YES
- White background: YES (corner brightness 1.0)
- QA PASS >=1200 px: YES (3543x2834)
- Tree and heatmap aligned (no offset/blank): YES — gheatmap aligns by tip label rowname match
- Colors from theme: YES — gcol from nature_pal_anno, heatmap from nature_div
- Text English: YES (tip labels T01-T24, feature labels Feat1-6, legend titles "Clade", "Row z")
- card.md has BOTH rendering AND analysis-rigour pitfalls: YES
  - Rendering (6 items): matrix rowname mismatch, offset/width, font size, colnames_angle, PLUS the two ggplot2-4.0 compat issues documented in detail
  - Analysis rigour (4 items): clustering-vs-phylogeny distinction, bootstrap/support values, ape::rtree is not a real phylogeny, tip order misleading
- No overbuilding: YES — follows brief code verbatim with only the two necessary compat shims

## Concerns

1. `base_family` warning from `theme_tree2(base_family=NATURE_FONT)` is non-fatal (ggplot2-4.0 changed theme element hierarchy) but appears on every render. Not fixed since it's in brief code and output is correct.
2. ref.svg not produced: save_nature writes .png + .pdf but ggtree S7 objects may not support svglite without additional workaround. Brief requires "ref.png + ref.pdf" — both present.
3. ggtree 3.14 + ggplot2 4.0 deprecation warnings (aes_(), aes_string()) are numerous but non-blocking.

---

*报告路径*：`.superpowers/sdd/task-5-report.md`

---

## Fix Notes（2026-06-30 追加）

### Fix 1 — card.md 兼容性说明节

在 `card.md` 末尾追加了 `## 兼容性说明（ggplot2 4.0 / ggtree 3.14）` 节，内容涵盖：
- 两处不兼容根因（`is.waive()` 移除 / S7 `@mapping` slot 冲突）的详细说明。
- `plot.R` 两处补丁（`empty()` 命名空间替换、`orig_mapping` 保存/恢复）的功能描述。
- 补丁作用域限制（仅 `Rscript` 一次性会话，交互环境仍会失败）及升级路径（等 ggtree 兼容 ggplot2-4.0 后删除补丁）。

### Fix 2 — 热图列名截断修复

**问题**：原渲染中 `colnames_position="top"` + `colnames_angle=90` 的竖向列名被面板上边缘裁切（显示为 "Fe…"）。

**修复方式**（`plot.R`）：
1. 在 `ph +` 链中加入 `coord_cartesian(clip="off")`，允许文字绘制到面板外。
2. 增加 `plot.margin=margin(t=18, r=4, b=4, l=4, unit="mm")` 提供顶部留白。
3. `height_mm` 从 120 调整为 130，提升整体面板高度。

**验证**：重新渲染后读取 PNG，六列标签（Feat1..Feat6）完整显示，字体大小、角度、树结构、配色均未改变。QA PASS (3543×3070 px, 角亮度 1)。

### Commit

```
fix(phylo-tree): 注释 ggplot2-4.0/ggtree 兼容补丁 + 修热图列名截断
```
