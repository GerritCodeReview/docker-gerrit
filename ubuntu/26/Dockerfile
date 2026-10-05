FROM eclipse-temurin:25.0.3_9-jdk-resolute
LABEL org.opencontainers.image.authors="luca.milanesio@gmail.com"

# Add Gerrit packages repository
RUN apt-get update && \
    apt-get -y install gnupg2

RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 55787ed781304950 && \
    gpg --export 55787ed781304950 | tee /etc/apt/keyrings/gerritforge.gpg > /dev/null && \
    chmod 644 /etc/apt/keyrings/gerritforge.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/gerritforge.gpg] mirror://mirrorlist.gerritforge.com/bionic gerrit contrib" > /etc/apt/sources.list.d/GerritForge.list

RUN apt-get update
RUN apt-get -y install sudo

ADD entrypoint.sh /

<<<<<<< PATCH SET (63e3619a253cee0c33d2f4e920776d69e493f48e Remove Java 21 on Ubuntu 26)
RUN apt-get -y upgrade && \
    apt-get -y install gerrit=3.15.0-rc0 && \
||||||| BASE      (4aa28a90a34c127d8487260a84e8003aa2c21c99 Set Gerrit to 3.15.0-rc0)
RUN apt-get -y install openjdk-21-jdk && \
    apt-get -y upgrade && \
    apt-get -y install gerrit=3.15.0-rc0 && \
    apt-get -y remove openjdk-21-jdk && \
=======
RUN apt-get -y install openjdk-21-jdk && \
    apt-get -y upgrade && \
    apt-get -y install gerrit=3.15.0-0rc0 && \
    apt-get -y remove openjdk-21-jdk && \
>>>>>>> BASE      (c2c75ef1873b4a7eb4e443a4326c62afc23ccbc2 Set Gerrit to 3.15.0-rc0)
    apt-mark hold gerrit && \
    /entrypoint.sh init && \
    bash -c 'rm -f /var/gerrit/etc/{ssh,secure}* && rm -Rf /var/gerrit/{static,index,logs,data,index,cache,git,db,tmp}/*' && \
    chown -R gerrit:gerrit /var/gerrit

# Note that temurin does everything that is needed in order to install JDK but doesn't
# update alternatives for java which is detected during the gerrit install step
# hence it is the only extra step that had to be added
RUN update-alternatives --install /usr/bin/java java $(which java) 2222

USER gerrit

ENV CANONICAL_WEB_URL=
ENV HTTPD_LISTEN_URL=

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

ENTRYPOINT ["/entrypoint.sh"]
