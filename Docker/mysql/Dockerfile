ARG BASE_IMAGE=docker.io/tpcorg/hammerdb:v6.1-base
FROM ${BASE_IMAGE}
ARG TARGETARCH
ARG MYSQL_AMD64_SHA256
ARG MYSQL_ARM64_SHA256
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl file binutils && \
    set -eux; case "$TARGETARCH" in \
      amd64) url=https://www.hammerdb.com/mysqllibs/libmysqlclient.so.24; libdir=/usr/lib/x86_64-linux-gnu; checksum="$MYSQL_AMD64_SHA256"; machine='Advanced Micro Devices X86-64' ;; \
      arm64) url=https://www.hammerdb.com/mysqllibsarm64/libmysqlclient.so.24; libdir=/usr/lib/aarch64-linux-gnu; checksum="$MYSQL_ARM64_SHA256"; machine='AArch64' ;; \
      *) echo "Unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; esac; \
    test -n "$checksum" || { echo 'Missing MySQL SHA-256 build argument' >&2; exit 1; }; \
    curl --fail --location --show-error --silent --retry 3 "$url" -o /tmp/libmysqlclient.so.24; \
    test -s /tmp/libmysqlclient.so.24; ! head -c 256 /tmp/libmysqlclient.so.24 | grep -Eiq '<html|<!doctype'; \
    echo "$checksum  /tmp/libmysqlclient.so.24" | sha256sum --check --strict -; \
    readelf -h /tmp/libmysqlclient.so.24 | grep -F "Machine:" | grep -F "$machine"; \
    readelf -d /tmp/libmysqlclient.so.24 | grep -E 'SONAME.*\[libmysqlclient\.so\.24\]'; \
    install -m 0755 /tmp/libmysqlclient.so.24 "$libdir/libmysqlclient.so.24"; rm /tmp/libmysqlclient.so.24; ldconfig; \
    ldconfig -p | grep -F libmysqlclient.so.24; rm -rf /var/lib/apt/lists/*
