# Release Notes for HammerDB 4.7

This Dockerfile builds a HammerDb-v4.7 client container that supports all the databases HammerDB is enabled for, i.e. Oracle, Microsoft SQL Server, MySQL, PostgreSQL and MariaDB, except for IBM Db2. We intend to add it in Future releases. TPC-Council#404
##### To create an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb .
##### To start a container named "hammerdb" with the image, "hammerdb"
        docker run -it --name hammerdb hammerdb bash
Networking is needed to communicate with a remote database when starting the container
##### For example, adding host network to the container.
        docker run --network=host -it --name hammerdb hammerdb bash
##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb)
        docker pull tpcorg/hammerdb
View all the Official TPC-Council HammerDB DockerHub images available [here](https://hub.docker.com/r/tpcorg/hammerdb/tags)

## Example Scripts
CLI example scripts for each database are included under "scripts folder". Examples for TPROC-C and TPROC-H workloads are given both in python and tcl languages.
These scripts are recommended to run from the HammerDB home directory, "~/HammerDB-4.7/"

This example Python script for MariaDB Database and HammerDB TPROC-C workload automate the following:
1. builds schema 
2. run an TPROC-C workload test
3. delete schema and
4. write the results to "~/HammerDB-4.7/TMP" directory.
        
##### This script can be executed as followed. 
        ./scripts/python/maria/tprocc/maria_tprocc_py.sh
###### Please note: Update the connection strings appropritaely in each of the following scripts before executing any experiments.
        ./scripts/python/maria/tprocc/maria_tprocc_buildschema.py
        ./scripts/python/maria/tprocc/maria_tprocc_run.py
        ./scripts/python/maria/tprocc/maria_tprocc_deleteschema.py
        ./scripts/python/maria/tprocc/maria_tprocc_result.py

Format is similar for every database in while using both TCL or Python 

## Enable GUI Interface for HammerDB in Docker
To use HammerDB in GUI Mode from running within a Docker container, make sure X11 forwarding is configured and environemnt variable DISPLAY is set appropriately.
##### For example on Ubuntu,
        export DISPLAY=localhost:10.0
##### Additionally disable host control, by executing the following.
        xhost+
##### To start HammerDB container:
        docker run -it --rm -v ~/.Xauthority:/root/.Xauthority -e DISPLAY=$DISPLAY --network=host --name hammerdb hammerdb bash

Refer to HammerDB blog "[How to deploy HammerDB CLI fast with Docker](https://www.hammerdb.com/blog/uncategorized/how-to-deploy-hammerdb-cli-fast-with-docker/) for more information.
