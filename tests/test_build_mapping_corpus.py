import sqlite3
import sys
import tempfile
import unittest
from contextlib import closing
from pathlib import Path
from unittest import mock


sys.path.insert(0, str(Path(__file__).parents[1] / "scripts"))

try:
    import build_mapping_corpus as builder
except ModuleNotFoundError:
    builder = None


class MappingModuleTests(unittest.TestCase):
    def test_builder_module_is_available(self):
        self.assertIsNotNone(builder, "build_mapping_corpus module must exist")


@unittest.skipIf(builder is None, "build_mapping_corpus is not implemented")
class MappingParserTests(unittest.TestCase):
    def test_parses_mojang_class_method_and_field_in_official_direction(self):
        rows = list(builder.parse_mojang([
            "net.minecraft.C -> a.b.C:",
            "    int count -> b",
            "    1:1:void tick(int) -> a",
        ]))

        self.assertEqual(len(rows), 3)
        self.assertEqual((rows[0].kind, rows[0].name_from, rows[0].name_to),
                         ("class", "net.minecraft.C", "a.b.C"))
        self.assertEqual((rows[1].kind, rows[1].name_from, rows[1].name_to),
                         ("field", "count", "b"))
        self.assertEqual((rows[2].namespace_from, rows[2].namespace_to),
                         ("official", "obfuscated"))
        self.assertEqual((rows[2].name_from, rows[2].name_to), ("tick", "a"))
        self.assertEqual(rows[2].signature, "void(int)")

    def test_parses_tsrg2_class_field_and_method(self):
        rows = list(builder.parse_tsrg2([
            "tsrg2 obf srg id",
            "a net/minecraft/C 1",
            "\tb f_1_ 2",
            "\tc (I)V m_2_ 3",
            "\t\t0 value p_2_ 4",
        ]))

        self.assertEqual(len(rows), 4)
        self.assertEqual((rows[0].kind, rows[0].name_from, rows[0].name_to),
                         ("class", "a", "net/minecraft/C"))
        self.assertEqual((rows[1].kind, rows[1].name_from, rows[1].name_to),
                         ("field", "b", "f_1_"))
        self.assertEqual((rows[2].kind, rows[2].name_from, rows[2].name_to),
                         ("method", "c", "m_2_"))
        self.assertEqual(rows[2].signature, "(I)V")
        self.assertEqual((rows[3].kind, rows[3].name_from, rows[3].name_to),
                         ("parameter", "value", "p_2_"))

    def test_parses_mcp_csv_names(self):
        rows = list(builder.parse_mcp_csv([
            "searge,name,side,desc",
            "m_123_,tick,2,Run one tick",
        ], "method"))

        self.assertEqual(len(rows), 1)
        self.assertEqual((rows[0].namespace_from, rows[0].namespace_to), ("srg", "mcp"))
        self.assertEqual((rows[0].kind, rows[0].name_from, rows[0].name_to),
                         ("method", "m_123_", "tick"))


@unittest.skipIf(builder is None, "build_mapping_corpus is not implemented")
class MappingBuilderTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.data = self.root / "Data"
        self.out = self.data / "Minecraft_Mappings_Corpus"
        self.fixture = self.data / "Minecraft_Java_Server_Client" / "1.20.1" / "client_mappings.txt"
        self.fixture.parent.mkdir(parents=True)
        self.fixture.write_text("net.minecraft.C -> a:\n    void tick() -> b\n", encoding="utf-8")

    def tearDown(self):
        self.temp.cleanup()

    def active_db(self):
        return self.out / (self.out / "_ACTIVE_DB.txt").read_text(encoding="utf-8").strip()

    def test_second_build_reparses_zero_sources(self):
        first = builder.build_corpus(self.data, self.out)
        self.assertIn("changed_sources_this_run", first)
        second = builder.build_corpus(self.data, self.out)

        self.assertEqual(first["changed_sources_this_run"], 1)
        self.assertEqual(second["changed_sources_this_run"], 0)
        with closing(sqlite3.connect(self.active_db())) as connection:
            self.assertEqual(connection.execute("SELECT COUNT(*) FROM symbols").fetchone()[0], 2)

    def test_invalid_candidate_preserves_active_pointer(self):
        self.assertTrue(callable(getattr(builder, "validate_candidate", None)),
                        "validate_candidate must exist")
        builder.build_corpus(self.data, self.out)
        old_name = (self.out / "_ACTIVE_DB.txt").read_text(encoding="utf-8").strip()
        self.fixture.write_text("net.minecraft.D -> d:\n", encoding="utf-8")

        with mock.patch.object(builder, "validate_candidate", return_value=False):
            with self.assertRaises(RuntimeError):
                builder.build_corpus(self.data, self.out)

        self.assertEqual((self.out / "_ACTIVE_DB.txt").read_text(encoding="utf-8").strip(), old_name)

    def test_removed_source_is_absent_from_new_database(self):
        first = builder.build_corpus(self.data, self.out)
        self.assertIn("changed_sources_this_run", first)
        other = self.data / "Minecraft_Java_Server_Client" / "1.20.2" / "client_mappings.txt"
        other.parent.mkdir(parents=True)
        other.write_text("net.minecraft.D -> d:\n", encoding="utf-8")
        builder.build_corpus(self.data, self.out)
        self.fixture.unlink()

        result = builder.build_corpus(self.data, self.out)

        self.assertEqual(result["removed_sources_this_run"], 1)
        with closing(sqlite3.connect(self.active_db())) as connection:
            self.assertEqual(connection.execute("SELECT COUNT(*) FROM sources").fetchone()[0], 1)


if __name__ == "__main__":
    unittest.main()
