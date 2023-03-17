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

# Install and configuring MySQL client libraries
RUN apt install -y libmysqlclient21

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


