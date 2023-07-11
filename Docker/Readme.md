# Release Notes for HammerDB Docker images

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb)
        docker pull tpcorg/hammerdb
        docker tag  tpcorg/hammerdb hammerdb
View all the Official TPC-Council HammerDB DockerHub images available [here](https://hub.docker.com/r/tpcorg/hammerdb/tags)

Alternatively, [Dockerfile](https://github.com/TPC-Council/HammerDB/blob/master/Docker/Dockerfile) can be used to build the same HammerDB client docker image that supports all the databases HammerDB is enabled for, i.e. Oracle, Microsoft SQL Server, MySQL, PostgreSQL and MariaDB, except for IBM Db2. We intend to add it in future releases. TPC-Council#404
##### To build an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb .
##### To create a container named "hammerdb" from the image, "hammerdb"
        docker run -it --name hammerdb hammerdb bash
Networking is needed to communicate with a remote database when starting the container
##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb hammerdb bash
##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb)
        docker pull tpcorg/hammerdb

## Database specific Docker container images
Given the wide usage of docker containers is in cloud and emphasizes on being light weight. Here are Database specific Dockerfiles which builds client libarries only for the desired database. Find them here:
1. [MySQL](https://github.com/TPC-Council/HammerDB/tree/master/Docker/mysql/Dockerfile), [Readme](https://github.com/TPC-Council/HammerDB/tree/master/Docker/mysql/Readme.md)
2. [MariaDB](https://github.com/TPC-Council/HammerDB/tree/master/Docker/maria/Dockerfile), [Readme](https://github.com/TPC-Council/HammerDB/tree/master/Docker/maria/Readme.md)
3. [PostgreSQL](https://github.com/TPC-Council/HammerDB/tree/master/Docker/postgres/Dockerfile), [Readme](https://github.com/TPC-Council/HammerDB/tree/master/Docker/postgres/Readme.md)
4. [Oracle Database](https://github.com/TPC-Council/HammerDB/tree/master/Docker/oracle/Dockerfile), [Readme](https://github.com/TPC-Council/HammerDB/tree/master/Docker/oracle/Readme.md)
5. [Microsoft SQL Server](https://github.com/TPC-Council/HammerDB/tree/master/Docker/mssqls/Dockerfile), [Readme](https://github.com/TPC-Council/HammerDB/tree/master/Docker/mssqls/Readme.md)

##### Alternatively, these pre built images can be downloaded from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb)
         docker pull tpcorg/hammerdb:mysql
         docker pull tpcorg/hammerdb:maria
         docker pull tpcorg/hammerdb:oracle
         docker pull tpcorg/hammerdb:postgres
         docker pull tpcorg/hammerdb:mssqls
         
## Example Scripts
CLI example scripts for each database are included under "scripts folder". Examples for TPROC-C and TPROC-H workloads are given both in python and tcl languages.
These scripts are recommended to run from the HammerDB home directory, "/home/hammerdb/" 
This example Python script for MariaDB Database and HammerDB TPROC-C workload automate the following:
1. builds schema 
2. run an TPROC-C workload test
3. delete schema and
4. write the results to "/home/hammerdb/TMP" directory.
        
##### This script can be executed as followed. 
        ./scripts/python/maria/tprocc/maria_tprocc_py.sh
###### Please note: Update the connection strings appropritaely in each of the following scripts before executing any experiments.
        ./scripts/python/maria/tprocc/maria_tprocc_buildschema.py
        ./scripts/python/maria/tprocc/maria_tprocc_run.py
        ./scripts/python/maria/tprocc/maria_tprocc_deleteschema.py
        ./scripts/python/maria/tprocc/maria_tprocc_result.py
Format is similar for every database while using both TCL or Python 

## Enable GUI Interface for HammerDB in Docker
To use HammerDB in GUI Mode from running within a Docker container, make sure X11 forwarding is configured and environment variable DISPLAY is set appropriately.
##### For example on Ubuntu,
        export DISPLAY=localhost:10.0
##### Additionally disable host control, by executing the following.
        xhost+
##### To start HammerDB container:
        docker run -it --rm -v ~/.Xauthority:/root/.Xauthority -e DISPLAY=$DISPLAY --network=host --name hammerdb hammerdb bash


Refer to HammerDB blog "[How to deploy HammerDB CLI fast with Docker](https://www.hammerdb.com/blog/uncategorized/how-to-deploy-hammerdb-cli-fast-with-docker/) for more information.
