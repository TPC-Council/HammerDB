# MariaDB Dockerfile

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb/tags)
        docker pull tpcorg/hammerdb:maria
        docker tag tpcorg/hammerdb:maria hammerdb:maria 


The [Dockerfile](https://github.com/TPC-Council/HammerDB/blob/master/Docker/maria/Dockerfile) here builds the same HammerDB client Docker image that supports MariaDB Database
##### To build an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:maria .      

##### To create a container named "hammerdb-maria" from the image, "hammerdb:maria"
        docker run -it --name hammerdb-maria hammerdb:maria bash

Networking is needed to communicate with a remote database when starting the container
##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb-maria hammerdb:maria bash
