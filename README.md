# ppngx: Podman + Paperless-ngx

This is a quick script for setting up [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) with [Rootless Podman](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) inside a [Podman Pod](https://docs.podman.io/en/latest/markdown/podman-pod.1.html).

It will launch Redis, PostgreSQL, Tika, Gotenberg, SFTPGo and Paperless-ngx inside a self-contained pod. I was able to get this working with [Brother ADS2800w](https://www.brother-usa.com/products/ads2800w) and SFTP to SFTPGo. Good luck!

If you want to have a VM runs Paperless-ngx, check out my other project which can be used to run everything on [Fedora CoreOS](https://docs.fedoraproject.org/en-US/fedora-coreos/).

https://github.com/quickvm/fcos-layer-paperless-ngx

## Setup
0. Ensure `jq` and `podman` packages are installed (ex `dnf install jq podman`)
1. Clone this repository
2. `cd ppngx`
3. Edit `start.sh` and customize at least these variables:
  ```
  PAPERLESS_TIME_ZONE=America/Chicago
  PAPERLESS_OCR_LANGUAGE=eng
  SFTPGO_ADMIN_PASSWORD=supersecret
  SFTPGO_PAPERLESS_PASSWORD=anothersupersecret
  PAPERLESS_SECRET_KEY=chamgemechamgemechamgemechamgemechamgemechamgemechamgemechamgeme
  POSTGRESQL_PASSWORD=paperlesschangeme
  ```
4. Run `./start.sh`
5. Wait a bit and make sure http://localhost:8000 is loading paperless.
6. Add a superuser to paperless-ngx with:
  ```
  podman exec -it paperless-webserver python manage.py createsuperuser
  ```
7. If you are going to send documents via SFTP use the `scanner` and password set in `SFTPGO_PAPERLESS_PASSWORD`. Some scanners need the RSA Public key from SFTPGo. It is output by the script and written out to a file `${PWD}/sftp_rsa_host_key.pub`

## Updating
The most straightforward methodology is to pull the latest image you care about and re-run start.sh. For example:
  ```
  podman pull ghcr.io/paperless-ngx/paperless-ngx:latest
  ./start.sh
  ```
This will pull the latest image, and assuming your `PAPERLESS_VERSION` specified in start.sh is `latest`, will rebuild the pod with the latest versions.
### Autostart with systemd

**Rootless Podman**
The script by default assumes you are going to run this as a rootless user. Run `loginctl enable-linger $USER` so the systemd user instance can be started at boot and kept running even after the user logs out.

1. Make sure Paperless-ngx is running via `start.sh`
1. `cd ${HOME}/.config/systemd/user`
1. `podman generate systemd --new --files --container-prefix='' --name paperless`
1. `systemctl daemon-reload --user`
1. `podman pod stop paperless`
1. `podman pod rm paperless`
1. `systemctl enable --user --now pod-paperless.service`

**Rootfull Podman**
If you want to run this via systemd as the root user, remove `USERMAP_GUID` and `USERMAP_GID` env vars from `paperless-webserver` before you run `start.sh`. You will also want to run this script as the `root` user.

1. Make sure Paperless-ngx is running via `start.sh`
1. `cd /etc/systemd/system`
1. `podman generate systemd --new --files --container-prefix='' --name paperless`
1. `systemctl daemon-reload`
1. `podman pod stop paperless`
1. `podman pod rm paperless`
1. `systemctl enable --now pod-paperless.service`

**Making changes to your units**

Note: If you make changes to `start.sh` after generating the systemd units you will need to do the following to update the units:

1. Make your changes to `start.sh`
1. `systemctl stop --user pod-paperless.service`
1. Make sure Paperless-ngx is running via `start.sh`
1. `cd ${HOME}/.config/systemd/user`
1. `rm -rf paperless-* pod-paperless.service`
1. `podman generate systemd --new --files --container-prefix='' --name paperless`
1. `systemctl daemon-reload --user`
1. `podman pod stop paperless` (stops paperless that was started by `start.sh`)
1. `podman pod rm paperless` (removes the paperless pod created by `start.sh`)
1. `systemctl enable --user --now pod-paperless.service`

Or you can edit the systemd unit files directly with your changes and run `systemctl daemon-reload --user` and then run `systemctl restart --user pod-paperless.service`.


# License

MIT License

Copyright (c) 2022 Joe Doss

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
