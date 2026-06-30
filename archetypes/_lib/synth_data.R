# 合成 demo 数据(设种子，可复现；不依赖任何真实/私有数据)
synth_expr <- function(n_genes = 40, n_samples = 60, seed = 1) {
  set.seed(seed)
  subtype <- factor(sample(c("Basal","LumA","LumB"), n_samples, TRUE))
  stage   <- factor(sample(c("I","II","III"), n_samples, TRUE), levels=c("I","II","III"))
  tissue  <- factor(sample(c("Tumor","Normal"), n_samples, TRUE, prob=c(.7,.3)))
  base  <- matrix(rnorm(n_genes*n_samples), n_genes, n_samples)
  dummy <- model.matrix(~subtype)[, -1, drop=FALSE]              # n×2
  load  <- matrix(rnorm(n_genes*2, 0, 1.2), 2, n_genes)          # 2×n_genes
  mat   <- base + t(dummy %*% load)                              # n_genes×n
  mat   <- t(scale(t(mat)))                                      # 行 z-score
  rownames(mat) <- paste0("Gene", sprintf("%02d", seq_len(n_genes)))
  colnames(mat) <- paste0("S",   sprintf("%03d", seq_len(n_samples)))
  list(mat = mat,
       col_anno = data.frame(Subtype=subtype, Stage=stage, Tissue=tissue,
                             row.names=colnames(mat)))
}
synth_survival <- function(col_anno, seed = 3) {
  set.seed(seed); n <- nrow(col_anno); risk <- as.integer(col_anno$Stage)
  data.frame(time   = round(rexp(n, 0.03*risk) + 1),
             status = rbinom(n, 1, pmin(0.9, 0.4 + 0.15*(risk-1))),
             group  = col_anno$Subtype, row.names = rownames(col_anno))
}
synth_enrich <- function(seed = 4, n = 10) {
  set.seed(seed)
  terms <- c("Cell cycle","DNA repair","Immune response","Apoptosis","Angiogenesis",
             "p53 signaling","MAPK cascade","Metabolism","Hypoxia","ECM organization")[seq_len(n)]
  data.frame(Term=factor(terms, levels=rev(terms)), Count=sample(8:60, n),
             GeneRatio=round(runif(n,0.05,0.4),3), p.adjust=sort(10^(-runif(n,2,8))))
}
synth_genome <- function(seed = 5, n_chr = 8, per = 40) {
  set.seed(seed); chr <- paste0("chr", seq_len(n_chr))
  track <- do.call(rbind, lapply(chr, function(c){
    pos <- sort(sample(1:1000, per))
    data.frame(chr=c, start=pos, end=pos+5, cnv=cumsum(rnorm(per,0,0.3)), expr=rnorm(per))
  }))
  links <- data.frame(chr1=sample(chr,6,TRUE), pos1=sample(1:1000,6),
                      chr2=sample(chr,6,TRUE), pos2=sample(1:1000,6))
  list(track=track, links=links, chromosomes=chr)
}
