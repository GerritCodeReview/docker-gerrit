FROM ubuntu:22.04
MAINTAINER Gerrit Code Review Community

# Add Gerrit packages repository
RUN apt-get update && \
    apt-get -y install gnupg2
RUN echo "deb mirror://mirrorlist.gerritforge.com/bionic gerrit contrib" > /etc/apt/sources.list.d/GerritForge.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 847005AE619067D5

RUN apt-get update
RUN apt-key update
RUN apt-get -y install sudo

ADD entrypoint.sh /

# Install OpenJDK and Gerrit in two subsequent transactions
# (pre-trans Gerrit script needs to have access to the Java command)
RUN apt-get -y install openjdk-17-jdk
<<<<<<< PATCH SET (db79c4 Set Gerrit to 3.9.0-rc0 and upgrade to Java 17)
RUN apt-get -y install gerrit=3.9.0-0rc0 && \
=======
RUN apt-get -y install gerrit=3.8.2-1 && \
>>>>>>> BASE      (0ddfe4 Update Java version to 17)
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
