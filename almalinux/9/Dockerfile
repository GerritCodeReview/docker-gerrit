<<<<<<< PATCH SET (ce9ba920657b1dca5d6e3764f364883a371f1dff Switch default Java version to 25)
FROM almalinux:9.7
LABEL org.opencontainers.image.authors="luca.milanesio@gmail.com"

# Add Gerrit packages repository and the newest GPG key
RUN rpm -i https://gerritforge.com/gerritforge-repo-1-5.noarch.rpm

ADD entrypoint.sh /

# Install OS pre-prequisites, OpenJDK and Gerrit in two subsequent transactions
# (pre-trans Gerrit script needs to have access to the Java command)
RUN yum -y install initscripts && \
    yum -y install java-25-openjdk

RUN yum -y install gerrit-3.14.0-0rc4 && \
    /entrypoint.sh init && \
    rm -f /var/gerrit/etc/{ssh,secure}* && rm -Rf /var/gerrit/{static,index,logs,data,index,cache,git,db,tmp}/* && chown -R gerrit:gerrit /var/gerrit && \
    yum -y clean all

# Enable LEGACY security policies by default (for TLS 1.0/1.1 compatibility)
RUN update-crypto-policies --set LEGACY

USER gerrit

ENV CANONICAL_WEB_URL=
ENV HTTPD_LISTEN_URL=

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

ENTRYPOINT ["/entrypoint.sh"]
||||||| BASE      (e367f4f9f879107a00ca10c9f5fda415dcf8d2bd Set Gerrit to 3.14.0-rc4)
FROM almalinux:9.7
LABEL org.opencontainers.image.authors="luca.milanesio@gmail.com"

# Add Gerrit packages repository and the newest GPG key
RUN rpm -i https://gerritforge.com/gerritforge-repo-1-5.noarch.rpm

ADD entrypoint.sh /

# Install OS pre-prequisites, OpenJDK and Gerrit in two subsequent transactions
# (pre-trans Gerrit script needs to have access to the Java command)
RUN yum -y install initscripts && \
    yum -y install java-21-openjdk

RUN yum -y install gerrit-3.14.0-0rc4 && \
    /entrypoint.sh init && \
    rm -f /var/gerrit/etc/{ssh,secure}* && rm -Rf /var/gerrit/{static,index,logs,data,index,cache,git,db,tmp}/* && chown -R gerrit:gerrit /var/gerrit && \
    yum -y clean all

# Enable LEGACY security policies by default (for TLS 1.0/1.1 compatibility)
RUN update-crypto-policies --set LEGACY

USER gerrit

ENV CANONICAL_WEB_URL=
ENV HTTPD_LISTEN_URL=

# Allow incoming traffic
EXPOSE 29418 8080

VOLUME ["/var/gerrit/git", "/var/gerrit/index", "/var/gerrit/cache", "/var/gerrit/db", "/var/gerrit/etc"]

ENTRYPOINT ["/entrypoint.sh"]
=======
>>>>>>> BASE      (0e7be367848f2fbc9830962396bc56e308e87db2 Allow specifying the Dockerfile to use)
