#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_DIR="$ROOT_DIR/android"

if [[ -z "${JAVA_HOME:-}" ]]; then
  HOMEBREW_JDK="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"
  if [[ -x "$HOMEBREW_JDK/bin/java" ]]; then
    export JAVA_HOME="$HOMEBREW_JDK"
    export PATH="$JAVA_HOME/bin:$PATH"
  fi
fi

if ! command -v java >/dev/null 2>&1; then
  echo "Java is required for the Android receipt camera compile gate." >&2
  echo "Install OpenJDK 17 or set JAVA_HOME before running this script." >&2
  exit 1
fi

cd "$ANDROID_DIR"
./gradlew :app:compileDebugKotlin
