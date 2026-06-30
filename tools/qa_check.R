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
