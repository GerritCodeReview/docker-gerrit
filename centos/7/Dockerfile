FROM centos:7.6.1810
MAINTAINER Gerrit Code Review Community

# Add Gerrit packages repository
RUN rpm -i https://gerritforge.com/gerritforge-repo-1-2.noarch.rpm

ADD entrypoint.sh /

# Install OS pre-prequisites, OpenJDK and Gerrit in two subsequent transactions
# (pre-trans Gerrit script needs to have access to the Java command)
RUN yum -y install initscripts && \
    yum -y install java-1.8.0-openjdk && \
    yum -y install gerrit-3.0.0-1 && \
    /entrypoint.sh init && \
    rm -f /var/gerrit/etc/{ssh,secure}* && rm -Rf /var/gerrit/{static,index,logs,data,index,cache,git,db,tmp}/* && chown -R gerrit:gerrit /var/gerrit && \
    yum -y clean all

USER gerrit

ENV CANONICAL_WEB_URL=

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

ENTRYPOINT /entrypoint.sh
