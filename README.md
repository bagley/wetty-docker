## WeTTy = Web + TTy

Terminal over HTTP and https. WeTTy is an alternative to ajaxterm and anyterm
but much better than them because WeTTy uses xterm.js which is a full fledged
implementation of terminal emulation written entirely in JavaScript. WeTTy uses
websockets rather then Ajax and hence better response time.

Here's a [tutorial on how to set this up](https://www.supertechcrew.com/wetty-browser-ssh-terminal/). Or there's some instrustions below.

_The setup of WeTTy in this repo is built specifically to run under Traefik, as quickly as possible. For the original, go to [github.com/krishnasrinivas/wetty](https://github.com/krishnasrinivas/wetty)_

![WeTTy](/terminal.jpg?raw=true)

## Running WeTTy with Traefik under Docker

WeTTy can be run in a container, allowing you to connect to it with your browser to ssh to a remote host or the host system.

### Volumes

The `docker-compose.yml` will automatically create the needed volumes. They are called `wetty-data` for the `wetty` container, and `wetty_ssh-data` for the `wetty-ssh` containter. 

They keep the SSH keys, `known_hosts` files, and other files needed across recreates/updates. Feel free to override these if you would like, just set them to the same folders.

### Settings

Rename `env-wetty-ssh.example` to `env-wetty-ssh` and set the user and SSH settings.

```sh
WETTY_USER=YourUser
WETTY_PASSWORD=YourPassPhrase

SSHHOST=w.x.y.z
SSHPORT=22
SSHUSER=Your.SSH.User
```

Rename `.env.example` to `.env` and set the domain url, and the base url, so it will be `https://{DOMAINNAME}{BASEURL}`

```sh
DOMAINNAME=console.example.com
BASEURL=/manage
```

Now go ahead and bring it up:

```sh
$ docker-compose up -d
$ docker-compose logs -f
```

Then go to your site, `https://console.example.com/manage`

## FAQ

### What browsers are supported?

WeTTy supports all browsers that
[xterm.js supports](https://github.com/xtermjs/xterm.js#browser-support).

