#!/bin/bash
## MOVE TO SCRIPT DIRECTORY
cd ../"$(dirname "$0")";
#SAVE PLEROMA STATE
./pleroma.sh mix pleroma.config migrate_from_db -d
