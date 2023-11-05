#!/bin/bash

# SET THESE VARIABLES
export USER="SETME"
export BACKUP_DIR="/home/$USER/paperless_backup/"
export BACKUP_FOLDER_NAME="tmp/"
export BACKUP_TAR_OUTPUT_DIR="/home/$USER/paperless_backup/"
# If you aren't using paperless:latest and tika:latest, change those lines (around line 40ish).
echo "Set the above variables and then remove this line (and the below exit). "
exit 1

# exit when any command fails
set -e
# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# Echo an error before failing!
trap 'echo "\"${last_command}\" command failed with exit code $?."' EXIT

## Do the webserver version print out trick.
## Do this early as it must be done before we stop the pod.
cd $BACKUP_DIR/$BACKUP_FOLDER_NAME
sudo -u $USER podman exec -it paperless-webserver python manage.py --version > paperless-webserver-version.txt

# Stop the pod
sudo -u $USER podman pod stop paperless
sleep 10

# Export each volume.
sudo -u $USER podman volume export paperless-sftpgo --output paperless-sftpgo.tar
sudo -u $USER podman volume export paperless-redis --output paperless-redis.tar
sudo -u $USER podman volume export paperless-postgresql --output paperless-postgresql.tar
sudo -u $USER podman volume export paperless-media --output paperless-media.tar
sudo -u $USER podman volume export paperless-data --output paperless-data.tar

# Export volume info/logs.
# Get the version of all non latest images.
# Useful to ensure we know what version of paperless we backed up so we can restore the same version.
sudo -u $USER podman image ls > paperless-podman-image-ls.txt
sudo -u $USER podman volume ls > paperless-podman-volume-ls.txt

# Now get the info of the two latest images
sudo -u $USER podman image inspect ghcr.io/paperless-ngx/paperless-ngx:latest > paperless-ngx-inspect.txt
sudo -u $USER podman image inspect docker.io/apache/tika:latest > paperless-tika-inspect.txt


# Now backup the directory.
cd $BACKUP_TAR_OUTPUT_DIR


rm -f paperless_backup.tar
tar -cvpf paperless_backup.tar -C $BACKUP_DIR $BACKUP_FOLDER_NAME
chmod 400 paperless_backup.tar
sleep 10
sudo -u $USER podman pod start paperless


trap - EXIT


# Restoring

#Change start.sh to pin to version from outputted logs, and then run it.

# Once start.sh has ran successfully, stop the pod, import the volumes, and restart it.
# Example
# breggodesktop ~/Documents/restore-media-paperless-backup-test/paperless/backup % podman pod stop paperless     
# breggodesktop ~/Documents/restore-media-paperless-backup-test/paperless/backup % podman volume import paperless-data ./paperless-data.tar
# breggodesktop ~/Documents/restore-media-paperless-backup-test/paperless/backup % podman volume import paperless-media ./paperless-media.tar
# breggodesktop ~/Documents/restore-media-paperless-backup-test/paperless/backup % podman volume import paperless-postgresql ./paperless-postgresql.tar
# breggodesktop ~/Documents/restore-media-paperless-backup-test/paperless/backup % podman volume import paperless-redis ./paperless-redis.tar
# breggodesktop ~/Documents/restore-media-paperless-backup-test/paperless/backup % podman volume import paperless-sftpgo ./paperless-sftpgo.tar
# breggodesktop ~/Documents/restore-media-paperless-backup-test/paperless/backup % podman pod start paperless 


