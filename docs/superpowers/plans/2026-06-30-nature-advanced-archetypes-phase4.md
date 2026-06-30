# Nature 高级图型 archetype 库 — Phase 4（clinical 小集 + 收口）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development（项目侧任务）。控制者任务（改 ~/.claude 共享件）由控制者亲自执行。

**Goal:** ① 补两个 clinical archetype（森林图、ggpubr 带*箱线）；② 把 ggsci 期刊配色**增量**折进共享 `nature_theme.R`（不改既有默认）；③ 把图型野心阶梯接进 nature-figure 的 **SKILL.md 主流程**（出图前默认查阶梯）。

**Architecture:** 项目侧沿用"五件套 + QA 门禁"。**跨项目共享件改动（nature_theme.R、SKILL.md）= 纯增量 + 备份 + 改后回归确认无破坏 + 展示 diff**，由控制者执行（不委派盲改）。

**Tech Stack:** R 4.4.3 · ggplot2 · ggpubr(stat_compare_means) · ggsci · theme 既有 nature_forest · figure_setup.R。全部已装。

## Global Constraints

- 项目侧 plot.R 顶部 source `_lib/figure_setup.R`；**项目侧不改 nature_theme.R**（只有控制者 C1 增量改）。
- **nature_theme.R 改动必须纯增量**：只加新函数（`nature_journal_pal`/`scale_*_journal`），**不改任何既有默认调色板/函数**；改后回归 ≥2 个既有 archetype 渲染无破坏。
- 脚本真跑、出真图；合成数据设种子；图内英文；中文只在 card.md/docs。
- 每张新 archetype 卡片含渲染 + 分析严谨双重翻车点。
- 所有 ~/.claude 改动：先备份 → 改 → 展示 diff。

## 文件结构

```
archetypes/
├── _lib/synth_data.R          # 改：+ synth_forest() + synth_box()
├── clinical-forest/           # 新 ⑮（nature_forest 森林图）
├── box-compare/               # 新 ⑯（ggpubr 带*箱线）
skill-integration/advanced-archetypes.md  # 改：2 条新条目 + 阶梯标注 + ggsci 入 theme 说明
docs/superpowers/plans/ROADMAP.md          # 改：勾掉 clinical + Phase 4 收口
~/.claude/assets/figure-style/nature_theme.R  # 控制者增量：ggsci API
~/.claude/skills/nature-figure/SKILL.md       # 控制者：野心阶梯接进主流程
```

---

### Task 1: synth_forest + synth_box 生成器

**Files:** Modify `archetypes/_lib/synth_data.R`（末尾追加）

**Interfaces:**
- `synth_forest(seed=31)` → `data.frame(term, HR, lo, hi, p, n)`（多变量 Cox 风格：8-10 个变量，HR/95%CI/p/样本数）。
- `synth_box(n=160, seed=32)` → `data.frame(group(factor 4 组), value)`（组间有差异，便于 stat_compare_means 出 *）。

- [ ] **Step 1: 追加两个生成器**

```r
# —— Phase 4 追加：clinical ——
synth_forest <- function(seed = 31) {
  set.seed(seed)
  term <- c("Age >= 60","Male","Stage III-IV","High grade","Subtype C2",
            "TP53 mut","High TMB","Treatment B","ECOG >= 2")
  hr <- round(exp(rnorm(length(term), 0, 0.45)), 2)
  se <- runif(length(term), 0.12, 0.30)
  lo <- round(hr * exp(-1.96 * se), 2); hi <- round(hr * exp(1.96 * se), 2)
  z  <- abs(log(hr)) / se; p <- round(2 * pnorm(-z), 4)
  data.frame(term = term, HR = hr, lo = lo, hi = hi, p = p,
             n = sample(40:120, length(term)), stringsAsFactors = FALSE)
}

synth_box <- function(n = 160, seed = 32) {
  set.seed(seed)
  group <- factor(rep(c("Ctrl","LowDose","HighDose","Combo"), length.out = n),
                  levels = c("Ctrl","LowDose","HighDose","Combo"))
  base <- c(Ctrl = 0, LowDose = 0.6, HighDose = 1.4, Combo = 2.2)[group]
  value <- as.numeric(base) + rnorm(n, 0, 0.8)
  data.frame(group = group, value = value)
}
```

- [ ] **Step 2: 验证** `Rscript -e 'source("archetypes/_lib/synth_data.R"); f<-synth_forest(); stopifnot(all(c("term","HR","lo","hi","p") %in% names(f))); b<-synth_box(); stopifnot(nrow(b)==160, nlevels(b$group)==4); cat("synth phase4 OK\n")'` → `synth phase4 OK`
- [ ] **Step 3: 提交** `feat(synth): 追加 synth_forest + synth_box（Phase 4 clinical）`

---

### Task 2: Archetype ⑮ — 森林图（theme nature_forest）

**Files:** Create `archetypes/clinical-forest/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_forest()`；`figure_setup.R`；theme `nature_forest`（定义在 nature_theme.R:546，签名 `nature_forest(df, term="term", hr="HR", lo="lo", hi="hi", p="p", ...)`——实现者**先读该函数定义**确认完整参数与返回类型，再正确调用）。

- [ ] **Step 1: 写 plot.R**（顶部 source figure_setup.R + synth_data.R；调 `nature_forest(synth_forest(), ...)`；若返回 ggplot 直接 save_nature，若返回 patchwork/列表按其结构处理——读定义确认；标题英文 "Multivariable Cox forest (synthetic demo)"；诚实 caption）。**不改 theme，只调用。**
- [ ] **Step 2-3: 跑 + QA**（`Rscript archetypes/clinical-forest/plot.R` → done；qa_check minwidth 1200 → PASS）。
- [ ] **Step 4: card.md**（渲染翻车点：HR 轴 log 刻度 / 参考线 HR=1 / CI 越界截断；**分析翻车点**：⑤ 森林图 HR 来自模型，**多变量校正与否结论不同**，须注明模型与协变量；⑥ 宽 CI（小 n）的 HR 不稳定，别只看点估计；⑦ 多重比较未校正时 p 值偏乐观）。
- [ ] **Step 5: 提交** `feat(archetype): 森林图(nature_forest) + 真参考图(QA 通过)`

---

### Task 3: Archetype ⑯ — ggpubr 带*箱线（stat_compare_means）

**Files:** Create `archetypes/box-compare/plot.R`、`card.md`；Produce `out/ref.{png,pdf}`

**Interfaces:** Consumes `synth_box()`；`figure_setup.R`；ggpubr。`ggboxplot` + `stat_compare_means(comparisons=...)` 出显著性 *。配色用 ggpubr 的 `palette="npg"`（ggsci，局部）。

- [ ] **Step 1: 写 plot.R**

```r
#!/usr/bin/env Rscript
# Archetype: 带显著性标注的箱线图（ggpubr stat_compare_means）
suppressPackageStartupMessages({
  source(file.path(dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1])), "..", "_lib", "figure_setup.R"))
  library(ggplot2); library(ggpubr)
})
here <- dirname(sub("--file=","",grep("--file=",commandArgs(FALSE),value=TRUE)[1]))
if (is.na(here) || here=="") here <- "archetypes/box-compare"
source(file.path(here,"..","_lib","synth_data.R"))
out <- file.path(here,"out"); dir.create(out, showWarnings=FALSE, recursive=TRUE)

d <- synth_box(seed=32)
cmp <- list(c("Ctrl","LowDose"), c("Ctrl","HighDose"), c("Ctrl","Combo"))
p <- ggpubr::ggboxplot(d, x="group", y="value", color="group", palette="npg",
                       add="jitter", add.params=list(size=0.6, alpha=0.5)) +
  ggpubr::stat_compare_means(comparisons=cmp, label="p.signif", size=2.4) +
  ggpubr::stat_compare_means(label.y=max(d$value)+2.2, size=2.4) +   # 全局 Kruskal-Wallis
  labs(x=NULL, y="Expression", title="Group comparison with significance (synthetic demo)",
       caption="Synthetic data, style demo only (not real results). set.seed(32); Wilcoxon vs Ctrl, Kruskal-Wallis global.") +
  theme_nature() +
  theme(legend.position="none",
        plot.caption=element_text(size=6, colour="grey45", hjust=0, family=NATURE_FONT))

save_nature(p, file.path(out,"ref"), width_mm=120, height_mm=110)
cat("done:", file.path(out,"ref.png"), "\n")
```

- [ ] **Step 2-3: 跑 + QA**（minwidth 1200）。若 stat_compare_means 默认方法/标签报版本差异，读 `?stat_compare_means` 修正（method 默认 wilcox.test 两组、kruskal.test 多组）；不删显著性标注。
- [ ] **Step 4: card.md**（渲染翻车点：comparisons 列表配对 / label.y 防与须状重叠 / jitter 透明；**分析翻车点**：⑤ **`*` 只表示 p 阈值不表示效应量**，须同时报效应量/置信区间；⑥ 默认非参检验(Wilcoxon/KW)假设要核对，正态时可用 t/ANOVA；⑦ 多重两两比较未校正会假阳性，必要时 `p.adjust.method`）。注明用了 ggsci npg(经 ggpubr palette)。
- [ ] **Step 5: 提交** `feat(archetype): ggpubr 带*箱线 + 真参考图(QA 通过)`

---

### Task 4: 集成进 skill-integration（项目侧）

**Files:** Modify `skill-integration/advanced-archetypes.md`

- [ ] ② 清单追加两条（O 森林图 / P 带*箱线），each 含分析严谨翻车点 + 参考图路径（`forest.png`/`boxsig.png`）。野心阶梯"两组差异"中级项把"带*箱线"标 ✅就绪；"临床/生存"若有行标森林 ✅就绪。在设计克制护栏（①·6）注明：**ggsci 期刊配色现已并入 nature_theme.R（`nature_journal_pal()`/`scale_*_journal()`），可直接调用**。提交 `docs(skill-integration): 增森林图/带*箱线 + ggsci 入 theme 说明`。

---

### Task 5: 控制者收口（~/.claude 共享件 + 部署 + 回归）—— 控制者亲做，不委派

- [ ] **C1: ggsci 增量进 nature_theme.R**：备份 → 在 theme 末尾追加 `nature_journal_pal(journal,n)` + `scale_color/colour/fill_journal()`（缺 ggsci 优雅回退 nature_pal_anno）；**不改任何既有定义**。source-check（既有函数仍在 + 新函数可用）+ 渲染 2 个既有 archetype 确认无破坏 + 展示 diff。
- [ ] **C2: SKILL.md 接野心阶梯**：备份 → 在 nature-figure SKILL.md 的"figure contract / default operating stance"加一步：出图前先查 `references/advanced-archetypes.md` 的图型野心阶梯 + 画前自检(分析严谨)+ 设计克制护栏，优先复用已就绪 archetype，再落基础函数；展示 diff。
- [ ] **C3: 部署 + 回归**：拷 2 张新参考图 + advanced-archetypes.md → skill（assets 应 16 张）；项目侧全回归（16 archetype，分批避免超时）；更新 ROADMAP（勾 clinical + Phase 4 收口 + ggsci 已折入）。

---

## 自检（Self-Review 结果）
- 覆盖：synth(T1)、forest(T2)、box-stat(T3)、集成(T4)、控制者收口 ggsci/SKILL.md/部署/回归(T5)——三件事全覆盖。
- 跨项目安全：nature_theme.R 纯增量、备份、回归、diff；不改既有默认。
- 类型一致：synth_forest(term/HR/lo/hi/p/n)、synth_box(group/value)；nature_forest 返回类型由实现者读定义确认。
- 占位：无 TBD；nature_forest 返回类型与 stat_compare_means 版本差异给了"读定义修正"处置。
