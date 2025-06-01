FROM docker.io/tpcorg/hammerdb:v5.0-base

# Install and configuring MySQL client libraries
RUN apt-get update && \
    wget -O /usr/lib/x86_64-linux-gnu/libmysqlclient.so.24  http://www.hammerdb.com/mysqllibs/libmysqlclient.so.24
