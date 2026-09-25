# Knowledge MCP 2.x Migration Implementation Plan

**Goal:** Add an MCP 2.2.0 implementation of the knowledge server while preserving the MCP 1.30.0 rollback and existing Work tool behavior.

**Architecture:** Keep `scripts/knowledge_mcp.py` as the v1 implementation. Create a sibling v2 script with the same tools and data logic, replacing the removed v1 `FastMCP` import with MCP 2.x `MCPServer`; switch the active configuration only after a stdio client can initialize the server and enumerate every tool.

**Tech Stack:** Python, MCP Python SDK 1.30.0 and 2.2.0, SQLite, ChatGPT Work stdio transport.

**Global Constraints:** Preserve command-line arguments, database resolution, root paths, tool names, return JSON, and v1 rollback. Pin both SDK versions. Test v2 before changing `.codex/config.toml`.

**Review Focus:** Tool registration parity; stdio initialization; active database pointer resolution; Work command and argument compatibility; v1 file unchanged.

### Task 1: Add isolated v2 server and dependency pins

**Files:**
- Create: `scripts/knowledge_mcp_v2.py`
- Create: `requirements-mcp-v1.txt`
- Create: `requirements-mcp-v2.txt`
- Test: `tests/test_knowledge_mcp_v2.py`

- [ ] Copy the v1 implementation, change only the server import/constructor to MCP 2.x `MCPServer`, and retain all tool functions and CLI arguments.
- [ ] Pin `mcp==1.30.0` and `mcp==2.2.0` in separate requirement files.
- [ ] Add a stdio client test that starts v2 with the existing `--db`/`--root` arguments and asserts initialization plus the complete tool-name set.

### Task 2: Validate then switch Work configuration

**Files:**
- Modify: `.codex/config.toml`

- [ ] Run syntax/import and stdio tool-list tests with the isolated v2 runtime.
- [ ] Confirm the v1 script has no diff.
- [ ] Update only the active server command to the v2 runtime and sibling script; preserve database, root, cwd, and timeouts.
- [ ] Re-run the v2 client test using the exact configured command.
