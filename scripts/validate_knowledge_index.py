#!/usr/bin/env python3
"""Validate the canonical GokuAI knowledge index + mappings corpus."""
from __future__ import annotations

import argparse
import json
import sqlite3
import sys
from pathlib import Path


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
    knowledge_canonical = Path(args.knowledge_db).resolve() if args.knowledge_db else station / 'DataIndex' / 'minecraft-knowledge' / 'knowledge.db'
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
    check(
        'active_pointer',
        (knowledge_canonical.parent / '_ACTIVE_DB.txt').is_file(),
        str(knowledge_canonical.parent / '_ACTIVE_DB.txt'),
        failures,
        warnings,
    )

    if knowledge_db.is_file():
        with ro(knowledge_db) as con:
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
        with ro(mapping_db) as con:
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

    # Stale path hygiene
    manifest = data / 'knowledge_manifest.json'
    if manifest.is_file():
        text = manifest.read_text(encoding='utf-8-sig')
        stale = 'rmblocal_llm' in text
        check('manifest_no_rmblocal', not stale, str(manifest), failures, warnings)
    status = data / 'Minecraft_Mappings_Corpus' / '_STATUS.json'
    if status.is_file():
        text = status.read_text(encoding='utf-8-sig')
        stale = 'rmblocal_llm' in text
        check('mappings_status_no_rmblocal', not stale, str(status), failures, warnings)

    # Legacy goku-data coverage warning (non-fatal)
    goku = station / 'DataIndex' / 'goku-data.db'
    if goku.is_file():
        with ro(goku) as con:
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
        out.write_text(json.dumps(report, indent=2), encoding='utf-8')
        print(f'Report: {out}')

    print(json.dumps({'ok': report['ok'], 'failure_count': len(failures), 'warning_count': len(warnings)}, indent=2))
    return 0 if not failures else 2


if __name__ == '__main__':
    raise SystemExit(main())
