# GokuCodexAI repair policy

## Authority

Codex is the repair orchestrator. It owns evidence gathering, routing, worker
selection, integration, validation, and promotion of a repaired conversion.

The orchestrator route is Luna High (`gpt-5.6-luna-high`, high reasoning).
For hard issues, repeated failures, conflicting evidence, or an orchestrator
failure, preserve the evidence and hand off to Sol Medium
(`gpt-5.6-sol-medium`, medium reasoning). KAT remains the optional bounded
local worker and is not promoted to orchestrator.

KAT and Qwen are optional bounded workers. They may receive one compact issue
packet, but they never own the workspace, choose the overall repair strategy,
or promote their own output. Missing, timed-out, malformed, or uncertain local
worker output returns control to Codex without applying edits.

## Required resolution order

1. Re-run and inspect deterministic conversion evidence.
2. Search the persistent Solutions Index and hardened fixes under
   `C:\GokuCodexAI\Data\Solved_Problems`.
3. Retrieve compact evidence for the exact source and NeoForge 26.2 target.
4. Consult exact-version physical sources before making target API claims.
5. Use AST repair for Java or Gradle structure when deterministic rules and
   known solutions are insufficient.
6. Optionally send one bounded issue to KAT or Qwen when that reduces risk.
7. Integrate only evidence-backed changes, then validate build and runtime
   correctness as separate gates.

## Preservation contract

Preserve and verify assets, models, items, entities, AI, and behaviour as close
to the original mod as NeoForge 26.2 permits. A clean build is not proof that
content loads, registries are complete, or gameplay behaviour is correct.

## Worker contract

Each `.gokuai/issues/<issue-id>/request.json` contains `issue_id`, `problem`,
`acceptance_criteria`, `evidence_paths`, `failure_excerpt`,
`validation_commands`, and `result_path`.

Worker results must contain `status`, `diagnosis`, `files_changed`,
`evidence_paths`, `validation`, `remaining_risks`, and `confidence`. Codex must
validate the result before applying any proposed edit.

## Hardware policy

- KAT is the default optional local worker; Qwen is an optional review worker.
- All model layers stay on the RTX 4090; automatic CPU/RAM offload is forbidden.
- OOM, timeout, missing executable, and malformed output are recoverable worker
  failures. Codex continues without the local worker.
