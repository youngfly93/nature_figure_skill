# 独立基因组圈图 (circlize)

- **何时用**：全基因组多维证据（CNV、表达、突变密度、染色体间重排/互作）想在一张圆图里同时展示；泛基因组/结构变异 Figure。
- **数据形状**：每条染色体的位置 + 各轨道数值（CNV/表达…）+ 连线端点（chr1,pos1,chr2,pos2）。
- **核心依赖**：circlize、ragg、figure_setup.R。
- **配色规则**：轨道/连线色取自 theme（nature_seq/nature_div），不硬编。
- **常见翻车点（渲染）**：① circos 是 base 图、非 ggplot → 出图用 agg_png/cairo_pdf 直接画，别塞 ggsave；② 忘了 circos.clear() 两端包裹 → 状态泄漏导致下一张图叠加异常；③ 轨道太多挤成糊 → 控制 ≤4 轨、留 track.margin；④ 默认会写 Rplots.pdf → 末尾 unlink；⑤ circos.track 传 y 但漏传 x → "Length of x and y differ" 报错，需同时传 x=position。
- **常见翻车点（分析严谨）**：⑥ **连线(links)极易过度解读**——视觉上"连起来"会暗示因果/互作，但若只是共现/相关/预测，必须在图注写清是相关而非验证的互作，不得凭圈图连线直接得出功能关联结论；⑦ **CNV 轨用未按 ploidy/纯度校正的原始拷贝数**会夸大幅度，跨样本比较前先说明是否经 purity/ploidy 校正（未校正的相对拷贝数只能同样本内比较方向，不能跨样本量化绝对拷贝数变化）；⑧ **随机游走合成数据的 CNV 值可能超出生物合理范围**（正常 1–4 copy），若替换真实数据须确认轴范围及参考线（diploid=0 或 log2ratio=0）语义一致。
- **参考实现**：`archetypes/genome-circos/`
