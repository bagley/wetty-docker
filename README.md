## WeTTy = Web + TTy

Terminal over HTTP and https. WeTTy is an alternative to ajaxterm and anyterm
but much better than them because WeTTy uses xterm.js which is a full fledged
implementation of terminal emulation written entirely in JavaScript. WeTTy uses
websockets rather then Ajax and hence better response time.

![WeTTy](/terminal.png?raw=true)

## Running WeTTy with Traefik under Docker

WeTTy can be run from a container to ssh to a remote host or the host system.

Rename `env.example` to `env` and set the user and SSH settings.

```sh
WETTY_USER=YourUser
WETTY_PASSWORD=YourPassPhrase

SSHHOST=w.x.y.z
SSHPORT=22
SSHUSER=Your.SSH.User
```

Rename `env-wetty.example` to `env-wetty` and set the domain and the base url.

```sh
DOMAINNAME=console.example.com
BASEURL=/manage
```

Then you can either change DOMAINNAME in the `docker-compose.yml`, or you can set the variable:

```sh
$ export DOMAINNAME=console.example.com
$ docker-compose up -d
```

Then go to your site, `https://console.example.com/manage`

## FAQ

### What browsers are supported?

WeTTy supports all browsers that
[xterm.js supports](https://github.com/xtermjs/xterm.js#browser-support).
