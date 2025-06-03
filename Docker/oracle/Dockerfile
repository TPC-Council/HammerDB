FROM docker.io/tpcorg/hammerdb:v5.0-base

# Install and configure Oracle client libraries
RUN wget https://download.oracle.com/otn_software/linux/instantclient/2118000/instantclient-basic-linux.x64-21.18.0.0.0dbru.zip  && \
    unzip *.zip -d /home/ && \
    echo 'export LD_LIBRARY_PATH=/home/instantclient_21_18/:$LD_LIBRARY_PATH'  >> ~/.bashrc && \
    ln -s /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /usr/lib/x86_64-linux-gnu/libaio.so.1 && \
    rm *.zip

ENV ORACLE_LIBRARY=/home/instantclient_21_18/libclntsh.so
