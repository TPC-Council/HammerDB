FROM       ubuntu:24.04
LABEL maintainer="Pooja Jain"

# Update & upgrade apt and download basic utilities
RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get -y install -q && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y wget unzip gnupg apt-utils iputils-ping vim netcat-traditional libxft-dev libcairo2-dev xauth python3 

RUN wget http://archive.ubuntu.com/ubuntu/pool/main/liba/libaio/libaio1t64_0.3.113-6build1_amd64.deb && \
    apt install `pwd`/libaio1t64_0.3.113-6build1_amd64.deb && \
    rm -rf  /var/lib/apt/lists/* `pwd`/libaio1t64_0.3.113-6build1_amd64.deb 

# Install configure HammerDB-v5.0
ARG HAMMERDB_VERSION=5.0
RUN wget https://github.com/TPC-Council/HammerDB/releases/download/v$HAMMERDB_VERSION/HammerDB-$HAMMERDB_VERSION-Prod-Lin-UBU24.tar.gz -O - | \
    tar -xvzf - -C /home/ && \
    ln -s /home/HammerDB-$HAMMERDB_VERSION /home/hammerdb

WORKDIR /home/hammerdb

CMD tail -f /dev/null
