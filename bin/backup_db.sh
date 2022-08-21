#!/bin/bash
## MOVE TO SCRIPT DIRECTORY
cd ../"$(dirname "$0")";
#SAVE PLEROMA STATE
if [[ -z `./pleroma.sh ps | grep 'db'` ]]; then
	P_STATE=false
elif [[ -n `./pleroma.sh ps | grep 'db'` ]]; then
	P_STATE=true
fi
if [[ -n $1 && $1 = 'restart' ]]; then
	./pleroma.sh down && /usr/local/bin/docker-compose up -d db && sleep 2 && /usr/local/bin/docker-compose exec db pg_dump -U pleroma pleroma | gzip >/backups/my_db-$(date +%Y-%m-%d).tar.gz;
else
	/usr/local/bin/docker-compose exec db pg_dump -U pleroma pleroma | gzip >/backups/my_db-$(date +%Y-%m-%d).tar.gz;
fi

if [[ "$P_STATE" = true ]]; then
	./pleroma.sh up
else
	./pleroma.sh down
fi
