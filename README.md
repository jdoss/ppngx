# ppngx: Podman + Paperless-ngx

This is a quick script for setting up [Paperless-ngx](https://github.com/paperless-ngx/paperless-ngx) with [Rootless Podman](https://github.com/containers/podman/blob/main/docs/tutorials/rootless_tutorial.md) inside a [Podman Pod](https://docs.podman.io/en/latest/markdown/podman-pod.1.html).

It will launch Redis, PostgreSQL, Tika, Gotenberg, SFTPGo and Paperless-ngx inside a self-contained pod. I got this working with [Brother ADS2800w](https://www.brother-usa.com/products/ads2800w) and SFTP to SFTPGo. Good luck!

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
