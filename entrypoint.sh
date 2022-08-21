#!/bin/ash
# shellcheck shell=dash

set -e

log() {
    echo -e "\n#> $@\n" 1>&2
}

if [ -n "$BUILDTIME" ]; then
    log "Getting rebar..."
    mix local.rebar --force

    log "Getting hex..."
    mix local.hex --force

    log "Getting dependencies..."
    mix deps.get

    log "Precompiling..."
    mix compile
    exit 0
fi

log "Syncing changes and patches..."
rsync -av /custom.d/ /home/pleroma/pleroma/

log "Recompiling..."
mix compile

log "Waiting for postgres..."
while ! pg_isready -U pleroma -d postgres://db:5432/pleroma -t 1; do
    sleep 1s
done

log "Performing sanity checks..."
if ! touch /uploads/.sanity-check; then
    log "\
The uploads datadir is NOT writable by `id -u`:`id -g`!\n\
This will break all upload functionality.\n\
Please fix the permissions and try again.\
    "
    exit 1
fi
rm /uploads/.sanity-check

log "Migrating database..."
mix ecto.migrate

log "Liftoff o/"
exec mix phx.server
