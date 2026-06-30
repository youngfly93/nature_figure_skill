# 图形 preamble：字体 + 主题的单一收口点。所有 archetype plot.R 顶部 source 本文件，
# 不再各自 options(nature_font=...) / source(theme)。英文图统一 Helvetica(→真 Arial,0 字体警告)。
local({
  # 解析本文件所在目录：遍历整个调用栈寻找携带 $ofile 的帧（兼容在
  # suppressPackageStartupMessages({source(...)}) 内部嵌套 source 的场景，此时
  # frame 1 是 suppressPackageStartupMessages，没有 $ofile；frame 2 才是 source()）。
  # 若整栈均无 $ofile（如 Rscript 直接执行本文件），退化为相对路径硬编码。
  # 不使用 --file= 回退，因为那指向调用方的 plot.R，不是本文件。
  ofile <- NA_character_
  for (i in seq_len(sys.nframe())) {
    f <- tryCatch(sys.frame(i)$ofile, error = function(e) NULL)
    if (!is.null(f) && length(f) == 1 && !is.na(f) && nzchar(f)) {
      ofile <- normalizePath(f); break
    }
  }
  if (is.na(ofile)) ofile <- "archetypes/_lib/figure_setup.R"   # last-resort relative
  assign(".FIG_LIB_DIR", dirname(ofile), envir = globalenv())
})
here_lib <- function(f) file.path(get(".FIG_LIB_DIR", envir = globalenv()), f)

options(nature_font = "Helvetica")
suppressPackageStartupMessages(
  source("~/.claude/assets/figure-style/nature_theme.R")
)
