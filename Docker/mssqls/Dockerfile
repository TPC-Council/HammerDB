ARG BASE_IMAGE=docker.io/tpcorg/hammerdb:v6.1.1-base
FROM ${BASE_IMAGE}
ARG UNIXODBC_VERSION=2.3.12
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl gnupg gcc make libc6-dev && \
    curl --fail --location --silent --show-error https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/ubuntu/24.04/prod noble main" > /etc/apt/sources.list.d/microsoft-prod.list && \
    curl --fail --location --silent --show-error "https://www.unixodbc.org/unixODBC-${UNIXODBC_VERSION}.tar.gz" -o /tmp/unixodbc.tar.gz && \
    tar -xzf /tmp/unixodbc.tar.gz -C /tmp && cd "/tmp/unixODBC-${UNIXODBC_VERSION}" && \
    configure_args='--prefix=/usr/local/unixODBC --enable-gui=no --enable-drivers=no --enable-iconv --with-iconv-char-enc=UTF8 --with-iconv-ucode-enc=UTF16LE --enable-threads=yes --enable-fastvalidate' && \
    printf '%s\n' "$configure_args" > /usr/local/unixODBC-configure.args && ./configure $configure_args && make -j"$(nproc)" && make install && \
    apt-get update && ACCEPT_EULA=Y DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends msodbcsql18 mssql-tools18 && \
    driver=$(find /opt/microsoft/msodbcsql18 -type f -name 'libmsodbcsql-*.so*' -print -quit); test -n "$driver"; \
    printf '[ODBC Driver 18 for SQL Server]\nDescription=Microsoft ODBC Driver 18 for SQL Server\nDriver=%s\nUsageCount=1\n' "$driver" > /usr/local/unixODBC/etc/odbcinst.ini && \
    echo /usr/local/unixODBC/lib > /etc/ld.so.conf.d/unixodbc.conf && ldconfig && \
    /usr/local/unixODBC/bin/odbcinst -j && /usr/local/unixODBC/bin/odbcinst -q -d | grep -Fx '[ODBC Driver 18 for SQL Server]' && \
    grep -F -- '--enable-fastvalidate' /usr/local/unixODBC-configure.args && \
    apt-get purge -y gcc make libc6-dev && apt-get autoremove -y && rm -rf /tmp/unixODBC* /var/lib/apt/lists/*
ENV PATH=/opt/mssql-tools18/bin:/usr/local/unixODBC/bin:$PATH
ENV ODBCINI=/usr/local/unixODBC/etc/odbc.ini
ENV ODBCSYSINI=/usr/local/unixODBC/etc
ENV LD_LIBRARY_PATH=/usr/local/unixODBC/lib
