# Nature 高级图型 archetype 库 — Phase 1（组学硬核）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 Phase 0 地基上，先把字体设定 DRY 收口，再加三个组学硬核 archetype（oncoprint 突变全景、circos 独立圈图、ggtree 进化树+热图联排），每张卡片带「分析严谨护栏」，集成进 `nature-figure` skill。

**Architecture:** 沿用 Phase 0 的"五件套 + QA 门禁"模式：每个 archetype = 可跑脚本（source 共享 `_lib/figure_setup.R` preamble → 统一字体+主题）+ 真渲染参考图（过 `tools/qa_check.R`）+ 含渲染**与分析**双重翻车点的 card。新增合成数据生成器进 `_lib/synth_data.R`。

**Tech Stack:** R 4.4.3 · ComplexHeatmap(oncoPrint) · circlize · ggtree/treeio/ape/aplot · ggplot2 · ragg/Cairo。全部已实测安装。

## Global Constraints

- 配色/主题/字体唯一真源：脚本顶部 `source(here_lib("figure_setup.R"))`（它内部 `options(nature_font="Helvetica"); source("~/.claude/assets/figure-style/nature_theme.R")`）；**不再每图各写 options/source**，不复制配色。
- 每个脚本必须**真跑、出真图**；参考图来自真跑，绝不编造/占位。
- 合成数据**设种子**、可复现；不依赖任何真实/私有数据。
- 图内文字一律**英文**；中文只在 card.md / docs（用 Write 写，防乱码）。
- **缺包先停下商量**（Phase 1 所需包已实测齐备：ape/ggtree/treeio/aplot/ggnewscale/ComplexHeatmap/circlize；若 env 报缺，停）。
- **每张新 archetype 卡片的「常见翻车点」必须含分析/严谨性陷阱**（不只渲染），至少 1 条针对该图型的"会让人得出比数据更强结论"的风险。
- 导出多格式：PNG（预览/QA）+ PDF/SVG（矢量）。版心宽度用 `NATURE_W_*`。
- 改既有文件前 `git diff` 展示；skill 侧改动走 Task 7 的部署流程（已授权）。

## 文件结构

```
archetypes/
├── _lib/
│   ├── figure_setup.R          # 新增：字体+主题 preamble（DRY 收口点）
│   └── synth_data.R            # 扩展：+ synth_mutations() + synth_tree()
├── omics-multiannot-heatmap/plot.R     # 改：改用 figure_setup.R
├── composite-cancer-multiomics/plot.R  # 改：改用 figure_setup.R
├── omics-oncoprint/            # 新：archetype ③
│   ├── plot.R · card.md · out/ref.{png,pdf}
├── genome-circos/              # 新：archetype ④
│   ├── plot.R · card.md · out/ref.{png,pdf}
└── phylo-tree-heatmap/         # 新：archetype ⑤
    ├── plot.R · card.md · out/ref.{png,pdf}
skill-integration/advanced-archetypes.md   # 改：3 条新 archetype 标 ✅就绪 + 卡片
docs/superpowers/plans/ROADMAP.md          # 改：勾掉 Phase 1
```

---

### Task 1: 字体 DRY 收口 — figure_setup.R preamble

**Files:**
- Create: `archetypes/_lib/figure_setup.R`
- Modify: `archetypes/omics-multiannot-heatmap/plot.R`、`archetypes/composite-cancer-multiomics/plot.R`

**Interfaces:**
- Produces: `figure_setup.R`，被 source 后：① 已 `options(nature_font="Helvetica")`；② 已 `source(nature_theme.R)`（即 `theme_nature`/`save_heatmap`/`nature_*` 全可用）；③ 提供 `here_lib(f)` 帮助函数返回 `_lib` 下文件的绝对路径。

- [ ] **Step 1: 写 figure_setup.R**

```r
# 图形 preamble：字体 + 主题的单一收口点。所有 archetype plot.R 顶部 source 本文件，
# 不再各自 options(nature_font=...) / source(theme)。英文图统一 Helvetica(→真 Arial,0 字体警告)。
local({
  # 解析本文件所在目录（被 source 时 sys.frame 的 ofile 可用；Rscript 直接跑时回退）
  this <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NA_character_)
  if (is.na(this)) {
    args <- commandArgs(FALSE); fa <- sub("--file=", "", grep("--file=", args, value = TRUE))
    this <- if (length(fa)) normalizePath(fa[1]) else "archetypes/_lib/figure_setup.R"
  }
  assign(".FIG_LIB_DIR", dirname(this), envir = globalenv())
})
here_lib <- function(f) file.path(get(".FIG_LIB_DIR", envir = globalenv()), f)

options(nature_font = "Helvetica")
suppressPackageStartupMessages(
  source("~/.claude/assets/figure-style/nature_theme.R")
)
```

- [ ] **Step 2: 验证 figure_setup.R 可被 source 且接口齐备**

Run:
```bash
cd /mnt/f/work/research/nature_figure_skill
Rscript -e 'source("archetypes/_lib/figure_setup.R"); stopifnot(getOption("nature_font")=="Helvetica", exists("theme_nature"), exists("save_heatmap"), is.function(here_lib)); cat("figure_setup OK\n")'
```
Expected: `figure_setup OK`

- [ ] **Step 3: 改 omics-multiannot-heatmap/plot.R 顶部改用 preamble**

把开头的
```r
suppressPackageStartupMessages({
  # Nature 图为英文专用 → 严格 Helvetica 字形（Nature 标准西文）。
  # ...（原注释若干行）...
  options(nature_font = "Helvetica")
  source("~/.claude/assets/figure-style/nature_theme.R")
  library(ComplexHeatmap); library(circlize); library(grid)
})
```
整体替换为：
```r
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ComplexHeatmap); library(circlize); library(grid)
})
```
（其余代码不动。`source` 的相对路径基于脚本自身位置 → `_lib/figure_setup.R`。）

- [ ] **Step 4: 改 composite-cancer-multiomics/plot.R 顶部同样改用 preamble**

把开头的
```r
suppressPackageStartupMessages({
  # Nature 图为英文专用 → 严格 Helvetica 字形（与 omics 热图一致，Nature 标准西文）。
  # ...（原注释若干行）...
  options(nature_font = "Helvetica")
  source("~/.claude/assets/figure-style/nature_theme.R")
  library(ComplexHeatmap); library(circlize); library(grid)
  library(ggplot2); library(survival); library(survminer); library(cowplot); library(scales)
})
```
整体替换为：
```r
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ComplexHeatmap); library(circlize); library(grid)
  library(ggplot2); library(survival); library(survminer); library(cowplot); library(scales)
})
```

- [ ] **Step 5: 两图重渲 + QA，确认改 preamble 后行为不变**

Run:
```bash
Rscript archetypes/omics-multiannot-heatmap/plot.R && Rscript tools/qa_check.R archetypes/omics-multiannot-heatmap/out/ref.png
Rscript archetypes/composite-cancer-multiomics/plot.R && Rscript tools/qa_check.R archetypes/composite-cancer-multiomics/out/ref.png 1800
```
Expected: 两行都 `QA PASS`，且运行日志出现 `使用字体 'Helvetica'`（证明 preamble 生效）。

- [ ] **Step 6: 丢弃非确定性 pdf 字节变动后提交**

```bash
git checkout -- archetypes/omics-multiannot-heatmap/out/ archetypes/composite-cancer-multiomics/out/ 2>/dev/null
git add archetypes/_lib/figure_setup.R archetypes/omics-multiannot-heatmap/plot.R archetypes/composite-cancer-multiomics/plot.R
git commit -m "refactor: 字体设定收口到 _lib/figure_setup.R preamble（DRY，两图改用）"
```

---

### Task 2: 扩展合成数据 — synth_mutations + synth_tree

**Files:**
- Modify: `archetypes/_lib/synth_data.R`（追加两个函数）

**Interfaces:**
- Consumes: 无（独立生成器）。
- Produces:
  - `synth_mutations(n_genes=20, n_samples=40, seed=7)` → `list(mat=字符矩阵 基因×样本（元素为分号分隔的变异类型，如 "Missense;Amp" 或 ""）, types=变异类型向量 c("Missense","Truncating","Amp","Del"), clin=data.frame(Subtype,Stage row.names=样本))`
  - `synth_tree(n_tip=24, n_feat=6, seed=8)` → `list(tree=ape::phylo, mat=tip×feature 数值矩阵(行名=tip label), group=每个 tip 的分组 factor)`

- [ ] **Step 1: 在 synth_data.R 末尾追加两个生成器**

```r
# —— Phase 1 追加 ——
synth_mutations <- function(n_genes = 20, n_samples = 40, seed = 7) {
  set.seed(seed)
  types <- c("Missense", "Truncating", "Amp", "Del")
  genes <- paste0("GENE", sprintf("%02d", seq_len(n_genes)))
  samp  <- paste0("P", sprintf("%03d", seq_len(n_samples)))
  freq  <- sort(runif(n_genes, 0.05, 0.6), decreasing = TRUE)   # 高频基因在前
  mat <- matrix("", n_genes, n_samples, dimnames = list(genes, samp))
  for (i in seq_len(n_genes)) for (j in seq_len(n_samples)) {
    if (runif(1) < freq[i]) {
      k <- sample(types, sample(1:2, 1), prob = c(.5, .25, .15, .10))
      mat[i, j] <- paste(k, collapse = ";")
    }
  }
  clin <- data.frame(
    Subtype = factor(sample(c("S1","S2","S3"), n_samples, TRUE)),
    Stage   = factor(sample(c("I","II","III"), n_samples, TRUE), levels = c("I","II","III")),
    row.names = samp)
  list(mat = mat, types = types, clin = clin)
}

synth_tree <- function(n_tip = 24, n_feat = 6, seed = 8) {
  set.seed(seed)
  if (!requireNamespace("ape", quietly = TRUE)) stop("需要 ape 包")
  tr <- ape::rtree(n_tip)
  tr$tip.label <- paste0("T", sprintf("%02d", seq_len(n_tip)))
  grp <- factor(sample(c("Clade A","Clade B","Clade C"), n_tip, TRUE))
  mat <- matrix(rnorm(n_tip * n_feat), n_tip, n_feat,
                dimnames = list(tr$tip.label, paste0("Feat", seq_len(n_feat))))
  mat <- mat + as.numeric(grp)                      # 按 clade 注入结构
  mat <- t(scale(t(mat)))                           # 行 z-score
  list(tree = tr, mat = mat, group = grp)
}
```

- [ ] **Step 2: 验证两个生成器形状正确**

Run:
```bash
Rscript -e 'source("archetypes/_lib/synth_data.R"); m<-synth_mutations(); stopifnot(dim(m$mat)==c(20,40), is.character(m$mat)); t<-synth_tree(); stopifnot(inherits(t$tree,"phylo"), nrow(t$mat)==24); cat("synth phase1 OK\n")'
```
Expected: `synth phase1 OK`

- [ ] **Step 3: 提交**

```bash
git add archetypes/_lib/synth_data.R
git commit -m "feat(synth): 追加 synth_mutations + synth_tree（Phase 1 archetype 用）"
```

---

### Task 3: Archetype ③ — oncoprint 突变全景

**Files:**
- Create: `archetypes/omics-oncoprint/plot.R`、`archetypes/omics-oncoprint/card.md`
- Produce: `archetypes/omics-oncoprint/out/ref.{png,pdf}`

**Interfaces:**
- Consumes: `synth_mutations()`（Task 2）；`figure_setup.R`；ComplexHeatmap::oncoPrint。
- Produces: `out/ref.png`。

- [ ] **Step 1: 写 plot.R（用 ComplexHeatmap::oncoPrint，配色取自 theme）**

```r
#!/usr/bin/env Rscript
# Archetype: oncoprint 突变全景 (ComplexHeatmap::oncoPrint)
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ComplexHeatmap); library(grid)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/omics-oncoprint"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d <- synth_mutations(n_genes=20, n_samples=40, seed=7)
mat <- d$mat; clin <- d$clin

# 变异类型配色（取自 theme 调色板，不硬编）
vcol <- c(Missense   = nature_pal_anno[4],
          Truncating = nature_div[1],
          Amp        = nature_sig_col[["Up"]],
          Del        = nature_sig_col[["Down"]])
# alter_fun：每种变异画一个矩形/条
alter_fun <- list(
  background = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.85, gp=gpar(fill="#EEEEEE", col=NA)),
  Missense   = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.85, gp=gpar(fill=vcol["Missense"], col=NA)),
  Truncating = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.85, gp=gpar(fill=vcol["Truncating"], col=NA)),
  Amp        = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.40, gp=gpar(fill=vcol["Amp"], col=NA)),
  Del        = function(x,y,w,h) grid.rect(x,y,w*0.92,h*0.40, gp=gpar(fill=vcol["Del"], col=NA)))

top_anno <- HeatmapAnnotation(
  Subtype = clin$Subtype, Stage = clin$Stage,
  col = list(Subtype = setNames(nature_pal_anno[1:3], levels(clin$Subtype)),
             Stage   = setNames(nature_seq[c(2,4,6)], levels(clin$Stage))),
  annotation_name_gp = gpar(fontsize=6, fontfamily=NATURE_FONT),
  simple_anno_size = unit(2.5,"mm"),
  annotation_legend_param = list(
    Subtype=list(title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT), labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT)),
    Stage  =list(title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT), labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT))))

ht <- oncoPrint(mat, get_type = function(x) strsplit(x, ";")[[1]],
  alter_fun = alter_fun, col = vcol, top_annotation = top_anno,
  row_names_gp = gpar(fontsize=5.5, fontfamily=NATURE_FONT),
  pct_gp = gpar(fontsize=5, fontfamily=NATURE_FONT),
  column_title = "Mutation landscape (synthetic demo)",
  column_title_gp = gpar(fontsize=7, fontfamily=NATURE_FONT, fontface="bold"),
  heatmap_legend_param = list(title="Alteration",
    title_gp=gpar(fontsize=6,fontfamily=NATURE_FONT), labels_gp=gpar(fontsize=5,fontfamily=NATURE_FONT)))

save_heatmap(ht, file.path(out,"ref"), width_mm=150, height_mm=120)
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2: 跑 plot.R 出图**

Run: `Rscript archetypes/omics-oncoprint/plot.R`
Expected: 打印 `done: .../out/ref.png`。若 oncoPrint 因某变异类型在 alter_fun/col 命名不一致报错，对照 `vcol` 名称修正，不要删变异类型。

- [ ] **Step 3: 过 QA**

Run: `Rscript tools/qa_check.R archetypes/omics-oncoprint/out/ref.png 1200`
Expected: `QA PASS`

- [ ] **Step 4: 写 card.md（含渲染 + 分析双重翻车点）**

```markdown
# oncoprint 突变全景 (ComplexHeatmap::oncoPrint)

- **何时用**：基因×样本的突变/CNV 矩阵，想一图展示哪些基因在哪些样本被改变、变异类型构成、与临床注释的关系。癌症基因组 Main Figure 常客。
- **数据形状**：字符矩阵（行=基因，列=样本，元素为分号分隔的变异类型，如 "Missense;Amp"，无变异为 ""）+ 样本临床注释 data.frame。
- **核心依赖**：ComplexHeatmap（oncoPrint）、figure_setup.R。
- **配色规则**：变异类型色取自 theme（nature_pal_anno/nature_div/nature_sig_col），不硬编彩虹。
- **常见翻车点（渲染）**：① get_type 拆分符与数据里的分隔符不一致 → 变异丢失；② alter_fun 的 key 和 col 命名不一致 → 报错或漏画；③ 样本太多列名挤 → 关列名、靠 top 注释；④ Amp/Del 用满格矩形会盖住点突变 → 用半高条分层。
- **常见翻车点（分析严谨）**：⑤ **基因排序默认按改变频率，会让"高频=重要"产生暗示**——若高频基因是大基因/已知 hypermutation 热点，需说明排序依据、必要时按驱动证据而非频率；⑥ **样本若来自不同测序 panel/深度，突变检出率不可直接比**，先说明 panel 一致性，否则"某亚型突变多"可能只是测得深。
- **参考实现**：`archetypes/omics-oncoprint/`
```

- [ ] **Step 5: 提交**

```bash
git add archetypes/omics-oncoprint
git commit -m "feat(archetype): oncoprint 突变全景 + 真参考图(QA 通过)"
```

---

### Task 4: Archetype ④ — circos 独立圈图

**Files:**
- Create: `archetypes/genome-circos/plot.R`、`archetypes/genome-circos/card.md`
- Produce: `archetypes/genome-circos/out/ref.{png,pdf}`

**Interfaces:**
- Consumes: `synth_genome()`（Phase 0 synth_data.R）；`figure_setup.R`；circlize。
- Produces: `out/ref.png`。比 Phase 0 复合图里的圈图面板更丰富：扇区标签 + CNV 线轨 + 点轨 + 染色体间连线。

- [ ] **Step 1: 写 plot.R（circlize base 图，直接出 png/pdf）**

```r
#!/usr/bin/env Rscript
# Archetype: 独立基因组圈图 (circlize) —— 多轨道 + 连线
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(circlize); library(ragg)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/genome-circos"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

gn <- synth_genome(seed=5, n_chr=12, per=60)
tr <- gn$track

draw_circos <- function() {
  circos.clear()
  circos.par(gap.degree=2, cell.padding=c(0,0,0,0), track.margin=c(0.004,0.004),
             start.degree=90)
  circos.initialize(factors=factor(tr$chr, levels=gn$chromosomes), x=tr$start)
  # 轨1：扇区标签 + 外圈刻度块
  circos.track(factors=tr$chr, ylim=c(0,1), track.height=0.06, bg.border=NA,
    panel.fun=function(x,y){
      circos.rect(CELL_META$cell.xlim[1], 0, CELL_META$cell.xlim[2], 1,
                  col=nature_seq[4], border=NA)
      circos.text(CELL_META$xcenter, 1.8, CELL_META$sector.index,
                  cex=0.5, niceFacing=TRUE, facing="bending.inside")})
  # 轨2：CNV 线
  cnv_range <- range(tr$cnv)
  circos.track(factors=tr$chr, y=tr$cnv, ylim=cnv_range, track.height=0.20, bg.border=NA,
    panel.fun=function(x,y){
      circos.lines(c(CELL_META$cell.xlim[1],CELL_META$cell.xlim[2]), c(0,0),
                   col="#CCCCCC", lwd=0.5)
      circos.lines(x, y, col=nature_div[7], lwd=1, area=FALSE)})
  # 轨3：表达点
  circos.track(factors=tr$chr, y=tr$expr, track.height=0.16, bg.border=NA,
    panel.fun=function(x,y) circos.points(x, y, pch=16, cex=0.18,
                                          col=scales::alpha(nature_div[1], .5)))
  # 中心连线
  lk <- gn$links
  for (i in seq_len(nrow(lk)))
    circos.link(lk$chr1[i], lk$pos1[i], lk$chr2[i], lk$pos2[i],
                col=scales::alpha(nature_div[2], .35), lwd=0.9)
  circos.clear()
}

w <- 150/25.4; h <- 150/25.4
agg_png(file.path(out,"ref.png"), width=w, height=h, units="in", res=600, background="white")
draw_circos(); title(main="Genome-wide circos: CNV + expression + interchromosomal links",
                     cex.main=0.8, font.main=2); dev.off()
cairo_pdf(file.path(out,"ref.pdf"), width=w, height=h, family="Helvetica")
draw_circos(); title(main="Genome-wide circos: CNV + expression + interchromosomal links",
                     cex.main=0.8, font.main=2); dev.off()
unlink("Rplots.pdf")
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2: 跑 plot.R 出图**

Run: `Rscript archetypes/genome-circos/plot.R`
Expected: `done: .../out/ref.png`。circos "point out of plotting region" 提示是合成随机游走数据所致，可接受（不要 clamp 掉真实信号；本图为合成 demo）。

- [ ] **Step 3: 过 QA**

Run: `Rscript tools/qa_check.R archetypes/genome-circos/out/ref.png 1200`
Expected: `QA PASS`

- [ ] **Step 4: 写 card.md（含渲染 + 分析双重翻车点）**

```markdown
# 独立基因组圈图 (circlize)

- **何时用**：全基因组多维证据（CNV、表达、突变密度、染色体间重排/互作）想在一张圆图里同时展示；泛基因组/结构变异 Figure。
- **数据形状**：每条染色体的位置 + 各轨道数值（CNV/表达…）+ 连线端点（chr1,pos1,chr2,pos2）。
- **核心依赖**：circlize、ragg、figure_setup.R。
- **配色规则**：轨道/连线色取自 theme（nature_seq/nature_div），不硬编。
- **常见翻车点（渲染）**：① circos 是 base 图、非 ggplot → 出图用 agg_png/cairo_pdf 直接画，别塞 ggsave；② 忘了 circos.clear() 两端包裹 → 状态泄漏；③ 轨道太多挤成糊 → 控制 ≤4 轨、留 track.margin；④ 默认会写 Rplots.pdf → 末尾 unlink。
- **常见翻车点（分析严谨）**：⑤ **连线(links)极易过度解读**——视觉上"连起来"会暗示因果/互作，但若只是共现/相关，必须在图注写清是相关而非验证的互作；⑥ **CNV 轨用未按 ploidy/纯度校正的原始拷贝数**会夸大幅度，跨样本比较前先说明校正口径。
- **参考实现**：`archetypes/genome-circos/`
```

- [ ] **Step 5: 提交**

```bash
git add archetypes/genome-circos
git commit -m "feat(archetype): 独立基因组圈图(circlize 多轨道+连线) + 真参考图(QA 通过)"
```

---

### Task 5: Archetype ⑤ — ggtree 进化树 + 热图联排

**Files:**
- Create: `archetypes/phylo-tree-heatmap/plot.R`、`archetypes/phylo-tree-heatmap/card.md`
- Produce: `archetypes/phylo-tree-heatmap/out/ref.{png,pdf}`

**Interfaces:**
- Consumes: `synth_tree()`（Task 2）；`figure_setup.R`；ggtree::gheatmap。
- Produces: `out/ref.png`。树（按 clade 着色）+ 右侧 tip×feature 热图联排。

- [ ] **Step 1: 写 plot.R（ggtree + gheatmap，ggplot 对象用 save_nature 导出）**

```r
#!/usr/bin/env Rscript
# Archetype: 进化树 + 热图联排 (ggtree::gheatmap)
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggtree); library(ggplot2)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/phylo-tree-heatmap"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d <- synth_tree(n_tip=24, n_feat=6, seed=8)
grp_df <- data.frame(label=d$tree$tip.label, Clade=d$group)
gcol <- setNames(nature_pal_anno[1:nlevels(d$group)], levels(d$group))

p <- ggtree(d$tree, linewidth=0.4) %<+% grp_df +
  geom_tippoint(aes(color=Clade), size=1.1) +
  geom_tiplab(size=1.6, family=NATURE_FONT, align=TRUE, linesize=0.15) +
  scale_color_manual(values=gcol, name="Clade") +
  theme_tree2(base_family=NATURE_FONT) +
  theme(legend.position="left", legend.title=element_text(size=6),
        legend.text=element_text(size=5))

ph <- gheatmap(p, as.data.frame(d$mat), offset=0.6, width=0.6,
               colnames_position="top", font.size=1.8,
               colnames_angle=90, hjust=0) +
  scale_fill_gradientn(colours=nature_div, name="Row z",
                       guide=guide_colorbar(barwidth=0.4, barheight=3)) +
  theme(legend.title=element_text(size=6), legend.text=element_text(size=5))

save_nature(ph, file.path(out,"ref"), width_mm=150, height_mm=120)
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2: 跑 plot.R 出图**

Run: `Rscript archetypes/phylo-tree-heatmap/plot.R`
Expected: `done: .../out/ref.png`。注：`save_nature` 的输出文件名/格式以 Task 1 已知（写 ref.png + ref.pdf + ref.svg）为准；若 `%<+%`/`gheatmap` 因 ggtree 版本报参数名差异，读 `?gheatmap` 修正参数，不要换掉联排机制。

- [ ] **Step 3: 过 QA**

Run: `Rscript tools/qa_check.R archetypes/phylo-tree-heatmap/out/ref.png 1200`
Expected: `QA PASS`

- [ ] **Step 4: 写 card.md（含渲染 + 分析双重翻车点）**

```markdown
# 进化树 + 热图联排 (ggtree::gheatmap)

- **何时用**：一组样本/物种/克隆有层级（系统发育、层次聚类树），想把树结构与每个叶子的特征矩阵（表达/丰度/基因型）对齐展示。微生物组、肿瘤克隆进化、菌株分型 Figure。
- **数据形状**：一棵树（ape::phylo / treedata）+ tip×feature 数值矩阵（行名=tip label，须与树叶标签一致）。
- **核心依赖**：ggtree、ggplot2、figure_setup.R。
- **配色规则**：clade/分组色取自 nature_pal_anno；热图用 nature_div。
- **常见翻车点（渲染）**：① 矩阵行名与 tip.label 不一致 → 热图错位/留白；② gheatmap 的 offset/width 没调 → 树和热图重叠或离太远；③ tip 标签字号过大挤成团 → ≤2 pt + align=TRUE；④ 列名角度默认 0 度会重叠 → colnames_angle=90。
- **常见翻车点（分析严谨）**：⑤ **树的拓扑会强烈暗示"亲缘/演化关系"**——若树其实是表达距离的层次聚类（非真系统发育），别用"进化/谱系"措辞，标注清楚是 clustering dendrogram 还是 phylogeny；⑥ **bootstrap/支持度未显示时，分支可信度被默认当成 100%**，关键分叉应标支持值。
- **参考实现**：`archetypes/phylo-tree-heatmap/`
```

- [ ] **Step 5: 提交**

```bash
git add archetypes/phylo-tree-heatmap
git commit -m "feat(archetype): ggtree 进化树+热图联排 + 真参考图(QA 通过)"
```

---

### Task 6: 集成进 skill-integration（项目侧）

**Files:**
- Modify: `skill-integration/advanced-archetypes.md`（野心阶梯标 ✅就绪 + 新增 3 条 archetype 清单）

**Interfaces:**
- Consumes: 三个新 archetype 的 card.md 与 out/ref.png。
- Produces: 更新后的 advanced-archetypes.md（项目侧真源），供 Task 7 部署。

- [ ] **Step 1: 野心阶梯里把已就绪项更新**

在 `skill-integration/advanced-archetypes.md` 的「① 图型野心阶梯」表中：把「癌症基因组」相关高级项的 oncoprint/circos 标 `✅就绪`（Phase 1 已建）；进化树/克隆相关若在表中同样标注。若阶梯表无对应行，在「② 已就绪 Archetype 清单」新增即可，不强行塞表。

- [ ] **Step 2: 在「② 已就绪 Archetype 清单」追加三条**

用 Write/Edit 在该节末尾追加三个 archetype 小节（oncoprint / circos / ggtree+heatmap），每条从对应 `card.md` 蒸馏，**必须包含该卡片的「分析严谨」翻车点**，并标注参考图相对路径 `assets/advanced-archetypes/oncoprint.png` / `circos.png` / `phylo_heatmap.png`（部署后路径）。

- [ ] **Step 3: 自检 + 提交**

确认：三条新 archetype 各含「分析严谨」翻车点；野心阶梯就绪标注与实际一致。
```bash
git add skill-integration/advanced-archetypes.md
git commit -m "docs(skill-integration): 野心阶梯增 oncoprint/circos/ggtree 三 archetype（带分析护栏）"
```

---

### Task 7: 部署 + 回归 + 路线图

**Files:**
- Modify: `~/.claude/skills/nature-figure/references/advanced-archetypes.md`（部署）
- Create: `~/.claude/skills/nature-figure/assets/advanced-archetypes/{oncoprint,circos,phylo_heatmap}.png`（部署）
- Modify: `docs/superpowers/plans/ROADMAP.md`（勾掉 Phase 1）

**Interfaces:**
- Produces: 全库回归通过 + skill 部署同步 + 路线图更新。

- [ ] **Step 1: Phase 1 回归（全部 archetype 重渲 + QA）**

```bash
cd /mnt/f/work/research/nature_figure_skill
Rscript tools/env_check.R && Rscript tools/test_qa.R && \
for a in omics-multiannot-heatmap composite-cancer-multiomics omics-oncoprint genome-circos phylo-tree-heatmap; do
  Rscript archetypes/$a/plot.R || { echo "FAIL $a"; exit 1; }
done && \
Rscript tools/qa_check.R archetypes/omics-multiannot-heatmap/out/ref.png && \
Rscript tools/qa_check.R archetypes/composite-cancer-multiomics/out/ref.png 1800 && \
Rscript tools/qa_check.R archetypes/omics-oncoprint/out/ref.png 1200 && \
Rscript tools/qa_check.R archetypes/genome-circos/out/ref.png 1200 && \
Rscript tools/qa_check.R archetypes/phylo-tree-heatmap/out/ref.png 1200 && \
echo "PHASE1 REGRESSION OK"
```
Expected: 末行 `PHASE1 REGRESSION OK`。任一步失败即停下报告，不跳过。

- [ ] **Step 2: 部署到 skill（拷 3 张新参考图 + 更新 advanced-archetypes.md）**

```bash
SKILL=~/.claude/skills/nature-figure
BAK="/tmp/advanced-archetypes.bak.$(date +%Y%m%d_%H%M%S).md"
cp "$SKILL/references/advanced-archetypes.md" "$BAK"
cp skill-integration/advanced-archetypes.md "$SKILL/references/advanced-archetypes.md"
cp archetypes/omics-oncoprint/out/ref.png   "$SKILL/assets/advanced-archetypes/oncoprint.png"
cp archetypes/genome-circos/out/ref.png     "$SKILL/assets/advanced-archetypes/circos.png"
cp archetypes/phylo-tree-heatmap/out/ref.png "$SKILL/assets/advanced-archetypes/phylo_heatmap.png"
cmp -s skill-integration/advanced-archetypes.md "$SKILL/references/advanced-archetypes.md" && echo "部署一致 ✓"
ls -lh "$SKILL/assets/advanced-archetypes/"
```
Expected: `部署一致 ✓`，assets 目录含 5 张 png（含 Phase 0 两张）。

- [ ] **Step 3: 更新 ROADMAP.md（勾掉 Phase 1）**

用 Edit 把 `docs/superpowers/plans/ROADMAP.md` 里 `- [ ] Phase 1（组学硬核）...` 改为 `- [x]`，并补一句"oncoprint/circos/ggtree 已就绪"。

- [ ] **Step 4: 提交**

```bash
git checkout -- archetypes/*/out/*.pdf 2>/dev/null
git add -A
git commit -m "feat(phase1): 部署 3 archetype 进 skill + Phase1 回归通过 + 路线图更新"
```

---

## 自检（Self-Review 结果）

- **覆盖**：字体 DRY（T1）、新合成数据（T2）、oncoprint（T3）、circos（T4）、ggtree（T5）、集成（T6）、部署+回归（T7）——Phase 1 范围全覆盖。
- **分析护栏**：T3/T4/T5 的 card 各含「分析严谨」翻车点（oncoprint 排序/panel 偏差、circos links 过度解读/ploidy、ggtree 拓扑误读/支持度），落实验证发现的原则。
- **类型一致**：synth_mutations 返回 `list(mat,types,clin)`、synth_tree 返回 `list(tree,mat,group)`，T3/T5 调用一致；figure_setup.R 的 `here_lib`/preamble 全程一致。
- **占位**：无 TBD；API 不确定处（save_nature 输出名、gheatmap 参数、oncoPrint alter_fun）均给了具体处置且不降级。
