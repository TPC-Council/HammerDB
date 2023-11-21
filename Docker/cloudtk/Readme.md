#  Dockerfile for HammerDB client with Cloudtk

[CloudTk](https://wiki.tcl-lang.org/page/CloudTk)  is based on WebSockit2me, a TCP to WebSocket gateway that uses noVNC  to display Tk applications (X11 apps) in a modern Web Browser.

##### HammerDB prebuild Docker images can be downloaded directly from [Official TPC-Council HammerDB DockerHub](https://hub.docker.com/r/tpcorg/hammerdb/tags)
        docker pull tpcorg/hammerdb:cloudtk
        docker tag tpcorg/hammerdb:cloudtk hammerdb:cloudtk
The [Dockerfile](https://github.com/TPC-Council/HammerDB/blob/master/Docker/cloud/Dockerfile) here builds the HammerDB client Docker image with Cloudtk
##### To build an image: Go to the folder containing the Dockerfile
        docker build -t hammerdb:cloudtk .      
##### To create a container named "hammerdb-cloudtk" from the image, "hammerdb:cloudtk". ports 8080-8082 need to be exposed if not using host network. 
        docker run -p 8081:8081 -p 8082:8082 -p 8080:8080 --name hammerdb-cloudtk hammerdb:cloudtk 
##### HammerDB application can be viewed from any local browser on http port 8081, https port 8082. Jobs can also be viewed on port 8080 once webservice is started from the application.

Networking is needed to communicate with a remote database when starting the container
##### For example, adding host network to the container, in this case you don't need to expose the ports above explicitly
        docker run --network=host -it --name hammerdb-cloudtk hammerdb:cloudtk bash
