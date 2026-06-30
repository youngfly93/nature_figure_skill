# Nature 高级图型 archetype 库 — Phase 3（关系网络）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development。Steps use checkbox (`- [ ]`).

**Goal:** 新增四个"关系/网络/集合"archetype（富集通路网络、Sankey/alluvial 流向、chord 弦图、UpSet 集合交集），全部 theme 驱动、不缺包；每张卡片含分析严谨翻车点。

**Architecture:** 沿用"五件套 + QA 门禁"。合成关系数据进 `_lib/synth_data.R`。ggplot 系（ggraph/ggalluvial）经 `save_nature` 导出；base 图系（circlize chord / UpSetR）直接 agg_png/cairo_pdf 导出（参照 circos archetype）。

**Tech Stack:** R 4.4.3 · ggraph/tidygraph/igraph · ggalluvial · circlize · UpSetR · ggplot2 · figure_setup.R + nature_theme.R。全部已实测安装（ComplexUpset/forestploter 缺——本期不用，UpSet 用 UpSetR）。

## Global Constraints

- 配色/主题/字体唯一真源：plot.R 顶部 source `_lib/figure_setup.R`；**不改 nature_theme.R**；离散类别用 nature_pal_anno，连续量用 nature_seq/nature_div。
- 脚本真跑、出真图；参考图来自真跑，绝不编造/占位；合成数据设种子可复现。
- 图内文字英文；中文只在 card.md（用 Write 写，防乱码）。
- 每张 archetype 卡片含**渲染 + 分析严谨**双重翻车点。
- base 图（circlize/UpSetR）末尾 `unlink("Rplots.pdf")`；ggraph/网络布局设种子（布局含随机）。
- 导出多格式。

## 文件结构

```
archetypes/
├── _lib/synth_data.R          # 改：+ synth_network() + synth_flow() + synth_chord() + synth_sets()
├── enrich-network/            # 新 ⑪（ggraph 富集通路网络）
├── flow-alluvial/             # 新 ⑫（ggalluvial Sankey/流向）
├── chord-diagram/             # 新 ⑬（circlize 弦图）
├── upset-sets/                # 新 ⑭（UpSetR 集合交集）
│   （各 plot.R · card.md · out/ref.{png,pdf}）
skill-integration/advanced-archetypes.md  # 改：4 条新条目 + 阶梯"通路/关系"✅就绪
docs/superpowers/plans/ROADMAP.md          # 改：勾掉 Phase 3
```

---

### Task 1: 合成关系数据生成器（network/flow/chord/sets）

**Files:** Modify `archetypes/_lib/synth_data.R`（末尾追加）

**Interfaces:**
- `synth_network(n_terms=8, genes_per_term=6, seed=21)` → `list(edges=data.frame(from=term, to=gene), terms=data.frame(name, p.adjust))`（二部图：term↔gene）。
- `synth_flow(n=300, seed=22)` → `data.frame(Tissue, Subtype(factor), Response(factor))`（分类阶段，供 alluvial）。
- `synth_chord(n_cat=6, seed=24)` → 方阵 `matrix(n_cat×n_cat, dimnames=CellType)`，对角 0（互作计数）。
- `synth_sets(n_items=200, seed=23)` → 命名 `list(DEG_up, DEG_down, Methylated, CNV_gain)`（每个是 item id 向量，供 UpSet）。

- [ ] **Step 1: 追加四个生成器**

```r
# —— Phase 3 追加：关系/网络/集合 ——
synth_network <- function(n_terms = 8, genes_per_term = 6, seed = 21) {
  set.seed(seed)
  terms <- c("Cell cycle","DNA repair","Immune response","Apoptosis",
             "Angiogenesis","p53 signaling","MAPK cascade","Metabolism")[seq_len(n_terms)]
  gene_pool <- paste0("G", sprintf("%03d", seq_len(60)))
  edges <- do.call(rbind, lapply(seq_along(terms), function(i) {
    g <- sample(gene_pool, genes_per_term + sample(0:4, 1))
    data.frame(from = terms[i], to = g, stringsAsFactors = FALSE)
  }))
  terms_df <- data.frame(name = terms, p.adjust = sort(10^(-runif(n_terms, 2, 8))),
                         stringsAsFactors = FALSE)
  list(edges = edges, terms = terms_df)
}

synth_flow <- function(n = 300, seed = 22) {
  set.seed(seed)
  tissue  <- sample(c("Tumor","Normal"), n, TRUE, prob = c(.72, .28))
  subtype <- factor(ifelse(tissue == "Tumor",
                           sample(c("C1","C2","C3"), n, TRUE), "Normal"),
                    levels = c("C1","C2","C3","Normal"))
  presp   <- ifelse(subtype %in% c("C1","Normal"), .7, .35)
  response <- factor(ifelse(runif(n) < presp, "Responder", "Non-responder"),
                     levels = c("Responder","Non-responder"))
  data.frame(Tissue = tissue, Subtype = subtype, Response = response)
}

synth_chord <- function(n_cat = 6, seed = 24) {
  set.seed(seed)
  cats <- paste0("CellType", seq_len(n_cat))
  m <- matrix(rpois(n_cat^2, 5), n_cat, n_cat, dimnames = list(cats, cats))
  diag(m) <- 0
  m
}

synth_sets <- function(n_items = 200, seed = 23) {
  set.seed(seed)
  pool <- seq_len(n_items)
  list(DEG_up     = sample(pool, 85),
       DEG_down   = sample(pool, 70),
       Methylated = sample(pool, 60),
       CNV_gain   = sample(pool, 50))
}
```

- [ ] **Step 2: 验证形状**

Run:
```bash
Rscript -e 'source("archetypes/_lib/synth_data.R"); nw<-synth_network(); stopifnot(all(c("from","to") %in% names(nw$edges)), nrow(nw$terms)==8); fl<-synth_flow(); stopifnot(nrow(fl)==300, all(c("Tissue","Subtype","Response") %in% names(fl))); ch<-synth_chord(); stopifnot(dim(ch)==c(6,6), all(diag(ch)==0)); st<-synth_sets(); stopifnot(length(st)==4, is.numeric(st$DEG_up)); cat("synth phase3 OK\n")'
```
Expected: `synth phase3 OK`

- [ ] **Step 3: 提交**

```bash
git add archetypes/_lib/synth_data.R
git commit -m "feat(synth): 追加 synth_network/flow/chord/sets（Phase 3 关系网络）"
```

---

### Task 2: Archetype ⑪ — 富集通路网络（ggraph 二部图）

**Files:** Create `archetypes/enrich-network/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_network()`；`figure_setup.R`；ggraph/tidygraph/igraph。term 节点大（按基因数）+ 按 -log10 p.adjust 着色，gene 节点小灰，边细灰。cnetplot 风格。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: 富集通路网络（ggraph 二部图，cnetplot 风格）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggraph); library(tidygraph); library(igraph); library(ggplot2)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/enrich-network"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)
set.seed(21)

nw <- synth_network()
g  <- igraph::graph_from_data_frame(nw$edges, directed=FALSE)
deg <- igraph::degree(g)
is_term <- names(deg) %in% nw$terms$name
padj <- setNames(nw$terms$p.adjust, nw$terms$name)
tg <- tidygraph::as_tbl_graph(g) |>
  tidygraph::activate(nodes) |>
  dplyr::mutate(type   = ifelse(name %in% nw$terms$name, "Pathway", "Gene"),
                deg    = deg[name],
                neglp  = ifelse(type=="Pathway", -log10(padj[name]), NA_real_))

p <- ggraph(tg, layout="fr") +
  geom_edge_link(colour="grey80", edge_width=0.25, alpha=0.6) +
  geom_node_point(aes(size=ifelse(type=="Pathway", deg, 1.5),
                      colour=neglp, shape=type)) +
  geom_node_text(aes(label=ifelse(type=="Pathway", name, NA)),
                 size=2.2, fontface="bold", repel=TRUE, family=NATURE_FONT) +
  scale_size_continuous(range=c(1.5,8), name="gene count", guide="none") +
  scale_shape_manual(values=c(Pathway=16, Gene=16), guide="none") +
  scale_colour_gradientn(colours=rev(nature_seq[-1]), na.value="grey75",
                         name=expression(-log[10]~italic(p)[adj])) +
  labs(title="Pathway–gene enrichment network (synthetic demo)") +
  theme_void(base_family=NATURE_FONT) +
  theme(plot.title=element_text(size=8, face="bold"),
        legend.title=element_text(size=6), legend.text=element_text(size=5))

save_nature(p, file.path(out,"ref"), width_mm=150, height_mm=130)
cat("done:", file.path(out,"ref.png"), "\n")
```

> 注：若 `dplyr` 未随 tidygraph 加载，顶部加 `library(dplyr)`。若 `repel=TRUE` 在本机 ggraph 版本报参数名差异，改用 `geom_node_text(..., check_overlap=TRUE)`；不要删 term 标签。

- [ ] **Step 2-3: 跑 + QA**（minwidth 1200）。

- [ ] **Step 4: card.md**（渲染翻车点：布局设种子否则每次不同 / term-gene 双类型用大小+颜色区分 / 基因标签太多→只标 term；**分析翻车点**：⑤ 网络布局(fr/力导向)是**美学排布非定量关系**，节点远近不代表生物学距离；⑥ 富集网络的边来自基因-通路注释数据库，**结论受注释库版本影响**；⑦ 通路冗余——高度重叠的通路会让网络虚胖，需先去冗余(如 simplify)）。注明 enrichplot::cnetplot/emapplot 为 canonical 替代。

- [ ] **Step 5: 提交** `feat(archetype): 富集通路网络(ggraph) + 真参考图(QA 通过)`。

---

### Task 3: Archetype ⑫ — Sankey/alluvial 流向图（ggalluvial）

**Files:** Create `archetypes/flow-alluvial/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_flow()`；ggalluvial。三阶段 Tissue→Subtype→Response 流向。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: Sankey/alluvial 流向图（ggalluvial）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(ggalluvial)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/flow-alluvial"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

df  <- synth_flow(n=300, seed=22)
agg <- as.data.frame(table(df))            # Tissue,Subtype,Response,Freq
agg <- agg[agg$Freq > 0, ]
sub_lv <- levels(df$Subtype)
cols <- setNames(nature_pal_anno[seq_along(sub_lv)], sub_lv)

p <- ggplot(agg, aes(axis1=Tissue, axis2=Subtype, axis3=Response, y=Freq)) +
  geom_alluvium(aes(fill=Subtype), alpha=0.7, width=0.32) +
  geom_stratum(width=0.32, fill="grey92", colour="grey55", linewidth=0.3) +
  geom_text(stat="stratum", aes(label=after_stat(stratum)), size=2, family=NATURE_FONT) +
  scale_x_discrete(limits=c("Tissue","Subtype","Response"), expand=c(.05,.05)) +
  scale_fill_manual(values=cols, name="Subtype") +
  labs(y="Samples", title="Sample flow: tissue → subtype → response (synthetic demo)") +
  theme_nature() +
  theme(axis.title.x=element_blank())

save_nature(p, file.path(out,"ref"), width_mm=150, height_mm=110)
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2-3: 跑 + QA**（minwidth 1200）。

- [ ] **Step 4: card.md**（渲染翻车点：stratum/alluvium 宽度一致、stratum 标签字号、阶段顺序 limits；**分析翻车点**：⑤ alluvial 流宽=样本数，**别把流宽解读成概率/因果**；⑥ 阶段顺序是人为排列，换序会改变视觉叙事，需如实反映真实时序/逻辑；⑦ 小流(少样本)视觉上易被忽略但可能重要，必要时标注 n）。

- [ ] **Step 5: 提交** `feat(archetype): Sankey/alluvial 流向图(ggalluvial) + 真参考图(QA 通过)`。

---

### Task 4: Archetype ⑬ — chord 弦图（circlize）

**Files:** Create `archetypes/chord-diagram/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_chord()`；circlize base 图，直接 agg_png/cairo_pdf 导出。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: chord 弦图（circlize）——类别间互作矩阵
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(circlize); library(ragg)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/chord-diagram"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

m <- synth_chord(n_cat=6, seed=24)
grid_col <- setNames(nature_pal_anno[seq_len(nrow(m))], rownames(m))

draw_chord <- function() {
  circos.clear()
  circos.par(gap.degree=3, start.degree=90)
  chordDiagram(m, grid.col=grid_col, transparency=0.35,
               annotationTrack=c("grid"), preAllocateTracks=1,
               directional=1, direction.type=c("diffHeight","arrows"),
               link.arr.type="big.arrow")
  circos.trackPlotRegion(track.index=1, panel.fun=function(x,y){
    circos.text(CELL_META$xcenter, CELL_META$ylim[1]+mm_y(3),
                CELL_META$sector.index, facing="clockwise", niceFacing=TRUE,
                adj=c(0,0.5), cex=0.5)
  }, bg.border=NA)
  circos.clear()
}

w <- 130/25.4; h <- 130/25.4
agg_png(file.path(out,"ref.png"), width=w, height=h, units="in", res=600, background="white")
draw_chord(); title(main="Cell–cell interaction chord (synthetic demo)", cex.main=0.8, font.main=2); dev.off()
cairo_pdf(file.path(out,"ref.pdf"), width=w, height=h, family="Helvetica")
draw_chord(); title(main="Cell–cell interaction chord (synthetic demo)", cex.main=0.8, font.main=2); dev.off()
unlink("Rplots.pdf")
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2-3: 跑 + QA**（minwidth 1200）。无 Rplots 残留。

- [ ] **Step 4: card.md**（渲染翻车点：circos.clear 两端、扇区标签 facing、preAllocateTracks 给标签留轨、base 图直接 agg_png 导出；**分析翻车点**：⑤ 弦宽=互作强度/计数，**别把"连起来"当成已验证的因果互作**——可能只是共现/相关；⑥ 有向 chord 的方向(arrows)需有数据支撑，否则别加箭头误导；⑦ 自互作(对角)已置 0，真实数据需说明是否计入）。

- [ ] **Step 5: 提交** `feat(archetype): chord 弦图(circlize) + 真参考图(QA 通过)`。

---

### Task 5: Archetype ⑭ — UpSet 集合交集（UpSetR）

**Files:** Create `archetypes/upset-sets/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_sets()`；UpSetR base 图，直接导出。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: UpSet 集合交集（UpSetR）——多组学/多比较的集合 overlap
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(UpSetR); library(ragg); library(grid)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/upset-sets"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

sets <- synth_sets(seed=23)
mat  <- UpSetR::fromList(sets)

draw_upset <- function()
  print(UpSetR::upset(mat, nsets=length(sets), order.by="freq",
                      main.bar.color=nature_seq[5], sets.bar.color=nature_pal_anno[1],
                      matrix.color=nature_div[1], shade.color="grey85",
                      text.scale=c(1.1,1.0,1.0,0.9,1.0,0.9),
                      mainbar.y.label="Intersection size", sets.x.label="Set size"))

w <- 160/25.4; h <- 110/25.4
agg_png(file.path(out,"ref.png"), width=w, height=h, units="in", res=600, background="white")
draw_upset(); dev.off()
cairo_pdf(file.path(out,"ref.pdf"), width=w, height=h, family="Helvetica")
draw_upset(); dev.off()
unlink("Rplots.pdf")
cat("done:", file.path(out,"ref.png"), "\n")
```

> 注：UpSetR::upset 是 base/grid 图；用 `print()` 触发绘制到当前设备。配色用 theme 调色板。若某 text.scale 槽位报错，按 `?upset` 调长度。

- [ ] **Step 2-3: 跑 + QA**（minwidth 1800；UpSet 横宽）。无 Rplots 残留。

- [ ] **Step 4: card.md**（渲染翻车点：fromList 转换、order.by="freq"、text.scale 6 槽位、base 图导出；**分析翻车点**：⑤ UpSet 替代 Venn 但**交集大小受各集合定义阈值影响**(如 DEG 的 FDR/logFC 截断)，需统一阈值；⑥ 只看交集大小不看**显著性**——大交集可能只是大集合的必然，必要时做超几何检验；⑦ 集合来源若 batch/平台不同，overlap 不可直接比）。注明 ComplexUpset 为更美替代(本机未装)。

- [ ] **Step 5: 提交** `feat(archetype): UpSet 集合交集(UpSetR) + 真参考图(QA 通过)`。

---

### Task 6: 集成进 skill-integration

**Files:** Modify `skill-integration/advanced-archetypes.md`

- [ ] **Step 1:** ② 清单追加四条（K 富集网络 / L Sankey / M chord / N UpSet），each 含 何时用/数据形状/依赖/渲染翻车点 + **分析严谨翻车点** / 参考图相对路径（`assets/advanced-archetypes/enrich_network.png`/`alluvial.png`/`chord.png`/`upset.png`）/ 参考实现。富集网络注明 enrichplot::cnetplot canonical 替代；UpSet 注明 ComplexUpset 更美替代(未装)。
- [ ] **Step 2:** 野心阶梯"富集/通路分析"高级项把**通路网络**标 ✅就绪；若有"关系/集合"行同样标注。
- [ ] **Step 3:** 更新 footer meta-line（Phase 3 新增 K-N）。
- [ ] **Step 4:** 提交 `docs(skill-integration): 野心阶梯增关系网络 4 archetype（带分析护栏）`。

---

### Task 7: ROADMAP + 部署 + 回归

- [ ] **Step 1: Phase 3 全回归**（env_check + test_qa + 全部 14 archetype 重渲 + QA；新四个 minwidth：enrich-network 1200、flow-alluvial 1200、chord-diagram 1200、upset-sets 1800）。末行 `PHASE3 REGRESSION OK`。任一失败即停。
- [ ] **Step 2: 更新 ROADMAP.md**：勾掉 Phase 3；注明 forestploter/ggpubr-box 归后续 clinical 小集。
- [ ] **Step 3: 提交（项目侧）** `docs: Phase 3 回归通过 + 路线图勾掉 Phase 3`。
- [ ] **Step 4: 部署（控制者亲做）**：拷 4 张新参考图 + advanced-archetypes.md → skill；展示 diff；assets 应 14 张。

---

## 自检（Self-Review 结果）

- **覆盖**：synth 生成器（T1）、富集网络（T2）、Sankey（T3）、chord（T4）、UpSet（T5）、集成（T6）、部署回归（T7）——Phase 3 关系网络 family 全覆盖。
- **缺包处置**：ComplexUpset/forestploter 缺——UpSet 用 UpSetR、森林图归后续（用 theme nature_forest 无需 forestploter）；本期不触发缺包阻塞。
- **base vs ggplot 导出**：chord/UpSet 是 base/grid 图，直接 agg_png/cairo_pdf + unlink Rplots；ggraph/ggalluvial 是 ggplot，走 save_nature。
- **类型一致**：synth_network(edges/terms)、synth_flow(3 因子列)、synth_chord(方阵)、synth_sets(命名 list)，各 archetype 消费一致。
- **占位**：无 TBD；API 不确定处（ggraph repel、UpSetR text.scale）给了具体处置。
