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

# —— Phase 1.5 追加：差异表达（火山图用）——
synth_deg <- function(n = 12000, n_up = 280, n_dn = 260, seed = 42) {
  set.seed(seed)
  n_ns <- n - n_up - n_dn
  lf_ns <- rnorm(n_ns, 0, 0.35); z_ns <- rnorm(n_ns, 0, 0.9)
  lf_up <- rnorm(n_up,  2.4, 0.7); z_up <- lf_up/0.30 + rnorm(n_up, 0, 1.2)
  lf_dn <- rnorm(n_dn, -2.4, 0.7); z_dn <- lf_dn/0.30 + rnorm(n_dn, 0, 1.2)
  logFC <- c(lf_ns, lf_up, lf_dn)
  pval  <- 2 * pnorm(-abs(c(z_ns, z_up, z_dn)))
  adjP  <- p.adjust(pval, "BH")
  gene  <- sprintf("G%05d", seq_len(n))
  up_sym <- c("MMP9","SPP1","CDK1","TOP2A","COL1A1","KIF20A","CCNB1","AURKA","FOXM1","UBE2C")
  dn_sym <- c("ADH1B","PLIN1","CIDEC","ADIPOQ","FABP4","CD36","PPARG","KLF15","LPL","CFD")
  gene[order(-logFC)[seq_along(up_sym)]] <- up_sym
  gene[order( logFC)[seq_along(dn_sym)]] <- dn_sym
  fc_th <- 1; p_th <- 0.05
  sig <- factor(ifelse(adjP < p_th & logFC >=  fc_th, "Up",
                ifelse(adjP < p_th & logFC <= -fc_th, "Down", "ns")),
                levels = c("Up","Down","ns"))
  data.frame(gene = gene, logFC = logFC, adj.P.Val = adjP, sig = sig,
             y = -log10(pmax(adjP, 1e-300)), stringsAsFactors = FALSE)
}

# —— Phase 2 追加：单细胞 + 空间 ——
synth_scrna <- function(n_cells = 2000, n_types = 6, n_markers = 4, seed = 11) {
  set.seed(seed)
  types <- paste0("CellType", seq_len(n_types))
  ct <- factor(sample(types, n_cells, TRUE), levels = types)
  # 每个 celltype 一个 UMAP 簇中心
  ctr <- matrix(runif(n_types * 2, -8, 8), n_types, 2, dimnames = list(types, c("U1","U2")))
  emb <- data.frame(
    UMAP1 = ctr[ct, 1] + rnorm(n_cells, 0, 1.1),
    UMAP2 = ctr[ct, 2] + rnorm(n_cells, 0, 1.1),
    celltype = ct,
    cluster  = factor(as.integer(ct)))
  # marker 基因：每 celltype n_markers 个，在该型高表达
  genes <- paste0("M", sprintf("%02d", seq_len(n_types * n_markers)))
  gmap  <- data.frame(gene = genes,
                      celltype = factor(rep(types, each = n_markers), levels = types))
  base <- matrix(rpois(length(genes) * n_cells, 0.4), length(genes), n_cells,
                 dimnames = list(genes, NULL))
  for (i in seq_along(genes)) {
    hit <- ct == gmap$celltype[i]
    base[i, hit] <- base[i, hit] + rpois(sum(hit), 6)
  }
  expr <- log1p(base)                                  # 表达量（log1p 计数）
  lineage <- as.integer(ct) + rnorm(n_cells, 0, 0.3)   # 连续潜变量（拟时序参考）
  list(emb = emb, expr = expr, markers = gmap, counts = base, lineage = lineage)
}

synth_spatial <- function(n_spots = 1500, seed = 12) {
  set.seed(seed)
  side <- ceiling(sqrt(n_spots))
  g <- expand.grid(x = seq_len(side), y = seq_len(side))[seq_len(n_spots), ]
  # 空间域：按 x 分三带 + 噪声
  dom <- cut(g$x + rnorm(n_spots, 0, 1.2), breaks = 3, labels = c("Domain1","Domain2","Domain3"))
  feature <- sin(g$x / side * pi) * 2 + g$y / side + rnorm(n_spots, 0, 0.25)  # 空间梯度
  data.frame(x = g$x, y = g$y, celltype = factor(dom), feature = feature)
}

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
