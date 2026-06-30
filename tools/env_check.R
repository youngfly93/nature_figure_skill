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
