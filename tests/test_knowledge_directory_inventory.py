import importlib.util
import os
import tempfile
import unittest
from pathlib import Path


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "validate_knowledge_index.py"
SPEC = importlib.util.spec_from_file_location("validate_knowledge_index", MODULE_PATH)
validator = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(validator)


class KnowledgeDirectoryInventoryTests(unittest.TestCase):
    def test_inventory_reports_indexable_and_excluded_files_per_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            alpha = root / "alpha"
            alpha.mkdir()
            (alpha / "readme.md").write_text("knowledge", encoding="utf-8")
            (alpha / "primer.mdx").write_text("primer", encoding="utf-8")
            (alpha / "page.html").write_text("page", encoding="utf-8")
            (alpha / "texture.png").write_bytes(b"png")
            (root / "Minecraft_Mappings_Corpus").mkdir()
            (root / "Minecraft_Mappings_Corpus" / "symbols.db").write_bytes(b"db")
            (root / "NeoForm_All_Patches").mkdir()
            (root / "NeoForm_All_Patches" / "change.patch").write_text("patch", encoding="utf-8")
            (root / "Exact_Version_Sources" / "NeoForge" / "26.2").mkdir(parents=True)
            (root / "Exact_Version_Sources" / "NeoForge" / "26.2" / "change.patch").write_text("patch", encoding="utf-8")
            (root / "_upstream" / "repo").mkdir(parents=True)
            (root / "_upstream" / "repo" / "history.patch").write_text("patch", encoding="utf-8")

            indexed = {
                os.path.normcase(os.path.normpath(str(alpha / "readme.md"))),
                os.path.normcase(os.path.normpath(str(alpha / "primer.mdx"))),
                os.path.normcase(os.path.normpath(str(alpha / "page.html"))),
                os.path.normcase(os.path.normpath(str(root / "NeoForm_All_Patches" / "change.patch"))),
                os.path.normcase(os.path.normpath(str(root / "Exact_Version_Sources" / "NeoForge" / "26.2" / "change.patch"))),
            }
            inventory = validator.build_directory_inventory(root, indexed)
            by_name = {item["name"]: item for item in inventory}

            self.assertEqual(by_name["alpha"]["physical_files"], 4)
            self.assertEqual(by_name["alpha"]["indexable_files"], 3)
            self.assertEqual(by_name["alpha"]["indexed_files"], 3)
            self.assertEqual(by_name["alpha"]["excluded_files"], 1)
            self.assertEqual(by_name["Minecraft_Mappings_Corpus"]["indexable_files"], 0)
            self.assertEqual(by_name["NeoForm_All_Patches"]["indexable_files"], 1)
            self.assertEqual(by_name["Exact_Version_Sources"]["indexable_files"], 1)
            self.assertEqual(by_name["_upstream"]["indexable_files"], 0)


if __name__ == "__main__":
    unittest.main()
