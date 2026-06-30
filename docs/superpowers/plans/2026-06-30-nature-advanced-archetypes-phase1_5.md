# Nature 高级图型 archetype 库 — Phase 1.5（参考包学习 → 优化现有 + house 沉淀）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 把 `/mnt/f/work/research/nature_R/` 参考包(尤其两个 demo)里的可迁移做法落地：① 把复合大图升级成 patchwork **hero 布局** + 充分调用 `nature_theme.R` 既有 house 函数 + `tag_levels="A"`；② 新增 **volcano archetype**(ggsci NPG + ggrepel)；③ 把「设计克制护栏」+「诚实 caption 约定」沉淀进 skill；并为 Phase 2/3 标注参考蓝本。

**Architecture:** 沿用"五件套 + QA 门禁"模式。本阶段以**优化现有 archetype**为主 + 1 个新 archetype。**不改跨项目共享真源 `nature_theme.R`**（ggsci 期刊配色是否折进 theme，作为单独的跨项目决策列入 ROADMAP，本阶段不做）。ggsci 仅在 volcano archetype 内**局部**使用。

**Tech Stack:** R 4.4.3 · patchwork · ggsci · ggrepel · ggplot2 · ComplexHeatmap · survival/survminer · 既有 `_lib/figure_setup.R` + `nature_theme.R` house 函数。全部已实测安装。

## Global Constraints

- 配色/主题/字体唯一真源：plot.R 顶部 source `_lib/figure_setup.R`；**优先调用 theme 既有 house 函数**(`nature_heatmap`/`nature_hm_anno`/`nature_pca`/`nature_enrich_dot`/`nature_km`/`nature_volcano`/`nature_hm_gp`)，少手搓。
- **不修改 `~/.claude/assets/figure-style/nature_theme.R`**（跨项目共享真源）。ggsci 配色只在 archetype 脚本内局部用；"折进 theme"是 ROADMAP 里待用户决策的独立项。
- 每个脚本真跑、出真图；参考图来自真跑，绝不编造/占位；合成数据设种子可复现。
- 图内文字一律**英文**（参考 demo 用了中文，我们守英文）；中文只在 card.md/docs（用 Write 写，防乱码）。
- 每张 archetype 卡片「常见翻车点」含**渲染 + 分析严谨**双重陷阱。
- 拼图用 `patchwork`（`plot_layout(design=...)` + `plot_annotation(tag_levels="A")`），导出多格式 PNG/PDF/SVG。
- 诚实 caption 约定：复合/演示图的 caption 注明 `set.seed`、关键阈值、"synthetic demo, not real results"。

## 文件结构

```
archetypes/
├── _lib/synth_data.R                       # 改：+ synth_deg()（volcano 用）
├── composite-cancer-multiomics/plot.R      # 改：retrofit 成 hero 布局 + theme 函数 + tag_levels
│   └── card.md                             # 改：更新机制说明 + 诚实 caption
├── volcano-deg/                            # 新：archetype ⑥
│   ├── plot.R · card.md · out/ref.{png,pdf}
skill-integration/advanced-archetypes.md    # 改：+设计克制护栏 +诚实caption约定 +volcano条目 +composite更新
docs/superpowers/plans/ROADMAP.md           # 改：Phase 1.5 + Phase 2/3 参考蓝本标注 + ggsci-theme 决策项
```

---

### Task 1: synth_deg 生成器（volcano 用）

**Files:** Modify `archetypes/_lib/synth_data.R`（末尾追加）

**Interfaces:**
- Produces: `synth_deg(n=12000, n_up=280, n_dn=260, seed=42)` → `data.frame(gene, logFC, adj.P.Val, sig=factor(Up/Down/ns levels), y=-log10(adjP))`，并把最剧烈的若干基因名替换成可识别符号（便于标注）。

- [ ] **Step 1: 追加 synth_deg**

```r
# —— Phase 1.5 追加：差异表达（火山图用）——
synth_deg <- function(n = 12000, n_up = 280, n_dn = 260, seed = 42) {
  set.seed(seed)
  n_ns <- n - n_up - n_dn
  lf_ns <- rnorm(n_ns, 0, 0.35); z_ns <- rnorm(n_ns, 0, 0.9)
  lf_up <- rnorm(n_up,  2.4, 0.7); z_up <- lf_up/0.30 + rnorm(n_up, 0, 1.2)
  lf_dn <- rnorm(n_dn, -2.4, 0.7); z_dn <- lf_dn/0.30 + rnorm(n_dn, 0, 1.2)
  logFC <- c(lf_ns, lf_up, lf_dn)
  pval  <- 2 * pnorm(-abs(c(z_ns, z_up, z_dn)))
  adjP  <- p.adjust(pval, "BH")
  gene  <- sprintf("G%05d", seq_len(n))
  up_sym <- c("MMP9","SPP1","CDK1","TOP2A","COL1A1","KIF20A","CCNB1","AURKA","FOXM1","UBE2C")
  dn_sym <- c("ADH1B","PLIN1","CIDEC","ADIPOQ","FABP4","CD36","PPARG","KLF15","LPL","CFD")
  gene[order(-logFC)[seq_along(up_sym)]] <- up_sym
  gene[order( logFC)[seq_along(dn_sym)]] <- dn_sym
  fc_th <- 1; p_th <- 0.05
  sig <- factor(ifelse(adjP < p_th & logFC >=  fc_th, "Up",
                ifelse(adjP < p_th & logFC <= -fc_th, "Down", "ns")),
                levels = c("Up","Down","ns"))
  data.frame(gene = gene, logFC = logFC, adj.P.Val = adjP, sig = sig,
             y = -log10(pmax(adjP, 1e-300)), stringsAsFactors = FALSE)
}
```

- [ ] **Step 2: 验证形状**

Run:
```bash
Rscript -e 'source("archetypes/_lib/synth_data.R"); d<-synth_deg(); stopifnot(nrow(d)==12000, all(c("Up","Down","ns") %in% levels(d$sig)), sum(d$sig=="Up")>50); cat("synth_deg OK\n")'
```
Expected: `synth_deg OK`

- [ ] **Step 3: 提交**

```bash
git add archetypes/_lib/synth_data.R
git commit -m "feat(synth): 追加 synth_deg（volcano archetype 用）"
```

---

### Task 2: Archetype ⑥ — volcano 火山图（ggsci NPG + ggrepel）

**Files:** Create `archetypes/volcano-deg/plot.R`、`archetypes/volcano-deg/card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_deg()`（Task 1）；`figure_setup.R`；`ggsci`/`ggrepel`/`ggplot2`/`patchwork`。Produces `out/ref.png`。一页"默认 vs 优化"对比(A 默认灰底/B 应用参考原则)，体现去 chartjunk + 期刊配色 + 防重叠标注。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: 火山图 —— 默认风格 vs 应用参考原则（ggsci NPG + ggrepel + 去 chartjunk）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(ggrepel); library(ggsci); library(patchwork); library(scales)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/volcano-deg"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

df <- synth_deg(seed=42)
fc_th <- 1; p_th <- 0.05
n_up <- sum(df$sig=="Up"); n_dn <- sum(df$sig=="Down")

## A) 默认风格（典型未优化生信图）
pA <- ggplot(df, aes(logFC, y, colour=sig)) +
  geom_point(size=1.0) +
  labs(x="log2FC", y="-log10(adjP)", title="Default (unoptimized)", colour="sig") +
  theme_gray(base_size=8, base_family=NATURE_FONT)

## B) 应用参考原则：ggsci NPG + ggrepel + 去 chartjunk
npg <- ggsci::pal_npg("nrc")(9)
col <- c(Up=npg[1], Down=npg[4], ns="grey82")            # NPG 红/深蓝
lab <- rbind(utils::head(df[order(-df$logFC),][df$sig[order(-df$logFC)]=="Up",   ], 10),
             utils::head(df[order( df$logFC),][df$sig[order( df$logFC)]=="Down", ], 10))
pB <- ggplot(df, aes(logFC, y, colour=sig)) +
  geom_vline(xintercept=c(-fc_th,fc_th), linetype="dashed", linewidth=0.25, colour="grey60") +
  geom_hline(yintercept=-log10(p_th),    linetype="dashed", linewidth=0.25, colour="grey60") +
  geom_point(data=subset(df, sig=="ns"), size=0.5, alpha=0.35) +
  geom_point(data=subset(df, sig!="ns"), size=0.9, alpha=0.85) +
  scale_color_manual(values=col, breaks=c("Up","Down"),
                     labels=c(sprintf("Up (n=%d)",n_up), sprintf("Down (n=%d)",n_dn)), name=NULL) +
  ggrepel::geom_text_repel(data=lab, aes(label=gene), size=2.0, fontface="italic",
                           max.overlaps=30, segment.size=0.18, segment.colour="grey70",
                           min.segment.length=0, box.padding=0.25, force=1.5,
                           colour="grey15", show.legend=FALSE) +
  scale_x_continuous(expand=expansion(mult=c(0.02,0.02))) +
  labs(x=expression(log[2]~"fold change"), y=expression(-log[10]~adjusted~italic(P)),
       title="Reference principles applied", subtitle="ggsci NPG · ggrepel · de-chartjunk") +
  theme_nature() +
  theme(legend.position="inside", legend.position.inside=c(0.99,0.99),
        legend.justification=c(1,1),
        legend.background=element_rect(fill=scales::alpha("white",0.7), colour=NA))

fig <- pA + pB + plot_layout(ncol=2) +
  plot_annotation(tag_levels="A",
    caption="Synthetic data, style demo only (not real results). set.seed(42); FDR<0.05 & |log2FC|>=1.",
    theme=theme(plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT)))

save_nature(fig, file.path(out,"ref"), width_mm=183, height_mm=92)
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2: 跑 plot.R 出图**

Run: `Rscript archetypes/volcano-deg/plot.R`
Expected: `done: .../out/ref.png`。`save_nature` 写 ref.png+pdf(+svg)。

- [ ] **Step 3: 过 QA**

Run: `Rscript tools/qa_check.R archetypes/volcano-deg/out/ref.png 1800`
Expected: `QA PASS`

- [ ] **Step 4: 写 card.md（渲染 + 分析双重翻车点）**

```markdown
# 火山图（差异表达，ggsci NPG + ggrepel）

- **何时用**：双组差异表达/蛋白/甲基化，想一图展示效应量(log2FC) × 显著性(-log10 adjP)并标注关键基因。差异分析 Main/补充图常客。
- **数据形状**：data.frame(基因, logFC, 校正 P(adj.P.Val))；阈值 |log2FC| 与 FDR 自定。
- **核心依赖**：ggplot2、ggrepel、ggsci、patchwork、figure_setup.R。
- **配色规则**：用 ggsci 期刊配色(`pal_npg("nrc")` 红/深蓝)做 Up/Down，ns 用浅灰；≤3 主色。
- **常见翻车点（渲染）**：① ns 点不降透明/不减小 → 糊成一团盖住信号；② 标签不用 ggrepel → 互相重叠；③ 标全部显著基因 → 太挤，应只标 top N；④ 坐标轴用纯文本 → 用 `expression(log[2]~..., -log[10]~italic(P))` 排版；⑤ 灰底+默认配色+大图例 = chartjunk → theme_nature + 图例内置。
- **常见翻车点（分析严谨）**：⑥ **必须用校正后 P(FDR/adjP)，不是原始 p**——12000 基因多重检验，原始 p<0.05 假阳性成片；⑦ **高 -log10P ≠ 生物学重要**：极小 p 可能来自高表达/低方差基因，需结合效应量(log2FC)与表达量；⑧ **标注基因别只挑"故事好"的**——cherry-pick 标注会误导，应按统一规则(top |log2FC| 或 top 显著)选并说明。
- **参考实现**：`archetypes/volcano-deg/`
```

- [ ] **Step 5: 提交**

```bash
git add archetypes/volcano-deg
git commit -m "feat(archetype): volcano 火山图(ggsci NPG+ggrepel, 默认vs优化对比) + 真参考图(QA 通过)"
```

---

### Task 3: 复合大图 retrofit → patchwork hero 布局 + theme 函数

**Files:** Modify `archetypes/composite-cancer-multiomics/plot.R`、`card.md`；regenerate `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_expr`/`synth_survival`/`synth_enrich`（既有）；theme `nature_heatmap`/`nature_hm_anno`/`nature_hm_gp`/`nature_pca`/`nature_enrich_dot`/`nature_km`；patchwork。
**设计决策（plan 内已定，可在 review 推翻）**：第四面板由 circos 改为 **PCA**——circos 已是 Phase 1 archetype ④ 独立成图，复合图改用"分子分型故事"(热图 hero + PCA + 富集 + KM)最能展示 hero 布局 + house 函数，且不与 ④ 冗余。

- [ ] **Step 1: 重写 plot.R（hero 布局 + house 函数 + tag_levels）**

```r
#!/usr/bin/env Rscript
# Archetype: 复合多面板叙事大图（分子分型故事，hero 布局）
# A 热图(hero) + B PCA + C 富集 + D KM，全部走 nature_theme house 函数；patchwork hero design。
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ComplexHeatmap); library(grid); library(ggplot2); library(patchwork)
  library(survival)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/composite-cancer-multiomics"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d  <- synth_expr(n_genes=40, n_samples=80, seed=1)
grp <- d$col_anno$Subtype                      # 用 Subtype 当分型
sv <- synth_survival(d$col_anno, seed=3)
en <- synth_enrich(seed=4, n=10)

## A) hero 热图（带注释轨 + 按分型/模块分裂）
ha <- nature_hm_anno(Subtype=d$col_anno$Subtype, Stage=d$col_anno$Stage, Tissue=d$col_anno$Tissue)
ht <- nature_heatmap(d$mat, name="Z-score", top_annotation=ha,
                     column_split=grp, show_column_names=FALSE,
                     column_title_gp=nature_hm_gp(7,"bold"),
                     row_names_gp=nature_hm_gp(4.4))
gA <- patchwork::wrap_elements(full = grid::grid.grabExpr(
  ComplexHeatmap::draw(ht, heatmap_legend_side="right", annotation_legend_side="bottom",
                       merge_legend=FALSE, padding=unit(c(2,8,2,6),"mm")),
  width=unit(95,"mm"), height=unit(150,"mm")))

## B) PCA（house 函数）
pca <- prcomp(t(d$mat)); ve <- 100*pca$sdev^2/sum(pca$sdev^2)
pca_df <- data.frame(PC1=pca$x[,1], PC2=pca$x[,2], group=grp)
gB <- nature_pca(pca_df, group="group", var_explained=c(PC1=ve[1], PC2=ve[2]),
                 title="Subtype separation (PCA)")

## C) 富集 dotplot（house 函数）
gC <- nature_enrich_dot(en, top_n=10, title="Pathway enrichment")

## D) KM 生存（house 函数）
gD <- nature_km(sv, time="time", status="status", group="group",
                risk_table=FALSE, show_cox_p=FALSE,
                title="Overall survival", time_lab="Time (months)",
                surv_lab="Survival probability")

## 拼图：hero 布局（A 跨三行，BCD 叠右）
fig <- gA + gB + gC + gD +
  plot_layout(design="AB\nAC\nAD", widths=c(1.25,1)) +
  plot_annotation(tag_levels="A",
    title="Molecular subtyping integrative figure (synthetic demo)",
    caption="Synthetic data, style demo only (not real results). set.seed(1/3/4); n=80 samples.",
    theme=theme(plot.title=element_text(size=10, face="bold", family=NATURE_FONT),
                plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT)))

ggsave(file.path(out,"ref.png"), fig, width=183, height=178, units="mm", dpi=300,
       device=ragg::agg_png, bg="white")
ggsave(file.path(out,"ref.pdf"), fig, width=183, height=178, units="mm", device=cairo_pdf, bg="white")
unlink("Rplots.pdf")
cat("done:", file.path(out,"ref.png"), "\n")
```

> 注：`nature_pca`/`nature_enrich_dot`/`nature_km`/`nature_hm_anno`/`nature_heatmap` 的确切参数若与上面略有出入，读 `nature_theme.R` 对应函数定义修正调用（这些函数确认存在：第 215/221/236/350/394/484 行）；不要改 theme 本体，只调用。`nature_km` 若返回 ggsurvplot 列表则取 `$plot`（读定义确认）。

- [ ] **Step 2: 跑 plot.R 出图**

Run: `Rscript archetypes/composite-cancer-multiomics/plot.R`
Expected: `done: .../out/ref.png`。若某 house 函数返回类型导致 patchwork 拼装报错（如 nature_km 返回非 ggplot），读其定义取正确对象；不要降级删面板。

- [ ] **Step 3: 过 QA**

Run: `Rscript tools/qa_check.R archetypes/composite-cancer-multiomics/out/ref.png 1800`
Expected: `QA PASS`

- [ ] **Step 4: 人眼自检 + 更新 card.md**

更新 `card.md`：机制说明改为 "hero 布局(patchwork design) + 全程 house 函数(nature_heatmap/pca/enrich_dot/km) + tag_levels='A' + 诚实 caption"；保留并补充分析严谨翻车点（分型故事易过度解读：PCA 分离≠因果、KM 差异需校正混杂、富集 FDR）。

- [ ] **Step 5: 提交**

```bash
git checkout -- archetypes/composite-cancer-multiomics/out/*.pdf 2>/dev/null
git add archetypes/composite-cancer-multiomics/plot.R archetypes/composite-cancer-multiomics/card.md archetypes/composite-cancer-multiomics/out/ref.png archetypes/composite-cancer-multiomics/out/ref.pdf
git commit -m "refactor(archetype): 复合图 retrofit 成 patchwork hero 布局 + 全程 house 函数 + tag_levels（学 demo_composite）"
```

---

### Task 4: skill-integration — 设计克制护栏 + 诚实 caption + 新条目

**Files:** Modify `skill-integration/advanced-archetypes.md`

- [ ] **Step 1: 加「②·6 设计克制护栏」段**

在 `advanced-archetypes.md` 现有「①·5 画前自检（分析严谨）」之后、清单之前，加一段**设计克制护栏**（与分析护栏并列），含：≤3 主色（优先 ggsci 期刊配色 `pal_npg`/`lancet`/`nejm`，别彩虹/默认）；统一一套字体靠字号字重分层级；去 chartjunk（删灰底/多余网格/边框/冗余图例）；留白；对齐到网格；数据-墨水比高；多面板用 `patchwork plot_annotation(tag_levels="A")`；那层"精修感"靠导出 PDF/SVG 后在 Inkscape/Illustrator 手工拼版（代码出毛坯）。

- [ ] **Step 2: 加「诚实 caption 约定」一句**

明确：演示/复合图 caption 必须注明 `set.seed`、关键阈值(FDR/logFC)、"synthetic demo, not real results"——数字可溯源、不夸大。

- [ ] **Step 3: 清单加 volcano 条目 + 更新 composite 条目**

② 清单追加 volcano（含分析翻车点 + 参考图 `assets/advanced-archetypes/volcano.png`）；更新 composite 条目说明（hero 布局 + house 函数）。野心阶梯"两组差异"高级项把 volcano 标 ✅就绪。

- [ ] **Step 4: 提交**

```bash
git add skill-integration/advanced-archetypes.md
git commit -m "docs(skill-integration): +设计克制护栏 +诚实caption约定 +volcano条目 +composite hero 更新"
```

---

### Task 5: ROADMAP + Phase 2/3 参考蓝本标注 + 部署 + 回归

**Files:** Modify `docs/superpowers/plans/ROADMAP.md`；部署到 `~/.claude/skills/nature-figure/`（控制者亲做）

- [ ] **Step 1: Phase 1.5 全回归**

```bash
cd /mnt/f/work/research/nature_figure_skill
Rscript tools/env_check.R && Rscript tools/test_qa.R && \
for a in omics-multiannot-heatmap composite-cancer-multiomics omics-oncoprint genome-circos phylo-tree-heatmap volcano-deg; do
  Rscript archetypes/$a/plot.R || { echo "FAIL $a"; exit 1; }; done && \
Rscript tools/qa_check.R archetypes/omics-multiannot-heatmap/out/ref.png && \
Rscript tools/qa_check.R archetypes/composite-cancer-multiomics/out/ref.png 1800 && \
Rscript tools/qa_check.R archetypes/omics-oncoprint/out/ref.png 1200 && \
Rscript tools/qa_check.R archetypes/genome-circos/out/ref.png 1200 && \
Rscript tools/qa_check.R archetypes/phylo-tree-heatmap/out/ref.png 1200 && \
Rscript tools/qa_check.R archetypes/volcano-deg/out/ref.png 1800 && echo "PHASE1.5 REGRESSION OK"
```
Expected: `PHASE1.5 REGRESSION OK`（6 archetype 全 QA PASS）。任一失败即停。

- [ ] **Step 2: 更新 ROADMAP.md**

用 Edit 在 ROADMAP 加：
- `- [x] Phase 1.5（参考包学习）：复合图 hero 化 + volcano + 设计克制护栏`
- Phase 2 行后加注：**参考蓝本 `/mnt/f/work/research/nature_R/nature_figure_refs/05_singlecell`（scCustomize 一键发表级 UMAP/violin/dotplot；dittoSeq 色盲友好；Nebulosa 密度 UMAP）**
- Phase 3 行后加注：**参考蓝本 `03_enrichment`（enrichplot cnetplot/emapplot/gseaplot2）+ ggraph 网络**
- 加一行临床蓝本：**forestploter（森林图）+ ggpubr stat_compare_means（带 * 箱线）见 `01_style_palette`/`04_survival_clinical`**
- 加一个**待决策项**：「ggsci 期刊配色是否折进共享 `nature_theme.R`（作为 house 选项）—— 跨项目影响，需用户拍板；当前仅在 volcano archetype 内局部用」。

- [ ] **Step 3: 提交（项目侧）**

```bash
git checkout -- archetypes/*/out/*.pdf 2>/dev/null
git add docs/superpowers/plans/ROADMAP.md
git commit -m "docs: Phase 1.5 回归通过 + 路线图标注 Phase 2/3 参考蓝本 + ggsci-theme 决策项"
```

- [ ] **Step 4: 部署（控制者亲做，本步在执行时由控制者直接运行，不派子代理）**

```bash
SKILL=~/.claude/skills/nature-figure
BAK="/tmp/advanced-archetypes.bak.$(date +%Y%m%d_%H%M%S).md"
cp "$SKILL/references/advanced-archetypes.md" "$BAK"
cp skill-integration/advanced-archetypes.md "$SKILL/references/advanced-archetypes.md"
cp archetypes/volcano-deg/out/ref.png                "$SKILL/assets/advanced-archetypes/volcano.png"
cp archetypes/composite-cancer-multiomics/out/ref.png "$SKILL/assets/advanced-archetypes/composite.png"   # hero 版覆盖旧 composite 图
cmp -s skill-integration/advanced-archetypes.md "$SKILL/references/advanced-archetypes.md" && echo "部署一致 ✓"
ls "$SKILL/assets/advanced-archetypes/"   # 应 6 张
```

---

## 自检（Self-Review 结果）

- **覆盖**：synth_deg（T1）、volcano archetype（T2）、composite hero retrofit（T3）、设计克制护栏+诚实caption+条目（T4）、ROADMAP+蓝本+部署+回归（T5）——学习清单高价值项全覆盖；Phase 2/3 蓝本以 ROADMAP 标注落位（不在本阶段实现）。
- **跨项目安全**：明确不改 `nature_theme.R`；ggsci 仅局部用；"折进 theme"作为待决策项留给用户。
- **类型一致**：synth_deg 返回 data.frame(gene,logFC,adj.P.Val,sig,y)，volcano 消费一致；composite 调用的 house 函数均确认存在（行号在 T3 注明），返回类型不确定处给了"读定义修正、不降级"的处置。
- **占位**：无 TBD；house 函数参数不确定处给具体处置。
