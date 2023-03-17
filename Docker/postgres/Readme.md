# PostgreSQL Dockerfile
This Dockerfile builds HammerDB client environemnt that supports PostgreSQL Database

##### To create an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:postgres .

##### To start a container named "hammerdb-postgres" with the image, "hammerdb:postgres" built from from Dockerfile
        docker run -it --name hammerdb-postgres hammerdb:postgres bash

Networking is needed to communicate with a remote database when starting the container

##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb-postgres hammerdb:postgres bash

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb/tags)
        docker pull tpcorg/hammerdb:postgres
