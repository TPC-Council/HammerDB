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
    apt -y wget unzip gnupg apt-utils libaio1  iputils-ping vim netcat libxft-dev libcairo2-dev xauth

# Install and configure Microsoft SQLServer client libraries
RUN apt -y install -q \
    apt -y curl gcc make && \
    apt update && apt install -y lsb-release && \
    curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 && echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc && \
    wget http://www.unixodbc.org/unixODBC-2.3.11.tar.gz && tar -xvzf unixODBC-2.3.11.tar.gz && cd unixODBC-2.3.11 && \
    ./configure --prefix=/usr/local/unixODBC --enable-gui=no --enable-drivers=no --enable-iconv --with-iconv-char-enc=UTF8 \
    --with-iconv-ucode-enc=UTF16LE --enable-threads=yes --enable-fastvalidate && make && make install && cd .. && \
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin:/usr/local/unixODBC/bin" \n\
    export ODBCINI="/usr/local/unixODBC/etc/odbc.ini" \n\
    export ODBCSYSINI="/usr/local/unixODBC/etc" \n\
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/unixODBC/lib"'  >> ~/.bashrc && \
    echo "[ODBC Driver 18 for SQL Server] \n\
    Description=Microsoft ODBC Driver 18 for SQL Server \n\
    Driver=/opt/microsoft/msodbcsql18/lib64/libmsodbcsql-18.1.so.2.1 \n\
    UsageCount=1 " >> /usr/local/unixODBC/etc/odbcinst.ini && \
    odbcinst -j && \
    rm -rf *.tar.gz *.zip unixODBC-2.3.11

#Install Python3.8
RUN apt install -y python3

# Install configure HammerDB-v4.7
RUN wget https://github.com/TPC-Council/HammerDB/releases/download/v4.7/HammerDB-4.7-Linux.tar.gz && \
    tar -xvzf HammerDB-4.7-Linux.tar.gz && ls && \
    echo 'export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu/:$LD_LIBRARY_PATH'  >> ~/.bashrc && \
    rm -rf *.tar.gz *.zip
WORKDIR /home/hammerdb/HammerDB-4.7

#CMD "bash"
CMD tail -f /dev/null

#To create an image: Go to the folder containing the Dockerfile 
#       docker build -t hammerdb .
#To start a container with that image
#       docker run -it --name hammerdb hammerdb bash
#To use HammerDB in GUI Mode, make sure X11 forwarding is configured, Environemnt variable DISPLAY is set appropriately,  for example on Ubuntu,
#       export DISPLAY=localhost:10.0
# and also  disable host control, by executing the following.
#       xhost+
#you can then start container:
#       docker run -it --rm -v /root/.Xauthority:/root/.Xauthority -e DISPLAY=$DISPLAY --network=host --name hammerdb hammerdb bash


