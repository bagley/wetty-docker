## Docker setup for running WeTTy (Web + TTy) under Traefik

[WeTTy](https://github.com/butlerx/wetty) is your terminal running in your browser over HTTP and https.
It is is an alternative to ajaxterm and anyterm
but much better than them because WeTTy uses xterm.js which is a full fledged
implementation of terminal emulation written entirely in JavaScript. WeTTy uses
websockets rather then Ajax and hence better response time.

![WeTTy](/terminal.jpg?raw=true)

This repo contains a dockerized version of [WeTTy](https://github.com/butlerx/wetty) specifically made to run under Traefik, as quickly as possible. Plus, it contains

- Built in `healthcheck`
- Relatively small docker images
- Enviroment files. No need to edit the `docker-compose.yml`
- Auto setup and saving of ssh host keys, so you can just run it.
- Can also have Two Factor Authentication (see tutorial).

There is a [tutorial on how to set this up](https://www.supertechcrew.com/wetty-browser-ssh-terminal/), or follow the (simplified) instructions below.

The Official repo for WeTTy is [github.com/butlerx/wetty](https://github.com/butlerx/wetty).

### Have Traefik up and running

You'll need a [working setup of Traefik (tutorial)](https://www.supertechcrew.com/traefik-cloud-native-router-docker-compose/) in order to access WeTTy.

### Volumes

The `docker-compose.yml` will automatically create the needed volumes. They are called `wetty-data` for the `wetty` container, and `wetty_ssh-data` for the `wetty-ssh` container.

They keep the SSH keys, `known_hosts` files, and other files needed across recreates/updates. Feel free to override these if you would like, just set them to the same folders.

### Settings

There are two environment settings files, `.env` and `env-wetty-ssh`.

_Why two files? Because the public facing container should not already have your username/password to login to the second, in case someone were to break into it. It would make it too easy to get into the ssh one._

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

#### Previous settings files

If you have an `env` and `env-wetty` file from the previous version of the tutorial, run these commands to move them for the current `docker-compose.yml`. I changed the name of the environment files, as they were a bit confusing to know which one did what. Note that this is not needed if you are continuing to use the previous [docker-compose.yml](https://github.com/bagley/wetty/blob/b229ae0a3a40b01f62d54af68c93091057101691/docker-compose.yml), only if you are using the new one.

```
$ mv env env-wetty-ssh
$ mv env-wetty .env
```

### Healthcheck

The images come with a healthcheck. The WeTTY container self checks that it can `curl` to its http connection. The SSH container makes sure it can connect to its ssh instance.

You may see lines like the following in the log:

```
wetty-ssh    | Connection closed by 127.0.0.1 port 58824 [preauth]
```

This is just the healthcheck connecting to the ssh container and making sure it will accept connections.

### Docker hub

Images are automatically pulled from Docker hub by `docker-compose`. Just noting this here for reference.
- [wetty](https://hub.docker.com/r/mydigitalwalk/wetty)
- [wetty-ssh](https://hub.docker.com/r/mydigitalwalk/wetty-ssh)

### Building

If you wish to build the image, instead of having it use Docker hub, You'll need to get the WeTTy source code, as this is not automatically added with `clone`. If you already have it cloned, run this to get the code:

Use this also to update the WeTTy code too.

```
git submodule update --init --recursive
```

Or run this if you haven't already cloned it:

```
git clone --recurse-submodules https://github.com/bagley/wetty
```

Then, uncomment out the lines for building it, and either just bring it up (docker-compose will build it), or manually build it:

```
docker-compose build
```

There is a script `autobuild.sh` which I use to build the image, start it (under and testing name, so production one can keep running), and then will test and verify the image before uploading to Docker hub.

## FAQ

### What browsers are supported?

WeTTy supports all browsers that
[xterm.js supports](https://github.com/xtermjs/xterm.js#browser-support).
