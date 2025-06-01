FROM  docker.io/tpcorg/hammerdb:oracle as oracle

FROM  docker.io/tpcorg/hammerdb:mssqls

# Install and configure IBM Db2 client libraries, 
# You will need to pre-download IDB Db2 client libraries and place in the local folder
# RUN mkdir -p db2_cli_odbc_driver/odbc_cli
# ADD odbc_cli db2_cli_odbc_driver/odbc_cli/
# RUN apt update && \
#    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
#    apt -y install libxml2 && \
#    echo 'export DB2_CLI_DRIVER_INSTALL_PATH="/home/db2_cli_odbc_driver/odbc_cli/clidriver"' >> ~/.bashrc && \
#    echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/home/db2_cli_odbc_driver/odbc_cli/clidriver/lib"' >> ~/.bashrc && \
#    echo 'export LIBPATH="/home/db2_cli_odbc_driver/odbc_cli/clidriver/lib"' >> ~/.bashrc && \
#    echo 'export PATH="$PATH:/home/db2_cli_odbc_driver/odbc_cli/clidriver/bin"' >> ~/.bashrc && \
#    echo 'export PATH="$PATH:/home/db2_cli_odbc_driver/odbc_cli/clidriver/adm"' >>  ~/.bashrc

COPY --from=oracle /home/instantclient_21_18 /home/instantclient_21_18
ENV ORACLE_LIBRARY=/home/instantclient_21_18/libclntsh.so
RUN echo 'export LD_LIBRARY_PATH=/home/instantclient_21_18/:$LD_LIBRARY_PATH'  >> ~/.bashrc  && \
    ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y libmariadb3 libpq-dev && \
    wget -O /usr/lib/x86_64-linux-gnu/libmysqlclient.so.24  http://www.hammerdb.com/mysqllibs/libmysqlclient.so.24 && \
    rm -rf /var/lib/apt/lists/*

