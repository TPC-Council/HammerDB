#!/usr/bin/env bash
set -euo pipefail
: "${PLATFORM:?set PLATFORM (linux/amd64 or linux/arm64)}"
: "${LOCAL_REGISTRY:=localhost:5000}"
: "${TAG_PREFIX:=$LOCAL_REGISTRY/hammerdb-v6.1.1-test}"
for v in HAMMERDB_AMD64_SHA256 HAMMERDB_ARM64_SHA256 MYSQL_AMD64_SHA256 MYSQL_ARM64_SHA256 ORACLE_AMD64_SHA256 ORACLE_ARM64_SHA256; do
  [[ ${!v:-} =~ ^[0-9a-fA-F]{64}$ ]] || { echo "FAIL: $v must be a 64-character SHA-256" >&2; exit 1; }
done
build=(docker buildx build --platform "$PLATFORM" --push)
docker_args=(--build-arg HAMMERDB_AMD64_SHA256 --build-arg HAMMERDB_ARM64_SHA256)
"${build[@]}" "${docker_args[@]}" -t "$TAG_PREFIX-base" Docker/base
for name in mysql maria postgres oracle mssqls villagesql; do
  extra=(--build-arg "BASE_IMAGE=$TAG_PREFIX-base")
  [[ $name == villagesql ]] && extra=(--build-arg "MYSQL_IMAGE=$TAG_PREFIX-mysql")
  [[ $name == mysql ]] && extra+=(--build-arg MYSQL_AMD64_SHA256 --build-arg MYSQL_ARM64_SHA256)
  [[ $name == oracle ]] && extra+=(--build-arg ORACLE_AMD64_SHA256 --build-arg ORACLE_ARM64_SHA256)
  "${build[@]}" "${extra[@]}" -t "$TAG_PREFIX-$name" "Docker/$name"
done
combined_args=()
for name in mysql maria postgres oracle mssqls villagesql; do
  combined_args+=(--build-arg "${name^^}_IMAGE=$TAG_PREFIX-$name")
done
"${build[@]}" "${combined_args[@]}" -t "$TAG_PREFIX" Docker
for name in base mysql maria postgres oracle mssqls villagesql; do docker pull --platform "$PLATFORM" "$TAG_PREFIX-$name"; done
docker pull --platform "$PLATFORM" "$TAG_PREFIX"
