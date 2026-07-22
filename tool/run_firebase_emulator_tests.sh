#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HARNESS_DIR="$ROOT_DIR/firebase_emulator_tests"
PROJECT_ID="demo-maintainiac-rules-test"
JDK_CANDIDATES=(
  "${JAVA_HOME:-}"
  "/opt/homebrew/opt/openjdk@21"
  "/usr/local/opt/openjdk@21"
  "/Applications/Android Studio.app/Contents/jbr/Contents/Home"
)

cd "$HARNESS_DIR"

if [[ "$PROJECT_ID" != demo-* ]]; then
  echo "Refusing to run Firebase tests against a non-demo project: $PROJECT_ID" >&2
  exit 1
fi

if [[ ! -d node_modules ]]; then
  echo "Installing emulator test dependencies in firebase_emulator_tests only..."
  npm install
fi

JAVA_READY=false
for candidate in "${JDK_CANDIDATES[@]}"; do
  if [[ -n "$candidate" && -x "$candidate/bin/java" ]]; then
    export JAVA_HOME="$candidate"
    export PATH="$candidate/bin:$PATH"
    JAVA_READY=true
    break
  fi
done
if [[ "$JAVA_READY" != true ]]; then
  echo "Java 21+ is required for the local Firebase emulators." >&2
  exit 1
fi

export GCLOUD_PROJECT="$PROJECT_ID"

npx firebase emulators:exec \
  --project "$PROJECT_ID" \
  --only auth,firestore,storage \
  "npm test"
