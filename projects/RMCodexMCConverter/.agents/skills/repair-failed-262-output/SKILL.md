---
name: repair-failed-262-output
description: >-
  Repair a failed RB Legacy Java Converter NeoForge 26.2 output folder.
  Use for Repair with GokuCodexAI, CODEX_REPAIR_REQUEST.md, compile-errors.log repair,
  or any failed-output path that needs green gradlew build.
---

# Repair failed 26.2 output

Run this playbook under `legacy-java-converter-vnext`, which owns stage order,
preservation, escalation, and the distinction between build and runtime success.

## First actions

1. Read `CODEX_REPAIR_REQUEST.md` (names **FAILED OUTPUT FOLDER**).
2. Read `MIGRATION_EVIDENCE.md`, `SOURCE_PROFILE.json`,
   `conversion-manifest.json`, and `compile-errors.log`.
3. Copy/fill an evidence packet beside the failed output:
   - Template: `references/evidence-packet-template.md`
   - Suggested path: `<FAILED OUTPUT>\EVIDENCE_PACKET.md` (keep under ~9k chars)
4. State detected `source_version` + primer ledger path before editing.

## Knowledge order (one file at a time)

1. `C:\GokuCodexAI\Data\262r\converter\` then matching `shards\` (one shard)
2. Solved cases under `C:\GokuCodexAI\Data\Solved_Problems\legacy-java-converter-26.2`
3. One `primer_changes` shard for detected-source → 26.2
4. Exact 26.2 physical source confirmation
5. Edit → validate → encode

## Validation

Use skill `validate-destination-build` (JDK 25).
`Gradle requires JVM 17+ ... JVM 8` = wrong JDK, not a mod bug.

## Session hygiene

After a green jar **or** a finished error family, prefer a **fresh chat** with only: failed-output path + `EVIDENCE_PACKET.md` + next error family. Do not carry a huge tool transcript into unrelated remaps.

## Agents

After the packet exists:

1. Optional `mc-research` if the matching 262r shard is unclear
2. `mc-fast` or `mc-code` with the packet path in the prompt
3. Parent `validate-destination-build`
4. Optional `mc-reviewer`
5. `encode-262r-remap` when reusable

Use the issue packet fields in this skill and the parent vNext orchestration
skill; no separate migration playbook is required.
Shard id cheat-sheet (links only): `references/262r-shard-index.md`.

## Encode

Reusable fixes → skill `encode-262r-remap`.
