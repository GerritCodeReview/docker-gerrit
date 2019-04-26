FROM centos:7.6.1810
MAINTAINER Gerrit Code Review Community

# Add Gerrit packages repository
RUN rpm -i https://gerritforge.com/gerritforge-repo-1-2.noarch.rpm

# Install OS pre-prequisites, OpenJDK and Gerrit in two subsequent transactions
# (pre-trans Gerrit script needs to have access to the Java command)
RUN yum -y install initscripts && \
    yum -y install java-1.8.0-openjdk && \
    yum -y install gerrit-3.0.0.rc1-1  && rm -Rf /var/gerrit/{logs,tmp}/* && rm -Rf /var/gerrit/.gerritcodereview && \
    yum -y clean all

USER gerrit

RUN java -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit && \
    java -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit && \
    git config -f /var/gerrit/etc/gerrit.config --add container.javaOptions "-Djava.security.egd=file:/dev/./urandom"

ENV CANONICAL_WEB_URL=

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

# Start Gerrit
CMD git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}" && \
    git config -f /var/gerrit/etc/gerrit.config noteDb.changes.autoMigrate true && \
        /var/gerrit/bin/gerrit.sh run
