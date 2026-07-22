#!/usr/bin/env python3
"""Low-memory, preservation-first Maintainiac repository consolidator."""

from __future__ import annotations

import argparse
import difflib
import hashlib
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
import time
from collections import Counter
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Iterable, Iterator, Sequence

ENGINE_VERSION = "1"
CODE_EXTENSIONS = {".dart", ".kt", ".java", ".swift", ".m", ".mm", ".h", ".py", ".js", ".ts", ".tsx", ".jsx"}
TEXT_EXTENSIONS = CODE_EXTENSIONS | {".md", ".txt", ".yaml", ".yml", ".json", ".xml", ".gradle", ".properties", ".sh", ".html", ".css"}
GENERATED_PARTS = {".git", ".dart_tool", ".gradle", "build", "Pods", "node_modules", "DerivedData", "ephemeral", ".idea", ".vscode", "__pycache__"}
SAFE_PREFIXES = ("lib/", "test/", "tool/", "assets/", "docs/", "android/", "ios/", "macos/", "windows/", "linux/", "web/")
ROOT_SAFE_FILES = {"pubspec.yaml", "pubspec.lock", "analysis_options.yaml", "firebase.json", "firestore.rules", "storage.rules"}
SECRET_RE = re.compile(r"(^|/)(\.env($|\.)|google-services\.json$|GoogleService-Info\.plist$|.*credential.*|.*secret.*|.*token.*|.*\.pem$|.*\.p12$|.*\.jks$|.*\.keystore$)", re.I)
TOKEN_RE = re.compile(r"[A-Za-z_$][\w$]*|0x[0-9A-Fa-f]+|\d+(?:\.\d+)?|=>|==|!=|<=|>=|&&|\|\||\?\?|\?\.|\+\+|--|[{}()[\].,;:+\-*/%<>=!?&|^~]")
IMPORT_RE = re.compile(r"\b(?:import|export|part)\s+['\"]([^'\"]+)['\"]|\b(?:require|from)\s*\(?['\"]([^'\"]+)['\"]")
SYMBOL_RE = re.compile(r"^\s*(?:abstract\s+|sealed\s+|base\s+|final\s+)?(class|mixin|enum|extension|typedef|interface)\s+([A-Za-z_$][\w$]*)|^\s*(?:[\w<>,?\[\] ]+\s+)?([A-Za-z_$][\w$]*)\s*\([^;{}]*\)\s*(?:async\s*)?(?:=>|\{)", re.M)
PROTECTED_FEATURES = {
    "work_supplies_materials": ("work suppl", "material", "inventory", "trade pack"),
    "trip_tracking": ("trip tracking", "trip_tracking", "odometer", "gps"),
    "receipt_ocr_camera": ("receipt", "ocr", "camera", "stitch"),
    "pdf_invoices_estimates": ("pdf", "invoice", "estimate"),
    "expenses_payments": ("expense", "payment"),
    "jobs_maintenance_calendar": ("job", "maintenance", "calendar"),
    "firebase_storage": ("firebase", "firestore", "hive"),
    "mapbox_dashboard_profiles": ("mapbox", "dashboard", "profile"),
}


@dataclass(frozen=True)
class FileFacts:
    path: str
    size: int
    sha256: str
    normalized_sha256: str | None
    kind: str
    generated: bool
    secret: bool
    symbols: tuple[tuple[str, str], ...]
    imports: tuple[str, ...]
    blocks: tuple[str, ...]
    features: tuple[str, ...]


@dataclass
class Decision:
    path: str
    action: str
    reason: str
    target_matches: list[str]
    prior_matches: list[str]
    symbol_conflicts: list[str]
    block_overlap: float
    features: list[str]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_text(path: Path, limit: int = 8 * 1024 * 1024) -> str | None:
    if path.stat().st_size > limit:
        return None
    try:
        return path.read_text(encoding="utf-8")
    except (UnicodeDecodeError, OSError):
        return None


def strip_comments(value: str) -> str:
    value = re.sub(r"/\*.*?\*/", " ", value, flags=re.S)
    value = re.sub(r"(?m)//.*$|^\s*#.*$", " ", value)
    return value


def code_tokens(value: str) -> list[str]:
    return TOKEN_RE.findall(strip_comments(value))


def block_hashes(tokens: Sequence[str], width: int = 48, stride: int = 16) -> tuple[str, ...]:
    if len(tokens) < width:
        return ()
    result = {
        hashlib.sha256(" ".join(tokens[index:index + width]).encode()).hexdigest()[:24]
        for index in range(0, len(tokens) - width + 1, stride)
    }
    return tuple(sorted(result))


def classify_path(relative: str) -> tuple[bool, bool, str]:
    parts = Path(relative).parts
    generated = any(part in GENERATED_PARTS for part in parts)
    secret = bool(SECRET_RE.search(relative))
    suffix = Path(relative).suffix.lower()
    kind = "code" if suffix in CODE_EXTENSIONS else "text" if suffix in TEXT_EXTENSIONS else "binary"
    return generated, secret, kind


def extract_symbols(text: str) -> tuple[tuple[str, str], ...]:
    found: set[tuple[str, str]] = set()
    for match in SYMBOL_RE.finditer(text):
        if match.group(1):
            found.add((match.group(1), match.group(2)))
        elif match.group(3) not in {"if", "for", "while", "switch", "catch"}:
            found.add(("function", match.group(3)))
    return tuple(sorted(found))


def extract_imports(text: str) -> tuple[str, ...]:
    return tuple(sorted({left or right for left, right in IMPORT_RE.findall(text)}))


def detect_features(relative: str, text: str | None) -> tuple[str, ...]:
    haystack = f"{relative}\n{text or ''}".lower()
    return tuple(name for name, terms in PROTECTED_FEATURES.items() if any(term in haystack for term in terms))


def facts_for(root: Path, path: Path) -> FileFacts:
    relative = path.relative_to(root).as_posix()
    generated, secret, kind = classify_path(relative)
    if path.is_symlink():
        target = os.readlink(path)
        digest = hashlib.sha256(f"SYMLINK:{target}".encode()).hexdigest()
        return FileFacts(relative, len(target), digest, None, "symlink", generated, secret, (), (), (), detect_features(relative, target))
    digest = sha256_file(path)
    text = read_text(path) if kind in {"code", "text"} and not generated else None
    tokens = code_tokens(text) if text is not None and kind == "code" else []
    normalized = hashlib.sha256(" ".join(tokens).encode()).hexdigest() if tokens else None
    return FileFacts(
        relative, path.stat().st_size, digest, normalized, kind, generated, secret,
        extract_symbols(text or "") if kind == "code" else (),
        extract_imports(text or "") if kind == "code" else (),
        block_hashes(tokens) if kind == "code" else (),
        detect_features(relative, text),
    )


def walk_files(root: Path) -> Iterator[Path]:
    for current, directories, files in os.walk(root, followlinks=False):
        directories[:] = sorted(name for name in directories if name != ".git")
        if Path(current).name == ".dart_tool":
            directories[:] = [name for name in directories if name != "repository_consolidation"]
        base = Path(current)
        for name in sorted(files):
            yield base / name
        for name in sorted(directories):
            path = base / name
            if path.is_symlink():
                yield path


class Index:
    def __init__(self, database: Path):
        database.parent.mkdir(parents=True, exist_ok=True)
        self.db = sqlite3.connect(database)
        self.db.execute("PRAGMA journal_mode=WAL")
        self.db.execute("PRAGMA synchronous=NORMAL")
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS files(scope TEXT, path TEXT, size INTEGER, sha TEXT,
              normalized_sha TEXT, kind TEXT, generated INTEGER, secret INTEGER,
              features TEXT, PRIMARY KEY(scope,path));
            CREATE INDEX IF NOT EXISTS files_sha ON files(sha);
            CREATE INDEX IF NOT EXISTS files_normalized ON files(normalized_sha);
            CREATE TABLE IF NOT EXISTS symbols(scope TEXT,path TEXT,kind TEXT,name TEXT);
            CREATE INDEX IF NOT EXISTS symbols_name ON symbols(name,kind);
            CREATE TABLE IF NOT EXISTS blocks(scope TEXT,path TEXT,hash TEXT);
            CREATE INDEX IF NOT EXISTS blocks_hash ON blocks(hash);
            CREATE TABLE IF NOT EXISTS imports(scope TEXT,path TEXT,value TEXT);
            CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY,value TEXT);
        """)

    def reset_scope(self, scope: str) -> None:
        for table in ("files", "symbols", "blocks", "imports"):
            self.db.execute(f"DELETE FROM {table} WHERE scope=?", (scope,))
        self.db.commit()

    def add(self, scope: str, facts: FileFacts) -> None:
        self.db.execute(
            "INSERT OR REPLACE INTO files VALUES(?,?,?,?,?,?,?,?,?)",
            (scope, facts.path, facts.size, facts.sha256, facts.normalized_sha256,
             facts.kind, facts.generated, facts.secret, json.dumps(facts.features)),
        )
        self.db.executemany("INSERT INTO symbols VALUES(?,?,?,?)", ((scope, facts.path, kind, name) for kind, name in facts.symbols))
        self.db.executemany("INSERT INTO blocks VALUES(?,?,?)", ((scope, facts.path, value) for value in facts.blocks))
        self.db.executemany("INSERT INTO imports VALUES(?,?,?)", ((scope, facts.path, value) for value in facts.imports))

    def index_root(self, scope: str, root: Path) -> int:
        self.reset_scope(scope)
        count = 0
        for path in walk_files(root):
            self.add(scope, facts_for(root, path))
            count += 1
            if count % 500 == 0:
                self.db.commit()
        self.db.commit()
        return count

    def paths_for_hash(self, sha: str, scope: str | None = None) -> list[str]:
        if scope:
            rows = self.db.execute("SELECT path FROM files WHERE sha=? AND scope=? LIMIT 50", (sha, scope))
        else:
            rows = self.db.execute("SELECT scope||':'||path FROM files WHERE sha=? LIMIT 50", (sha,))
        return [row[0] for row in rows]

    def normalized_matches(self, normalized: str | None) -> list[str]:
        if not normalized:
            return []
        return [row[0] for row in self.db.execute("SELECT path FROM files WHERE scope='target' AND normalized_sha=? LIMIT 50", (normalized,))]

    def target_at(self, path: str) -> tuple[str, str | None] | None:
        return self.db.execute("SELECT sha,normalized_sha FROM files WHERE scope='target' AND path=?", (path,)).fetchone()

    def symbol_conflicts(self, symbols: Sequence[tuple[str, str]]) -> list[str]:
        result: set[str] = set()
        for kind, name in symbols:
            result.update(row[0] for row in self.db.execute(
                "SELECT DISTINCT path FROM symbols WHERE scope='target' AND kind=? AND name=? LIMIT 50", (kind, name)))
        return sorted(result)[:50]

    def block_overlap(self, blocks: Sequence[str]) -> float:
        if not blocks:
            return 0.0
        matched = 0
        for start in range(0, len(blocks), 400):
            batch = blocks[start:start + 400]
            marks = ",".join("?" for _ in batch)
            matched += self.db.execute(
                f"SELECT COUNT(DISTINCT hash) FROM blocks WHERE scope='target' AND hash IN ({marks})", batch).fetchone()[0]
        return matched / len(blocks)


def git_metadata(source: Path, target: Path) -> dict[str, object]:
    def run(root: Path, *args: str) -> str:
        result = subprocess.run(["git", "-C", str(root), *args], text=True, capture_output=True)
        return result.stdout.strip() if result.returncode == 0 else ""
    source_head = run(source, "rev-parse", "HEAD")
    target_head = run(target, "rev-parse", "HEAD")
    merge_base = run(target, "merge-base", target_head, source_head) if source_head and target_head else ""
    commits = run(target, "log", "--format=%H%x09%s", f"{target_head}..{source_head}").splitlines() if merge_base else []
    return {
        "is_git": bool(source_head), "branch": run(source, "branch", "--show-current"),
        "head": source_head, "target_head": target_head, "merge_base": merge_base,
        "unique_commits": commits, "origin": run(source, "remote", "get-url", "origin"),
    }


def high_confidence(facts: FileFacts, conflicts: Sequence[str], overlap: float) -> bool:
    safe_path = facts.path in ROOT_SAFE_FILES or facts.path.startswith(SAFE_PREFIXES)
    return safe_path and not facts.generated and not facts.secret and not conflicts and overlap < 0.35


def copy_new(source: Path, target: Path, relative: str) -> None:
    source_path, target_path = source / relative, target / relative
    if target_path.exists() or target_path.is_symlink():
        raise RuntimeError(f"refusing to overwrite {target_path}")
    target_path.parent.mkdir(parents=True, exist_ok=True)
    if source_path.is_symlink():
        os.symlink(os.readlink(source_path), target_path)
    else:
        shutil.copy2(source_path, target_path)


def source_slug(source: Path) -> str:
    return re.sub(r"[^A-Za-z0-9._-]+", "_", source.name)


def tree_guard(root: Path) -> str:
    digest = hashlib.sha256()
    for path in walk_files(root):
        relative = path.relative_to(root).as_posix()
        stat = path.lstat()
        link = os.readlink(path) if path.is_symlink() else ""
        digest.update(f"{relative}\0{stat.st_size}\0{stat.st_mtime_ns}\0{link}\n".encode())
    return digest.hexdigest()


def scan_source(index: Index, target: Path, source: Path, apply: bool, report_root: Path) -> dict[str, object]:
    slug, scope = source_slug(source), f"source:{source_slug(source)}"
    index.reset_scope(scope)
    report_root.mkdir(parents=True, exist_ok=True)
    decision_log = report_root / f"{slug}.decisions.jsonl"
    patch_path = report_root / f"{slug}.patch"
    counts: Counter[str] = Counter()
    features: Counter[str] = Counter()
    manual_preview: list[dict[str, object]] = []
    manual_total = 0
    source_guard_before = {"git": git_status(source), "tree": tree_guard(source)}
    with decision_log.open("w", encoding="utf-8") as decisions_out, patch_path.open("w", encoding="utf-8") as patch_out:
        for number, path in enumerate(walk_files(source), 1):
            facts = facts_for(source, path)
            target_matches = index.paths_for_hash(facts.sha256, "target")
            prior_matches = [item for item in index.paths_for_hash(facts.sha256) if not item.startswith("target:") and not item.startswith(f"{scope}:")]
            same_path = index.target_at(facts.path)
            normalized_matches = index.normalized_matches(facts.normalized_sha256)
            conflicts = index.symbol_conflicts(facts.symbols)
            overlap = index.block_overlap(facts.blocks)
            if target_matches:
                action, reason = "skip_duplicate", "exact content already exists in target"
            elif facts.generated:
                action, reason = "skip_generated", "generated or vendored path"
            elif facts.secret:
                action, reason = "manual_secret", "credential-like path"
            elif normalized_matches:
                target_matches = normalized_matches
                action, reason = "manual_text_difference", "code is duplicated but non-code text differs"
            elif same_path:
                action, reason = "manual_merge", "same target path has different content"
                source_text, target_text = read_text(path), read_text(target / facts.path)
                if source_text is not None and target_text is not None:
                    patch_out.writelines(difflib.unified_diff(
                        target_text.splitlines(True), source_text.splitlines(True),
                        fromfile=f"target/{facts.path}", tofile=f"source/{facts.path}"))
            elif high_confidence(facts, conflicts, overlap):
                action, reason = ("add" if apply else "plan_add"), "unique safe-path content"
                if apply:
                    copy_new(source, target, facts.path)
                    index.add("target", facts)
            else:
                action, reason = "manual_review", "unique content requires ownership or overlap review"
            index.add(scope, facts)
            for feature in facts.features:
                features[feature] += 1
            decision = Decision(facts.path, action, reason, target_matches, prior_matches, conflicts, round(overlap, 4), list(facts.features))
            decision_value = asdict(decision)
            decisions_out.write(json.dumps(decision_value, separators=(",", ":")) + "\n")
            counts[action] += 1
            if action.startswith("manual"):
                manual_total += 1
                if len(manual_preview) < 500:
                    manual_preview.append(decision_value)
            if number % 500 == 0:
                index.db.commit()
    index.db.commit()
    source_guard_after = {"git": git_status(source), "tree": tree_guard(source)}
    if source_guard_before != source_guard_after:
        raise RuntimeError(f"source changed during scan: {source}")
    report = {
        "engine_version": ENGINE_VERSION, "source": str(source), "target": str(target),
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "applied": apply,
        "git": git_metadata(source, target), "counts": dict(sorted(counts.items())),
        "features": dict(sorted(features.items())), "source_guard": source_guard_after,
        "decision_log": decision_log.name, "manual_total": manual_total,
        "manual_preview": manual_preview,
    }
    (report_root / f"{slug}.json").write_text(json.dumps(report, indent=2) + "\n")
    write_markdown(report_root / f"{slug}.md", report)
    return report


def git_status(root: Path) -> str:
    result = subprocess.run(["git", "-C", str(root), "status", "--porcelain=v1"], text=True, capture_output=True)
    return result.stdout if result.returncode == 0 else "NON_GIT_READ_ONLY"


def write_markdown(path: Path, report: dict[str, object]) -> None:
    counts = report["counts"]
    features = report["features"]
    lines = [f"# Consolidation report: {Path(str(report['source'])).name}", "", f"- Applied: `{report['applied']}`", "- Source remained unchanged: `true`", "", "## Counts", ""]
    lines.extend(f"- {name}: {value}" for name, value in counts.items())
    lines.extend(["", "## Protected-feature signals", ""])
    lines.extend(f"- {name}: {value}" for name, value in features.items())
    lines.extend(["", "## Manual review", ""])
    manual = report["manual_preview"]
    lines.extend(f"- `{item['path']}` — {item['reason']}" for item in manual[:500])
    if report["manual_total"] > len(manual):
        lines.append(f"- Remaining manual items: {report['manual_total'] - len(manual)} (see JSONL)")
    path.write_text("\n".join(lines) + "\n")


def candidate_sources(documents: Path, target: Path) -> list[Path]:
    result: list[Path] = []
    for path in sorted(item for item in documents.iterdir() if item.is_dir() and item != target):
        if path.name in {"Maintainiac_5.6_Active", "Codex"}:
            continue
        evidence = path.name.lower().startswith("maintainiac")
        pubspec = path / "pubspec.yaml"
        if pubspec.exists():
            evidence = evidence or "maintainiac" in (read_text(pubspec) or "").lower()
        remote = subprocess.run(["git", "-C", str(path), "remote", "get-url", "origin"], text=True, capture_output=True)
        evidence = evidence or (remote.returncode == 0 and "maintainiac" in remote.stdout.lower())
        if evidence:
            result.append(path)
    return result


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=("discover", "baseline", "scan", "run-all"))
    parser.add_argument("--target", type=Path, required=True)
    parser.add_argument("--documents", type=Path, default=Path.home() / "Documents")
    parser.add_argument("--source", action="append", type=Path, default=[])
    parser.add_argument("--apply-high-confidence", action="store_true")
    parser.add_argument("--database", type=Path)
    parser.add_argument("--reports", type=Path)
    return parser.parse_args(argv)


def main(argv: Sequence[str] = sys.argv[1:]) -> int:
    args = parse_args(argv)
    target = args.target.resolve()
    if target.name != "Maintainiac_5.7_Active" or not (target / ".git").exists():
        raise SystemExit("target must be an independent Maintainiac_5.7_Active Git repository")
    database = args.database or target / ".dart_tool/repository_consolidation/index.sqlite3"
    reports = args.reports or target / "docs/consolidation_reports"
    sources = [path.resolve() for path in args.source] or candidate_sources(args.documents.resolve(), target)
    if args.command == "discover":
        print(json.dumps([str(path) for path in sources], indent=2))
        return 0
    index = Index(database)
    if args.command in {"baseline", "run-all"} or not index.db.execute("SELECT 1 FROM files WHERE scope='target' LIMIT 1").fetchone():
        count = index.index_root("target", target)
        print(f"baseline_files={count}")
    if args.command == "baseline":
        return 0
    if args.command == "scan" and len(sources) != 1:
        raise SystemExit("scan requires exactly one --source")
    for source in sources:
        if source == target or target in source.parents or source in target.parents:
            raise SystemExit(f"unsafe source/target relationship: {source}")
        report = scan_source(index, target, source, args.apply_high_confidence, reports)
        print(json.dumps({"source": str(source), "counts": report["counts"], "features": report["features"]}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
