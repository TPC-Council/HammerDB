#!/usr/bin/env bash
set -euo pipefail
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
status() { printf '%s: %s\n' "$1" "$2"; }
require_image() { [[ -n "${IMAGE:-}" ]] || fail 'set IMAGE to the image under test'; }
run() { docker run --rm --platform "${PLATFORM:?set PLATFORM}" "$IMAGE" "$@"; }
validate_common() {
  require_image
  run bash -euc 'grep -qx "VERSION_ID=\"24.04\"" /etc/os-release; test "$(uname -m)" = "'"${EXPECTED_MACHINE:?set EXPECTED_MACHINE}"'"; test -x /home/hammerdb/hammerdbcli; test "$(readlink -f /home/hammerdb)" = /home/HammerDB-6.1.1; printf "exit\n" | timeout 30 /home/hammerdb/hammerdbcli'
}
librarycheck() {
  local pattern=$1
  run bash -euc 'output=$(printf "librarycheck\nexit\n" | timeout 60 /home/hammerdb/hammerdbcli 2>&1); printf "%s\n" "$output"; grep -Ei -- "$1" <<<"$output"' -- "$pattern"
}
