#!/usr/bin/env python3

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import audit_firebase_durable_sources as audit


class FirebaseDurableSourceAuditTest(unittest.TestCase):
    def test_candidate_filter_is_narrow(self) -> None:
        accepted = (
            "firestore.rules",
            "functions/index.js",
            "lib/shared/records/maintainiac_durable_record_store.dart",
            "lib/screens/expenses/data/expense_cloud_backup_queue.dart",
        )
        rejected = (
            "lib/screens/expenses/expense_home.dart",
            "build/firebase.json",
            "firebase_emulator_tests/node_modules/pkg/index.js",
            "assets/receipt.png",
        )
        self.assertTrue(all(audit.is_candidate(path) for path in accepted))
        self.assertTrue(all(not audit.is_candidate(path) for path in rejected))

    def test_run_reports_only_missing_and_different_files(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            target = self._repo(root / "target")
            source = self._repo(root / "source")
            self._track(target, "firestore.rules", "same\n")
            self._track(source, "firestore.rules", "same\n")
            self._track(target, "storage.rules", "target\n")
            self._track(source, "storage.rules", "source\n")
            self._track(source, "lib/shared/firebase/new_sink.dart", "new\n")
            self._track(source, "lib/unrelated.dart", "ignored\n")

            output = root / "report.json"
            result = audit.run(
                [
                    "--target",
                    str(target),
                    "--source",
                    str(source),
                    "--output",
                    str(output),
                    "--max-print",
                    "0",
                ]
            )

            self.assertEqual(result, 0)
            report = json.loads(output.read_text(encoding="utf-8"))
            counts = report["sources"][0]["counts"]
            self.assertEqual(counts, {"different": 1, "identical": 1, "missing": 1})
            self.assertEqual(
                {(item["status"], item["path"]) for item in report["findings"]},
                {
                    ("different", "storage.rules"),
                    ("missing", "lib/shared/firebase/new_sink.dart"),
                },
            )
            self.assertEqual(len(report["candidate_groups"]), 2)

    def test_group_findings_collapses_matching_worktree_variants(self) -> None:
        shared = {
            "path": "firestore.rules",
            "status": "different",
            "source_sha256": "old",
            "target_sha256": "new",
            "source_bytes": 10,
            "target_bytes": 20,
        }
        groups = audit.group_findings(
            [
                audit.Candidate(source="/old/a", **shared),
                audit.Candidate(source="/old/b", **shared),
            ]
        )
        self.assertEqual(len(groups), 1)
        self.assertEqual(groups[0]["sources"], ["/old/a", "/old/b"])

    @staticmethod
    def _repo(path: Path) -> Path:
        path.mkdir()
        subprocess.run(["git", "init", "-q", str(path)], check=True)
        return path

    @staticmethod
    def _track(repo: Path, relative_path: str, contents: str) -> None:
        path = repo / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(contents, encoding="utf-8")
        subprocess.run(["git", "-C", str(repo), "add", relative_path], check=True)


if __name__ == "__main__":
    unittest.main()
