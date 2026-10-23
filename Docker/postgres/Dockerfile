ARG BASE_IMAGE=docker.io/tpcorg/hammerdb:v6.1-base
FROM ${BASE_IMAGE}
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
    install -d -m 0755 /etc/apt/keyrings && curl --fail --location --silent --show-error https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/postgresql.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/postgresql.gpg] https://apt.postgresql.org/pub/repos/apt noble-pgdg main 17" > /etc/apt/sources.list.d/pgdg.list && \
    printf 'Package: libpq5\nPin: version 17.*\nPin-Priority: 1001\n' > /etc/apt/preferences.d/libpq17 && \
    apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends postgresql-client-17 libpq5='17.*' && \
    psql --version | grep -E ' 17\.' && /usr/lib/postgresql/17/bin/pg_config --version | grep -E ' 17\.' && \
    ldconfig && ldconfig -p | grep -F libpq.so.5 && rm -rf /var/lib/apt/lists/*
