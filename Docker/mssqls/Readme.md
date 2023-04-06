# Microsoft SQL Server Dockerfile

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb/tags)
        docker pull tpcorg/hammerdb:mssqls
        docker tag tpcorg/hammerdb:mssqls hammerdb:mssqls

The [Dockerfile](https://github.com/TPC-Council/HammerDB/blob/master/Docker/mssqls/Dockerfile) here builds the same HammerDB client Docker image that supports  Microsoft SQL Server Database

##### To build an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:mssqls .

##### To start a container named "hammerdb-mssqls" from the image, "hammerdb:mssqls"
        docker run -it --name hammerdb-mssqls hammerdb:mssqls bash

Networking is needed to communicate with a remote database when starting the container

##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb-mssqls hammerdb:mssqls bash
