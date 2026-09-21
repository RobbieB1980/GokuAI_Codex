# Converter — Fix-in-Grok handoff

**Scripts:** `Open-GrokRepairSession.ps1`, `C:\gokuai\Start-GokuAI.ps1`  
**IDs:** `mc-262r-fix-in-grok-promptfile`, `mc-262r-fix-in-grok-path`

## Failure mode

`GROK_REPAIR_PROMPT.md` correctly names `FAILED OUTPUT FOLDER`, but inlining the full multiline prompt into `launch-grok-session.bat` truncates at the first newline. Agents only saw the first sentence.

## Rule

When `-PromptFile` is set (or `-Prompt` contains newlines):

1. Do **not** paste the full body into the `.bat` CLI arg.
2. Pass a **single-line pointer**: open the prompt file first; it names the failed output.
3. Agent then reads `MIGRATION_EVIDENCE.md`, `SOURCE_PROFILE.json`, `compile-errors.log` from that folder.
4. `Open-GrokRepairSession.ps1` / compile-failure path must call `Write-GrokRepairPrompt` so the prompt always includes the **destination Java 25** build mandate and pins `org.gradle.java.home`.
5. Agent validation builds use `tools/Build-WithDestinationJava.ps1` (or `Invoke-GradleBuildWithRequiredJava`) — never ambient/source Java first.

## Proven

2026-09-05 Easy Mob Farm: prompt file had the path; bat truncation hid it until Start-GokuAI pointer fix.  
2026-09-05 Cat Fighting repair: agent ran bare `gradlew` under Java 8 first; destination-Java pin + prompt hardening added.
