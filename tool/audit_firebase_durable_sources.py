#!/usr/bin/env python3
"""Compare centralized Firebase/durable-storage files across Git worktrees.

The audit is read-only. It uses tracked-file names and SHA-256 hashes so an
agent can find useful candidates without loading entire repositories into its
working context. Detailed results are written as JSON; stdout stays concise.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, Sequence


ROOT_FILES = {
    ".firebaserc",
    "firebase.json",
    "firestore.indexes.json",
    "firestore.rules",
    "storage.rules",
}
CENTRAL_PREFIXES = (
    "firebase_emulator_tests/",
    "functions/",
    "lib/shared/backup/",
    "lib/shared/firebase/",
    "lib/shared/records/",
    "lib/shared/storage/",
)
FEATURE_MARKERS = (
    "cloud_backup",
    "cloud_restore",
    "durable_record",
    "firebase",
    "firestore",
    "record_lifecycle",
    "storage_guard",
    "sync_queue",
    "upload_queue",
)
IGNORED_PARTS = {
    ".dart_tool",
    ".git",
    ".gradle",
    "Pods",
    "build",
    "node_modules",
}


@dataclass(frozen=True)
class Candidate:
    source: str
    path: str
    status: str
    source_sha256: str
    target_sha256: str | None
    source_bytes: int
    target_bytes: int | None


def group_findings(findings: Iterable[Candidate]) -> list[dict[str, object]]:
    groups: dict[tuple[object, ...], dict[str, object]] = {}
    for finding in findings:
        key = (
            finding.path,
            finding.status,
            finding.source_sha256,
            finding.target_sha256,
            finding.source_bytes,
            finding.target_bytes,
        )
        group = groups.setdefault(
            key,
            {
                "path": finding.path,
                "status": finding.status,
                "source_sha256": finding.source_sha256,
                "target_sha256": finding.target_sha256,
                "source_bytes": finding.source_bytes,
                "target_bytes": finding.target_bytes,
                "sources": [],
            },
        )
        sources = group["sources"]
        assert isinstance(sources, list)
        sources.append(finding.source)
    result = list(groups.values())
    for group in result:
        sources = group["sources"]
        assert isinstance(sources, list)
        sources.sort()
    result.sort(
        key=lambda item: (
            item["status"] != "missing",
            item["path"],
            item["source_sha256"],
        )
    )
    return result


def is_candidate(relative_path: str) -> bool:
    normalized = relative_path.replace("\\", "/").lstrip("./")
    parts = set(Path(normalized).parts)
    if parts & IGNORED_PARTS:
        return False
    if normalized in ROOT_FILES or normalized.startswith(CENTRAL_PREFIXES):
        return True
    if not normalized.startswith(("lib/", "test/", "tool/")):
        return False
    lowered = normalized.lower()
    return any(marker in lowered for marker in FEATURE_MARKERS)


def tracked_files(repo: Path) -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(repo), "ls-files", "-z"],
        check=True,
        capture_output=True,
    )
    return [
        value.decode("utf-8")
        for value in result.stdout.split(b"\0")
        if value and is_candidate(value.decode("utf-8"))
    ]


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def compare_source(target: Path, source: Path) -> tuple[dict[str, int], list[Candidate]]:
    counts = {"identical": 0, "different": 0, "missing": 0}
    findings: list[Candidate] = []
    for relative_path in tracked_files(source):
        source_path = source / relative_path
        target_path = target / relative_path
        if not source_path.is_file():
            continue
        source_hash = sha256(source_path)
        target_hash = sha256(target_path) if target_path.is_file() else None
        if target_hash == source_hash:
            counts["identical"] += 1
            continue
        status = "different" if target_hash else "missing"
        counts[status] += 1
        findings.append(
            Candidate(
                source=str(source),
                path=relative_path,
                status=status,
                source_sha256=source_hash,
                target_sha256=target_hash,
                source_bytes=source_path.stat().st_size,
                target_bytes=target_path.stat().st_size if target_path.is_file() else None,
            )
        )
    return counts, findings


def validate_repo(path: Path, label: str) -> Path:
    resolved = path.expanduser().resolve()
    if not resolved.is_dir():
        raise ValueError(f"{label} does not exist: {resolved}")
    result = subprocess.run(
        ["git", "-C", str(resolved), "rev-parse", "--is-inside-work-tree"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0 or result.stdout.strip() != "true":
        raise ValueError(f"{label} is not a Git worktree: {resolved}")
    return resolved


def unique_sources(paths: Iterable[Path], target: Path) -> list[Path]:
    result: list[Path] = []
    seen = {target}
    for path in paths:
        resolved = validate_repo(path, "source")
        if resolved not in seen:
            result.append(resolved)
            seen.add(resolved)
    return result


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target", required=True, type=Path)
    parser.add_argument("--source", action="append", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--max-print", type=int, default=30)
    return parser.parse_args(argv)


def run(argv: Sequence[str]) -> int:
    args = parse_args(argv)
    target = validate_repo(args.target, "target")
    sources = unique_sources(args.source, target)
    if not sources:
        raise ValueError("at least one source distinct from the target is required")

    source_reports = []
    all_findings: list[Candidate] = []
    for source in sources:
        counts, findings = compare_source(target, source)
        source_reports.append({"source": str(source), "counts": counts})
        all_findings.extend(findings)

    all_findings.sort(key=lambda item: (item.status != "missing", item.path, item.source))
    candidate_groups = group_findings(all_findings)
    output = args.output.expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(
            {
                "generated_at_utc": datetime.now(timezone.utc).isoformat(),
                "target": str(target),
                "sources": source_reports,
                "findings": [asdict(item) for item in all_findings],
                "candidate_groups": candidate_groups,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )

    print(f"Target: {target}")
    for report in source_reports:
        counts = report["counts"]
        print(
            f"{Path(report['source']).name}: "
            f"{counts['missing']} missing, {counts['different']} different, "
            f"{counts['identical']} identical"
        )
    print(f"Detailed report: {output}")
    print(
        f"Distinct candidates: {len(candidate_groups)} "
        f"({len(all_findings)} source occurrences)"
    )
    for group in candidate_groups[: max(args.max_print, 0)]:
        source_names = ",".join(Path(value).name for value in group["sources"])
        print(f"{group['status']:9} {group['path']} [{source_names}]")
    remaining = len(candidate_groups) - max(args.max_print, 0)
    if remaining > 0:
        print(f"... {remaining} additional findings are in the JSON report")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(run(sys.argv[1:]))
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"audit failed: {error}", file=sys.stderr)
        raise SystemExit(2)
