FROM docker.io/tpcorg/hammerdb:v5.0-base

# Install and Configure MariaDB client libraries
RUN apt-get update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -y libmariadb3 && \
	rm -rf /var/lib/apt/lists/*
