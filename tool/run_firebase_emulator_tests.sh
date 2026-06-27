#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HARNESS_DIR="$ROOT_DIR/firebase_emulator_tests"
PROJECT_ID="demo-maintainiac-rules-test"
JDK21_HOME="/opt/homebrew/opt/openjdk@21"

cd "$HARNESS_DIR"

if [[ "$PROJECT_ID" != demo-* ]]; then
  echo "Refusing to run Firebase tests against a non-demo project: $PROJECT_ID" >&2
  exit 1
fi

if [[ ! -d node_modules ]]; then
  echo "Installing emulator test dependencies in firebase_emulator_tests only..."
  npm install
fi

if [[ -d "$JDK21_HOME" ]]; then
  export JAVA_HOME="$JDK21_HOME"
  export PATH="$JDK21_HOME/bin:$PATH"
fi

npx firebase emulators:exec \
  --project "$PROJECT_ID" \
  --only firestore \
  "npm test"
