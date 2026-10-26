FROM ubuntu:24.04
LABEL maintainer="HammerDB Project"

ARG TARGETARCH
ARG HAMMERDB_VERSION=6.1.1
# SHA256 values are mandatory inputs. They are deliberately not given unsafe placeholders.
ARG HAMMERDB_AMD64_SHA256
ARG HAMMERDB_ARM64_SHA256

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates curl libaio1t64 libxft2 libcairo2 xauth python3 iputils-ping netcat-traditional && \
    case "$TARGETARCH" in \
      amd64) libaio_dir=/usr/lib/x86_64-linux-gnu ;; \
      arm64) libaio_dir=/usr/lib/aarch64-linux-gnu ;; \
      *) echo "Unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    test -e "$libaio_dir/libaio.so.1t64" && \
    ln -sf "$libaio_dir/libaio.so.1t64" "$libaio_dir/libaio.so.1" && \
    ldconfig && \
    test -e "$libaio_dir/libaio.so.1" && \
    rm -rf /var/lib/apt/lists/*
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) archive="HammerDB-${HAMMERDB_VERSION}-Prod-Lin-UBU24-x64.tar.gz"; checksum="$HAMMERDB_AMD64_SHA256" ;; \
      arm64) archive="HammerDB-${HAMMERDB_VERSION}-Prod-Lin-UBU24-ARM64.tar.gz"; checksum="$HAMMERDB_ARM64_SHA256" ;; \
      *) echo "Unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    test -n "$checksum" || { echo "Missing published SHA-256 for $archive" >&2; exit 1; }; \
    curl --fail --location --show-error --silent --retry 3 \
      "https://github.com/TPC-Council/HammerDB/releases/download/v${HAMMERDB_VERSION}/${archive}" -o "/tmp/${archive}"; \
    echo "$checksum  /tmp/${archive}" | sha256sum --check --strict -; \
    tar -xzf "/tmp/${archive}" -C /home; \
    test -x "/home/HammerDB-${HAMMERDB_VERSION}/hammerdbcli"; \
    ln -s "/home/HammerDB-${HAMMERDB_VERSION}" /home/hammerdb; \
    rm -f "/tmp/${archive}"

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /home/hammerdb
CMD ["tail", "-f", "/dev/null"]
