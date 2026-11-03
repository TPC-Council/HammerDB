#!/usr/bin/env bash
# Build the OceanBase-only Tcl binding; the client SDK remains external.
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: build.sh --tcl-config FILE --sdk DIRECTORY --output DIRECTORY

  --tcl-config  Trusted Tcl 9 tclConfig.sh, installed or in its build tree
  --sdk         OceanBase Connector/C SDK root (include/ and lib/ or lib64/)
  --output      Package directory, normally .../lib/obmysqltcl0.1

TCL_CONFIG and OBCLIENT_ROOT may supply the first two defaults.
CC, CFLAGS and LDFLAGS select the compiler and additional build flags.
Linux is currently supported. No client library is copied or downloaded.
USAGE
}

tcl_config=${TCL_CONFIG:-}
sdk=${OBCLIENT_ROOT:-}
output=
while (($#)); do
    case "$1" in
        --tcl-config|--sdk|--output)
            (($# >= 2)) || { echo "Missing value for $1" >&2; exit 2; }
            case "$1" in
                --tcl-config) tcl_config=$2;;
                --sdk) sdk=$2;;
                --output) output=$2;;
            esac
            shift 2;;
        -h|--help) usage; exit 0;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2;;
    esac
done
if [[ -z "$tcl_config" || -z "$sdk" || -z "$output" ]]; then
    usage >&2
    exit 2
fi
[[ $(uname -s) == Linux ]] || { echo 'This binding build currently supports Linux only.' >&2; exit 1; }
[[ -f "$tcl_config" ]] || { echo "Missing Tcl configuration: $tcl_config" >&2; exit 1; }
[[ -d "$sdk" ]] || { echo "Missing OceanBase SDK: $sdk" >&2; exit 1; }
src_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
config_dir=$(cd -- "$(dirname -- "$tcl_config")" && pwd)
tcl_config="$config_dir/$(basename -- "$tcl_config")"
sdk=$(cd -- "$sdk" && pwd)

# tclConfig.sh is an executable shell configuration, as used by Tcl's own
# extension builds. Only source a trusted configuration from the selected SDK.
source "$tcl_config"
case "${TCL_VERSION:-}" in
    9.*) ;;
    *) echo "Tcl 9 is required; selected config reports ${TCL_VERSION:-unknown}." >&2; exit 1;;
esac
include_flags=()
if [[ -n "${TCL_SRC_DIR:-}" && -f "$TCL_SRC_DIR/generic/tcl.h" ]]; then
    include_flags+=("-I$TCL_SRC_DIR/generic")
elif [[ -n "${TCL_INCLUDE_SPEC:-}" ]]; then
    # Preserve the shell quoting supplied by the trusted Tcl configuration.
    eval "include_flags=($TCL_INCLUDE_SPEC)"
else
    echo 'The Tcl configuration does not locate its headers.' >&2
    exit 1
fi
stub=
for candidate in "$config_dir/${TCL_STUB_LIB_FILE:-libtclstub.a}" \
    "${TCL_BUILD_STUB_LIB_PATH:-}" "${TCL_STUB_LIB_PATH:-}"; do
    if [[ -n "$candidate" && -f "$candidate" ]]; then stub=$candidate; break; fi
done
[[ -n "$stub" ]] || { echo 'Build or install the Tcl stub library before building obmysqltcl.' >&2; exit 1; }
[[ -f "$sdk/include/mysql.h" ]] || { echo "Missing OB SDK header: $sdk/include/mysql.h" >&2; exit 1; }
client_libdir=
for candidate in "$sdk/lib" "$sdk/lib64"; do
    if [[ -e "$candidate/libobclnt.so" ]]; then client_libdir=$candidate; break; fi
done
[[ -n "$client_libdir" ]] || { echo 'The SDK must contain lib/libobclnt.so or lib64/libobclnt.so.' >&2; exit 1; }

cc=${CC:-cc}
cflags=(); ldflags=()
read -r -a cflags <<< "${CFLAGS:-}"
read -r -a ldflags <<< "${LDFLAGS:-}"
mkdir -p -- "$output"
output=$(cd -- "$output" && pwd)
command=("$cc" -std=gnu99 -O2 -fPIC -fvisibility=hidden -DUSE_TCL_STUBS=1
    -DTCL_THREADS=1 "${include_flags[@]}" "-I$sdk/include" "${cflags[@]}"
    -shared "$src_dir/obmysqltcl.c" "$stub" "-L$client_libdir" -lobclnt
    -Wl,-z,defs "${ldflags[@]}" -o "$output/libobmysqltcl0.1.so")
printf 'Building:'
printf ' %q' "${command[@]}"
printf '\n'
"${command[@]}"
cp -- "$src_dir/pkgIndex.tcl" "$src_dir/COPYING" "$src_dir/NOTICE" "$output/"
{
    printf 'Package: obmysqltcl 0.1\nTcl: %s\nPlatform: %s %s\n' "$TCL_VERSION" "$(uname -s)" "$(uname -m)"
    printf 'Tcl config: %s\nOceanBase SDK: %s\n' "$tcl_config" "$sdk"
    printf 'Linkage: external shared libobclnt; no client library bundled; no embedded RPATH\n'
    printf 'Command:'; printf ' %q' "${command[@]}"; printf '\n'
    sha256sum "$src_dir/obmysqltcl.c" "$output/libobmysqltcl0.1.so" "$client_libdir/libobclnt.so"
} > "$output/BUILDINFO"
printf 'Built package: %s\n' "$output"
