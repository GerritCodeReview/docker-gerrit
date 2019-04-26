#!/bin/bash -e

if [ ! -d /var/gerrit/git/All-Projects.git ]
then
  echo "Initializing Gerrit site ..."
  java -jar /var/gerrit/bin/gerrit.war init --batch --install-all-plugins -d /var/gerrit
  java -jar /var/gerrit/bin/gerrit.war reindex -d /var/gerrit
fi

git config -f /var/gerrit/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}"

echo "Running Gerrit ..."
exec /var/gerrit/bin/gerrit.sh run
