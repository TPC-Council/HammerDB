FROM  docker.io/tpcorg/hammerdb:latest

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y tigervnc-standalone-server  matchbox-window-manager libxss1
    
RUN  wget https://github.com/sm-shaw/CloudTk/archive/refs/tags/1.4.0-51.tar.gz && tar -xvzf 1.4.0-51.tar.gz && rm -rf 1.4.0-51.tar.gz && \
     mkdir CloudTk-1.4.0-51/certs && \
     openssl req -new -x509 -days 365 -nodes -out CloudTk-1.4.0-51/certs/server.pem -keyout CloudTk-1.4.0-51/certs/skey.pem -subj "/C=/ST=/L=/O=[Internet Widgits Pty Ltd]/CN="
     
ENTRYPOINT  cd /home/hammerdb/CloudTk-1.4.0-51 &&  ./tclkit-Linux64 CloudTK.kit  -library custom -port 8081 -https_port 8082 
