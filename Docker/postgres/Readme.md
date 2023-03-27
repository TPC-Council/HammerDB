# PostgreSQL Dockerfile

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb/tags)
        docker pull tpcorg/hammerdb:postgres
        docker tag tpcorg/hammerdb:postgres hammerdb:postgres

The [Dockerfile](https://github.com/TPC-Council/HammerDB/blob/master/Docker/postgres/Dockerfile) here builds the same HammerDB client Docker image that supports PostgreSQL Database

##### To build an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:postgres .

##### To create a container named "hammerdb-postgres" from the image, "hammerdb:postgres" 
        docker run -it --name hammerdb-postgres hammerdb:postgres bash

Networking is needed to communicate with a remote database when starting the container

##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb-postgres hammerdb:postgres bash
