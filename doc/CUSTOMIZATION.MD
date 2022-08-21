
# Customization

Add your customizations (and their folder structure) to `custom.d/`.<br/>
They will be copied into the right place when the container starts.<br/>
You can even replace/patch akkoma’s code with this, because the project is recompiled at startup if needed.

In general: Prepending `custom.d/` to akkoma’s customization guides should work all the time.<br/>

For example: A custom thumbnail now goes into `custom.d/` + `instance/static/instance/thumbnail.jpeg`.

Hint: `./manage.sh enter` gives you a shell, from where you can `cd` and `ls` to explore the file structure

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

### Patches

** THIS DOES NOT WORK AT THE MOMENT, unlike Pleroma, Akkoma is not hosted on gitlab so the same API is not in place **

~~Works exactly like customization, but we have a neat little helper here.<br/>~~
~~Use `./manage.sh mod [regex]` to mod any file that ships with akkoma, without having to type the complete path.~~