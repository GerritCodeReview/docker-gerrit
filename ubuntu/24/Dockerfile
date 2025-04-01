FROM eclipse-temurin:21.0.6_7-jdk-noble
LABEL org.opencontainers.image.authors="luca.milanesio@gmail.com"

# Add Gerrit packages repository
RUN apt-get update && \
    apt-get -y install gnupg2
RUN echo "deb mirror://mirrorlist.gerritforge.com/bionic gerrit contrib" > /etc/apt/sources.list.d/GerritForge.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 55787ed781304950

RUN apt-get update
RUN apt-key update
RUN apt-get -y install sudo

ADD entrypoint.sh /

# Note that temurin does everything that is needed in order to install JDK but doesn't
# update alternatives for java which is detected during the gerrit install step
# hence it is the only extra step that had to be added
RUN update-alternatives --install /usr/bin/java java $(which java) 2222 && \
    apt-get -y upgrade && \
    apt-get -y install gerrit=3.11.2-1 && \
    apt-mark hold gerrit && \
    /entrypoint.sh init && \
    bash -c 'rm -f /var/gerrit/etc/{ssh,secure}* && rm -Rf /var/gerrit/{static,index,logs,data,index,cache,git,db,tmp}/*' && \
    chown -R gerrit:gerrit /var/gerrit

USER gerrit

ENV CANONICAL_WEB_URL=
ENV HTTPD_LISTEN_URL=

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

ENTRYPOINT ["/entrypoint.sh"]
