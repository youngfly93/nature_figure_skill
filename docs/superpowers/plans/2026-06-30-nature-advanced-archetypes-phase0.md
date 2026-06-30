# Nature 高级图型 archetype 库 — Phase 0 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 打通"可跑 archetype 五件套"模式——建工程脚手架 + QA 门禁 + 2 个高级 archetype(多注释热图、癌症多组学复合大图),并集成进现有 `nature-figure` skill,供用户验收后再批量铺 Phase 1–4。

**Architecture:** 项目目录开发可跑 R 脚本(自带合成数据、真跑出真图),每张图过 `qa_check.R` 自动门禁(存在/非空/白底/分辨率);验证通过的参考图与说明蒸馏进 `~/.claude/skills/nature-figure/`。配色/主题/字体只认 `nature_theme.R` 一个真源。

**Tech Stack:** R 4.4.3 · ComplexHeatmap · circlize · cowplot · survminer · ggplot2 · ragg/Cairo。

## Global Constraints

- 配色/主题/字体唯一真源:脚本顶部 `source("~/.claude/assets/figure-style/nature_theme.R")`;不复制、不每图重定义。
- 优先用 theme 既有接口:`theme_nature` / `save_nature` / `save_heatmap` / `nature_heatmap_col` / `nature_group_cols` / `nature_seq` / `nature_div` / `nature_pal_anno` / `NATURE_FONT`。
- 每个脚本必须**真跑、出真图**;参考图来自真跑,绝不编造/占位。
- 合成数据**设种子**、可复现;不依赖任何真实/私有数据。
- 图内文字一律**英文**(Nature 规范 + 规避 CJK 字体问题);中文只出现在 `card.md` / docs。
- **缺包先停下商量**,绝不静默降级成简单图(Phase 0 所需包已实测齐备;若 env_check 报缺,停)。
- 改 `~/.claude/skills/nature-figure/` 内**既有**文件前先 `git status`/`diff`(或备份)展示差异,确认后再动;Phase 0 优先**新增文件**,既有文件只做最小追加。
- 导出多格式:PNG(预览/QA)+ PDF/SVG(矢量投稿)。版心宽度用 `NATURE_W_SINGLE/DOUBLE`(89/183 mm)。

## 文件结构

```
nature_figure_skill/
├── README.md                                  # 项目索引 + 用法
├── tools/
│   ├── env_check.R                            # 环境探测(包 + theme 接口)
│   ├── qa_check.R                             # QA 门禁:校验一张输出图
│   └── test_qa.R                              # qa_check 自测(好图过/坏图挂)
├── archetypes/
│   ├── _lib/synth_data.R                      # 合成 demo 数据生成器(设种子)
│   ├── omics-multiannot-heatmap/
│   │   ├── plot.R · card.md · out/ref.{png,pdf}
│   └── composite-cancer-multiomics/
│       ├── plot.R · card.md · out/ref.{png,pdf}
└── docs/superpowers/{specs,plans}/            # spec(已有)+ 本计划
```

skill 侧(Phase 0 新增/最小改):
```
~/.claude/skills/nature-figure/
├── references/advanced-archetypes.md          # 新增:高级 archetype 索引 + 野心阶梯
├── references/r-template-index.md             # 最小追加一段指针
└── assets/advanced-archetypes/*.png           # 新增:参考图
```

---

### Task 1: 工程脚手架 + 环境探测

**Files:**
- Create: `tools/env_check.R`
- Create: `README.md`
- Create: `archetypes/_lib/.keep`、`tools/.keep`(占位保目录)
- Create: `theme_api_notes.md`(记录 theme 关键接口的实测签名/返回类型/输出文件名)

**Interfaces:**
- Produces: `tools/env_check.R` 可执行,Phase 0 包/接口齐备时 exit 0、否则非 0 并打印缺项。`theme_api_notes.md` 记录 `save_heatmap`/`save_nature`/`nature_group_cols`/`nature_km` 的确切签名与输出文件名,供 Task 3/4 引用。

- [ ] **Step 1: 写 env_check.R**

```r
#!/usr/bin/env Rscript
# Phase 0 环境探测：所需包 + nature_theme.R 接口是否齐备
THEME <- "~/.claude/assets/figure-style/nature_theme.R"
req <- c("ComplexHeatmap","circlize","cowplot","survminer","survival",
         "ggplot2","scales","grid","ragg")
miss <- req[!vapply(req, requireNamespace, logical(1), quietly = TRUE)]
cat("R:", as.character(getRversion()), "\n")
if (length(miss)) { cat("缺失(Phase 0 必需):", paste(miss, collapse=", "), "\n"); quit(status=1) }
cat("Phase 0 必需包: 全部就绪\n")
src <- path.expand(THEME)
if (!file.exists(src)) { cat("缺 nature_theme.R\n"); quit(status=1) }
e <- new.env(); sys.source(src, envir = e)
need <- c("theme_nature","save_nature","save_heatmap","nature_heatmap_col",
          "nature_group_cols","nature_seq","nature_div","nature_palette",
          "nature_pal_anno","NATURE_FONT")
mo <- need[!vapply(need, exists, logical(1), envir = e, inherits = FALSE)]
if (length(mo)) { cat("theme 缺接口:", paste(mo, collapse=", "), "\n"); quit(status=1) }
cat("theme 接口: 全部就绪 (NATURE_FONT =", e$NATURE_FONT, ")\nENV OK\n")
```

- [ ] **Step 2: 跑 env_check,确认 ENV OK**

Run: `Rscript tools/env_check.R`
Expected: 末行 `ENV OK`,exit 0。若打印"缺失/缺接口",**停下报告**,不继续。

- [ ] **Step 3: 记录 theme 接口实测签名到 theme_api_notes.md**

读 `~/.claude/assets/figure-style/nature_theme.R`,把以下函数的**确切参数、返回类型、写出的文件名/格式**记进 `theme_api_notes.md`:`save_heatmap`、`save_nature`、`nature_group_cols`、`nature_heatmap_col`、`nature_km`。重点确认:`save_heatmap(ht, base_path, ...)` 实际写出哪些后缀(用于 Task 3 的 QA 路径)。

- [ ] **Step 4: 写 README.md(项目索引)**

```markdown
# Nature 高级图型 archetype 库

让 agent 不止画基础款,而能画 Nature 级复杂/复合图。每个 archetype = 可跑脚本 + 真参考图 + 说明卡。
配色/主题唯一真源:`~/.claude/assets/figure-style/nature_theme.R`。

## 用法
- 环境自检:`Rscript tools/env_check.R`
- 出某图:`Rscript archetypes/<name>/plot.R` → 写 `archetypes/<name>/out/ref.{png,pdf}`
- QA 门禁:`Rscript tools/qa_check.R archetypes/<name>/out/ref.png`

## 设计/计划
见 `docs/superpowers/specs/` 与 `docs/superpowers/plans/`。
```

- [ ] **Step 5: 建占位目录并提交**

```bash
mkdir -p archetypes/_lib tools archetypes/omics-multiannot-heatmap archetypes/composite-cancer-multiomics
touch archetypes/_lib/.keep
git add -A
git commit -m "chore: Phase 0 脚手架 + 环境探测 (env_check)"
```

---

### Task 2: 共享库 — 合成数据 + QA 门禁

**Files:**
- Create: `archetypes/_lib/synth_data.R`
- Create: `tools/qa_check.R`
- Create: `tools/test_qa.R`

**Interfaces:**
- Produces:
  - `synth_expr(n_genes, n_samples, seed)` → `list(mat=基因×样本 z-score 矩阵, col_anno=data.frame(Subtype,Stage,Tissue))`
  - `synth_survival(col_anno, seed)` → `data.frame(time, status, group)`
  - `synth_enrich(seed, n)` → `data.frame(Term(factor), Count, GeneRatio, p.adjust)`
  - `synth_genome(seed, n_chr, per)` → `list(track=data.frame(chr,start,end,cnv,expr), links=data.frame(chr1,pos1,chr2,pos2), chromosomes)`
  - `qa_check.R <png> [minwidth]` → exit 0 通过 / 1 不达标 / 2 用法错。

- [ ] **Step 1: 写 synth_data.R**

```r
# 合成 demo 数据(设种子，可复现；不依赖任何真实/私有数据)
synth_expr <- function(n_genes = 40, n_samples = 60, seed = 1) {
  set.seed(seed)
  subtype <- factor(sample(c("Basal","LumA","LumB"), n_samples, TRUE))
  stage   <- factor(sample(c("I","II","III"), n_samples, TRUE), levels=c("I","II","III"))
  tissue  <- factor(sample(c("Tumor","Normal"), n_samples, TRUE, prob=c(.7,.3)))
  base  <- matrix(rnorm(n_genes*n_samples), n_genes, n_samples)
  dummy <- model.matrix(~subtype)[, -1, drop=FALSE]              # n×2
  load  <- matrix(rnorm(n_genes*2, 0, 1.2), 2, n_genes)          # 2×n_genes
  mat   <- base + t(dummy %*% load)                              # n_genes×n
  mat   <- t(scale(t(mat)))                                      # 行 z-score
  rownames(mat) <- paste0("Gene", sprintf("%02d", seq_len(n_genes)))
  colnames(mat) <- paste0("S",   sprintf("%03d", seq_len(n_samples)))
  list(mat = mat,
       col_anno = data.frame(Subtype=subtype, Stage=stage, Tissue=tissue,
                             row.names=colnames(mat)))
}
synth_survival <- function(col_anno, seed = 3) {
  set.seed(seed); n <- nrow(col_anno); risk <- as.integer(col_anno$Stage)
  data.frame(time   = round(rexp(n, 0.03*risk) + 1),
             status = rbinom(n, 1, pmin(0.9, 0.4 + 0.15*(risk-1))),
             group  = col_anno$Subtype, row.names = rownames(col_anno))
}
synth_enrich <- function(seed = 4, n = 10) {
  set.seed(seed)
  terms <- c("Cell cycle","DNA repair","Immune response","Apoptosis","Angiogenesis",
             "p53 signaling","MAPK cascade","Metabolism","Hypoxia","ECM organization")[seq_len(n)]
  data.frame(Term=factor(terms, levels=rev(terms)), Count=sample(8:60, n),
             GeneRatio=round(runif(n,0.05,0.4),3), p.adjust=sort(10^(-runif(n,2,8))))
}
synth_genome <- function(seed = 5, n_chr = 8, per = 40) {
  set.seed(seed); chr <- paste0("chr", seq_len(n_chr))
  track <- do.call(rbind, lapply(chr, function(c){
    pos <- sort(sample(1:1000, per))
    data.frame(chr=c, start=pos, end=pos+5, cnv=cumsum(rnorm(per,0,0.3)), expr=rnorm(per))
  }))
  links <- data.frame(chr1=sample(chr,6,TRUE), pos1=sample(1:1000,6),
                      chr2=sample(chr,6,TRUE), pos2=sample(1:1000,6))
  list(track=track, links=links, chromosomes=chr)
}
```

- [ ] **Step 2: 验证 synth_data.R 可加载、维度正确**

Run:
```bash
Rscript -e 'source("archetypes/_lib/synth_data.R"); d<-synth_expr(); stopifnot(dim(d$mat)==c(40,60)); cat("synth OK\n")'
```
Expected: `synth OK`

- [ ] **Step 3: 写 qa_check.R(先于任何 plot.R —— 这是门禁)**

```r
#!/usr/bin/env Rscript
# QA 门禁：一张输出图是否达交付底线（存在/非空/白底/分辨率）
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) { cat("用法: qa_check.R <png> [minwidth]\n"); quit(status=2) }
png_path <- args[[1]]; min_w <- if (length(args)>=2) as.integer(args[[2]]) else 900L
fail <- function(m){ cat("QA FAIL:", m, "\n"); quit(status=1) }
if (!file.exists(png_path)) fail(paste("文件不存在:", png_path))
sz <- file.info(png_path)$size
if (is.na(sz) || sz < 10000) fail(paste("文件过小(疑似空图):", sz, "bytes"))
if (requireNamespace("png", quietly = TRUE)) {
  img <- png::readPNG(png_path); d <- dim(img)            # [h, w, ch]
  if (d[[2]] < min_w) fail(paste("宽度不足:", d[[2]], "<", min_w, "px"))
  corner <- function(im, yi, xi){ h<-dim(im)[1]; w<-dim(im)[2]
    ys <- if (yi==1) 1:8 else (h-7):h; xs <- if (xi==1) 1:8 else (w-7):w
    mean(im[ys, xs, 1:min(3, dim(im)[3])]) }
  br <- mean(c(corner(img,1,1),corner(img,1,2),corner(img,2,1),corner(img,2,2)))
  if (br < 0.9) fail(paste("四角非白底(亮度", round(br,3), "<0.9) — 检查默认灰底"))
  cat("QA PASS:", basename(png_path), "—", d[[2]], "x", d[[1]], "px, 角亮度", round(br,3), "\n")
} else {
  cat("QA PASS(降级:无 png 包,仅查存在与大小):", basename(png_path), "—", sz, "bytes\n")
}
quit(status = 0)
```

- [ ] **Step 4: 写 test_qa.R(自测:白图过、灰图挂)**

```r
#!/usr/bin/env Rscript
# 自测 qa_check：白底图应 PASS，灰底图应 FAIL
dir.create("scratchpad", showWarnings=FALSE)
wp <- "scratchpad/_qa_white.png"; gp <- "scratchpad/_qa_gray.png"
ragg::agg_png(wp, width=1000, height=800, res=300); plot.new(); dev.off()
ragg::agg_png(gp, width=1000, height=800, res=300); par(bg="grey75"); plot.new(); dev.off()
rc_white <- system2("Rscript", c("tools/qa_check.R", wp), stdout=TRUE, stderr=TRUE)
ok_white <- attr(rc_white,"status"); ok_white <- if (is.null(ok_white)) 0L else ok_white
rc_gray  <- system2("Rscript", c("tools/qa_check.R", gp), stdout=TRUE, stderr=TRUE)
st_gray  <- attr(rc_gray,"status"); st_gray <- if (is.null(st_gray)) 0L else st_gray
cat("white ->", paste(rc_white, collapse=" "), "\n")
cat("gray  ->", paste(rc_gray,  collapse=" "), "\n")
stopifnot(ok_white == 0L, st_gray == 1L)
cat("QA self-test OK\n")
```

- [ ] **Step 5: 跑自测,确认门禁分得清好坏图**

Run: `Rscript tools/test_qa.R`
Expected: 末行 `QA self-test OK`(白图 PASS、灰图 FAIL)。

- [ ] **Step 6: 提交**

```bash
git add archetypes/_lib/synth_data.R tools/qa_check.R tools/test_qa.R
git commit -m "feat: 合成数据生成器 + QA 门禁(含自测)"
```

---

### Task 3: Archetype A — 多注释轨道差异热图

**Files:**
- Create: `archetypes/omics-multiannot-heatmap/plot.R`
- Create: `archetypes/omics-multiannot-heatmap/card.md`
- Produce: `archetypes/omics-multiannot-heatmap/out/ref.{png,pdf}`

**Interfaces:**
- Consumes: `synth_expr()`(Task 2);theme `nature_heatmap_col`/`nature_seq`/`nature_pal_anno`/`NATURE_FONT`/`save_heatmap`。
- Produces: `out/ref.png`(供 QA 与 skill 引用)。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: 多注释轨道差异热图 (ComplexHeatmap)
suppressPackageStartupMessages({
  source("~/.claude/assets/figure-style/nature_theme.R")
  library(ComplexHeatmap); library(circlize); library(grid)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/omics-multiannot-heatmap"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d <- synth_expr(n_genes=40, n_samples=60, seed=1); mat <- d$mat; anno <- d$col_anno
sub_lv <- levels(anno$Subtype); stg_lv <- levels(anno$Stage); tis_lv <- levels(anno$Tissue)
legp <- function() list(title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT),
                        labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT))
top <- HeatmapAnnotation(
  Subtype=anno$Subtype, Stage=anno$Stage, Tissue=anno$Tissue,
  col=list(Subtype=setNames(nature_pal_anno[seq_along(sub_lv)], sub_lv),
           Stage  =setNames(nature_seq[c(2,4,6)][seq_along(stg_lv)], stg_lv),
           Tissue =setNames(nature_pal_anno[4:5][seq_along(tis_lv)], tis_lv)),
  annotation_name_gp=gpar(fontsize=6,fontfamily=NATURE_FONT),
  simple_anno_size=unit(2.5,"mm"), gap=unit(0.6,"mm"),
  annotation_legend_param=list(Subtype=legp(), Stage=legp(), Tissue=legp()))
ht <- Heatmap(mat, name="Z-score", col=nature_heatmap_col(), top_annotation=top,
  show_column_names=FALSE, row_names_gp=gpar(fontsize=5,fontfamily=NATURE_FONT),
  clustering_distance_rows="pearson", clustering_distance_columns="pearson",
  row_dend_width=unit(6,"mm"), column_dend_height=unit(6,"mm"),
  heatmap_legend_param=legp())
save_heatmap(ht, file.path(out,"ref"), width_mm=120, height_mm=150)
cat("done:", file.path(out,"ref.png"), "\n")
```

> 注:`save_heatmap` 的确切输出文件名以 Task 1 `theme_api_notes.md` 为准;若它不直接写 `ref.png`,在本脚本末尾补 `png()/draw(ht)/dev.off()` 显式出 `ref.png`(供 QA)。

- [ ] **Step 2: 跑 plot.R 出图**

Run: `Rscript archetypes/omics-multiannot-heatmap/plot.R`
Expected: 打印 `done: .../out/ref.png`,且该文件存在。

- [ ] **Step 3: 过 QA 门禁**

Run: `Rscript tools/qa_check.R archetypes/omics-multiannot-heatmap/out/ref.png`
Expected: `QA PASS: ref.png — <宽>x<高> px, 角亮度 >=0.9`

- [ ] **Step 4: 写 card.md(说明卡)**

```markdown
# 多注释轨道差异热图 (ComplexHeatmap)

- **何时用**:基因×样本表达矩阵 + 多个样本注释(亚型/分期/组织),想一图展示聚类结构与注释关系。
- **数据形状**:数值矩阵(行=特征,列=样本,建议行 z-score)+ 样本注释 data.frame。
- **依赖**:ComplexHeatmap、circlize、nature_theme.R。
- **配色**:主体 `nature_heatmap_col()`(蓝-白-红发散);注释 `nature_pal_anno` / `nature_seq`。
- **常见翻车点**:① 不做行 z-score → 颜色被极值吃掉;② 注释色用默认彩虹色 → 俗;③ 列名挤成黑条 → `show_column_names=FALSE`;④ 字号过大 → 5–6 pt;⑤ 多图例不合并 → `merge_legend`/统一 `legp()`。
- **参考图**:`out/ref.png`
```

- [ ] **Step 5: 提交**

```bash
git add archetypes/omics-multiannot-heatmap
git commit -m "feat(archetype): 多注释轨道差异热图 + 真参考图(QA 通过)"
```

---

### Task 4: Archetype B — 癌症多组学复合大图

**Files:**
- Create: `archetypes/composite-cancer-multiomics/plot.R`
- Create: `archetypes/composite-cancer-multiomics/card.md`
- Produce: `archetypes/composite-cancer-multiomics/out/ref.{png,pdf}`

**Interfaces:**
- Consumes: `synth_expr`/`synth_survival`/`synth_enrich`/`synth_genome`(Task 2);theme `nature_heatmap_col`/`nature_group_cols`/`nature_seq`/`nature_div`/`theme_nature`/`NATURE_FONT`。
- Produces: `out/ref.png`。展示"一个 Figure 讲一个故事":a 热图 · b 生存 · c 富集 · d 圈图,`cowplot::plot_grid` 拼装。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: 复合多面板叙事大图(癌症多组学)
suppressPackageStartupMessages({
  source("~/.claude/assets/figure-style/nature_theme.R")
  library(ComplexHeatmap); library(circlize); library(grid)
  library(ggplot2); library(survival); library(survminer); library(cowplot); library(scales)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/composite-cancer-multiomics"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d  <- synth_expr(n_genes=24, n_samples=48, seed=1)
sv <- synth_survival(d$col_anno, seed=3)
en <- synth_enrich(seed=4, n=8)
gn <- synth_genome(seed=5)

## a) 表达热图 -> grob
ht <- Heatmap(d$mat, name="Z-score", col=nature_heatmap_col(), show_column_names=FALSE,
  row_names_gp=gpar(fontsize=4.5,fontfamily=NATURE_FONT),
  column_dend_height=unit(4,"mm"), row_dend_width=unit(4,"mm"),
  heatmap_legend_param=list(title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT),
                            labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT)))
gA <- grid.grabExpr(draw(ht, merge_legend=TRUE))

## b) 生存曲线
fit <- survfit(Surv(time, status) ~ group, data=sv)
pal <- unname(nature_group_cols(levels(sv$group)))
gB <- ggsurvplot(fit, data=sv, palette=pal, conf.int=FALSE, censor.size=2,
                 legend.title="", legend="right",
                 ggtheme=theme_nature(base_size=7))$plot +
      labs(x="Time (months)", y="Survival probability")

## c) 富集 dotplot
gC <- ggplot(en, aes(GeneRatio, Term)) +
  geom_point(aes(size=Count, color=p.adjust)) +
  scale_color_gradientn(colours=rev(nature_seq[-1]), trans="log10",
                        name=expression(italic(p)[adj])) +
  scale_size_continuous(range=c(1.5,5), name="Count") +
  labs(x="Gene ratio", y=NULL) + theme_nature(base_size=7)

## d) 基因组圈图 -> grob(base 图经 cowplot 捕获)
draw_circos <- function() {
  circos.clear()
  circos.par(gap.degree=2, cell.padding=c(0,0,0,0), track.margin=c(0.005,0.005))
  tr <- gn$track
  circos.initialize(factors=factor(tr$chr, levels=gn$chromosomes), x=tr$start)
  circos.track(factors=tr$chr, y=tr$cnv, track.height=0.18, bg.border=NA,
    panel.fun=function(x,y) circos.text(CELL_META$xcenter,
        CELL_META$cell.ylim[2]+mm_y(2), CELL_META$sector.index,
        cex=0.4, niceFacing=TRUE))
  for (cn in gn$chromosomes) { s <- tr[tr$chr==cn,]
    circos.lines(s$start, s$cnv, sector.index=cn, col=nature_seq[5], lwd=1) }
  lk <- gn$links
  for (i in seq_len(nrow(lk)))
    circos.link(lk$chr1[i], lk$pos1[i], lk$chr2[i], lk$pos2[i],
                col=alpha(nature_div[1], .4), lwd=0.8)
  circos.clear()
}
gD <- as_grob(draw_circos)

fig <- plot_grid(gA, gB, gC, gD, labels=c("a","b","c","d"),
  label_fontface="bold", label_size=9, label_fontfamily=NATURE_FONT,
  ncol=2, rel_heights=c(1,0.95))

ggsave(file.path(out,"ref.png"), fig, width=183, height=160, units="mm",
       dpi=300, device=ragg::agg_png)
ggsave(file.path(out,"ref.pdf"), fig, width=183, height=160, units="mm", device=cairo_pdf)
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2: 跑 plot.R 出图**

Run: `Rscript archetypes/composite-cancer-multiomics/plot.R`
Expected: 打印 `done: .../out/ref.png`。
若 `as_grob(draw_circos)` 报错(cowplot 捕获 base 图失败),按 systematic-debugging 处理:改用 `cowplot::ggdraw() + cowplot::draw_grob()`,或先把 circos 渲染到临时 png 再 `cowplot::draw_image()`;**不要**降级删掉圈图面板。卡住就停下报告。

- [ ] **Step 3: 过 QA 门禁(复合大图用更高最小宽度)**

Run: `Rscript tools/qa_check.R archetypes/composite-cancer-multiomics/out/ref.png 1800`
Expected: `QA PASS: ref.png — >=1800 宽 px, 角亮度 >=0.9`

- [ ] **Step 4: 写 card.md**

```markdown
# 复合多面板叙事大图(癌症多组学)

- **何时用**:一张 Figure 要把多个证据(表达/生存/通路/基因组)串成一个论证。这是"高大上"最大来源——靠**构图与叙事**,不是单图复杂。
- **数据形状**:每个面板各自的数据(矩阵 / 生存表 / 富集表 / 基因组段)。
- **依赖**:ComplexHeatmap、circlize、cowplot、survminer、ggplot2、nature_theme.R。
- **拼装机制**:非 ggplot 面板(热图/圈图)经 `grid.grabExpr` / `cowplot::as_grob` 转 grob,再与 ggplot 面板一起 `cowplot::plot_grid`。子图标号 a/b/c/d 用 `label_*` 参数,粗体 8–9 pt。
- **常见翻车点**:① ComplexHeatmap/circos 不是 ggplot,直接 patchwork 会失败 → 必须转 grob;② 子图字号不统一 → 全用 7 pt;③ 面板配色各自为政 → 全部走 theme;④ 留白不足、排版挤 → 控制面板数(≤6)、留 gap;⑤ 只导 PNG → 同时出 PDF 矢量。
- **参考图**:`out/ref.png`
```

- [ ] **Step 5: 提交**

```bash
git add archetypes/composite-cancer-multiomics
git commit -m "feat(archetype): 癌症多组学复合大图 + 真参考图(QA 通过)"
```

---

### Task 5: 集成进 nature-figure skill

**Files:**
- Create: `~/.claude/skills/nature-figure/references/advanced-archetypes.md`
- Create: `~/.claude/skills/nature-figure/assets/advanced-archetypes/heatmap.png`、`composite.png`
- Modify(最小追加): `~/.claude/skills/nature-figure/references/r-template-index.md`

**Interfaces:**
- Consumes: 两个 archetype 的 `out/ref.png` 与 `card.md`。
- Produces: skill 内的"高级 archetype 索引 + 野心阶梯",让 agent 拿到任务时主动评估能否上更高级图型。

- [ ] **Step 1: 改 skill 既有文件前先看状态**

```bash
ls -la ~/.claude/skills/nature-figure/references/
git -C ~/.claude/skills/nature-figure status -s 2>/dev/null || echo "(skill 目录非 git 仓库，改前先手动备份 r-template-index.md)"
cp ~/.claude/skills/nature-figure/references/r-template-index.md /tmp/r-template-index.bak.md
```

- [ ] **Step 2: 拷参考图进 skill 资产目录**

```bash
mkdir -p ~/.claude/skills/nature-figure/assets/advanced-archetypes
cp archetypes/omics-multiannot-heatmap/out/ref.png       ~/.claude/skills/nature-figure/assets/advanced-archetypes/heatmap.png
cp archetypes/composite-cancer-multiomics/out/ref.png    ~/.claude/skills/nature-figure/assets/advanced-archetypes/composite.png
```

- [ ] **Step 3: 写 advanced-archetypes.md(索引 + 野心阶梯)**

用 Write 工具写 `~/.claude/skills/nature-figure/references/advanced-archetypes.md`,内容含:
1. **图型野心阶梯**表:常见分析场景 → 基础 / 中级 / **高级** 三档默认选项(例:两组差异:分组柱状图 → 带统计箱线 → 多注释差异热图 / 带边际分布火山图;生存:单 KM → 分层 KM → 多组学复合大图)。规则一句话:**先问"这个结论能不能用更高级、更贴切的图讲",再落到具体 archetype**。
2. **已就绪 archetype 清单**(Phase 0 两个,后续 Phase 追加):每条含 何时用 / 数据形状 / 依赖 / 常见翻车点(从各 `card.md` 蒸馏)+ 参考图相对路径 `assets/advanced-archetypes/*.png`。
3. **诚实边界**:机制示意/解剖卡通/美工拼版 = BioRender/Illustrator,别硬用代码画。

- [ ] **Step 4: 在 r-template-index.md 末尾追加一段指针**

在 `~/.claude/skills/nature-figure/references/r-template-index.md` **末尾**追加(不改原文):

```markdown

## 高级/复合 archetype(见 advanced-archetypes.md)

当任务需要"复杂高大上"图(多注释热图、circos、ggtree、UMAP atlas、Sankey/网络、复合多面板大图)时,
先查 `references/advanced-archetypes.md` 的「图型野心阶梯」与已就绪 archetype,优先复用其参考实现,
再按数据适配。基础~中级图仍走 nature_theme.R 既有函数。
```

- [ ] **Step 5: 校验 skill 改动(只新增 + 一处追加,展示差异)**

```bash
diff /tmp/r-template-index.bak.md ~/.claude/skills/nature-figure/references/r-template-index.md
ls -la ~/.claude/skills/nature-figure/references/advanced-archetypes.md ~/.claude/skills/nature-figure/assets/advanced-archetypes/
```
Expected: diff 只显示末尾新增一段;两个 png + 一个 md 就位。给用户看 diff 确认。

- [ ] **Step 6: 提交(项目侧记录集成完成)**

```bash
git add -A
git commit -m "feat(skill): 集成高级 archetype 索引 + 野心阶梯到 nature-figure"
```

---

### Task 6: Phase 0 回归 + 路线图收口

**Files:**
- Create: `docs/superpowers/plans/ROADMAP.md`

**Interfaces:**
- Produces: 一键回归(env + 两图重出 + QA 全过)与 Phase 1–4 路线图。

- [ ] **Step 1: 一键回归**

```bash
Rscript tools/env_check.R && \
Rscript tools/test_qa.R && \
Rscript archetypes/omics-multiannot-heatmap/plot.R && \
Rscript tools/qa_check.R archetypes/omics-multiannot-heatmap/out/ref.png && \
Rscript archetypes/composite-cancer-multiomics/plot.R && \
Rscript tools/qa_check.R archetypes/composite-cancer-multiomics/out/ref.png 1800 && \
echo "PHASE0 REGRESSION OK"
```
Expected: 末行 `PHASE0 REGRESSION OK`。任一步失败即停下报告,不跳过。

- [ ] **Step 2: 写 ROADMAP.md**

```markdown
# Archetype 库路线图

- [x] Phase 0：脚手架 + QA 门禁 + 多注释热图 + 癌症多组学复合大图 + skill 集成
- [ ] Phase 1（组学硬核）：oncoprint 突变全景 · circos 圈图(独立) · ggtree+heatmap 联排
- [ ] Phase 2（单细胞/空间）：装 monocle3(卡住即停) · UMAP atlas · dotplot 矩阵 · 拟时序 · 空间叠加
- [ ] Phase 3（关系/网络）：ggalluvial/Sankey · ggraph 网络 · chord 弦图 · UpSet
- [ ] Phase 4（收口）：野心阶梯写入 SKILL.md 主流程 · 全库回归 · 文档索引

每个 Phase 各自展开成 docs/superpowers/plans/ 下独立详细计划,沿用 Phase 0 的"五件套 + QA 门禁"模式。
```

- [ ] **Step 3: 提交**

```bash
git add docs/superpowers/plans/ROADMAP.md
git commit -m "docs: Phase 0 回归通过 + Phase 1-4 路线图"
```

---

## 路线图（Phase 1–4 概要，验收后各自展开）

详见 Task 6 产出的 `ROADMAP.md`。每个 Phase 沿用 Phase 0 模式(可跑脚本 + 合成数据 + 真参考图 + QA 门禁 + card + skill 集成),各自一份独立详细计划。Phase 2 起始需后台试装 `monocle3`,卡住即停下与用户商量,不静默降级。
