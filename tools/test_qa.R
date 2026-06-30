#!/usr/bin/env Rscript
# 自测 qa_check：白底图应 PASS，灰底图应 FAIL
# 注：用 plot() 内容图（而非空白 plot.new()）确保文件 >10KB 通过大小门槛，
#     同时保持四角亮度语义不变：白底=1.0 (PASS), 灰底=0.75 (FAIL)
dir.create("scratchpad", showWarnings=FALSE)
wp <- "scratchpad/_qa_white.png"; gp <- "scratchpad/_qa_gray.png"
ragg::agg_png(wp, width=1000, height=800, res=300)
set.seed(42); plot(rnorm(300), rnorm(300), pch=20, col=rainbow(300))
dev.off()
ragg::agg_png(gp, width=1000, height=800, res=300)
par(bg="grey75"); set.seed(42); plot(rnorm(300), rnorm(300), pch=20, col=rainbow(300))
dev.off()
rc_white <- system2("Rscript", c("tools/qa_check.R", wp), stdout=TRUE, stderr=TRUE)
ok_white <- attr(rc_white,"status"); ok_white <- if (is.null(ok_white)) 0L else ok_white
rc_gray  <- system2("Rscript", c("tools/qa_check.R", gp), stdout=TRUE, stderr=TRUE)
st_gray  <- attr(rc_gray,"status"); st_gray <- if (is.null(st_gray)) 0L else st_gray
cat("white ->", paste(rc_white, collapse=" "), "\n")
cat("gray  ->", paste(rc_gray,  collapse=" "), "\n")
stopifnot(ok_white == 0L, st_gray == 1L)
cat("QA self-test OK\n")
