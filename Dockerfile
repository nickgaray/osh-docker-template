################################################################################
##
##  OpenSensorHub Node
##  Nicolas Garay
##
##  Builds a container image of the OpenSensorHub Node. This Dockerfile assumes
##  that it can pull source code from OpenSensorHub public GitHub repos other
##  repos as well. The target source code will be built and deployed by within
##  the image by the dockerfile
##
################################################################################

## Based on Dockerfile template provided in RepositoryTemplate repository.

## Environment variables outside image context. These will be available until the first FROM statement.
ARG BASE_REGISTRY=docker.io
ARG BASE_BUILD_IMAGE=library/ubuntu
ARG BASE_BUILD_TAG=22.04
ARG BASE_DEPLOY_IMAGE=library/ubuntu
ARG BASE_DEPLOY_TAG=22.04

## Base build image
FROM ${BASE_REGISTRY}/${BASE_BUILD_IMAGE}:${BASE_BUILD_TAG} AS build_container

## Working directory. Will be created if it doesn't exist by default.
# WORKDIR <directory>
WORKDIR buildDir

## root user
USER root

## Install dependencies
# COPY <source file(s) required for resolving dependencies> <container destination>
# RUN <command(s) to install build container dependencies, shared by all environments>
RUN apt-get update \
    && apt-get install -y git \
    && apt install -y openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

## Copy source
# Retrieve the sources from a repo using the REPO_URL and BRANCH passed as a command line argument
ARG REPO_URL
ARG BRANCH
RUN git clone -b ${BRANCH} --recursive ${REPO_URL} .

# Run build excluding unit tests and OSGi bundle generation, the latter is not needed for this deployment setup
RUN chmod +x ./gradlew 
RUN ./gradlew build -x test -x osgi

## root command(s)
# RUN <command(s)>
RUN apt remove -y git


## Base deploy image
FROM ${BASE_REGISTRY}/${BASE_DEPLOY_IMAGE}:${BASE_DEPLOY_TAG} AS deploy_container

## Environment variables in image build context. These will be available until image is built or next FROM statement.
# ARG <VARIABLE><=default value>

## Environment variable(s) in image context. These will be available in image after it has been built.
# ENV <VARIABLE>=<value>
ENV OSH_HOME=/opt/osh

## Working directory. Will be created if it doesn't exist by default.
# WORKDIR <directory>
WORKDIR ${OSH_HOME}

## root user
# USER root
USER 0:0

## Install dependencies
# COPY <source file(s) required for resolving dependencies> <container destination>
# RUN <command(s) to install build container dependencies, shared by all environments>
RUN apt-get update \
    && apt-get install -y unzip \
    && apt-get install -y openjdk-17-jre \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Override java security settings as provided by MCSCOP ISSE for OSH FIPS compliance
RUN sed -i 's/security.useSystemPropertiesFile=true/security.useSystemPropertiesFile=false/g' \
    /etc/java-17-openjdk/security/java.security

# Create the "real" structure of the install.
RUN \
  mkdir -p ${OSH_HOME} && \
  mkdir -p ${OSH_HOME}/defaultconfig && \
#  mkdir -p ${OSH_HOME}/config && \
  mkdir -p ${OSH_HOME}/data && \
  mkdir -p ${OSH_HOME}/db && \
  mkdir -p ${OSH_HOME}/lib && \
  mkdir -p ${OSH_HOME}/userlib && \
  mkdir -p ${OSH_HOME}/userclasses

# Remove unneeded groups and accounts. OpenSCAP CCE-85987-6.
RUN \
  userdel bin && \
  userdel daemon && \
  userdel lp && \
  userdel sync && \
  userdel mail && \
  groupdel dialout 

# We'll run as a non-privileged user with UID and GID 4242
ARG USERNAME=osh
ARG USER_UID=14242
ARG USER_GID=14243
RUN \
  groupadd --gid ${USER_GID} ${USERNAME} && \
  useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME}

## Copy source
# COPY ./<source file or directory requiring root ownership> <container destination>
# COPY --chown=<default user>:0 ./<source file or directory requiring default user ownership> <container destination>
# COPY --chown=<default user>:0 --from=build_container ./<source file or directory from build_container requiring default user ownership> <container destination>
COPY --from=build_container ./buildDir/build/distributions/osh-node*.zip /tmp/.
RUN unzip /tmp/osh-node-*.zip "*" -d /opt
RUN mv /opt/osh-node-*/* ${OSH_HOME}
RUN rmdir /opt/osh-node-*
COPY config/config.json config/logback.xml ${OSH_HOME}/defaultconfig/

# Set permissions appropriately. All directories are given 770 mode. All files
# are given 660. And "*.sh" in the OSH_HOME dir are given 770.
RUN \
  chown -R ${USER_UID}:${USER_GID} ${OSH_HOME} && \
  find ${OSH_HOME} -type d -print0 | xargs -0 chmod 770 && \
  find ${OSH_HOME} -type f -print0 | xargs -0 chmod 660 && \
  chmod 770 ${OSH_HOME}/*.sh

## Cleanup Unzip
RUN apt remove -y unzip

# CVE-2019-20916, PRISMA-2022-0168
RUN rm -rf /usr/lib/python3.6

## Default user
#USER <default user>:0
USER ${USER_UID}:${USER_GID}

## Expose port(s)
# EXPOSE <#>
EXPOSE 8080 8443

## Default startup executable. Will treat elements of 'docker run' command, or elements of "CMD" input, as parameters.
# ENTRYPOINT ["<executable>"]
# Specifying a docker entrypoint that can do a little extra stuff at startup.
# Ultimately, it will end up calling "java" to run the SensorHub class.
ENTRYPOINT [ "./launch.sh" ]

## Default startup input. Will be overridden by elements of 'docker run' command.
# CMD ["<input to be run from the working directory>"]

## Declare volume(s) for mount point directories
# VOLUME [<"/first/container/directory"><, "/second/container/directory", ...]
# Location of config.json and logback.xml.
VOLUME ${OSH_HOME}/config

# Suggested location of any data, such as video files, or other sensor data.
# Can be referenced as "./data" in node configuration paths.
VOLUME ${OSH_HOME}/data

# Suggested location to save H2 database files. Can be referenced as "./db" in
# node configuration.
VOLUME ${OSH_HOME}/db

# Any additional ".class" files that the user may want to include in the
# classpath after install. These will be first in the classpath, before any
# other libraries included in the image.
VOLUME ${OSH_HOME}/userclasses

# Any additional libraries that the user may want to include in the classpath
# after install. These will be second in the classpath, before other libraries
# that are included in the image.
VOLUME ${OSH_HOME}/userlib
