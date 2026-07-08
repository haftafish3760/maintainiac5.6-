#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

tmp_dir="${TMPDIR:-/tmp}/maintainiac_receipt_stitch_health"
mkdir -p "$tmp_dir"

run_pack() {
  local pack="$1"
  local out="$tmp_dir/${pack}.json"
  dart run tool/receipt_qa_runner.dart \
    --pack="$pack" \
    --fail-under=1.0 \
    --summary-json >"$out"
  node - "$out" "$pack" <<'NODE'
const fs = require('fs');
const file = process.argv[2];
const pack = process.argv[3];
const raw = fs.readFileSync(file, 'utf8');
const json = JSON.parse(raw.slice(raw.indexOf('{'), raw.lastIndexOf('}') + 1));
const failed = json.failedCheckCount || 0;
const blockers = json.blockers || [];
const score = Number(json.score || 0);
const dimensions = json.dimensionScores || {};
const failedFixtures = json.failedFixtures || [];
console.log(`${pack}: score=${score.toFixed(3)} checks=${json.passedCheckCount}/${json.checkCount} failed=${failed}`);
for (const [name, value] of Object.entries(dimensions)) {
  console.log(`  ${name}=${Number(value).toFixed(3)}`);
}
for (const fixture of failedFixtures) {
  console.log(`  FAIL fixture=${fixture.name} score=${Number(fixture.score || 0).toFixed(3)}`);
  for (const issue of fixture.issues || []) console.log(`    - ${issue}`);
}
for (const blocker of blockers) console.log(`  BLOCKER ${blocker}`);
if (failed > 0 || blockers.length > 0 || score < 1) process.exit(1);
NODE
}

echo "Receipt long-receipt stitch health"
run_pack long_receipt
run_pack damaged_ocr
echo "Receipt long-receipt stitch health: PASS"
