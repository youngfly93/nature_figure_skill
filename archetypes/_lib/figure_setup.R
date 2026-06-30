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
