# Final Whole-Branch Review Fixes — Phase 0

Applied: 2026-06-30  
Branch: `feat/phase0-archetypes`

---

## FIX 1 — QA gate fail-closed when `png` absent (Important)

**Files changed:**
- `tools/qa_check.R` line 19-21: replaced degraded-PASS `else` branch with `quit(status=2)` and error message `QA UNAVAILABLE: 缺 png 包，无法做白底/分辨率检测（核心门禁不可降级，请装 png）`
- `tools/env_check.R` line 5: added `"png"` to `req` vector

**Verification:**
- `grep -n 'status = 2' tools/qa_check.R` → line 21
- `grep -n '"png"' tools/env_check.R` → line 5
- `Rscript tools/env_check.R` → `ENV OK`
- `Rscript tools/test_qa.R` → `QA self-test OK`

---

## FIX 2 — Stop leaving Rplots.pdf in repo root (Minor)

**Files changed:**
- `.gitignore`: appended `Rplots.pdf` on its own line
- `archetypes/composite-cancer-multiomics/plot.R` line 93: added `unlink("Rplots.pdf")` after ggsave calls
- Stray `Rplots.pdf` removed with `rm -f Rplots.pdf`

**Verification:**
- `grep -n 'Rplots.pdf' .gitignore` → line 7
- `grep -n 'unlink' archetypes/composite-cancer-multiomics/plot.R` → line 93
- After re-running plot.R: no `Rplots.pdf` found in repo root

---

## FIX 3 — Drop `group=` prefix in composite KM legend (Minor/aesthetic)

**File changed:**
- `archetypes/composite-cancer-multiomics/plot.R` line 31: added `legend.labs=levels(sv$group)` to `ggsurvplot()` call

**Verification:**
- `grep -n 'legend.labs' archetypes/composite-cancer-multiomics/plot.R` → line 31
- `Rscript archetypes/composite-cancer-multiomics/plot.R` → `done: archetypes/composite-cancer-multiomics/out/ref.png`
- `Rscript tools/qa_check.R archetypes/composite-cancer-multiomics/out/ref.png 1800` → `QA PASS: ref.png — 2161 x 1889 px, 角亮度 1`

---

## FIX 4 — Correct reversed palette-direction prose in theme_api_notes.md (Minor)

**File changed:**
- `theme_api_notes.md` constants table: corrected direction descriptions
  - `nature_seq`: `蓝→白，6色` → `白→深蓝，6色` (truth: `#FFFFFF` → `#0F4D92`)
  - `nature_div`: `蓝→白→红，7色` → `红→白→蓝，7色` (truth: `#9B2E25` → `#FFFFFF` → `#0F4D92`)

---

## Summary

All four fixes applied and verified. No blocked items. Composite QA PASS at 2161×1889 px.
