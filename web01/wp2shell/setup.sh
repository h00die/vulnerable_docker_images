#!/bin/bash
# Sourced from https://github.com/M4xSec/wp2shell-lab (lab/setup.sh, no-WAF variant)
# Port changed 8888 -> 8080 for the web01 stack.
set -e

# Run original WordPress entrypoint (copies core files + writes wp-config) then Apache
docker-entrypoint.sh apache2-foreground &
WP_PID=$!

WP="wp --allow-root --path=/var/www/html"

# Retry install until wp-config.php exists and the DB (PHP/mysqli) is reachable.
# The image ships no mysql client, so probe via wp core install itself, not wp db.
echo "[lab] Installing WordPress 6.9.0 (waiting for database)..."
until $WP core is-installed >/dev/null 2>&1; do
  $WP core install \
    --url="http://localhost:8080" \
    --title="wp2shell Lab" \
    --admin_user=admin \
    --admin_password='Summer2026!' \
    --admin_email=admin@lab.local \
    --skip-email >/dev/null 2>&1 || true
  sleep 3
done

# A published post is required as the oEmbed anchor for the RCE chain
if ! $WP post list --post_type=post --post_status=publish --field=ID | grep -q .; then
  $WP post create --post_type=post --post_status=publish \
    --post_title="Hello world" --post_content="Welcome to the wp2shell lab."
fi

# Direct filesystem writes are needed for the web-based plugin upload step
$WP config set FS_METHOD direct --type=constant || true

# Pretty permalinks so the /wp-json/batch/v1 route resolves
$WP rewrite structure '/%postname%/' || true
$WP rewrite flush || true

# wp-cli ran as root, so files it created under the mounted volume are root-owned.
# Hand wp-content back to the web user or the plugin-upload step returns HTTP 500.
mkdir -p /var/www/html/wp-content/upgrade
chown -R www-data:www-data /var/www/html/wp-content

echo "[lab] ========================================"
echo "[lab]  wp2shell Lab Ready"
echo "[lab]  WordPress 6.9.0 (VULNERABLE)"
echo "[lab]  URL:   http://localhost:8080"
echo "[lab]  Admin: admin / Summer2026!"
echo "[lab] ========================================"

wait $WP_PID
