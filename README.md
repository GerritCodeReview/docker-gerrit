# Gerrit Code Review docker images

These images provide official Gerrit Code Review releases using the
DEB/RPM packages available from the
[GerritForge repositories](https://gitenterprise.me/2015/02/27/gerrit-2-10-rpm-and-debian-packages-available/).
The DEB/RPM packages contain the release `gerrit.war` file along with additional configuration files that
provide an [out-of-the-box](https://gerrit.googlesource.com/plugins/out-of-the-box/) setup.

Each image is intended to be used AS-IS for training or staging environments.

For production environments, the images provide a base on which required customizations
to `gerrit.config` and persistent external modules can be made.

## Quickstart

Start Gerrit Code Review in its demo/staging "out-of-the-box" setup like so:

```
docker run -ti -p 8080:8080 -p 29418:29418 docker.io/gerritcodereview/gerrit
```

Wait a few minutes until the `Gerrit Code Review NNN ready` message appears,
where NNN is your current Gerrit version, then open your browser to http://localhost:8080
and you will be in Gerrit Code Review.

*NOTE*: If your docker server is running on a remote host, change 'localhost' to
the hostname or IP address of your remote docker server.

The [plugin-manager](https://gerrit.googlesource.com/plugins/plugin-manager/) introduction screen
guides you through the basics of Gerrit and allows installation of additional plugins downloaded from
[Gerrit CI](https://gerrit-ci.gerritforge.com).

Images for previous Gerrit Code Review releases are available; e.g. to run version 3.8.0,
use the following command:

```
docker run -ti -p 8080:8080 -p 29418:29418 docker.io/gerritcodereview/gerrit:3.8.0
```

## Build docker images

To build docker images, clone the git repository https://gerrit.googlesource.com/docker-gerrit.

Release tags are available and can be used to build particular releases.  E.g. to build an
image using Gerrit 3.8.0, checkout the respective tag:

```
git checkout v3.8.0
```

Navigate to either `./almalinux/9` or `./ubuntu/22` to build the almalinux- or ubuntu-based
docker image. Then run:

```
docker build -t gerritcodereview/gerrit:$(git describe) .
```

To build an image containing a development build of Gerrit (e.g. to test a change), run the
following command instead:

```
docker build --build-arg GERRIT_WAR_URL="<url>" -t gerritcodereview/gerrit -f Dockerfile-dev .
```

The `<url>` passed to the `GERRIT_WAR_URL`-build argument has to point to a Gerrit-`.war`-file.
The build argument defaults to the URL pointing to the last successful build of the Gerrit master
branch on the [Gerrit CI](https://gerrit-ci.gerritforge.com).

## Build multi-platform images

For the official releases one can build both `amd64` and `arm64` images at once and either
load them to the local docker registry or push them to the `gerritcodereview` dockerhub account.
In order to do that, one simply calls:

```
./build_multiplatform.sh --load
```

And multiplatform images will be created and loaded locally. Calling:

```
./build_multiplatform.sh --push
```

pushes images to docker-hub instead.

Notes:
* in the `--load` target only the current system architecture image is pushed to the local
  registry
* the almalinux image is additionally tagged as the default release image.

## Using persistent volumes

Use docker persistent volumes to keep Gerrit data across restarts.
Below is a sample `docker-compose.yaml` with externally-mounted Lucene indexes,
Caches and Git repositories.

```yaml
version: '3'

services:
  gerrit:
    image: docker.io/gerritcodereview/gerrit
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

Run `docker compose up` (or `docker-compose up` with older versions of
Docker) to trigger the build and execution of your container.

Note that the path `/var/gerrit/etc` may also be externally-mounted. If this is done, then
the config file `/var/gerrit/etc/gerrit.config` initialized by the Gerrit DEB/RPM
package inside the container will no longer be available.  If gerrit does not find an existing
`gerrit.config` file under the externally-mounted path, then it generates a new one.  However, the
newly generated config file does not provide the same first-run behaviour as the one from the
DEB/RPM package (the out-of-the-box plugin is not configured, and the introductory screen of
the plugin-manager will not appear).

## Environment variables

This is a list of available environment variables to change the Gerrit configuration:

* `CANONICAL_WEB_URL`: Optional. Set the `gerrit.canonicalWebUrl` parameter in `gerrit.config`.
Defaults to `http://<image_hostname>`
* `HTTPD_LISTEN_URL`: Optional. Override the `httpd.listenUrl` parameter in `gerrit.config`.

## Using Gerrit in production

When running Gerrit on Docker in production, it is a good idea to rely on a physical external
storage with much better performance and reliability than the Docker's internal AUFS, and an external
configuration directory (`etc`) for better change management traceability. Additionally,
you may want to use a proper external authentication (e.g. ldap).

A more advanced `docker-compose.yaml` example is given below, which uses OpenLDAP
(published by Osixia on Docker Hub).  The example assumes you have an external directory
available as `/external/gerrit`

```yaml
version: '3'

services:
  gerrit:
    image: docker.io/gerritcodereview/gerrit
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
    image: docker.io/osixia/openldap
    ports:
      - "389:389"
      - "636:636"
    environment:
      - LDAP_ADMIN_PASSWORD=secret
    volumes:
      - /external/gerrit/ldap/var:/var/lib/ldap
      - /external/gerrit/ldap/etc:/etc/ldap/slapd.d

  ldap-admin:
    image: docker.io/osixia/phpldapadmin
    ports:
      - "6443:443"
    environment:
      - PHPLDAPADMIN_LDAP_HOSTS=ldap
```

Example of `/external/gerrit/etc/gerrit.config`

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

Example of `/external/gerrit/etc/secure.config`
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

Uncomment the `command: init` option in `docker-compose.yaml` and run Gerrit with `docker compose`
in foreground.

```
docker compose up gerrit
```

Wait until you see in the output the message `Initialized /var/gerrit` and then the container
will exit.

#### Step-2: Start Gerrit in daemon mode

Comment out the `command: init` option in `docker-compose.yaml` and start all the nodes:

```
docker compose up -d
```

### Registering users in OpenLDAP with PhpLdapAdmin

The sample docker compose project includes a node with PhpLdapAdmin connected to OpenLDAP
and exposed via Web UX at https://localhost:6443.

The first user that logs in Gerrit is considered the initial administrator, it is important
that you configure it on LDAP to login and having the ability to administer your Gerrit setup.

#### Define the Gerrit administrator in OpenLDAP

Login to PhpLdapAdmin using `cn=admin,dc=example,dc=org` as username and `secret` as password
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
