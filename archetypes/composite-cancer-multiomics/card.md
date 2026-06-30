# Composite multi-panel narrative figure (molecular subtyping story)

- **When to use**: One figure needs to chain multiple evidence streams (expression / survival / pathways / PCA) into a single argument. This is the biggest source of "high-impact" visual impact — through **composition and narrative**, not individual panel complexity.
- **Data shape**: Each panel's own data: expression matrix → heatmap + PCA; survival table → KM; enrichment table → dotplot.
- **Dependencies**: ComplexHeatmap, grid, ggplot2, patchwork, survival, ragg, svglite, nature_theme.R.
- **Assembly mechanism — hero layout (patchwork design)**:
  - Panel A (heatmap) captured as a grob via `grid.grabExpr(ComplexHeatmap::draw(...))` then wrapped with `patchwork::wrap_elements(full = ht_grob)`.
  - Panels B/C/D are ggplot objects returned directly by house functions.
  - All 4 panels assembled with `plot_layout(design="AB\nAC\nAD", widths=c(1.25,1))` — A spans the left column across all 3 rows; B/C/D stack on the right.
  - `plot_annotation(tag_levels="A")` adds uppercase panel tags automatically.
- **House functions used (all 4 panels)**:
  - `nature_hm_anno` + `nature_heatmap` + `nature_hm_gp` → Panel A (heatmap hero with column annotation track and column split by subtype).
  - `nature_pca` → Panel B (PCA scatter with 95% ellipses and variance-explained axis labels).
  - `nature_enrich_dot` → Panel C (enrichment dotplot; pass `term="Term"` when data col is "Term" not "Description").
  - `nature_km(risk_table=FALSE)` → Panel D (returns a ggplot directly; no `$plot` extraction needed).
- **White background guarantee**: `save_all()` uses `ragg::agg_png(..., bg="white")` and `cairo_pdf(..., bg="white")`; `print(p)` inside the device call renders patchwork correctly.
- **Column mapping for `nature_enrich_dot`**: auto-detects `GeneRatio` as score, `p.adjust` as p, `Count` as count — but `term` column name must be passed explicitly if it is not "Description".
- **Shared colours**: call `nature_group_cols(levels)` once and pass `cols=` to both `nature_pca` and `nature_km` so all panels share the same subtype palette.

## Common failure points — rendering

1. ComplexHeatmap is not a ggplot: direct patchwork will fail → must convert via `grid.grabExpr` + `wrap_elements(full=...)`.
2. Font size inconsistency across panels → use `nature_hm_gp()` for heatmap text, `theme_nature()` (via house functions) for ggplot panels.
3. White background not propagated → pass `bg="white"` to every device call; the patchwork annotation theme does not guarantee corner brightness.
4. `nature_km` default `cols` is designed for 2 groups — with 3+ groups generate explicit named vector via `nature_group_cols(levels(grp))`.
5. Exporting only PNG → always co-export PDF (vector, press-ready) and optionally SVG.
6. Leftover `Rplots.pdf` → call `unlink("Rplots.pdf")` at end of script.

## Common failure points — analytical rigour (subtyping story)

1. **PCA separation ≠ causation**: unsupervised cluster separation in PC space is descriptive; do not imply that subtype differences cause phenotypic outcomes without causal evidence.
2. **KM differences need confounder adjustment**: naive log-rank p reflects subtype-survival association, not independent prognosis — stage, age, treatment are likely confounders; multivariable Cox is required before clinical claims.
3. **Enrichment FDR must be reported**: enrichment p-values should always be FDR (BH) corrected and the threshold stated; raw p-values dramatically overstate significance.
4. **Synthetic data is not evidence**: this archetype uses `synth_expr/synth_survival/synth_enrich` — all simulated. The caption must state this explicitly; never use this output as a result figure.
5. **Over-interpretation of PCA ellipses**: 95% confidence ellipses assume multivariate normality; with small or unbalanced groups they can be misleading.

- **Reference figure**: `out/ref.png`
