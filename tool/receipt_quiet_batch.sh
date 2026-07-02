#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  cat >&2 <<'USAGE'
Usage: tool/receipt_quiet_batch.sh <name> <command> [args...]

Starts a long receipt QA command detached from Codex terminal monitoring.
Results are written under /tmp/maintainiac_receipt_quiet_batch/<name>/:
  run.log      combined stdout/stderr
  status.txt   running, passed, or failed
  exit_code    command exit code after completion
  pid          background process id
USAGE
  exit 64
fi

name="$1"
shift

case "$name" in
  *[!A-Za-z0-9_.-]* | "")
    echo "Batch name must use only letters, numbers, dot, dash, or underscore." >&2
    exit 64
    ;;
esac

root="/tmp/maintainiac_receipt_quiet_batch/$name"
mkdir -p "$root"

log="$root/run.log"
status="$root/status.txt"
exit_code="$root/exit_code"
pid_file="$root/pid"
runner="$root/run_command.sh"
runner_started="$root/runner_started"
runner_finished="$root/runner_finished"
workdir="$(pwd -P)"

if [[ -f "$status" && "$(cat "$status")" == "running" ]]; then
  if [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
    echo "Batch '$name' is already running with pid $(cat "$pid_file")." >&2
    exit 70
  fi
fi

printf 'running\n' > "$status"
rm -f "$exit_code" "$pid_file" "$runner_started" "$runner_finished"
: > "$log"

args_literal="args=("
for arg in "$@"; do
  args_literal+=$'\n  '
  args_literal+="$(printf '%q' "$arg")"
done
args_literal+=$'\n)'
cat > "$runner" <<EOF
#!/usr/bin/env bash
set +e
code=255
cd $(printf '%q' "$workdir") || exit 125
$args_literal
printf '%s\n' "\$\$" > $(printf '%q' "$pid_file")
printf 'started\n' > $(printf '%q' "$runner_started")
finish() {
  printf '%s\n' "\$code" > $(printf '%q' "$exit_code")
  printf 'finished\n' > $(printf '%q' "$runner_finished")
  if [[ "\$code" -eq 0 ]]; then
    printf 'passed\n' > $(printf '%q' "$status")
  else
    printf 'failed\n' > $(printf '%q' "$status")
  fi
}
trap finish EXIT
{
  date '+START %Y-%m-%d %H:%M:%S %Z'
  "\${args[@]}"
  code=\$?
  date '+END %Y-%m-%d %H:%M:%S %Z'
  echo "EXIT_CODE \$code"
} > $(printf '%q' "$log") 2>&1
exit "\$code"
EOF

chmod +x "$runner"
screen_name="maintainiac_${name}_$(date +%s)_$$"
launch_label="com.maintainiac.receipt_quiet_batch.$name.$(date +%s).$$"
if command -v screen >/dev/null 2>&1; then
  screen -dmS "$screen_name" /bin/bash "$runner"
elif command -v launchctl >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
  if ! launchctl submit -l "$launch_label" -- /bin/bash "$runner" >/dev/null 2>&1; then
    nohup bash "$runner" >/dev/null 2>&1 </dev/null &
    printf '%s\n' "$!" > "$pid_file"
  fi
else
  nohup bash "$runner" >/dev/null 2>&1 </dev/null &
  printf '%s\n' "$!" > "$pid_file"
fi

for _ in 1 2 3 4 5 6 7 8 9 10; do
  [[ -s "$pid_file" ]] && break
  sleep 0.1
done
pid="$(cat "$pid_file" 2>/dev/null || echo unknown)"
echo "Started quiet batch '$name' with pid $pid. Check $status and $log after it completes."
