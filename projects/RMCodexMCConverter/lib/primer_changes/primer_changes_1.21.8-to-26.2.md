# Primer changes index: 1.21.8 → 26.2

Compact **index** for agents. Do **not** open every shard at once.
Open only the version shard(s) that match the API area you are converting.

## Agent protocol

1. Detect `source_version` from the jar/project.
2. Read this index for `1.21.8` → `26.2`.
3. Open **one version shard at a time** from the list below (start with the newest deltas that mention your symbol).
4. Only open a full primer `index.md` when a shard row needs surrounding prose.
5. Confirm final target APIs against exact-version physical NeoForge/Minecraft source.

## Metadata

- Generated: `2026-09-02T11:59:21Z`
- Selection rule: `source_version < primer_version <= target_version`
- Source primers root: `station:_upstream/neoforge_primers/primers`
- Chain: `1.21.9 → 1.21.10 → 1.21.11 → 26.1 → 26.2`
- Change rows: `985`
- Index: `station:NeoForge_Primers/26.2/primer_changes_1.21.8-to-26.2.md`
- Shards dir: `primer_changes_1.21.8-to-26.2/`

## Shards (open selectively)

- [`1.21.9`](primer_changes_1.21.8-to-26.2/1.21.9.md) — 249 change rows, 13 headings
- [`1.21.10`](primer_changes_1.21.8-to-26.2/1.21.10.md) — 3 change rows, 5 headings
- [`1.21.11`](primer_changes_1.21.8-to-26.2/1.21.11.md) — 261 change rows, 8 headings
- [`26.1`](primer_changes_1.21.8-to-26.2/26.1.md) — 240 change rows, 15 headings
- [`26.2`](primer_changes_1.21.8-to-26.2/26.2.md) — 232 change rows, 17 headings

## Suggested read order for converter work

1. Target end: `26.2`, then `26.1`
2. Large mid-chain deltas that usually matter: `1.21.11`, `1.21.9`, `1.21.5`, `1.21.2`, `1.21`, `1.20.5`
3. Skip tiny primers unless a symbol search hits them (`1.20.6`, `1.21.1`, `1.21.7`, `1.21.8`, `1.21.10`)
