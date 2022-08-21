#!/bin/bash
## MOVE TO SCRIPT DIRECTORY
cd ../"$(dirname "$0")";
#RUN mix pleroma.database prune_objects --vacuum only if pleroma is up
if [[ -n `./pleroma.sh ps | grep 'db'` ]]; then
	./pleroma.sh mix pleroma.database prune_objects --vacuum
fi
