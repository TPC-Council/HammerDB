FROM       ubuntu:20.04
LABEL maintainer="Pooja Jain"

# Update & upgrade apt and download basic utilities
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install -q && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget unzip gnupg apt-utils libaio1 iputils-ping vim netcat libxft-dev libcairo2-dev xauth python3 && \
    rm -rf  /var/lib/apt/lists/*

# Install configure HammerDB-v4.10
ARG HAMMERDB_VERSION=4.10
RUN wget https://github.com/TPC-Council/HammerDB/releases/download/v$HAMMERDB_VERSION/HammerDB-$HAMMERDB_VERSION-Linux.tar.gz -O - | \
    tar -xvzf - -C /home/ && \
    ln -s /home/HammerDB-$HAMMERDB_VERSION /home/hammerdb

WORKDIR /home/hammerdb

CMD tail -f /dev/null
