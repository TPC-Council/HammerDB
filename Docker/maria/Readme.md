# MariaDB Dockerfile
This Dockerfile builds HammerDB client environemnt that supports MariaDB Database

##### To create an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:maria .

##### To start a container named "hammerdb-maria" with the image, "hammerdb:maria" built from from Dockerfile
        docker run -it --name hammerdb-maria hammerdb:maria bash

Networking is needed to communicate with a remote database when starting the container

##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb-maria hammerdb:maria bash

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb)
        docker pull tpcorg/hammerdb:maria
