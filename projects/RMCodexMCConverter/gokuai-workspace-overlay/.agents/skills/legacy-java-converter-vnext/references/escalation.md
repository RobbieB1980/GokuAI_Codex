# GokuCodexAI escalation contract

Escalate only after deterministic transforms and matching known solutions have
failed or produced an explicit low-confidence diagnostic.

The packet must contain:

- failed-output path and source profile;
- exact failing stage and command;
- smallest relevant error family;
- consulted Solutions Index/262r/primer entries;
- exact target-source excerpts or mappings;
- relevant source files and preservation constraints;
- changes already attempted and their results;
- validation command and acceptance criteria.

GokuCodexAI proposes or applies the bounded repair. The orchestrator reviews
scope, verifies the Gradle build, records runtime/behavioural status, and
decides whether the repair is reusable. Successful reusable repairs must be
added to deterministic logic, the Solutions Index/262r, and regression tests.

Do not let escalation broaden into a whole-project rewrite or substitute a
feature-removing compile stub for faithful conversion.
