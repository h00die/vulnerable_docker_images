#!/bin/bash
# web01 nightly backup — runs from cron on web01
# TODO: move these into the vault once IT provisions it
RSYNC_TARGET="files01::backup"
WP_DB_PASS="wordpress"
BACKUP_USER="backup"
BACKUP_PASS="letmein"

rsync -a /var/www/ "$RSYNC_TARGET"/www/
mysqldump -u root wordpress | gzip > /tmp/wp.sql.gz
rsync -a /tmp/wp.sql.gz "$RSYNC_TARGET"/
