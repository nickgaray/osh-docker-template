# OpenSensorHub Build and Deployment Docker Template

This Docker template will work with OpenSensorHub projects based on
[OSH Node Dev Template](https://github.com/opensensorhub/osh-node-dev-template.git)
for creating OpenSensorHub nodes.

The [OSH Node Dev Template](https://github.com/opensensorhub/osh-node-dev-template.git)
allows you to write new modules for [OpenSensorHub](www.opensensorhub.org) and build a
deployable distribution.

This docker template allows you to point to a specific branch and repository URL in order
to clone, build, and deploy your own nodes in a containerized environment.

## TL;DR

To quickly get OSH running with the default project and settings, clone
this repository and run:

    docke compose up

Then go to http://localhost:8080/sensorhub/admin and login in with
username "admin", password "admin".

## Cloning this Repository

    git clone https://github.com/nickgaray/osh-docker-template.git

## Building the Project

Building is as simple as running the following command replacing the placeholders in ```[]```
with appropriate values. See the placeholders description below the build command template.

    docker build -t [image] . -f Dockerfile --build-arg BRANCH=[branch] --build-arg REPO_URL=[url]

- **image**: The image name and tag to assign to the image being built, usually of the form ```repo_url/image:tag```
  where the ```repo_url/``` and ```:tag``` may be omitted (tag defaults to ```latest```).
- **branch**: The branch (or tag) to check out
- **url**: The URL of the repository to an OpenSensorHub project based
  on [OSH Node Dev Template](https://github.com/opensensorhub/osh-node-dev-template.git)

Note: If possible, it is best to specify a tag instead of a branch to
checkout. Docker caches results based on the commands executed, without
knowing what the command will do. The Dockerfile will run a git clone
against the given branch (or tag) during the build. If the build is done
a second time after the remote branch was updated, docker will not
realize this and will use the cached result instead of the latest
version of the branch. By using tags, every new version will have
a different git clone command, which will then be ran when the tag
changes. Alternatively, add `--no-cache` to the build command to force
a clean build.

To get started with the default osh-node-dev-template, you can run:

    docker build -t osh-node-dev-template . -f Dockerfile --build-arg BRANCH=master --build-arg REPO_URL=https://github.com/opensensorhub/osh-node-dev-template.git

## Understanding Docker Commands

It is highly recommended that the user be or become familiar with docker and the following commands

● To run Docker image detached exposing ports

     sudo docker run -d -p 8080:8080 -p 8443:8443 [image]

- **-p port_visible_to_world:port_exposed_docker_container**:
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

     sudo docker build -t <image> . -f <dockerfile>

● To export an image:

     sudo docker save --output [filename].tar <image> . -f <dockerfile>

● To import an image:

     sudo docker load --input [filename].tar

## Executing via Docker Compose

Docker compose is originally intended for creating multiple related containers, but even for a single container
a ```docker-compose.yml``` file is a convenient way to store configuration about creating and running docker containers.

The image to be used can be specified in different ways. Edit the ```docker-compose.yml``` file to your needs. If you
leave it unchanged, it will run a container based on the [template project
repository](https://github.com/opensensorhub/osh-node-dev-template).

To run the compose file:

    sudo docker compose up

Add `-d` to run in the background. On older systems, you might need `docker-compose` instead of `docker compose`.

### Let compose build an image
You can have docker compose automatically build a new image, using the Dockerfile in this repository and a reference to
an opensensorhub project repository:

    osh:
      build:
        context: .
        args:
          REPO_URL: [branch]
          BRANCH: [url]

See the docs about "Building the project" above for details on how to fill in `[branch]` and `[url]`. Note that `docker
compose up` will only build an image if none exists yet. Add `--build` to force building it again.

### Let compose use a locally built image
You can have docker compose use an image you previously built manually with e.g. `docker build` (see "Building the
project" above). To do so, remove the `build` section from the ```docker-compose.yml``` file and add:

    osh:
      image: [image]

Here, the `[image]` is whatever you passed to `docker build -t`

### Let compose pull an iamge from docker hub
You can also have docker compose use an image from a remote docker repository. To do so, remove the `build` section from the
```docker-compose.yml``` file and add:

    osh:
      image: [repo_url]/[path]/[project]:[tag]

- **repo_url**:
  The URL of the docker repo to pull the image from (defaults to docker hub)
- **path**:
  The path within the docker repo to the hosted project images
- **project**:
  The project or image name to pull
- **tag**:
  The tag of the image to pull, such as a version identifier (defaults to latest)

### Volume(s) for mount point directories
The default compose file declares a number of volume mounts, which are
directories in the current directory that will be mounted inside the
container, so you can e.g. make config chagnes or read logfiles outside
of the container.

The default ```docker-compose.yml``` file creates these directories:

● **config**: Location of config.json and logback.xml.

● **data**: Suggested location of any data, such as video files, or other sensor data. Can be referenced as "./data" in
node configuration paths.

● **db**: Suggested location to save H2 database files. Can be referenced as "./db" in node configuration.

● **userclasses**: Any additional ".class" files that the user may want to include in the classpath after install. These
will be first in the classpath, before any other libraries included in the image.

● **userlib**: Any additional libraries that the user may want to include in the classpath after install. These will be
second in the classpath, before other libraries that are included in the image.

● **logs**: Log files are created here, both global and per-module (named after the modules' uuids).


### Shutting Down via Docker Compose

     docker compose down

## Executing or Running a Docker Container Manually

● To run docker image detached with mounted file system & name, using present working directory for filesystem source

Important: Make sure to create osh user and group on the host system for the volume to be mounted and set owner and
group to osh:osh for the volume being mounted

     docker run -d \
     -it \
     --name [container-friendly-name] \
     --mount type=bind,source=[mount-path],target=/opt/[osh-node-path]/[target-dir] \
     [image]

- **container-friendly-name**: a friendly name for the docker container
- **mount-path**: the absolute path to the directory to be mounted as a volume
- **osh-node-path**: the absolute path to the directory where OpenSensorHub lives within the container
- **target-dir**: the name of the directory where the source should be mounted within the target
- **image**: The image to run, usually of the form ```repo_url/image:tag``` where the ```repo_url/``` may be omitted

It is recommended to start the image using the following command if you want to mount a host filesystem path directory
where data is typically stored in OSH, making this data accessible outside the docker instance and persisting across
executions of the instance. The config.json can be stored in this path to persist configuration. The launch script needs
to be updated, if doing this, so that config.json and db are correctly referenced.

     docker run -d -p 8443:8443 -p 8080:8080 \
     -it --name [container-friendly-name] \
     --mount type=bind,source=[mount-path]/data,target=/opt/[osh-node-path]/data \
     [image]

- **container-friendly-name**: a friendly name for the docker container
- **mount-path**: the absolute path to the directory to be mounted as a volume
- **osh-node-path**: the absolute path to the directory where OpenSensorHub lives within the container
- **target-dir**: in this example it has been set to data and will contain the config and recorded data
- **image**: The image to run, usually of the form ```repo_url/image:tag``` where the ```repo_url/``` may be omitted

If using mounted volumes and the configuration file (config.json) is hosted on the mounted volume, then change the
launch.[sh | bat] to point to the correct path for the mounted volumes. Similarly, if data is to be stored externally to
the container, update path to location for database files.

## Testing Deployment

On your favorite browser go to: ```[protocol]://[address]:[port]/sensorhub/admin```
When prompted, unless changed utilize the default node admin username and password.
If you have deployed to another server, make sure to change ```localhost``` to the correct IP or base url.

- **protocol**: Either ```http``` or ```https``` according to how the node is configured in the
  nodes ```config/config.json```
- **address**: The address of the system hosting the node
- **port**: The port number configured in the nodes ```config/config.json```
