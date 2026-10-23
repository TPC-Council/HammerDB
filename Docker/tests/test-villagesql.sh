#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
validate_common
run bash -euc '
  p=$(ldconfig -p | sed -n "/libmysqlclient\\.so\\.24/{s/.* => //;p;q}")
  test -n "$p"
  file "$p" | grep -F "$1"
  readelf -d "$p" | grep -E "SONAME.*libmysqlclient\\.so\\.24"
' -- "${MYSQL_FILE_MACHINE:?}"
librarycheck '(Success|loaded library).*VillageSQL'
