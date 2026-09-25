from __future__ import annotations

import asyncio
import json
import os
from pathlib import Path
import unittest

from mcp.client.session import ClientSession
from mcp.client.stdio import StdioServerParameters, stdio_client


ROOT = Path(__file__).resolve().parents[1]
PYTHON = Path(os.environ.get("KNOWLEDGE_MCP_V2_PYTHON", ROOT / "runtime/python-mcp-v2/Scripts/python.exe"))
SCRIPT = ROOT / "scripts/knowledge_mcp_v2.py"
DB = ROOT / "DataIndex/minecraft-knowledge-local/knowledge.v5.1789184507.db"
DATA_ROOT = ROOT / "Data"


EXPECTED_TOOLS = {
    "knowledge_status",
    "list_knowledge_sources",
    "search_knowledge",
    "resolve_reference",
    "resolve_primer_chain",
    "grep_physical_source",
    "read_physical_source",
    "build_migration_evidence",
    "follow_reference_links",
    "find_symbol",
    "list_versions",
    "read_reference",
    "search_solved_projects",
    "mapping_status",
    "search_mappings",
    "resolve_mapping",
    "translate_mapping",
}


async def exercise_server() -> tuple[set[str], str]:
    server = StdioServerParameters(
        command=str(PYTHON),
        args=[str(SCRIPT), "--db", str(DB), "--root", str(DATA_ROOT)],
        cwd=str(ROOT),
    )
    async with stdio_client(server) as (read_stream, write_stream):
        async with ClientSession(read_stream, write_stream) as session:
            await session.initialize()
            result = await session.list_tools()
            status = await session.call_tool("knowledge_status", {})
            status_text = status.content[0].text if status.content else ""
            return {tool.name for tool in result.tools}, status_text


class KnowledgeMcpV2Tests(unittest.TestCase):
    def test_stdio_initializes_and_registers_all_tools(self) -> None:
        self.assertTrue(PYTHON.is_file(), PYTHON)
        self.assertTrue(SCRIPT.is_file(), SCRIPT)
        tools, status = asyncio.run(exercise_server())
        self.assertEqual(tools, EXPECTED_TOOLS)
        self.assertIn('"ready": true', status)
        self.assertIn(json.dumps(str(DB))[1:-1], status)


if __name__ == "__main__":
    unittest.main()
