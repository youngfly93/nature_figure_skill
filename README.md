# Nature 高级图型 archetype 库

让 agent 不止画基础款,而能画 Nature 级复杂/复合图。每个 archetype = 可跑脚本 + 真参考图 + 说明卡。
配色/主题唯一真源:`~/.claude/assets/figure-style/nature_theme.R`。

## 用法
- 环境自检:`Rscript tools/env_check.R`
- 出某图:`Rscript archetypes/<name>/plot.R` → 写 `archetypes/<name>/out/ref.{png,pdf}`
- QA 门禁:`Rscript tools/qa_check.R archetypes/<name>/out/ref.png`

## 设计/计划
见 `docs/superpowers/specs/` 与 `docs/superpowers/plans/`。
