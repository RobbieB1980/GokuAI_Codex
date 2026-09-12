#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import os
import re
import sqlite3
import time
from contextlib import closing
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Iterator


@dataclass(frozen=True)
class MappingRecord:
    namespace_from: str
    namespace_to: str
    kind: str
    owner_from: str | None
    owner_to: str | None
    name_from: str
    name_to: str
    signature: str | None = None


@dataclass(frozen=True)
class SourceInput:
    minecraft_version: str
    source_type: str
    path: Path


def parse_mojang(lines: Iterable[str]) -> Iterator[MappingRecord]:
    owner_from = owner_to = None
    class_pattern = re.compile(r"^(\S+)\s+->\s+(\S+):$")
    line_range = re.compile(r"^(?:\d+:\d+:)+")
    for raw in lines:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if not raw[:1].isspace():
            match = class_pattern.match(raw.strip())
            if not match:
                owner_from = owner_to = None
                continue
            owner_from, owner_to = match.groups()
            yield MappingRecord("official", "obfuscated", "class", None, None,
                                owner_from, owner_to)
            continue
        if not owner_from or " -> " not in raw:
            continue
        left, name_to = raw.strip().rsplit(" -> ", 1)
        left = line_range.sub("", left)
        method = re.match(r"^(.+?)\s+([^\s(]+)\((.*)\)$", left)
        if method:
            return_type, name_from, arguments = method.groups()
            yield MappingRecord("official", "obfuscated", "method", owner_from,
                                owner_to, name_from, name_to,
                                f"{return_type}({arguments})")
            continue
        field = re.match(r"^(.+?)\s+(\S+)$", left)
        if field:
            field_type, name_from = field.groups()
            yield MappingRecord("official", "obfuscated", "field", owner_from,
                                owner_to, name_from, name_to, field_type)


def parse_tsrg2(lines: Iterable[str]) -> Iterator[MappingRecord]:
    namespace_from, namespace_to = "obfuscated", "srg"
    owner_from = owner_to = None
    method_signature = None
    for raw in lines:
        line = raw.rstrip("\r\n")
        if not line or line.lstrip().startswith("#"):
            continue
        if line.startswith("tsrg2 "):
            parts = line.split()
            if len(parts) >= 3:
                namespace_from, namespace_to = parts[1:3]
            continue
        indent = len(line) - len(line.lstrip("\t"))
        parts = line.strip().split()
        if indent == 0 and len(parts) >= 2:
            owner_from, owner_to = parts[:2]
            method_signature = None
            yield MappingRecord(namespace_from, namespace_to, "class", None,
                                None, owner_from, owner_to)
        elif indent == 1 and owner_from and len(parts) >= 2:
            if len(parts) >= 3 and parts[1].startswith("("):
                method_signature = parts[1]
                yield MappingRecord(namespace_from, namespace_to, "method",
                                    owner_from, owner_to, parts[0], parts[2], parts[1])
            elif not parts[0].isdigit() and parts[0] != "static":
                method_signature = None
                yield MappingRecord(namespace_from, namespace_to, "field",
                                    owner_from, owner_to, parts[0], parts[1])
        elif indent == 2 and owner_from and len(parts) >= 3 and parts[0].isdigit():
            yield MappingRecord(namespace_from, namespace_to, "parameter",
                                owner_from, owner_to, parts[1], parts[2],
                                f"index={parts[0]};method={method_signature or ''}")


def parse_mcp_csv(lines: Iterable[str], kind: str) -> Iterator[MappingRecord]:
    for row in csv.DictReader(lines):
        name_from = (row.get("searge") or row.get("param") or "").strip()
        name_to = (row.get("name") or "").strip()
        if name_from and name_to:
            yield MappingRecord("srg", "mcp", kind, None, None,
                                name_from, name_to)


def discover_sources(data_root: Path) -> list[SourceInput]:
    found: list[SourceInput] = []
    minecraft = data_root / "Minecraft_Java_Server_Client"
    if minecraft.is_dir():
        for version_dir in minecraft.iterdir():
            if not version_dir.is_dir():
                continue
            for filename, source_type in (("client_mappings.txt", "official_client"),
                                          ("server_mappings.txt", "official_server")):
                path = version_dir / filename
                if path.is_file():
                    found.append(SourceInput(version_dir.name, source_type, path.resolve()))
    releases = data_root / "_upstream" / "mcpconfig" / "versions" / "release"
    if releases.is_dir():
        for version_dir in releases.iterdir():
            path = version_dir / "joined.tsrg"
            if version_dir.is_dir() and path.is_file():
                found.append(SourceInput(version_dir.name, "mcpconfig_tsrg", path.resolve()))
    stable = data_root / "Minecraft_MCP_Mappings" / "1.12.2" / "mcp_stable_39"
    for filename, source_type in (("fields.csv", "mcp_stable_39_field"),
                                  ("methods.csv", "mcp_stable_39_method"),
                                  ("params.csv", "mcp_stable_39_parameter")):
        path = stable / filename
        if path.is_file():
            found.append(SourceInput("1.12.2", source_type, path.resolve()))
    return sorted(found, key=lambda source: str(source.path).lower())


def parse_source(source: SourceInput) -> Iterator[MappingRecord]:
    with source.path.open("r", encoding="utf-8-sig", errors="replace", newline="") as stream:
        if source.source_type.startswith("official_"):
            yield from parse_mojang(stream)
        elif source.source_type == "mcpconfig_tsrg":
            yield from parse_tsrg2(stream)
        else:
            kind = source.source_type.rsplit("_", 1)[-1]
            yield from parse_mcp_csv(stream, kind)


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def initialize_schema(connection: sqlite3.Connection) -> None:
    connection.executescript("""
        PRAGMA user_version=3;
        PRAGMA foreign_keys=ON;
        CREATE TABLE IF NOT EXISTS sources(
            id INTEGER PRIMARY KEY,
            minecraft_version TEXT NOT NULL,
            source_type TEXT NOT NULL,
            physical_path TEXT NOT NULL UNIQUE,
            size INTEGER NOT NULL,
            mtime_ns INTEGER NOT NULL,
            sha256 TEXT NOT NULL,
            records INTEGER NOT NULL,
            updated_unix INTEGER NOT NULL
        );
        CREATE TABLE IF NOT EXISTS symbols(
            id INTEGER PRIMARY KEY,
            minecraft_version TEXT NOT NULL,
            namespace_from TEXT NOT NULL,
            namespace_to TEXT NOT NULL,
            kind TEXT NOT NULL,
            owner_from TEXT,
            owner_to TEXT,
            name_from TEXT NOT NULL,
            name_to TEXT NOT NULL,
            signature TEXT,
            source_id INTEGER NOT NULL,
            FOREIGN KEY(source_id) REFERENCES sources(id) ON DELETE CASCADE
        );
        CREATE INDEX IF NOT EXISTS idx_sources_version_type ON sources(minecraft_version,source_type);
        CREATE INDEX IF NOT EXISTS idx_symbols_from ON symbols(minecraft_version,namespace_from,name_from);
        CREATE INDEX IF NOT EXISTS idx_symbols_to ON symbols(minecraft_version,namespace_to,name_to);
        CREATE INDEX IF NOT EXISTS idx_symbols_owner_from ON symbols(minecraft_version,owner_from);
        CREATE INDEX IF NOT EXISTS idx_symbols_owner_to ON symbols(minecraft_version,owner_to);
        CREATE INDEX IF NOT EXISTS idx_symbols_source ON symbols(source_id);
    """)


def resolve_active_database(output_root: Path) -> Path | None:
    pointer = output_root / "_ACTIVE_DB.txt"
    if not pointer.is_file():
        return None
    name = pointer.read_text(encoding="utf-8-sig").strip()
    path = Path(name)
    if not path.is_absolute():
        path = output_root / path
    return path.resolve() if path.is_file() else None


def atomic_write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    part = path.with_suffix(path.suffix + ".part")
    part.write_text(content, encoding="utf-8")
    os.replace(part, path)


def atomic_write_json(path: Path, data: dict) -> None:
    atomic_write_text(path, json.dumps(data, indent=2, sort_keys=True))


def validate_candidate(path: Path) -> bool:
    try:
        with closing(sqlite3.connect(path)) as connection:
            if connection.execute("PRAGMA user_version").fetchone()[0] != 3:
                return False
            tables = {row[0] for row in connection.execute(
                "SELECT name FROM sqlite_master WHERE type='table'")}
            if not {"sources", "symbols"}.issubset(tables):
                return False
            if connection.execute("PRAGMA foreign_key_check").fetchone() is not None:
                return False
            invalid = connection.execute("""
                SELECT 1 FROM symbols
                WHERE namespace_from NOT IN ('obfuscated','srg','mcp','official')
                   OR namespace_to NOT IN ('obfuscated','srg','mcp','official')
                LIMIT 1
            """).fetchone()
            return invalid is None
    except sqlite3.Error:
        return False


def _copy_active_database(active: Path, candidate: Path) -> None:
    with closing(sqlite3.connect(f"file:{active}?mode=ro", uri=True)) as source:
        with closing(sqlite3.connect(candidate)) as destination:
            source.backup(destination)


def _insert_records(connection: sqlite3.Connection, source: SourceInput,
                    source_id: int) -> int:
    sql = """INSERT INTO symbols(
        minecraft_version,namespace_from,namespace_to,kind,owner_from,owner_to,
        name_from,name_to,signature,source_id) VALUES(?,?,?,?,?,?,?,?,?,?)"""
    batch = []
    count = 0
    for record in parse_source(source):
        batch.append((source.minecraft_version, record.namespace_from,
                      record.namespace_to, record.kind, record.owner_from,
                      record.owner_to, record.name_from, record.name_to,
                      record.signature, source_id))
        if len(batch) >= 10000:
            connection.executemany(sql, batch)
            count += len(batch)
            batch.clear()
    if batch:
        connection.executemany(sql, batch)
        count += len(batch)
    return count


def build_corpus(data_root: Path, output_root: Path) -> dict:
    data_root = Path(data_root).resolve()
    output_root = Path(output_root).resolve()
    output_root.mkdir(parents=True, exist_ok=True)
    inputs = discover_sources(data_root)
    active = resolve_active_database(output_root)
    old: dict[str, tuple[int, int, str]] = {}
    if active:
        with closing(sqlite3.connect(f"file:{active}?mode=ro", uri=True)) as connection:
            old = {row[0]: (int(row[1]), int(row[2]), row[3]) for row in connection.execute(
                "SELECT physical_path,size,mtime_ns,sha256 FROM sources")}

    changed: list[tuple[SourceInput, os.stat_result, str]] = []
    metadata_only: list[tuple[SourceInput, os.stat_result]] = []
    current_paths = {str(source.path) for source in inputs}
    for source in inputs:
        stat = source.path.stat()
        prior = old.get(str(source.path))
        if prior and prior[:2] == (stat.st_size, stat.st_mtime_ns):
            continue
        digest = sha256_file(source.path)
        if prior and prior[2] == digest:
            metadata_only.append((source, stat))
        else:
            changed.append((source, stat, digest))
    removed = sorted(set(old) - current_paths)

    if active and not changed and not metadata_only and not removed:
        with closing(sqlite3.connect(f"file:{active}?mode=ro", uri=True)) as connection:
            source_count = connection.execute("SELECT COUNT(*) FROM sources").fetchone()[0]
            symbol_rows = connection.execute("SELECT COUNT(*) FROM symbols").fetchone()[0]
        result = {
            "schema": 3, "status": "success", "database": str(active),
            "active_database": str(active), "source_count": source_count,
            "symbol_rows": symbol_rows, "changed_sources_this_run": 0,
            "removed_sources_this_run": 0, "metadata_updates_this_run": 0,
            "mapping_profile": "client+server", "incremental": True,
            "zero_copy": True, "updated_unix": int(time.time()),
        }
        atomic_write_json(output_root / "_STATUS.json", result)
        return result

    candidate = output_root / f"mappings.v3.{time.time_ns()}.db"
    try:
        if active:
            _copy_active_database(active, candidate)
        with closing(sqlite3.connect(candidate)) as connection:
            initialize_schema(connection)
            connection.execute("PRAGMA foreign_keys=ON")
            for path in removed + [str(source.path) for source, _, _ in changed]:
                connection.execute("DELETE FROM sources WHERE physical_path=?", (path,))
            for source, stat in metadata_only:
                connection.execute("UPDATE sources SET size=?,mtime_ns=?,updated_unix=? WHERE physical_path=?",
                                   (stat.st_size, stat.st_mtime_ns, int(time.time()), str(source.path)))
            for source, stat, digest in changed:
                cursor = connection.execute("""INSERT INTO sources(
                    minecraft_version,source_type,physical_path,size,mtime_ns,sha256,records,updated_unix)
                    VALUES(?,?,?,?,?,?,0,?)""",
                    (source.minecraft_version, source.source_type, str(source.path),
                     stat.st_size, stat.st_mtime_ns, digest, int(time.time())))
                records = _insert_records(connection, source, int(cursor.lastrowid))
                connection.execute("UPDATE sources SET records=? WHERE id=?",
                                   (records, int(cursor.lastrowid)))
            connection.commit()
        if not validate_candidate(candidate):
            raise RuntimeError(f"Mapping candidate validation failed: {candidate}")
        atomic_write_text(output_root / "_ACTIVE_DB.txt", candidate.name + "\n")
        with closing(sqlite3.connect(f"file:{candidate}?mode=ro", uri=True)) as connection:
            source_count = connection.execute("SELECT COUNT(*) FROM sources").fetchone()[0]
            symbol_rows = connection.execute("SELECT COUNT(*) FROM symbols").fetchone()[0]
            versions = [row[0] for row in connection.execute(
                "SELECT DISTINCT minecraft_version FROM sources ORDER BY minecraft_version")]
        result = {
            "schema": 3, "status": "success", "database": str(candidate),
            "active_database": str(candidate), "lock_safe_versioned_db": True,
            "source_count": source_count, "symbol_rows": symbol_rows,
            "changed_sources_this_run": len(changed),
            "removed_sources_this_run": len(removed),
            "metadata_updates_this_run": len(metadata_only), "versions": versions,
            "namespaces": ["obfuscated", "srg", "mcp", "official"],
            "mapping_profile": "client+server", "incremental": True,
            "zero_copy": True, "updated_unix": int(time.time()),
        }
        atomic_write_json(output_root / "_STATUS.json", result)
        return result
    except Exception:
        for suffix in ("", "-wal", "-shm"):
            try:
                Path(str(candidate) + suffix).unlink()
            except FileNotFoundError:
                pass
        raise


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data-root", required=True)
    parser.add_argument("--output-root")
    parser.add_argument("--json-out")
    args = parser.parse_args()
    data_root = Path(args.data_root)
    output_root = Path(args.output_root) if args.output_root else data_root / "Minecraft_Mappings_Corpus"
    result = build_corpus(data_root, output_root)
    if args.json_out:
        atomic_write_json(Path(args.json_out), result)
    print(json.dumps(result, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
