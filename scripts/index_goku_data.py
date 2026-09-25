#!/usr/bin/env python3
"""Legacy/simple FTS builder for benchmark consumers.

Canonical agent retrieval uses index_knowledge.py + knowledge_mcp_v2.py.
This index should stay slim: migration-relevant text only, no mapping dumps
or resource-pack asset noise.
"""
from __future__ import annotations
import argparse, hashlib, json, re, sqlite3, sys, time
from pathlib import Path

TEXT_EXTS = {
    '.md', '.mdx', '.txt', '.csv', '.tsv', '.json', '.json5', '.java', '.gradle', '.kts',
    '.properties', '.toml', '.yml', '.yaml', '.xml', '.html', '.htm', '.cfg', '.conf',
    '.accesswidener', '.diff', '.patch', '.mcmeta'
}
SKIP_EXTS = {
    '.jar', '.zip', '.png', '.jpg', '.jpeg', '.gif', '.webp', '.ogg', '.wav', '.mp3',
    '.class', '.dll', '.exe', '.so', '.bin', '.db', '.sqlite', '.pyc',
    '.tsrg', '.tiny', '.mapping', '.map', '.srg'  # dedicated mapping corpus owns these
}
SKIP_PARTS = {'.git', '.gradle', 'build', 'out', 'node_modules', 'logs', 'cache', 'caches', '__pycache__'}
SKIP_TOP_PREFIXES = (
    '26.2 java resource pack/',
    'minecraft_java/assets/',
    'minecraft_java/libraries/',
    'minecraft_java/jars/',
    'minecraft_mappings_corpus/',
)
SKIP_NAME_SUFFIXES = ('_mappings.txt',)
VERSION_RE = re.compile(r'(?<!\d)(?:1\.\d{1,2}(?:\.\d{1,2})?|2[4-9]\.\d{1,2})(?!\d)')


def norm_rel(p: Path, root: Path) -> str:
    return p.relative_to(root).as_posix()


def is_dedicated_mapping(rel: str, p: Path) -> bool:
    low = rel.lower()
    name = p.name.lower()
    if p.suffix.lower() in {'.tsrg', '.tiny', '.mapping', '.mappings', '.srg', '.map'}:
        return True
    if name.endswith('_mappings.txt'):
        return True
    if low.startswith('minecraft_mcp_mappings/') and p.suffix.lower() == '.csv':
        return True
    return False


def allowed(p: Path, root: Path, max_bytes: int) -> bool:
    rel = norm_rel(p, root)
    low = rel.lower()
    parts = set(low.split('/'))
    if any(low.startswith(prefix) for prefix in SKIP_TOP_PREFIXES):
        return False
    if any(x in low for x in ('/assets/objects/', '/logs/', '/.git/', '/.gradle/', '/build/', '/__pycache__/')):
        return False
    if parts & SKIP_PARTS or p.suffix.lower() in SKIP_EXTS:
        return False
    if is_dedicated_mapping(rel, p):
        return False
    if any(p.name.lower().endswith(suf) for suf in SKIP_NAME_SUFFIXES):
        return False
    size = p.stat().st_size
    if size == 0 or size > max_bytes:
        return False
    if p.suffix.lower() in TEXT_EXTS:
        return True
    return (not p.suffix) and any(x in low for x in ('primer', 'mcp', 'neoforge', 'geckolib', 'gradle', '262r'))


def read_text(p: Path) -> str | None:
    raw = p.read_bytes()
    if b'\0' in raw[:8192]:
        return None
    for enc in ('utf-8-sig', 'utf-8', 'cp1252'):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            pass
    return None


def chunks(text: str, size: int, overlap: int):
    text = text.replace('\r\n', '\n').replace('\r', '\n')
    start = 0
    n = len(text)
    while start < n:
        end = min(n, start + size)
        if end < n:
            cut = max(text.rfind('\n', start + size // 2, end), text.rfind(' ', start + size // 2, end))
            if cut > start:
                end = cut
        piece = text[start:end].strip()
        if piece:
            yield start, end, piece
        if end >= n:
            break
        start = max(start + 1, end - overlap)


def family(rel: str) -> str:
    x = rel.lower()
    rules = [
        ('exact_version_sources/neoforge', 'exact_neoforge'),
        ('_upstream/neoforge', 'upstream_neoforge'),
        ('_upstream/geckolib', 'upstream_geckolib'),
        ('_upstream/gradle', 'upstream_gradle'),
        ('_upstream/mcpconfig', 'upstream_mcpconfig'),
        ('_upstream/mcreator', 'upstream_mcreator'),
        ('_upstream/forge', 'upstream_forge'),
        ('neoforge migration primer changes', 'neoforge_changes'),
        ('neoforge-migration-primers', 'neoforge_primers'),
        ('neoforge_primers', 'neoforge_primers'),
        ('geckolib', 'geckolib'),
        ('mcreator', 'mcreator'),
        ('gradle migration', 'gradle'),
        ('solved_problems', 'solved_problems'),
        ('262r', 'repair_262r'),
        ('generator', 'generator_template'),
        ('_harvested_index', 'harvested_index'),
        ('_migration_index', 'migration_index'),
    ]
    for needle, name in rules:
        if needle in x:
            return name
    return 'other'


def safe_fts_query(q: str) -> str:
    tokens = re.findall(r'[A-Za-z0-9_.$:/#-]+', q or '')
    if not tokens:
        return '""'
    return ' AND '.join(f'"{t.replace(chr(34), "")}"' for t in tokens[:12])


def schema(c: sqlite3.Connection) -> None:
    c.executescript('''PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL;
    CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY,value TEXT NOT NULL);
    CREATE TABLE IF NOT EXISTS documents(id INTEGER PRIMARY KEY,sha256 TEXT UNIQUE,bytes INTEGER,mtime_ns INTEGER,family TEXT,versions TEXT,canonical_path TEXT);
    CREATE TABLE IF NOT EXISTS sources(document_id INTEGER,path TEXT UNIQUE,FOREIGN KEY(document_id) REFERENCES documents(id));
    CREATE TABLE IF NOT EXISTS chunks(id INTEGER PRIMARY KEY,document_id INTEGER,ordinal INTEGER,start_char INTEGER,end_char INTEGER,sha256 TEXT UNIQUE,text TEXT,FOREIGN KEY(document_id) REFERENCES documents(id));
    CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(text, path UNINDEXED, family UNINDEXED, versions UNINDEXED, chunk_id UNINDEXED, tokenize='unicode61');
    CREATE INDEX IF NOT EXISTS idx_sources_doc ON sources(document_id); CREATE INDEX IF NOT EXISTS idx_chunks_doc ON chunks(document_id);''')


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--root', default=r'C:\GokuCodexAI\Data')
    ap.add_argument('--out', default=r'C:\GokuCodexAI\DataIndex\goku-data.db')
    ap.add_argument('--chunk-size', type=int, default=1800)
    ap.add_argument('--overlap', type=int, default=240)
    ap.add_argument('--max-file-mib', type=int, default=8)
    ap.add_argument('--rebuild', action='store_true')
    a = ap.parse_args()

    root = Path(a.root).resolve()
    out = Path(a.out).resolve()
    out.parent.mkdir(parents=True, exist_ok=True)
    if a.rebuild and out.exists():
        out.unlink()
        for side in (str(out) + '-wal', str(out) + '-shm'):
            Path(side).unlink(missing_ok=True)

    con = sqlite3.connect(out)
    schema(con)
    stats = {
        'seen': 0, 'indexed': 0, 'duplicate_sources': 0, 'skipped': 0, 'binary': 0,
        'chunks': 0, 'errors': 0, 'skipped_mappings': 0, 'skipped_noise': 0,
        'schema': 'goku-data-index-v2',
        'policy': 'exclude mapping dumps + resource-pack noise; prefer migration text',
    }
    begun = time.time()
    con.execute('DELETE FROM chunks_fts')
    con.execute('DELETE FROM chunks')
    con.execute('DELETE FROM sources')
    con.execute('DELETE FROM documents')

    for p in root.rglob('*'):
        if not p.is_file():
            continue
        stats['seen'] += 1
        try:
            rel = norm_rel(p, root)
            low = rel.lower()
            if any(low.startswith(prefix) for prefix in SKIP_TOP_PREFIXES) or is_dedicated_mapping(rel, p):
                stats['skipped'] += 1
                if is_dedicated_mapping(rel, p) or low.startswith('minecraft_mappings_corpus/'):
                    stats['skipped_mappings'] += 1
                else:
                    stats['skipped_noise'] += 1
                continue
            if not allowed(p, root, a.max_file_mib * 1024 * 1024):
                stats['skipped'] += 1
                continue
            text = read_text(p)
            if text is None:
                stats['binary'] += 1
                continue
            rawhash = hashlib.sha256(text.encode('utf-8')).hexdigest()
            fam = family(rel)
            versions = ','.join(sorted(set(VERSION_RE.findall(rel + ' ' + text[:4000]))))
            row = con.execute('SELECT id FROM documents WHERE sha256=?', (rawhash,)).fetchone()
            if row:
                doc = row[0]
                con.execute('INSERT OR IGNORE INTO sources(document_id,path) VALUES(?,?)', (doc, rel))
                stats['duplicate_sources'] += 1
                continue
            cur = con.execute(
                'INSERT INTO documents(sha256,bytes,mtime_ns,family,versions,canonical_path) VALUES(?,?,?,?,?,?)',
                (rawhash, p.stat().st_size, p.stat().st_mtime_ns, fam, versions, rel),
            )
            doc = cur.lastrowid
            con.execute('INSERT INTO sources(document_id,path) VALUES(?,?)', (doc, rel))
            stats['indexed'] += 1
            for i, (s, e, txt) in enumerate(chunks(text, a.chunk_size, a.overlap)):
                ch = hashlib.sha256((rawhash + ':' + str(i) + ':' + txt).encode()).hexdigest()
                cur = con.execute(
                    'INSERT INTO chunks(document_id,ordinal,start_char,end_char,sha256,text) VALUES(?,?,?,?,?,?)',
                    (doc, i, s, e, ch, txt),
                )
                con.execute(
                    'INSERT INTO chunks_fts(text,path,family,versions,chunk_id) VALUES(?,?,?,?,?)',
                    (txt, rel, fam, versions, cur.lastrowid),
                )
                stats['chunks'] += 1
            if stats['indexed'] % 100 == 0:
                con.commit()
                print(f"indexed={stats['indexed']} chunks={stats['chunks']} seen={stats['seen']}", flush=True)
        except Exception as e:
            stats['errors'] += 1
            print(f'WARN {p}: {e}', file=sys.stderr, flush=True)

    stats['seconds'] = round(time.time() - begun, 2)
    stats['database'] = str(out)
    stats['root'] = str(root)
    stats['safe_fts_query_helper'] = 'quote tokens; use validate/search helpers, not raw MATCH with bare dots'
    for k, v in {
        'schema': 'goku-data-index-v2',
        'root': str(root),
        'created': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
        'stats': json.dumps(stats),
        'canonical_retrieval': 'DataIndex/minecraft-knowledge-local + knowledge_mcp.py',
    }.items():
        con.execute('INSERT OR REPLACE INTO meta(key,value) VALUES(?,?)', (k, v))
    con.commit()
    con.execute('PRAGMA optimize')
    con.close()
    Path(str(out) + '.manifest.json').write_text(json.dumps(stats, indent=2), encoding='utf-8')
    print(json.dumps(stats, indent=2))


if __name__ == '__main__':
    main()
