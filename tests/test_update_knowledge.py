import importlib.util
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "update_knowledge.py"
SPEC = importlib.util.spec_from_file_location("update_knowledge", MODULE_PATH)
updater = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(updater)


class SourceUpdaterTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)

    def tearDown(self):
        self.temp.cleanup()

    def test_atomic_write_json_leaves_no_partial_file(self):
        target = self.root / "manifest.json"

        changed = updater.atomic_write_json(target, {"ok": True})

        self.assertTrue(changed)
        self.assertEqual(json.loads(target.read_text(encoding="utf-8")), {"ok": True})
        self.assertFalse(target.with_suffix(".json.part").exists())

    def test_atomic_write_json_skips_unchanged_content(self):
        target = self.root / "manifest.json"
        updater.atomic_write_json(target, {"ok": True})
        before = target.stat().st_mtime_ns

        changed = updater.atomic_write_json(target, {"ok": True})

        self.assertFalse(changed)
        self.assertEqual(target.stat().st_mtime_ns, before)

    def test_failed_git_update_is_reported_as_retained_stale(self):
        upstream = self.root / "_upstream"
        repo = upstream / "repo"
        repo.mkdir(parents=True)
        with mock.patch.object(updater, "run", side_effect=RuntimeError("offline")):
            result = updater.update_git_repo("repo", "https://invalid.example/repo.git", upstream, True)

        self.assertEqual(result["status"], "retained_stale")
        self.assertIn("offline", result["error"])
        self.assertEqual(result["path"], str(repo.resolve()))

    def test_snapshots_are_default_and_release_only_opts_out(self):
        self.assertTrue(updater.should_include_snapshots(release_only=False))
        self.assertFalse(updater.should_include_snapshots(release_only=True))

    def test_both_mapping_files_are_default_but_server_jar_is_opt_in(self):
        target_builder = getattr(updater, "mojang_download_targets", None)
        self.assertTrue(callable(target_builder), "mojang_download_targets must exist")
        default_targets = target_builder(include_server_jar=False)
        server_targets = target_builder(include_server_jar=True)

        self.assertEqual(default_targets, {
            "client": "client.jar",
            "client_mappings": "client_mappings.txt",
            "server_mappings": "server_mappings.txt",
        })
        self.assertEqual(server_targets["server"], "server.jar")


if __name__ == "__main__":
    unittest.main()
