FROM docker.io/tpcorg/hammerdb:v5.0-base

# Install and configure PostgreSQL client libraries
RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y libpq-dev && \
        rm -rf /var/lib/apt/lists/*
