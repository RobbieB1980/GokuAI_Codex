# GokuAI orchestration policy

## Authority

GokuAI is the persistent local orchestrator. It owns routing, compact state,
retrieval order, worker selection, validation, and escalation decisions.

Local llama.cpp models are bounded issue workers. Codex/ChatGPT is the senior
escalation engine, not the always-on orchestrator.

## Required resolution order

1. Search hardened fixes under `C:\gokuai\Data\Solved_Problems`.
2. Retrieve compact evidence for the exact source and target versions.
3. Consult exact-version physical sources before making target API claims.
4. Send one compact issue packet to `goku-fast` for mechanical work or
   `goku-code` for normal code, repair, migration, and synthesis work.
5. Verify the result once against the stated acceptance criteria.
6. Escalate to Sol Medium when local work fails or remains uncertain.
7. Escalate to Sol High only after repeated local failure, conflicting
   evidence, a multi-version architectural migration, a subtle runtime bug,
   or an uncertain Medium result.

## Worker contract

Each request contains one problem, acceptance criteria, exact evidence paths,
a minimal error excerpt, validation commands, and a result path. Do not pass
the parent transcript or entire logs.

Write results to `.gokuai/issues/<issue-id>/result.json` with: `status`,
`diagnosis`, `files_changed`, `evidence_paths`, `validation`,
`remaining_risks`, and `confidence`.

## Hardware policy

- One persistent KAT worker model; do not swap local models.
- All model layers stay on the RTX 4090.
- Automatic CPU/RAM model offload is forbidden.
- An OOM is a controlled failure; switch profile or reduce context explicitly.
- Native `ngram-mod` speculative decoding is enabled without a draft model.`r`n- Thinking uses medium effort with a 384-token reasoning budget.

