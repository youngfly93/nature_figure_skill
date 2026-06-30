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

# —— Phase 1 追加 ——
synth_mutations <- function(n_genes = 20, n_samples = 40, seed = 7) {
  set.seed(seed)
  types <- c("Missense", "Truncating", "Amp", "Del")
  genes <- paste0("GENE", sprintf("%02d", seq_len(n_genes)))
  samp  <- paste0("P", sprintf("%03d", seq_len(n_samples)))
  freq  <- sort(runif(n_genes, 0.05, 0.6), decreasing = TRUE)   # 高频基因在前
  mat <- matrix("", n_genes, n_samples, dimnames = list(genes, samp))
  for (i in seq_len(n_genes)) for (j in seq_len(n_samples)) {
    if (runif(1) < freq[i]) {
      k <- sample(types, sample(1:2, 1), prob = c(.5, .25, .15, .10))
      mat[i, j] <- paste(k, collapse = ";")
    }
  }
  clin <- data.frame(
    Subtype = factor(sample(c("S1","S2","S3"), n_samples, TRUE)),
    Stage   = factor(sample(c("I","II","III"), n_samples, TRUE), levels = c("I","II","III")),
    row.names = samp)
  list(mat = mat, types = types, clin = clin)
}

synth_tree <- function(n_tip = 24, n_feat = 6, seed = 8) {
  set.seed(seed)
  if (!requireNamespace("ape", quietly = TRUE)) stop("需要 ape 包")
  tr <- ape::rtree(n_tip)
  tr$tip.label <- paste0("T", sprintf("%02d", seq_len(n_tip)))
  grp <- factor(sample(c("Clade A","Clade B","Clade C"), n_tip, TRUE))
  mat <- matrix(rnorm(n_tip * n_feat), n_tip, n_feat,
                dimnames = list(tr$tip.label, paste0("Feat", seq_len(n_feat))))
  mat <- mat + as.numeric(grp)                      # 按 clade 注入结构
  mat <- t(scale(t(mat)))                           # 行 z-score
  list(tree = tr, mat = mat, group = grp)
}
