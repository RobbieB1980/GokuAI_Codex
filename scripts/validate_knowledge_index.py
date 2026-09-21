#!/usr/bin/env python3
"""Validate the canonical GokuAI knowledge index + mappings corpus."""
from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys
from contextlib import closing
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
from index_knowledge import SKIP_DIRS, SourceSpec, iter_text_files


def active_db(canonical: Path) -> Path:
    pointer = canonical.parent / '_ACTIVE_DB.txt'
    try:
        name = pointer.read_text(encoding='utf-8-sig').strip()
    except OSError:
        name = ''
    if name:
        candidate = (canonical.parent / name).resolve()
        try:
            candidate.relative_to(canonical.parent.resolve())
        except ValueError:
            return canonical
        if candidate.exists():
            return candidate
    return canonical


def active_pointer_target(canonical: Path) -> tuple[Path, Path | None, bool]:
    pointer = canonical.parent / '_ACTIVE_DB.txt'
    try:
        name = pointer.read_text(encoding='utf-8-sig').strip()
    except OSError:
        return pointer, None, False
    if not name:
        return pointer, None, False
    target = Path(name)
    if not target.is_absolute():
        target = canonical.parent / target
    target = target.resolve()
    try:
        target.relative_to(canonical.parent.resolve())
    except ValueError:
        return pointer, target, False
    return pointer, target, target.is_file()


def ro(path: Path) -> sqlite3.Connection:
    con = sqlite3.connect(f'file:{path.resolve().as_posix()}?mode=ro', uri=True)
    con.row_factory = sqlite3.Row
    return con


def check(name: str, ok: bool, detail: str, failures: list[dict], warnings: list[dict], warn: bool = False) -> None:
    item = {'check': name, 'ok': ok, 'detail': detail}
    if ok:
        print(f'PASS  {name}: {detail}')
    elif warn:
        warnings.append(item)
        print(f'WARN  {name}: {detail}')
    else:
        failures.append(item)
        print(f'FAIL  {name}: {detail}')


def build_directory_inventory(data_root: Path, indexed_paths: set[str]) -> list[dict]:
    """Report physical, indexable, and indexed files for every data directory."""
    if not data_root.is_dir():
        return []

    def normalized(path: Path | str) -> str:
        return os.path.normcase(os.path.normpath(str(path)))

    physical: dict[str, int] = {}
    for directory in data_root.iterdir():
        if not directory.is_dir():
            continue
        count = 0
        for _current, dirs, names in os.walk(directory, followlinks=False):
            dirs[:] = [name for name in dirs if name not in SKIP_DIRS and not name.startswith('.git')]
            count += len(names)
        physical[directory.name] = count

    source = SourceSpec('local', data_root.resolve(), None, False)
    indexable: dict[str, int] = {name: 0 for name in physical}
    indexed: dict[str, int] = {name: 0 for name in physical}
    indexed_normalized = {normalized(path) for path in indexed_paths}
    for path in iter_text_files(source):
        relative = path.relative_to(data_root).parts
        if not relative or relative[0] not in indexable:
            continue
        top = relative[0]
        indexable[top] += 1
        if normalized(path) in indexed_normalized:
            indexed[top] += 1

    return [
        {
            'name': name,
            'physical_files': physical[name],
            'indexable_files': indexable[name],
            'indexed_files': indexed[name],
            'excluded_files': physical[name] - indexable[name],
            'missing_indexed_files': indexable[name] - indexed[name],
        }
        for name in sorted(physical, key=str.lower)
    ]


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument('--station-root', default=r'C:\GokuCodexAI')
    ap.add_argument('--data-root', default='')
    ap.add_argument('--knowledge-db', default='')
    ap.add_argument('--mapping-db', default='')
    ap.add_argument('--sample-paths', type=int, default=500)
    ap.add_argument('--json-out', default='')
    args = ap.parse_args()

    station = Path(args.station_root).resolve()
    data = Path(args.data_root).resolve() if args.data_root else station / 'Data'
    knowledge_canonical = Path(args.knowledge_db).resolve() if args.knowledge_db else station / 'DataIndex' / 'minecraft-knowledge-local' / 'knowledge.db'
    mapping_canonical = Path(args.mapping_db).resolve() if args.mapping_db else data / 'Minecraft_Mappings_Corpus' / 'mappings.db'

    knowledge_db = active_db(knowledge_canonical)
    mapping_db = active_db(mapping_canonical)

    failures: list[dict] = []
    warnings: list[dict] = []
    metrics: dict = {
        'station_root': str(station),
        'data_root': str(data),
        'knowledge_db': str(knowledge_db),
        'mapping_db': str(mapping_db),
    }

    check('data_root_exists', data.is_dir(), str(data), failures, warnings)
    check('knowledge_db_exists', knowledge_db.is_file(), str(knowledge_db), failures, warnings)
    check('mapping_db_exists', mapping_db.is_file(), str(mapping_db), failures, warnings)
    knowledge_pointer, knowledge_target, knowledge_pointer_ok = active_pointer_target(knowledge_canonical)
    mapping_pointer, mapping_target, mapping_pointer_ok = active_pointer_target(mapping_canonical)
    check('knowledge_active_pointer_target', knowledge_pointer_ok,
          f'pointer={knowledge_pointer} target={knowledge_target}', failures, warnings)
    check('mapping_active_pointer_target', mapping_pointer_ok,
          f'pointer={mapping_pointer} target={mapping_target}', failures, warnings)

    if knowledge_db.is_file():
        with closing(ro(knowledge_db)) as con:
            files = int(con.execute('SELECT COUNT(*) FROM files').fetchone()[0])
            chunks = int(con.execute('SELECT COUNT(*) FROM chunks').fetchone()[0])
            metrics['files'] = files
            metrics['chunks'] = chunks
            check('min_files', files >= 20000, f'files={files}', failures, warnings)
            check('min_chunks', chunks >= 50000, f'chunks={chunks}', failures, warnings)

            cats = {r['category']: int(r['n']) for r in con.execute(
                'SELECT category, COUNT(*) AS n FROM files GROUP BY category'
            )}
            metrics['categories'] = cats
            exact_262 = int(con.execute(
                "SELECT COUNT(*) FROM files WHERE category='ExactSource:neoforge' AND version='26.2'"
            ).fetchone()[0])
            check(
                'exact_neoforge_26_2',
                cats.get('ExactSource:neoforge', 0) >= 1000 and exact_262 >= 1000,
                f"ExactSource:neoforge total={cats.get('ExactSource:neoforge', 0)} v26.2={exact_262}",
                failures,
                warnings,
            )
            check(
                'upstream_neoforge',
                cats.get('Upstream:neoforge', 0) >= 500,
                f"Upstream:neoforge={cats.get('Upstream:neoforge', 0)}",
                failures,
                warnings,
            )
            check(
                'category_262r',
                cats.get('262r', 0) >= 1,
                f"262r={cats.get('262r', 0)}",
                failures,
                warnings,
            )
            check(
                'neoforge_primers',
                cats.get('NeoForge_Primers', 0) + cats.get('Upstream:neoforge_primers', 0) >= 10,
                f"NeoForge_Primers={cats.get('NeoForge_Primers', 0)} Upstream:neoforge_primers={cats.get('Upstream:neoforge_primers', 0)}",
                failures,
                warnings,
            )

            fts_n = int(con.execute(
                "SELECT COUNT(*) FROM chunks_fts WHERE chunks_fts MATCH 'DeferredRegister'"
            ).fetchone()[0])
            metrics['fts_DeferredRegister'] = fts_n
            check('fts_DeferredRegister', fts_n >= 50, f'hits={fts_n}', failures, warnings)

            sample = args.sample_paths
            missing = 0
            checked = 0
            bad: list[str] = []
            for row in con.execute('SELECT physical_path FROM files LIMIT ?', (sample,)):
                checked += 1
                pp = row['physical_path']
                if not Path(pp).exists():
                    missing += 1
                    if len(bad) < 5:
                        bad.append(pp)
            metrics['physical_sample_checked'] = checked
            metrics['physical_sample_missing'] = missing
            check(
                'physical_paths',
                missing == 0,
                f'missing={missing}/{checked}' + (f' examples={bad}' if bad else ''),
                failures,
                warnings,
            )

            indexed_paths = {row['physical_path'] for row in con.execute('SELECT physical_path FROM files')}
            inventory = build_directory_inventory(data, indexed_paths)
            metrics['directory_inventory'] = inventory
            missing_indexed = sum(item['missing_indexed_files'] for item in inventory)
            check(
                'directory_inventory',
                missing_indexed == 0,
                f'directories={len(inventory)} missing_indexed_files={missing_indexed}',
                failures,
                warnings,
            )

            sources = [dict(r) for r in con.execute(
                'SELECT source_id, source_root, COUNT(*) AS files FROM files GROUP BY source_id, source_root ORDER BY source_id'
            )]
            metrics['sources'] = sources
            for src in sources:
                exists = Path(src['source_root']).exists()
                check(
                    f"source_root:{src['source_id']}",
                    exists,
                    f"{src['source_root']} ({src['files']} files)",
                    failures,
                    warnings,
                    warn=(src['source_id'] != 'local'),
                )

    if mapping_db.is_file():
        with closing(ro(mapping_db)) as con:
            tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
            metrics['mapping_tables'] = sorted(tables)
            # Prefer a lightweight readiness probe over full table scans on a multi-GB DB.
            probe_ok = False
            detail = ''
            for table in ('symbols', 'edges', 'mappings', 'symbol', 'mapping_edges'):
                if table in tables:
                    row = con.execute(f'SELECT 1 FROM "{table}" LIMIT 1').fetchone()
                    probe_ok = row is not None
                    detail = f'table={table} has_rows={probe_ok}'
                    break
            if not detail:
                detail = f'tables={sorted(tables)[:12]}'
                probe_ok = len(tables) > 0
            metrics['mapping_probe'] = detail
            check('mapping_db_readable', probe_ok, detail, failures, warnings)
            if {'sources', 'symbols'}.issubset(tables):
                namespaces = {r[0] for r in con.execute(
                    'SELECT namespace_from FROM symbols UNION SELECT namespace_to FROM symbols'
                )}
                expected_namespaces = {'obfuscated', 'srg', 'mcp', 'official'}
                check('mapping_namespaces', expected_namespaces.issubset(namespaces),
                      f'namespaces={sorted(namespaces)}', failures, warnings)
                missing_mapping_sources = []
                for row in con.execute('SELECT physical_path FROM sources'):
                    if not Path(row[0]).is_file() and len(missing_mapping_sources) < 10:
                        missing_mapping_sources.append(row[0])
                check('mapping_source_paths', not missing_mapping_sources,
                      f'missing={len(missing_mapping_sources)}' +
                      (f' examples={missing_mapping_sources}' if missing_mapping_sources else ''),
                      failures, warnings)

    # Stale path hygiene
    manifest = data / 'knowledge_manifest.json'
    if manifest.is_file():
        text = manifest.read_text(encoding='utf-8-sig')
        stale = ('rm' + 'blocal_llm') in text
        check('manifest_no_rmblocal', not stale, str(manifest), failures, warnings)
        try:
            manifest_data = json.loads(text)
        except json.JSONDecodeError as exc:
            manifest_data = {}
            failures.append({'check': 'source_manifest_complete', 'ok': False,
                             'detail': f'invalid JSON: {exc}'})
        if manifest_data:
            repo_results = manifest_data.get('repository_results') or {}
            bad_results = {name: value.get('status') for name, value in repo_results.items()
                           if value.get('status') in {'failed', 'retained_stale'}}
            manifest_ok = manifest_data.get('status', 'success') == 'success' and not bad_results
            check('source_manifest_complete', manifest_ok,
                  f"status={manifest_data.get('status', 'legacy-success')} bad_repositories={bad_results}",
                  failures, warnings)
            missing_repositories = [path for path in (manifest_data.get('repository_paths') or {}).values()
                                    if not Path(path).is_dir()]
            check('canonical_repository_paths', not missing_repositories,
                  f'missing={len(missing_repositories)}' +
                  (f' examples={missing_repositories[:5]}' if missing_repositories else ''),
                  failures, warnings)
    else:
        check('source_manifest_complete', False, f'missing={manifest}', failures, warnings)

    partial_files = [str(path) for path in data.rglob('*.part') if path.is_file()]
    check('partial_files_absent', not partial_files,
          f'found={len(partial_files)}' + (f' examples={partial_files[:5]}' if partial_files else ''),
          failures, warnings)
    status = data / 'Minecraft_Mappings_Corpus' / '_STATUS.json'
    if status.is_file():
        text = status.read_text(encoding='utf-8-sig')
        stale = ('rm' + 'blocal_llm') in text
        check('mappings_status_no_rmblocal', not stale, str(status), failures, warnings)

    # Legacy goku-data coverage warning (non-fatal)
    goku = station / 'DataIndex' / 'goku-data.db'
    if goku.is_file():
        with closing(ro(goku)) as con:
            java_sources = int(con.execute(
                "SELECT COUNT(*) FROM sources WHERE lower(path) LIKE '%.java'"
            ).fetchone()[0])
            docs = int(con.execute('SELECT COUNT(*) FROM documents').fetchone()[0])
            metrics['goku_data'] = {'documents': docs, 'java_sources': java_sources, 'path': str(goku)}
            check(
                'goku_data_java_coverage',
                java_sources >= 100,
                f'documents={docs} java_sources={java_sources} (legacy benchmark index; canonical is knowledge.v5)',
                failures,
                warnings,
                warn=True,
            )

    report = {
        'ok': not failures,
        'failures': failures,
        'warnings': warnings,
        'metrics': metrics,
    }
    if args.json_out:
        out = Path(args.json_out)
        out.parent.mkdir(parents=True, exist_ok=True)
        part = out.with_suffix(out.suffix + '.part')
        part.write_text(json.dumps(report, indent=2), encoding='utf-8')
        part.replace(out)
        print(f'Report: {out}')

    print(json.dumps({'ok': report['ok'], 'failure_count': len(failures), 'warning_count': len(warnings)}, indent=2))
    return 0 if not failures else 2


if __name__ == '__main__':
    raise SystemExit(main())
