ARG BASE_IMAGE=docker.io/tpcorg/hammerdb:v6.1-base
FROM ${BASE_IMAGE}

ARG TARGETARCH
ARG ORACLE_AMD64_SHA256
ARG ORACLE_ARM64_SHA256
ARG ORACLE_VERSION=23.8.0.25.04

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl unzip file libaio1t64 && \
    set -eux; \
    case "$TARGETARCH" in \
      amd64) \
        archive=instantclient-basic-linux.x64-23.8.0.25.04.zip; \
        checksum="$ORACLE_AMD64_SHA256"; \
        machine='x86-64' \
        ;; \
      arm64) \
        archive=instantclient-basic-linux.arm64-23.8.0.25.04.zip; \
        checksum="$ORACLE_ARM64_SHA256"; \
        machine='ARM aarch64' \
        ;; \
      *) \
        echo "Unsupported TARGETARCH: $TARGETARCH" >&2; \
        exit 1 \
        ;; \
    esac; \
    test -n "$checksum" || { \
      echo 'Missing Oracle SHA-256 build argument' >&2; \
      exit 1; \
    }; \
    curl --fail --location --show-error --silent --retry 3 \
      "https://download.oracle.com/otn_software/linux/instantclient/2380000/$archive" \
      -o /tmp/oracle.zip; \
    echo "$checksum  /tmp/oracle.zip" | sha256sum --check --strict -; \
    unzip -q /tmp/oracle.zip -d /opt/oracle; \
    mv /opt/oracle/instantclient_* /opt/oracle/instantclient; \
    rm /tmp/oracle.zip; \
    resolved="$(readlink -f /opt/oracle/instantclient/libclntsh.so)"; \
    test -f "$resolved"; \
    file "$resolved" | grep -F "$machine"; \
    echo /opt/oracle/instantclient \
      > /etc/ld.so.conf.d/oracle-instantclient.conf; \
    ldconfig; \
    rm -rf /var/lib/apt/lists/*

ENV ORACLE_HOME=/opt/oracle/instantclient
ENV ORACLE_LIBRARY=/opt/oracle/instantclient/libclntsh.so
ENV TNS_ADMIN=/opt/oracle/instantclient/network/admin
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient
