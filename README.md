# OpenSensorHub Build and Deployment Docker Template

This Docker template will work with OpenSensorHub projects based on
[OSH Node Dev Template](https://github.com/opensensorhub/osh-node-dev-template.git)
for creating OpenSensorHub nodes.

The [OSH Node Dev Template](https://github.com/opensensorhub/osh-node-dev-template.git)
allows you to write new modules for [OpenSensorHub](www.opensensorhub.org) and build a 
deployable distribution.

This docker template allows you to point to a specific branch and repository URL in order
to clone, build, and deploy your own nodes in a containerized environment.

## Cloning this Repository

    git clone https://github.com/nickgaray/osh-docker-template.git

## Building the Project

Building is as simple as running the following command replacing the placeholders in ```[]```
with appropriate values.  See the placeholders description below the build command template.

    docker build -t [tag] . -f dockerfile --build-arg branch=[branch] --build-arg repoUrl=[url]

- **tag**: The tag to assign to the image being built
- **branch**: The branch to check out
- **url**: The URL of the repository to an OpenSensorHub project based on [OSH Node Dev Template](https://github.com/opensensorhub/osh-node-dev-template.git)

## Understanding Docker Commands

It is highly recommended that the user be or become familiar with docker and the following commands

● To run Docker image detached exposing ports

     sudo docker run -d -p443:443 [tag]

- **-p port_visible_to_world:port_exposed_docker_container:**
        Expose additional ports by including more -p switches, one for each port to be mapped

● To list Docker images:

     sudo docker images

● To see which Docker image is/are running:

     sudo docker ps

● To see which Docker all Docker images running or stopped:

     sudo docker ps -a

● To kill a Docker image:

     sudo docker kill <container id>

● To gracefully start a stopped a Docker image:

     sudo docker start <container id | friendly name>

● To gracefully stop a Docker image:

     sudo docker stop <container id | friendly name>

● To build and tag an image:

     sudo docker build -t <repository>:<tag> . -f <dockerfile>

● To export an image:

     sudo docker save --output [filename].tar <docker_registry>/<repository>:<tag> . -f <dockerfile>

● To import an image:

     sudo docker load --input [filename].tar

## Executing or Running a Docker Container

● To run docker image detached with mounted file system & name, using present working directory for filesystem source

Important: Make sure to create osh user and group on the host system for the volume to be mounted and set owner and group to osh:osh for the volume being mounted

     docker run -d \
     -it \
     --name [container-friendly-name] \
     --mount type=bind,source=[mount-path],target=/opt/[osh-node-path]/[target-dir] \
     [tag]

- **container-friendly-name**: a friendly name for the docker container
- **mount-path**: the absolute path to the directory to be mounted as a volume
- **osh-node-path**: the absolute path to the directory where OpenSensorHub lives within the container
- **target-dir**: the name of the directory where the source should be mounted within the target
- **tag**: The tag to assign to the image being built, usually of the form ```repo_url/image:tag``` where the ```repo_url/``` may be omitted

It is recommended to start the image using the following command if you want to mount a host filesystem path directory where data is typically stored in OSH, making this data accessible outside the docker instance and persisting across executions of the instance. The config.json can be stored in this path to persist configuration. The launch script needs to be updated, if doing this, so that config.json and db are correctly referenced.

     docker run -d -p 443:443 -p80:80 \
     -it --name [container-friendly-name] \
     --mount type=bind,source=[mount-path]/data,target=/opt/[osh-node-path]/data \
     [tag]

- **container-friendly-name**: a friendly name for the docker container
- **mount-path**: the absolute path to the directory to be mounted as a volume
- **osh-node-path**: the absolute path to the directory where OpenSensorHub lives within the container
- **target-dir**: in this example it has been set to data and will contain the config and recorded data
- **tag**: The tag to assign to the image being built, usually of the form ```repo_url/image:tag``` where the ```repo_url/``` may be omitted

If using mounted volumes and the configuration file (config.json) is hosted on the mounted volume, then change the launch.[sh | bat] to point to the correct path for the mounted volumes. Similarly, if data is to be stored externally to the container, update path to location for database files

     java -Xmx2g -Dlogback.configurationFile=./logback.xml -cp "lib/*" \
     -Djava.system.class.loader="org.sensorhub.utils.NativeClassLoader" \
     -Djavax.net.ssl.keyStore="./osh-keystore.p12" -Djavax.net.ssl.keyStorePassword="atakatak" \
     -Djavax.net.ssl.trustStore="./osh-keystore.p12" -Djavax.net.ssl.trustStorePassword="atakatak" \
     org.sensorhub.impl.SensorHub ./data/config.json ./data/db


## Testing Deployment

On your favorite browser go to: ```https://localhost/sensorhub/admin```
When prompted, unless changed utilize the default node admin username and password.
If you have deployed to another server, make sure to change ```localhost``` to the correct IP or base url.