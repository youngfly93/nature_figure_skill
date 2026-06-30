# 部署清单（控制者获批后执行）

> 本文件列出将项目侧内容部署进 `~/.claude/skills/nature-figure/` 的精确步骤。
> **执行前必须获得用户明确授权**，未授权时不得写入 `~/.claude/` 下任何路径。

---

## 前置检查

```bash
# 确认 skill 目录存在
ls -la ~/.claude/skills/nature-figure/references/
ls -la ~/.claude/skills/nature-figure/assets/ 2>/dev/null || echo "(assets 目录不存在，第二步会创建)"

# 检查 skill 目录是否是 git 仓库（决定回滚方式）
git -C ~/.claude/skills/nature-figure status -s 2>/dev/null || echo "(非 git 仓库，继续执行手动备份)"

# 备份将要修改的现有文件
cp ~/.claude/skills/nature-figure/references/r-template-index.md \
   /tmp/r-template-index.bak.$(date +%Y%m%d_%H%M%S).md
echo "备份完成"
```

---

## Step 1：拷贝参考图进 skill 资产目录

```bash
mkdir -p ~/.claude/skills/nature-figure/assets/advanced-archetypes

# 从项目侧拷贝（路径以项目实际 clone/checkout 位置为准）
cp /mnt/f/work/research/nature_figure_skill/archetypes/omics-multiannot-heatmap/out/ref.png \
   ~/.claude/skills/nature-figure/assets/advanced-archetypes/heatmap.png

cp /mnt/f/work/research/nature_figure_skill/archetypes/composite-cancer-multiomics/out/ref.png \
   ~/.claude/skills/nature-figure/assets/advanced-archetypes/composite.png

# 校验
ls -lh ~/.claude/skills/nature-figure/assets/advanced-archetypes/
```

预期输出：`heatmap.png` 与 `composite.png` 均出现，文件大小 > 0。

---

## Step 2：拷贝 advanced-archetypes.md 进 skill references 目录

```bash
cp /mnt/f/work/research/nature_figure_skill/skill-integration/advanced-archetypes.md \
   ~/.claude/skills/nature-figure/references/advanced-archetypes.md

# 校验
ls -lh ~/.claude/skills/nature-figure/references/advanced-archetypes.md
```

---

## Step 3：在 r-template-index.md 末尾追加指针段落

**追加内容（不改原文，仅在末尾新增）**：

```markdown

## 高级/复合 archetype（见 advanced-archetypes.md）

当任务需要"复杂高大上"图（多注释热图、circos、ggtree、UMAP atlas、Sankey/网络、复合多面板大图）时，
先查 `references/advanced-archetypes.md` 的「图型野心阶梯」与已就绪 archetype，优先复用其参考实现，
再按数据适配。基础~中级图仍走 nature_theme.R 既有函数。
```

执行追加：

```bash
cat >> ~/.claude/skills/nature-figure/references/r-template-index.md << 'EOF'

## 高级/复合 archetype（见 advanced-archetypes.md）

当任务需要"复杂高大上"图（多注释热图、circos、ggtree、UMAP atlas、Sankey/网络、复合多面板大图）时，
先查 `references/advanced-archetypes.md` 的「图型野心阶梯」与已就绪 archetype，优先复用其参考实现，
再按数据适配。基础~中级图仍走 nature_theme.R 既有函数。
EOF
```

---

## Step 4：校验 r-template-index.md 改动（仅末尾新增，展示 diff）

```bash
# 与备份对比，确认只有末尾追加
diff /tmp/r-template-index.bak.*.md ~/.claude/skills/nature-figure/references/r-template-index.md
```

预期 diff 输出：只显示末尾新增的 `## 高级/复合 archetype` 段落，无其他改动。**展示给用户确认后再关闭本部署流程。**

---

## Step 5：最终清单核验

```bash
echo "=== references 目录 ===" && ls -lh ~/.claude/skills/nature-figure/references/
echo "=== assets/advanced-archetypes ===" && ls -lh ~/.claude/skills/nature-figure/assets/advanced-archetypes/
```

预期：
- `references/advanced-archetypes.md` ✓
- `references/r-template-index.md`（已追加指针）✓
- `assets/advanced-archetypes/heatmap.png` ✓
- `assets/advanced-archetypes/composite.png` ✓

---

## 回滚方式

若部署出错需回滚：

```bash
# 恢复 r-template-index.md（替换为备份）
cp /tmp/r-template-index.bak.*.md ~/.claude/skills/nature-figure/references/r-template-index.md

# 删除新增文件
rm -f ~/.claude/skills/nature-figure/references/advanced-archetypes.md
rm -rf ~/.claude/skills/nature-figure/assets/advanced-archetypes/
```

---

*本文件由 Task 5（Phase 0）生成，部署前需用户授权。*
