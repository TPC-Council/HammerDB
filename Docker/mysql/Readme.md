
# MySQL Dockerfile

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb/tags)
        docker pull tpcorg/hammerdb:mysql
        docker tag tpcorg/hammerdb:mysql hammerdb:mysql

The [Dockerfile](https://github.com/TPC-Council/HammerDB/blob/master/Docker/mysql/Dockerfile) here builds the same HammerDB client Docker image that supports MySQL Database

##### To build an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:mysql .

##### To create a container named "hammerdb-mysql" from the image, "hammerdb:mysql" 
        docker run -it --name hammerdb-mysql hammerdb:mysql bash

Networking is needed to communicate with a remote database when starting the container

##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb-mysql hammerdb:mysql bash
