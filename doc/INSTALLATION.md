# Installation

These docs assume that you have at least a basic understanding
of the akkoma installation process and common docker commands.

If you have questions about Pleroma head over to https://docs.akkoma.dev/stable/.
For help with docker check out https://docs.docker.com/.

For other problems related to this script, contact me or open an issue :)

### Prerequisites

- ~1GB of free HDD space
- `git` if you want smart build caches
- ~~`curl`, `jq`, and `dialog` if you want to use `./manage.sh mod`~~
- Bash 4+
- Docker 18.06+ and docker-compose 1.22+

### Quick-start

- Clone this repository (or just copy the [docker-compose.yml](../docker-compose.yml))
- Copy the base [.env.dist](../.env.dist) to `.env` and change the desired values
- Run `./manage.sh up` or `docker-compose up`
- [Configure a reverse-proxy](#my-instance-is-up-how-do-i-reach-it)
- Profit!

After which you might want to make yourself an admin user as following:

```
./manage.sh mix pleroma.user new <username> <email> --admin
```

Hint:
You can also use normal `docker-compose` commands to maintain your setup.<br/>
The only command that you cannot use is `docker-compose build` due to build caching.

### Configuration


`.env` stores config values that need to be known at orchestration/build time as well as configuration values most commonly put in the `config.exs`.<br/>
All additional options that you usually put into your `*.secret.exs` now go into `config.d/config.exs`, this will be created on first run with a header.<br/>

Incase you mainly want to configure through the `admin-fe` add the following line to your `config.d/config.exs`:
```
config :pleroma, configurable_from_database: true
```


Documentation for the possible values, please refer to the Pleroma (since Akkoma does not have it yet at this time) configuration cheatsheet
 [[link]](https://docs-develop.pleroma.social/backend/configuration/cheatsheet/)


### My instance is up, how do I reach it?

To reach Gopher or SSH, just uncomment the port-forward in your `docker-compose.yml`.

To reach HTTP you will have to configure a "reverse-proxy".<br/>
Older versions of this project contained a huge amount of scripting to support all kinds of reverse-proxy setups.<br/>
This newer version tries to focus only on providing good akkoma tooling.<br/>
That makes the whole process a bit more manual, but also more flexible.

You can use Caddy, Traefik, Apache, nginx, or whatever else you come up with.<br/>
Just modify your `docker-compose.yml` accordingly.

One example would be to add an [nginx server](https://hub.docker.com/_/nginx) to your `docker-compose.yml`:
```yml
  # ...

  proxy:
    image: nginx
    init: true
    restart: unless-stopped
    links:
      - server
    volumes:
      - ./my-nginx-config.conf:/etc/nginx/nginx.conf:ro
    ports:
      - "80:80"
      - "443:443"
```

Then take a look at [the pleroma nginx example](https://git.pleroma.social/pleroma/pleroma/blob/develop/installation/pleroma.nginx) for hints about what to put into `my-nginx-config.conf`.

Using apache would work in a very similar way (see [Apache Docker Docs](https://hub.docker.com/_/httpd) and [the pleroma apache example](https://git.pleroma.social/pleroma/pleroma/blob/develop/installation/pleroma-apache.conf)).

The target that you proxy to is called `http://server:4000/`.<br/>
This will work automagically when the proxy also lives inside of docker.

If you need help with this, or if you think that this needs more documentation, please let me know.