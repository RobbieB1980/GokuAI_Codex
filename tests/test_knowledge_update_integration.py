import json
import sqlite3
import subprocess
import sys
import tempfile
import unittest
from contextlib import closing
from pathlib import Path


REPO = Path(__file__).parents[1]
VALIDATOR = REPO / "scripts" / "validate_knowledge_index.py"
sys.path.insert(0, str(REPO / "scripts"))
import build_mapping_corpus as builder


class KnowledgeUpdateIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.station = Path(self.temp.name)
        self.data = self.station / "Data"
        self.data.mkdir()

    def tearDown(self):
        self.temp.cleanup()

    def run_validator(self):
        report = self.station / "report.json"
        subprocess.run([
            sys.executable, str(VALIDATOR), "--station-root", str(self.station),
            "--data-root", str(self.data), "--json-out", str(report),
        ], check=False, capture_output=True, text=True)
        return json.loads(report.read_text(encoding="utf-8-sig"))

    def test_validator_rejects_partial_files_and_failed_source_manifest(self):
        (self.data / "orphan.jar.part").write_bytes(b"partial")
        (self.data / "knowledge_manifest.json").write_text(json.dumps({
            "status": "failed",
            "repository_paths": {"neoforge": str(self.data / "missing")},
            "repository_results": {"neoforge": {"status": "retained_stale"}},
        }), encoding="utf-8")

        report = self.run_validator()
        checks = {item["check"] for item in report["failures"]}

        self.assertIn("partial_files_absent", checks)
        self.assertIn("source_manifest_complete", checks)
        self.assertIn("canonical_repository_paths", checks)

    def test_validator_rejects_active_pointers_with_missing_targets(self):
        knowledge_root = self.station / "DataIndex" / "minecraft-knowledge"
        mapping_root = self.data / "Minecraft_Mappings_Corpus"
        knowledge_root.mkdir(parents=True)
        mapping_root.mkdir(parents=True)
        (knowledge_root / "_ACTIVE_DB.txt").write_text("missing-knowledge.db\n", encoding="utf-8")
        (mapping_root / "_ACTIVE_DB.txt").write_text("missing-mappings.db\n", encoding="utf-8")
        (self.data / "knowledge_manifest.json").write_text(json.dumps({
            "repository_paths": {},
        }), encoding="utf-8")

        report = self.run_validator()
        checks = {item["check"] for item in report["failures"]}

        self.assertIn("knowledge_active_pointer_target", checks)
        self.assertIn("mapping_active_pointer_target", checks)

    def test_offline_mapping_build_exposes_server_and_srg_to_mcp_edges(self):
        client = self.data / "Minecraft_Java_Server_Client" / "1.12.2" / "client_mappings.txt"
        server = client.with_name("server_mappings.txt")
        client.parent.mkdir(parents=True)
        client.write_text("net.minecraft.Client -> a:\n", encoding="utf-8")
        server.write_text("net.minecraft.Server -> b:\n", encoding="utf-8")
        methods = self.data / "Minecraft_MCP_Mappings" / "1.12.2" / "mcp_stable_39" / "methods.csv"
        methods.parent.mkdir(parents=True)
        methods.write_text("searge,name,side,desc\nfunc_1_tick,tick,2,\n", encoding="utf-8")

        result = builder.build_corpus(self.data, self.data / "Minecraft_Mappings_Corpus")

        with closing(sqlite3.connect(result["active_database"])) as connection:
            source_types = {row[0] for row in connection.execute("SELECT source_type FROM sources")}
            edge = connection.execute("""SELECT name_to FROM symbols
                WHERE namespace_from='srg' AND namespace_to='mcp' AND name_from='func_1_tick'""").fetchone()
        self.assertEqual(source_types, {"official_client", "official_server", "mcp_stable_39_method"})
        self.assertEqual(edge[0], "tick")


if __name__ == "__main__":
    unittest.main()
