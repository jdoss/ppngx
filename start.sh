#!/bin/bash

set -e

PAPERLESS_PORT=8000
PAPERLESS_UID=1000
PAPERLESS_GID=1000
PAPERLESS_VERSION=latest
PAPERLESS_TIME_ZONE=America/Chicago
PAPERLESS_OCR_LANGUAGE=eng

SFTPGO_SFTP_PORT=2022
SFTPGO_HTTP_PORT=8022
SFTPGO_ADMIN_USER=sftpadmin
SFTPGO_ADMIN_PASSWORD=supersecret
SFTPGO_PAPERLESS_USER=scanner
SFTPGO_PAPERLESS_PASSWORD=anothersupersecret

PAPERLESS_SECRET_KEY=chamgemechamgemechamgemechamgemechamgemechamgemechamgemechamgeme

REDIS_VERSION=6
REDIS_PORT=6379

POSTGRESQL_VERSION=13
POSTGRESQL_PORT=5432
POSTGRES_USER=paperless
POSTGRESQL_DB=paperless
POSTGRESQL_PASSWORD=paperlesschangeme

echo "Creating Paperless Pod..."
podman pod create --replace --name paperless \
  -p ${PAPERLESS_PORT}:${PAPERLESS_PORT} \
  -p ${SFTPGO_SFTP_PORT}:${SFTPGO_SFTP_PORT} \
  -p ${SFTPGO_HTTP_PORT}:${SFTPGO_HTTP_PORT}

echo "Starting Redis..."
podman volume create paperless-redis 2> /dev/null ||:
podman create --replace --pod paperless \
  --restart=unless-stopped \
  --name paperless-redis \
  --volume paperless-redis:/data:Z \
  docker.io/library/redis:${REDIS_VERSION}
podman start paperless-redis

echo "Starting PostgreSQL..."
podman volume create paperless-postgresql 2> /dev/null ||:
podman create --replace --pod paperless \
  --restart=unless-stopped \
  --name paperless-postgresql \
  --expose ${POSTGRESQL_PORT} \
  -e POSTGRES_USER=${POSTGRES_USER} \
  -e POSTGRES_PASSWORD=${POSTGRESQL_PASSWORD} \
  --volume paperless-postgresql:/var/lib/postgresql/data:Z \
  docker.io/library/postgres:${POSTGRESQL_VERSION}
podman start paperless-postgresql

echo "Starting Gotenberg..."
podman create --replace --pod paperless \
  --restart=unless-stopped \
  --name paperless-gotenberg \
  -e CHROMIUM_DISABLE_ROUTES=1 \
  docker.io/gotenberg/gotenberg:7
podman start paperless-gotenberg

echo "Starting Tika..."
podman create --replace --pod paperless \
  --restart=unless-stopped \
  --name paperless-tika \
  docker.io/apache/tika
podman start paperless-tika

echo "Starting Paperless..."
podman create --replace --pod paperless \
  --name paperless-webserver \
  --restart=unless-stopped \
  --stop-timeout=90 \
  --health-cmd='["curl", "-f", "http://localhost:8000"]' \
  --health-retries=5 \
  --health-start-period=60s \
  --health-timeout=10s \
  -e PAPERLESS_REDIS=redis://localhost:${REDIS_PORT} \
  -e PAPERLESS_DBHOST=localhost \
  -e PAPERLESS_DBNAME=${POSTGRES_USER} \
  -e PAPERLESS_DBPASS=${POSTGRESQL_PASSWORD} \
  -e PAPERLESS_TIKA_ENABLED=1 \
  -e PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://localhost:3000 \
  -e PAPERLESS_TIKA_ENDPOINT=http://localhost:9998 \
  -e USERMAP_UID=${PAPERLESS_UID} \
  -e USERMAP_GID=${PAPERLESS_GID} \
  -e PAPERLESS_SECRET_KEY=${PAPERLESS_SECRET_KEY} \
  -e PAPERLESS_TIME_ZONE=${PAPERLESS_TIME_ZONE} \
  -e PAPERLESS_OCR_LANGUAGE=${PAPERLESS_OCR_LANGUAGE} \
  -v paperless-data:/usr/src/paperless/data:Z \
  -v paperless-media:/usr/src/paperless/media:Z \
  -v paperless-consume:/usr/src/paperless/consume:U,z \
  -v ${PWD}/export:/usr/src/paperless/export:U,Z \
  ghcr.io/paperless-ngx/paperless-ngx:${PAPERLESS_VERSION}
podman start paperless-webserver

echo "Starting SFTPGo..."
podman create --replace --pod paperless \
  --restart=unless-stopped \
  --name paperless-sftpgo \
  -e SFTPGO_DATA_PROVIDER__CREATE_DEFAULT_ADMIN=1 \
  -e SFTPGO_DEFAULT_ADMIN_USERNAME=${SFTPGO_ADMIN_USER} \
  -e SFTPGO_DEFAULT_ADMIN_PASSWORD=${SFTPGO_ADMIN_PASSWORD} \
  -e SFTPGO_HTTPD__BINDINGS__0__PORT=${SFTPGO_HTTP_PORT} \
  -e SFTPGO_SFTPD__KEX_ALGORITHMS=curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group14-sha256,diffie-hellman-group14-sha1,diffie-hellman-group1-sha1 \
  -e SFTPGO_SFTPD__HOST_KEY_ALGORITHMS=rsa-sha2-256,rsa-sha2-512,ecdsa-sha2-nistp256,ssh-ed25519,ssh-rsa \
  -v paperless-sftpgo:/var/lib/sftpgo:Z \
  -v paperless-consume:/opt/paperless/consume:rw,z \
  ghcr.io/drakkan/sftpgo:v2.5.4
podman start paperless-sftpgo

sleep 5

JWT=$(curl -s -u ${SFTPGO_ADMIN_USER}:${SFTPGO_ADMIN_PASSWORD} http://127.0.0.1:${SFTPGO_HTTP_PORT}/api/v2/token | jq -r '.access_token')

curl -s --header "Content-Type: application/json" \
     --header 'Accept: application/json' -H "Authorization: Bearer ${JWT}" \
     --request POST \
     --data '{"username": "'${SFTPGO_PAPERLESS_USER}'", "password": "'${SFTPGO_PAPERLESS_PASSWORD}'", "status": 1, "home_dir": "/opt/paperless/consume", "permissions": {"/": ["*"]}}' \
     http://127.0.0.1:${SFTPGO_HTTP_PORT}/api/v2/users

SFTP_PUBLIC_KEY=$(podman exec -it paperless-sftpgo cat /var/lib/sftpgo/id_rsa.pub)

echo "Add the SFTP Public Key to your scanner:"
echo "${SFTP_PUBLIC_KEY}"

echo "${SFTP_PUBLIC_KEY}" > ${PWD}/sftp_rsa_host_key.pub
