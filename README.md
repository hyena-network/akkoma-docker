# Akkoma-Docker (Unofficial)

[Akkoma](https://akkoma.dev/) (A Pleroma fork) is a selfhosted social network that uses ActivityPub.

This repository dockerizes it for easier deployment.

This repository was heavily based on sn0w's work on [pleroma-docker](https://memleak.eu/sn0w/pleroma-docker)

#### Differences:

* Enviroment variable based configuration
* Autogenerating secrets
* Additional scripts

<hr>

```cpp
#include <LICENSE>

/*
 * This repository comes with ABSOLUTELY NO WARRANTY
 *
 * I will happily help you with issues related to this script,
 * but I am not responsible for burning servers, angry users, fedi drama,
 * thermonuclear war, or you getting fired because your boss saw your NSFW posts.
 *
 * Please do some research if you have any concerns about the
 * included features or software *before* using it.
 */
```

<hr>



## Docs

These docs assume that you have at least a basic understanding
of the akkoma installation process and common docker commands.

If you have questions about Pleroma head over to https://docs.akkoma.dev/stable/.
For help with docker check out https://docs.docker.com/.

For other problems related to this script, contact me or open an issue :)

### Prerequisites

- ~1GB of free HDD space
- `git` if you want smart build caches
- `curl`, `jq`, and `dialog` if you want to use `./manage.sh mod`
- Bash 4+
- Docker 18.06+ and docker-compose 1.22+

### Installation

- Clone this repository
- Create a `config.exs` and `.env` file
- Run `./manage.sh build` and `./manage.sh up`
- [Configure a reverse-proxy](#my-instance-is-up-how-do-i-reach-it)
- Profit!

Hint:
You can also use normal `docker-compose` commands to maintain your setup.<br/>
The only command that you cannot use is `docker-compose build` due to build caching.

### Configuration

All the akkoma options that you usually put into your `*.secret.exs` now go into `config.exs`.<br/>
`.env` stores config values that need to be known at orchestration/build time.<br/>
Documentation for the possible values is inside of that file.

### Updates

Run `./manage.sh build` again and start the updated image with `./manage.sh up`.<br/>
You don't need to stop your akkoma server for either of those commands.

### Frontends

To install alternative frontends other than the standard installed `pleroma-fe` and `admin-fe`.
First, uncomment the following volume line in `docker-compose.yml` like:
```
- $DOCKER_DATADIR/frontends:/home/akkoma/akkoma/instance/static/frontends
```
Then, use the `manage.sh` script to install them like this example:

```
./manage.sh mix pleroma.frontend install pleroma-fe
./manage.sh mix pleroma.frontend install admin-fe
./manage.sh mix pleroma.frontend install masto-fe
./manage.sh restart
```
From there on you should find a folder called `frontends` in your Docker data directory where you can see the installed frontends. 

### Maintenance

Pleroma maintenance is usually done with mix tasks.<br/>
You can run these tasks in your running akkoma server using `./manage.sh mix [task] [arguments...]`.<br/>
For example: `./manage.sh mix pleroma.user new sn0w ...`<br/>
If you need to fix bigger problems you can also spawn a shell with `./manage.sh enter`.

### Postgres Upgrades

Postgres upgrades are a slow process in docker (even more than usual) because we can't utilize `pg_upgrade` in any sensible way.<br/>
If you ever wish to upgrade postgres to a new major release for some reason, here's a list of things you'll need to do.

- Inform your users about the impending downtime
    - Seriously this can take anywhere from a couple hours to a week depending on your instance
- Make sure you have enough free disk space or some network drive to dump to, we can't do in-place upgrades
- Stop akkoma (`docker-compose stop server`)
- Dump the current database into an SQL file (`docker-compose exec db pg_dumpall -U akkoma > /my/sql/location/akkoma.sql`)
- Remove the old containers (`docker-compose down`)
- Modify the postgres version in `docker-compose.yml` to your desired release
- Delete `data/db` or move it into some different place (might be handy if you want to abort/revert the migration)
- Start the new postgres container (`docker-compose up -d db`)
- Start the import (`docker-compose exec -T db psql -U akkoma < /my/sql/location/akkoma.sql`)
- Wait for a possibly ridculously long time
- Boot akkoma again (`docker-compose up -d`)
- Wait for service to stabilize while federation catches up
- Done!

### Customization

Add your customizations (and their folder structure) to `custom.d/`.<br/>
They will be copied into the right place when the container starts.<br/>
You can even replace/patch akkoma’s code with this, because the project is recompiled at startup if needed.

In general: Prepending `custom.d/` to akkoma’s customization guides should work all the time.<br/>
Check them out in the [akkoma documentation](https://docs.akkoma.dev/stable/small_customizations.html#content).

For example: A custom thumbnail now goes into `custom.d/` + `instance/static/instance/thumbnail.jpeg`.

### Patches

** THIS DOES NOT WORK AT THE MOMENT, unlike Pleroma, Akkoma is not hosted on gitlab so the same API is not in place **

~~Works exactly like customization, but we have a neat little helper here.<br/>~~
~~Use `./manage.sh mod [regex]` to mod any file that ships with akkoma, without having to type the complete path.~~

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

### Attribution

Great thanks to sn0w for publishing their [pleroma-docker](https://memleak.eu/sn0w/pleroma-docker) repository on what this is based on.