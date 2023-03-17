# Oracle Dockerfile
This Dockerfile builds HammerDB client environemnt that supports Oracle Database

##### To create an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:oracle .

##### To start a container named "hammerdb-oracle" with the image, "hammerdb:oracle" built from from Dockerfile
        docker run -it --name hammerdb-oracle hammerdb:oracle bash

Networking is needed to communicate with a remote database when starting the container

##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb-oracle hammerdb:oracle bash

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb/tags)
        docker pull tpcorg/hammerdb:oracle


