FROM docker.io/tpcorg/hammerdb:base

# Install and configuring MySQL client libraries
RUN apt-get update && \
        DEBIAN_FRONTEND=noninteractive apt-get install -y libmysqlclient21 && \
        rm -rf /var/lib/apt/lists/*
