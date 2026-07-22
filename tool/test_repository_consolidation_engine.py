import tempfile
import unittest
import json
from pathlib import Path

import repository_consolidation_engine as engine


class ConsolidationEngineTest(unittest.TestCase):
    def test_duplicate_unique_and_conflict_classification(self):
        with tempfile.TemporaryDirectory() as value:
            root = Path(value)
            target, source = root / "Maintainiac_5.7_Active", root / "source"
            (target / "lib").mkdir(parents=True)
            (target / ".git").mkdir()
            (source / "lib").mkdir(parents=True)
            (target / "lib/existing.dart").write_text("class Existing { int value() => 1; }\n")
            (source / "lib/renamed.dart").write_text("class Existing { int value() => 1; }\n")
            (source / "lib/unique.dart").write_text("class UniqueWorkSupply { int stock() => 2; }\n")
            (source / "lib/existing.dart").write_text("class Existing { int value() => 3; }\n")
            index = engine.Index(root / "index.sqlite3")
            index.index_root("target", target)
            report = engine.scan_source(index, target, source, True, root / "reports")
            decisions = [json.loads(line) for line in (root / "reports" / report["decision_log"]).read_text().splitlines()]
            actions = {item["path"]: item["action"] for item in decisions}
            self.assertEqual("skip_duplicate", actions["lib/renamed.dart"])
            self.assertEqual("add", actions["lib/unique.dart"])
            self.assertEqual("manual_merge", actions["lib/existing.dart"])
            self.assertTrue((target / "lib/unique.dart").exists())
            self.assertEqual("class Existing { int value() => 1; }\n", (target / "lib/existing.dart").read_text())

    def test_generated_and_secret_files_are_not_added(self):
        with tempfile.TemporaryDirectory() as value:
            root = Path(value)
            target, source = root / "Maintainiac_5.7_Active", root / "source"
            (target / ".git").mkdir(parents=True)
            (source / "build").mkdir(parents=True)
            (source / "android/app").mkdir(parents=True)
            (source / "build/output.bin").write_bytes(b"generated")
            (source / "android/app/google-services.json").write_text("{}")
            index = engine.Index(root / "index.sqlite3")
            index.index_root("target", target)
            report = engine.scan_source(index, target, source, True, root / "reports")
            decisions = [json.loads(line) for line in (root / "reports" / report["decision_log"]).read_text().splitlines()]
            actions = {item["path"]: item["action"] for item in decisions}
            self.assertEqual("skip_generated", actions["build/output.bin"])
            self.assertEqual("manual_secret", actions["android/app/google-services.json"])


if __name__ == "__main__":
    unittest.main()
