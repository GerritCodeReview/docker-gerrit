FROM ubuntu:16.04
MAINTAINER Gerrit Code Review Community

# Add Gerrit packages repository
COPY GerritForge.list  /etc/apt/sources.list.d/GerritForge.list
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 1871F775 && \
    apt-get update                  &&\
    apt-key update                  &&\
    apt-get install -y              \
            openssh-client          \
            sudo                    \
            openjdk-8-jdk-headless  &&\
    apt-get install -y              \
            gerrit=2.14.3-1         &&\
    apt-get clean -y                &&\
    rm -f /var/gerrit/logs/*        &&\
    rm -rf /var/gerrit/tmp/*        &&\
    rm -rf /tmp/* 

USER gerrit
RUN java -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit && \
    rm -f /var/gerrit/logs/* &&\
    rm -rf /var/gerrit/tmp/* &&\
    rm -rf /tmp/* 

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

# Start Gerrit
CMD /var/gerrit/bin/gerrit.sh start && tail -f /var/gerrit/logs/error_log
