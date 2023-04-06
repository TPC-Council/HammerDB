# Oracle Dockerfile

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb/tags)
        docker pull tpcorg/hammerdb:oracle   
        docker tag tpcorg/hammerdb:oracle hammerdb:oracle
        
The [Dockerfile](https://github.com/TPC-Council/HammerDB/blob/master/Docker/oracle/Dockerfile) here builds the same HammerDB client Docker image that supports Oracle Database

##### To build an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:oracle .

##### To create a container named "hammerdb-oracle" from the image, "hammerdb:oracle"
        docker run -it --name hammerdb-oracle hammerdb:oracle bash

Networking is needed to communicate with a remote database when starting the container

##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb-oracle hammerdb:oracle bash
