FROM       ubuntu:20.04
LABEL maintainer="Pooja Jain"

# For apt install without question
ARG DEBIAN_FRONTEND=noninteractive

# Enable apt sources
RUN sed -i~orig -e 's/# deb-src/deb-src/' /etc/apt/sources.list

# Set working directory
WORKDIR /home/hammerdb

# Update & upgrade apt and download basic utilities
RUN apt update && \
    apt -y upgrade && \
    apt -y install -q \
    apt -y wget unzip gnupg apt-utils libaio1  iputils-ping vim netcat

# Install and configure Microsoft SQLServer client libraries
RUN apt -y install -q \ 
    apt -y curl gcc make && \
    curl https://packages.microsoft.com/keys/microsoft.asc |  apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get -yq install mssql-tools  && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile && \
    wget http://www.unixodbc.org/unixODBC-2.3.9.tar.gz && tar -xzvf unixODBC-2.3.9.tar.gz && cd unixODBC-2.3.9 && \ 
    ./configure --prefix=/usr/local/unixODBC --enable-gui=no --enable-drivers=no --enable-iconv --with-iconv-char-enc=UTF8 \
    --with-iconv-ucode-enc=UTF16LE --enable-threads=yes --enable-fastvalidate && make && make install && cd .. && \ 
    echo 'export PATH="$PATH:/opt/mssql-tools/bin:/usr/local/unixODBC/bin"' >> ~/.bashrc && \
    echo 'export ODBCINI="/usr/local/unixODBC/etc/odbc.ini"'  >> ~/.bashrc && \
    echo 'export ODBCSYSINI="/usr/local/unixODBC/etc"'  >> ~/.bashrc && \
    echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/unixODBC/lib"'  >> ~/.bashrc && \
    rm -rf *.tar.gz *.zip unixODBC-2.3.9 
   
# Install and configure Oracle client libraries
RUN wget https://download.oracle.com/otn_software/linux/instantclient/215000/instantclient-basic-linux.x64-21.5.0.0.0dbru.zip && \
    unzip *.zip && \
    echo 'export LD_LIBRARY_PATH=/home/hammerdb/instantclient_21_5/:$LD_LIBRARY_PATH'  >> ~/.bashrc && \
    echo 'export ORACLE_LIBRARY=/home/hammerdb/instantclient_21_5/libclntsh.so'  >> ~/.bashrc
  
# Install and configure IBM Db2 client libraries, 
# You will need to pre-download IDB Db2 client libraries and place in the local folder
 RUN mkdir -p db2_cli_odbc_driver/odbc_cli
 ADD odbc_cli db2_cli_odbc_driver/odbc_cli/
 RUN apt update && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt -y install libxml2 && \
    echo 'export DB2_CLI_DRIVER_INSTALL_PATH="/home/hammerdb/db2_cli_odbc_driver/odbc_cli/clidriver"' >> ~/.bashrc && \
    echo 'export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/home/hammerdb/db2_cli_odbc_driver/odbc_cli/clidriver/lib"' >> ~/.bashrc && \
    echo 'export LIBPATH="/home/hammerdb/db2_cli_odbc_driver/odbc_cli/clidriver/lib"' >> ~/.bashrc && \
    echo 'export PATH="$PATH:/home/hammerdb/db2_cli_odbc_driver/odbc_cli/clidriver/bin"' >> ~/.bashrc && \
    echo 'export PATH="$PATH:/home/hammerdb/db2_cli_odbc_driver/odbc_cli/clidriver/adm"' >>  ~/.bashrc

# Install and Configure MariaDB client libraries
RUN apt install -y libmariadb3

# Install and configure PostgreSQL client libraries
RUN apt install -y libpq-dev 

# Install and configuring MySQL client libraries
RUN apt install -y libmysqlclient21

# Install configure HammerDB-v4.5
RUN wget https://github.com/TPC-Council/HammerDB/releases/download/v4.5/HammerDB-4.5-Linux.tar.gz && \
    tar -xvzf HammerDB-4.5-Linux.tar.gz && ls && \
    echo 'export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/:$LD_LIBRARY_PATH'  >> ~/.bashrc && \
    rm -rf *.tar.gz *.zip unixODBC-2.3.9    
WORKDIR /home/hammerdb/HammerDB-4.5

# Adding some sample scripts to be used with HammerDB command line interface
ADD sample_scripts /home/hammerdb/HammerDB-4.5/sample_scripts

CMD "bash"

#To create an image: Go to the folder containing the Dockerfile 
#     docker build -t hammerdb-v4.5 .
#To start a container with that image
#     docker run -it -name hammerdb hammerdb-v4.5 bash
