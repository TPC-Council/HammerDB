# VillageSQL uses the MySQL-compatible client shipped for HammerDB 6.1.
ARG MYSQL_IMAGE=docker.io/tpcorg/hammerdb:v6.1-mysql
FROM ${MYSQL_IMAGE}
LABEL org.opencontainers.image.description="HammerDB 6.1 VillageSQL client image"
RUN ldconfig -p | grep -F libmysqlclient.so.24
