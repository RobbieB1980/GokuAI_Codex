# Session continue — skills/agents Phase 2+3

**Read this first.** Last saved: **2026-09-05**.

## Status

All planned phases for GokuAI migration skills/agents are in the converter project.

### Phase 1 (done)

- Slim `Agents.md` + session rules
- Skills: `minecraft-knowledge`, `migrate-neoforge-262`, `repair-failed-262-output`, `encode-262r-remap`, `validate-destination-build`
- Evidence packet template

### Phase 2 (done)

- Agents: `mc-research`, `mc-fast`, `mc-code`, `mc-reviewer` under `.grok/agents/`
- Spawn packet contract: `.grok/skills/migrate-neoforge-262/references/spawn-packet-contract.md`
- Workflow: `.grok/workflows/repair-neoforge-262.rhai` (smoke-checked; pass `args.failed_output`)

### Phase 3 (done)

- `262r-shard-index.md` links catalog ids only (no shard bodies)
- `tools/Lint-MigrationSkills.ps1` checks slim AGENTS, required skills/agents, catalog file presence, index id drift

## How to run

```text
/repair-failed-262-output
/validate-destination-build
/encode-262r-remap
/repair-neoforge-262   (workflow; args.failed_output = absolute path)
```

```powershell
powershell -NoProfile -File tools\Lint-MigrationSkills.ps1
```

## Related

- Converter product v2.10.11 destination JDK pin
- Live knowledge: `C:\gokuai\Data\262r`
