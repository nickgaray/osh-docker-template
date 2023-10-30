FROM ubuntu:22.04 AS base

ARG branch=''
ARG repoUrl= ''

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-11-jdk git unzip

FROM base AS build
ARG branch
ARG repoUrl

RUN git clone -b $branch --recursive $repoUrl ./buildDir
#RUN mv $(basename $repoUrl | cut -d. -f1) ./buildDir
RUN cd ./buildDir  && ./gradlew build -x test

FROM base as deployment

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y curl nano certbot wget nginx

# Create osh user
RUN useradd -r -s /bin/bash osh && echo "US/Central" > /etc/timezone

# Setup OSH Node in target directory
COPY --from=build ./buildDir/build/distributions/osh-node*.zip /opt/
RUN unzip /opt/osh-node-*.zip -d /opt/
RUN rm /opt/osh-node-*.zip
RUN basename /opt/osh-node-* | xargs -ixxx mv /opt/xxx /opt/opensensorhub
RUN chown -R osh:osh /opt/opensensorhub
RUN chmod 755 /opt/opensensorhub/launch.sh

# Copy the service script
COPY --from=build ./buildDir/container/osh-service /etc/init.d/
RUN chmod 755 /etc/init.d/osh-service

# Configure nginx
COPY --from=build ./buildDir/container/nginx-users /etc/nginx/
COPY --from=build ./buildDir/container/nginx.crt /etc/nginx/
COPY --from=build ./buildDir/container/nginx.key /etc/nginx/
COPY --from=build ./buildDir/container/nginx-default /etc/nginx/sites-available/
RUN mv /etc/nginx/sites-available/nginx-default /etc/nginx/sites-available/default

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

# Open ports
EXPOSE 80 443

CMD /etc/init.d/osh-service start && \
    service nginx start



