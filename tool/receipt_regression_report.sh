#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
flutter test -r expanded test/receipt_regression_report_test.dart
