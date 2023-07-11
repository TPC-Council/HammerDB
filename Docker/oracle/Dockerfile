FROM docker.io/tpcorg/hammerdb:base

# Install and configure Oracle client libraries
RUN wget https://download.oracle.com/otn_software/linux/instantclient/215000/instantclient-basic-linux.x64-21.5.0.0.0dbru.zip && \
    unzip *.zip -d /home/ && \
    echo 'export LD_LIBRARY_PATH=/home/instantclient_21_5/:$LD_LIBRARY_PATH'  >> ~/.bashrc && \
    rm *.zip

ENV ORACLE_LIBRARY=/home/instantclient_21_5/libclntsh.so
