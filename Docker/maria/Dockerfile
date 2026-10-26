ARG BASE_IMAGE=docker.io/tpcorg/hammerdb:v6.1.1-base
FROM ${BASE_IMAGE}
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libmariadb3 && \
    dpkg-query -W -f='${Package} ${Version}\n' libmariadb3 && ldconfig && \
    ldconfig -p | grep -F libmariadb.so.3 && rm -rf /var/lib/apt/lists/*
