# Knowledge index policy (GokuAI only)

Canonical Minecraft knowledge index:

- Root: `C:\GokuCodexAI\Data` (`source_id=local`)
- DB: `C:\GokuCodexAI\DataIndex\minecraft-knowledge\` (see `_ACTIVE_DB.txt`)
- Manifest: `C:\GokuCodexAI\Data\external_sources.json` must have `"sources": []`

**Do not** register `H:\GrokBuild_MF\Completed_Projects` or other external trees.

Rebuild:

```powershell
C:\GokuCodexAI\runtime\.venv\Scripts\python.exe C:\GokuCodexAI\scripts\index_knowledge.py `
  --root C:\GokuCodexAI\Data `
  --db C:\GokuCodexAI\DataIndex\minecraft-knowledge\knowledge.db `
  --sources-manifest C:\GokuCodexAI\Data\external_sources.json
```

Refresh project rules:

```powershell
C:\GokuCodexAI\runtime\.venv\Scripts\python.exe C:\GokuCodexAI\scripts\generate_project_knowledge_context.py `
  --root C:\GokuCodexAI --project C:\GokuCodexAI\projects\RB-Legacy-Java-Converter
```
