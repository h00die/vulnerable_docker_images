#!/bin/bash
set -e

# Start the real WordPress entrypoint (generates wp-config.php, waits for DB) + Apache
docker-entrypoint.sh "$@" &
APACHE_PID=$!

# Wait for wp-config.php to exist (means DB is up and config is written)
until [ -f /var/www/html/wp-config.php ]; do sleep 1; done

# Wait for Apache to serve a response
until curl -sf -o /dev/null http://127.0.0.1/; do sleep 2; done

# Install WordPress if not already installed
if ! wp --path=/var/www/html --allow-root core is-installed 2>/dev/null; then
    wp --path=/var/www/html --allow-root core install \
        --url="http://localhost" \
        --title="Corp Internal" \
        --admin_user=admin \
        --admin_password=admin \
        --admin_email=admin@corp.local \
        --skip-email
    echo "[wordpress] Core install complete (admin:admin)"

    # Load the extra lab users
    if [ -f /docker-entrypoint-initdb.d/wp_seed_users.sql ]; then
        mysql -h127.0.0.1 -uroot -proot wordpress \
            < /docker-entrypoint-initdb.d/wp_seed_users.sql \
            && echo "[wordpress] Seed users loaded"
    fi
fi

wait $APACHE_PID
