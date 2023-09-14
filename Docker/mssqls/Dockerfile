FROM docker.io/tpcorg/hammerdb:base

# Install and configure Microsoft SQLServer client libraries
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl gcc make lsb-release && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y DEBIAN_FRONTEND=noninteractive apt-get install -y msodbcsql18=18.2.2.1-1 && \
    ACCEPT_EULA=Y DEBIAN_FRONTEND=noninteractive apt-get install -y mssql-tools18 && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc && \
    wget http://www.unixodbc.org/unixODBC-2.3.11.tar.gz && tar -xvzf unixODBC-2.3.11.tar.gz && cd unixODBC-2.3.11 && \
    ./configure --prefix=/usr/local/unixODBC --enable-gui=no --enable-drivers=no --enable-iconv --with-iconv-char-enc=UTF8 \
    --with-iconv-ucode-enc=UTF16LE --enable-threads=yes --enable-fastvalidate && make && make install && cd .. && \
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin:/usr/local/unixODBC/bin" \n\
    export ODBCINI="/usr/local/unixODBC/etc/odbc.ini" \n\
    export ODBCSYSINI="/usr/local/unixODBC/etc" \n\
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/unixODBC/lib"'  >> ~/.bashrc && \
    echo "[ODBC Driver 18 for SQL Server] \n\
    Description=Microsoft ODBC Driver 18 for SQL Server \n\
    Driver=/opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.2.so.2.1 \n\
    UsageCount=1 " >> /usr/local/unixODBC/etc/odbcinst.ini && \
    odbcinst -j && \
    apt-get purge -y gcc make && \
    rm -rf *.tar.gz *.zip unixODBC-2.3.11 /var/lib/apt/lists/*
