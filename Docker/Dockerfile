ARG VILLAGESQL_IMAGE=docker.io/tpcorg/hammerdb:v6.1-villagesql
ARG MYSQL_IMAGE=docker.io/tpcorg/hammerdb:v6.1-mysql
ARG MARIA_IMAGE=docker.io/tpcorg/hammerdb:v6.1-maria
ARG POSTGRES_IMAGE=docker.io/tpcorg/hammerdb:v6.1-postgres
ARG ORACLE_IMAGE=docker.io/tpcorg/hammerdb:v6.1-oracle
ARG MSSQLS_IMAGE=docker.io/tpcorg/hammerdb:v6.1-mssqls
FROM ${MYSQL_IMAGE} AS mysql
FROM ${MARIA_IMAGE} AS maria
FROM ${POSTGRES_IMAGE} AS postgres
FROM ${ORACLE_IMAGE} AS oracle
FROM ${MSSQLS_IMAGE} AS mssqls
FROM ${VILLAGESQL_IMAGE} AS final

# Buildx resolves every stage for the target platform. Copy the complete runtime
# trees so transitive dependencies and architecture-specific loader paths follow.
COPY --from=mysql /usr/lib/ /usr/lib/
COPY --from=maria /usr/lib/ /usr/lib/
COPY --from=postgres /usr/lib/ /usr/lib/
COPY --from=postgres /usr/bin/psql /usr/bin/psql
COPY --from=postgres /usr/lib/postgresql/17/ /usr/lib/postgresql/17/
COPY --from=oracle /opt/oracle/ /opt/oracle/
COPY --from=oracle /etc/ld.so.conf.d/oracle-instantclient.conf /etc/ld.so.conf.d/oracle-instantclient.conf
ENV ORACLE_HOME=/opt/oracle/instantclient
ENV ORACLE_LIBRARY=/opt/oracle/instantclient/libclntsh.so
ENV TNS_ADMIN=/opt/oracle/instantclient/network/admin
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient:${LD_LIBRARY_PATH}
RUN ldconfig && ldconfig -p | grep -E 'lib(mysqlclient|mariadb|pq|clntsh|odbc)'

WORKDIR /home/hammerdb
CMD ["tail", "-f", "/dev/null"]
