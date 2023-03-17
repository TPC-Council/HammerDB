# Microsoft SQL Server Dockerfile
This Dockerfile builds HammerDB client environemnt that supports  Microsoft SQL Server Database

##### To create an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:mssqls .

##### To start a container named "hammerdb-mssqls" with the image, "hammerdb:mssqls" built from from Dockerfile
        docker run -it --name hammerdb-mssqls hammerdb:mssqls bash

Networking is needed to communicate with a remote database when starting the container

##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb-mssqls hammerdb:mssqls bash

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb/tags)
        docker pull tpcorg/hammerdb:mssqls
