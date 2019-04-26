FROM ubuntu:18.04
MAINTAINER Gerrit Code Review Community

ARG GERRIT_WAR_URL="https://gerrit-ci.gerritforge.com/view/Gerrit/job/Gerrit-bazel-master/lastSuccessfulBuild/artifact/gerrit/bazel-bin/release.war"

# Install OpenJDK and Git and allow remote connectivity and sudo
RUN apt-get update && apt-get -y install \
    openssh-client \
    sudo \
    openjdk-8-jdk \
    git && \
    rm -rf /var/lib/apt/lists/*

ADD entrypoint.sh /

RUN adduser --disabled-password --gecos "" gerrit --home /home/gerrit && \
    mkdir -p /var/gerrit/bin && \
    chown -R gerrit /var/gerrit
USER gerrit
ADD --chown=gerrit $GERRIT_WAR_URL  /var/gerrit/bin/gerrit.war
RUN mkdir -p /var/gerrit/etc && \
    touch /var/gerrit/etc/gerrit.config && \
    git config -f /var/gerrit/etc/gerrit.config auth.type DEVELOPMENT_BECOME_ANY_ACCOUNT && \
    git config --add -f /var/gerrit/etc/gerrit.config container.javaOptions "-Djava.security.egd=file:/dev/./urandom"

ENV CANONICAL_WEB_URL=

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

ENTRYPOINT /entrypoint.sh
