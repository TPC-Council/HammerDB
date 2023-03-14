********************************
Release Notes for HammerDB 4.7
********************************

This Dockerfile builds a HammerDb-v4.7 client container that supports all the databases HammerDB is enabled for, i.e. Oracle, Microsoft SQL Server, MySQL, PostgreSQL and MariaDB, except for IBM Db2. We intend to add it in Future releases. Follow the updates here.
        Add Db2 libraries to Docker build
        Track this issue with TPC-Council#404
        Awaiting addition of sqlecrea and sqledrpd APIs to db2tcl to create and delete Db2 database from within HammerDB.
        Track this issue with TPC-Council#431

To create an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb .

To start a container named "hammerdb" with the image, "hammerdb"
        docker run -it --name hammerdb hammerdb bash

Networking is needed to communicate with a remote database when starting the container
For example, adding host network to the container.
        docker run --network=host -it --name hammerdb hammerdb bash

HammerDB prebuild Docker images can be downloaded directly from Official TPC-Council HammerDB DockerHub, https://hub.docker.com/r/tpcorg/hammerdb
        docker pull tpcorg/hammerdb

To view all the images available, go to https://hub.docker.com/r/tpcorg/hammerdb/tags

CLI sample scripts for each database are included under "scripts folder". Samples for TPROC-C and TPROC-H workloads are given both in python and tcl language.

These scripts are recommended to run from the HammerDB  home directory, "~/HammerDB-4.7/"

Example Python scripts for MariaDB Database and HammerDb TPROC-C workload can be run as followed. This script builds schema, run an TPROC-C workload, delete schema and write results to a "~/HammerDB-4.7/TMP" directory.
./scripts/python/maria/tprocc/maria_tprocc_py.sh

Please note: Update the connection strings in eachs script

./scripts/python/maria/tprocc/maria_tprocc_buildschema.py
./scripts/python/maria/tprocc/maria_tprocc_run.py
./scripts/python/maria/tprocc/maria_tprocc_deleteschema.py
./scripts/python/maria/tprocc/maria_tprocc_result.py

Format is similar for every database.

To use HammerDB in GUI Mode, make sure X11 forwarding is configured, environemnt variable DISPLAY is set appropriately, for example on Ubuntu,
       export DISPLAY=localhost:10.0
Additionally disable host control, by executing the following.
       xhost+
To start container:
       docker run -it --rm -v ~/.Xauthority:/root/.Xauthority -e DISPLAY=$DISPLAY --network=host --name hammerdb hammerdb bash


Refer to the HammerDB blog for more information.
https://www.hammerdb.com/blog/uncategorized/how-to-deploy-hammerdb-cli-fast-with-docker/ 
**********************************************************************************************************
