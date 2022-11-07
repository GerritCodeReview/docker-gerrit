# Gerrit Code Review docker image

The official Gerrit Code Review image with an out-of-the-box setup
with H2 and DEVELOPMENT account setup.

This image is intended to be used AS-IS for training or staging environments.
It can be used for production as base image and requires customizations to its gerrit.config
and definition of persistent external modules.

## Quickstart

Start Gerrit Code Review in its demo/staging out-of-the-box setup:

```
docker run -ti -p 8080:8080 -p 29418:29418 gerritcodereview/gerrit
```

Wait a few minutes until the ```Gerrit Code Review NNN ready``` message appears,
where NNN is your current Gerrit version, then open your browser to http://localhost:8080
and you will be in Gerrit Code Review.

*NOTE*: If your docker server is running on a remote host, change 'localhost' to the hostname
or IP address of your remote docker server.

Starting from Ver. 2.14, a new introduction screen guides you through the basics of Gerrit
and allows installing additional plugins downloaded from [Gerrit CI](https://gerrit-ci.gerritforge.com).

Official releases are also available as Docker images, e.g. use the following to run the 3.3.0 version.

```
docker run -ti -p 8080:8080 -p 29418:29418 gerritcodereview/gerrit:3.3.0
```

## Build docker image

For docker images that contain released Gerrit versions, tags exist in this git repository pointing
to a state of the repository, where this version of Gerrit (e.g. 3.3.0) is referenced in the
Dockerfiles. To build such a docker image for development purposes, checkout the respective version
tag, e.g.:

```
git checkout v3.3.0
```

Navigate to either `./almalinux/9` or `./ubuntu/22` to build the almalinux- or ubuntu-based docker
image, respectively. Then run:

```
docker build -t gerritcodereview/gerrit:$(git describe) .
```

To build an image containing a development build of Gerrit, e.g. to test a change, run the following
command instead:

```
docker build --build-arg GERRIT_WAR_URL="<url>" -t gerritcodereview/gerrit -f Dockerfile-dev .
```

The `<url>` passed to the `GERRIT_WAR_URL`-build argument has to point to a Gerrit-`.war`-file.
The build argument defaults to the URL pointing to the last successful build of the Gerrit master
branch on the [Gerrit CI](https://gerrit-ci.gerritforge.com).

## Using persistent volumes

Use docker persistent volumes to keep Gerrit data across restarts.
See below a sample docker-compose.yaml per externally-mounted Lucene indexes,
Caches and Git repositories.

Example of /docker-compose.yaml

```yaml
version: '3'

services:
  gerrit:
    image: gerritcodereview/gerrit
    volumes:
       - git-volume:/var/gerrit/git
       - index-volume:/var/gerrit/index
       - cache-volume:/var/gerrit/cache
    ports:
       - "29418:29418"
       - "8080:8080"

volumes:
  git-volume:
  index-volume:
  cache-volume:
```


Run ```docker-compose up``` to trigger the build and execution of your custom Gerrit docker setup.

## Environment variables

This is a list of available environment variables to change the Gerrit configuration:

* `CANONICAL_WEB_URL`: Optional. Set the `gerrit.canonicalWebUrl` parameter in `gerrit.config`.
Defaults to `http://<image_hostname>`
* `HTTPD_LISTEN_URL`: Optional. Override the `httpd.listenUrl` parameter in `gerrit.config`.

## Using Gerrit in production

When running Gerrit on Docker in production, it is a good idea to rely on a physical external
storage with much better performance and reliability than the Docker's internal AUFS, and an external
configuration directory for better change management traceability. Additionally,
you may want to use a proper external authentication.

See below a more advanced example of docker-compose.yaml with OpenLDAP
(from Osixia's DockerHub).

Example of /docker-compose.yaml assuming you have an external directory available as /external/gerrit

```yaml
version: '3'

services:
  gerrit:
    image: gerritcodereview/gerrit
    ports:
      - "29418:29418"
      - "80:8080"
    depends_on:
      - ldap
    volumes:
      - /external/gerrit/etc:/var/gerrit/etc
      - /external/gerrit/git:/var/gerrit/git
      - /external/gerrit/db:/var/gerrit/db
      - /external/gerrit/index:/var/gerrit/index
      - /external/gerrit/cache:/var/gerrit/cache
    environment:
      - CANONICAL_WEB_URL=http://localhost
    # command: init

  ldap:
    image: osixia/openldap
    ports:
      - "389:389"
      - "636:636"
    environment:
      - LDAP_ADMIN_PASSWORD=secret
    volumes:
      - /external/gerrit/ldap/var:/var/lib/ldap
      - /external/gerrit/ldap/etc:/etc/ldap/slapd.d

  ldap-admin:
    image: osixia/phpldapadmin
    ports:
      - "6443:443"
    environment:
      - PHPLDAPADMIN_LDAP_HOSTS=ldap
```

Example of /external/gerrit/etc/gerrit.config

```
[gerrit]
  basePath = git

[index]
  type = LUCENE

[auth]
  type = ldap
  gitBasicAuth = true

[ldap]
  server = ldap://ldap
  username=cn=admin,dc=example,dc=org
  accountBase = dc=example,dc=org
  accountPattern = (&(objectClass=person)(uid=${username}))
  accountFullName = displayName
  accountEmailAddress = mail

[sendemail]
  smtpServer = localhost

[sshd]
  listenAddress = *:29418

[httpd]
  listenUrl = http://*:8080/

[cache]
  directory = cache

[container]
  user = root
```

Example of /external/gerrit/etc/secure.config
```
[ldap]
  password = secret
```

### Initialize Gerrit DB and Git repositories with Docker

The external filesystem needs to be initialized with gerrit.war beforehand:
- All-Projects and All-Users Git repositories created in Gerrit
- System Group UUIDs created in Git repositories

The initialization can be done as a one-off operation before starting all containers.

#### Step-1: Run Gerrit docker init setup from docker

Uncomment the `command: init` option in docker-compose.yaml and run Gerrit with docker-compose
in foreground.

```
docker-compose up gerrit
```

Wait until you see in the output the message ```Initialized /var/gerrit``` and then the container
will exit.

#### Step-2: Start Gerrit in daemon mode

Comment out the `command: init` option in docker-compose.yaml and start all the docker-compose nodes:

```
docker-compose up -d
```

### Registering users in OpenLDAP with PhpLdapAdmin

The sample docker compose project includes a node with PhpLdapAdmin connected to OpenLDAP
and exposed via Web UX at https://localhost:6443.

The first user that logs in Gerrit is considered the initial administrator, it is important
that you configure it on LDAP to login and having the ability to administer your Gerrit setup.

#### Define the Gerrit administrator in OpenLDAP

Login to PhpLdapAdmin using ```cn=admin,dc=example,dc=org``` as username and ```secret``` as password
and then create a new child node of type "Courier Mail Account" for the Gerrit Administrator

Example:

- Given Name: Gerrit
- Last Name: Admin
- Common Name: Gerrit Admin
- User ID: gerritadmin
- Email: gerritadmin@localdomain
- Password: secret

Verify that your data is correct and then commit the changes to LDAP.

#### Login to Gerrit as Administrator

Login to Gerrit on http://localhost using the new Gerrit Admin credentials created on LDAP.

Example:

- Login: gerritadmin
- Password: secret

## More information about Gerrit Code Review

Refer to Gerrit Documentation at http://localhost/Documentation/index.html for more information on
how to configure, administer and use Gerrit Code Review.

For a full list of Gerrit Code Review resources, refer to the [Gerrit Code Review home page](https://www.gerritcodereview.com)
