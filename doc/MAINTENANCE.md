# Maintenance

Pleroma maintenance is usually done with mix tasks.<br/>
You can run these tasks in your running akkoma server using `./manage.sh mix [task] [arguments...]`.<br/>
For example: `./manage.sh mix pleroma.user new sn0w ...`<br/>
If you need to fix bigger problems you can also spawn a shell with `./manage.sh enter`.

### Updates

Run `./manage.sh build` again and start the updated image with `./manage.sh up`.<br/>
You don't need to stop your akkoma server for either of those commands.

## Postgres Upgrades

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