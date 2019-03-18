FROM ubuntu:14.04
MAINTAINER Gerrit Code Review Community

# Add Gerrit packages repository
RUN echo "deb mirror://mirrorlist.gerritforge.com/deb gerrit contrib" > /etc/apt/sources.list.d/GerritForge.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1871F775

# Allow remote connectivity and sudo
RUN apt-get update
RUN apt-key update
RUN apt-get -y install openssh-client sudo

# Install OpenJDK and Gerrit in two subsequent transactions
# (pre-trans Gerrit script needs to have access to the Java command)
RUN apt-get -y install openjdk-7-jdk
RUN apt-get -y install gerrit=2.13.13-1 && rm -f /var/gerrit/logs/*

USER gerrit
RUN java -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit
RUN java -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit
RUN git config -f /var/gerrit/etc/gerrit.config container.javaOptions "-Djava.security.egd=file:/dev/./urandom"

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

# Start Gerrit
CMD /var/gerrit/bin/gerrit.sh start && tail -f /var/gerrit/logs/error_log
