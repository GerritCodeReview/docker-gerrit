FROM ubuntu:18.04
MAINTAINER Gerrit Code Review Community

# Add Gerrit packages repository
RUN apt-get update && \
    apt-get -y install gnupg2
RUN echo "deb mirror://mirrorlist.gerritforge.com/bionic gerrit contrib" > /etc/apt/sources.list.d/GerritForge.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 847005AE619067D5

RUN apt-get update
RUN apt-key update
RUN apt-get -y install sudo

# Install OpenJDK and Gerrit in two subsequent transactions
# (pre-trans Gerrit script needs to have access to the Java command)
RUN apt-get -y install openjdk-8-jdk
RUN apt-get -y install gerrit=3.0.0.rc0-1 && rm -f /var/gerrit/logs/*

USER gerrit
RUN java -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit
RUN java -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit
RUN git config -f /var/gerrit/etc/gerrit.config --add container.javaOptions "-Djava.security.egd=file:/dev/./urandom"

ENV CANONICAL_WEB_URL=

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

# Start Gerrit
CMD git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}" && \
    git config -f /var/gerrit/etc/gerrit.config noteDb.changes.autoMigrate true && \
        /var/gerrit/bin/gerrit.sh run
