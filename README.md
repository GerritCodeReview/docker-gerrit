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

## Using persistent volumes

Use docker persistent volumes to keep Gerrit data across restarts.
See below a sample docker-compose.yaml for persisting the H2 Database, Lucene indexes, Caches and
Git repositories.

Example of /docker-compose.yaml

```yaml
version: '3'

services:
  gerrit:
    image: gerritcodereview/gerrit
    volumes:
       - git-volume:/var/gerrit/git
       - db-volume:/var/gerrit/db
       - index-volume:/var/gerrit/index
       - cache-volume:/var/gerrit/cache
    ports:
       - "29418:29418"
       - "8080:8080"

volumes:
  git-volume:
  db-volume:
  index-volume:
  cache-volume:
```


Run ```docker-compose up``` to trigger the build and execution of your custom Gerrit docker setup.

## Using Gerrit in production

When running Gerrit on Docker in production, it is a good idea to rely on a physical external
storage with much better performance and reliability than the Docker's internal AUFS, and an external
configuration directory for better change management traceability.

Additionally, you may want to replace H2 with a more robust DBMS like PostgreSQL and an external
authentication system such as LDAP.

See below a more advanced example of docker-compose.yaml with PostgreSQL and OpenLDAP (from Osixia's DockerHub).

Example of /docker-compose.yaml assuming you have an external directory available as /external/gerrit

```yaml
version: '3'

services:
  gerrit:
    image: gerritcodereview/gerrit
    ports:
      - "29418:29418"
      - "80:8080"
    links:
      - postgres
    depends_on:
      - postgres
      - ldap
    volumes:
     - /external/gerrit/etc:/var/gerrit/etc
     - /external/gerrit/git:/var/gerrit/git
     - /external/gerrit/index:/var/gerrit/index
     - /external/gerrit/cache:/var/gerrit/cache
#    entrypoint: java -jar /var/gerrit/bin/gerrit.war init -d /var/gerrit

  postgres:
    image: postgres:9.6
    environment:
      - POSTGRES_USER=gerrit
      - POSTGRES_PASSWORD=secret
      - POSTGRES_DB=reviewdb
    volumes:
      - /external/gerrit/postgres:/var/lib/postgresql/data

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
  canonicalWebUrl = http://localhost

[database]
  type = postgresql
  hostname = postgres
  database = reviewdb
  username = gerrit

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
[database]
  password = secret

[ldap]
  password = secret
```

### Initialize Gerrit DB and Git repositories with Docker

The external filesystem needs to be initialized with gerrit.war beforehand:
- ReviewDB created and populated with the initial DDL
- All-Projects, All-Groups and All-Users Git repositories created in Gerrit
- System Group UUIDs created in Git repositories and initialized in ReviewDB

The initialization can be done as a one-off operation before starting all containers.

#### Step-1: Create the PostgreSQL ReviewDB

Start the postgres image standalone using docker compose:

```
docker-compose up -d postgres
docker-compose logs -f postgres
```

Wait until you see in the output a message like: "database system is ready to accept connections"

#### Step-2: Run Gerrit docker init setup from docker

Uncomment in docker-compose.yaml the Gerrit init step entrypoint and run Gerrit with docker-compose
in foreground.

```
docker-compose up gerrit
```

Wait until you see in the output the message ```Initialized /var/gerrit``` and then the container
will exit.

#### Step-3: Start Gerrit in daemon mode

Comment out the gerrit init entrypoint in docker-compose.yaml and start all the docker-compose nodes:

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