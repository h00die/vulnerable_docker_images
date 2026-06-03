#!/bin/bash
# Start dbus, the xrdp session manager, then xrdp in the foreground.
set -e
mkdir -p /var/run/dbus /var/run/xrdp
rm -f /var/run/xrdp/*.pid /var/run/xrdp/*.sock 2>/dev/null || true

dbus-daemon --system --fork 2>/dev/null || true
/usr/sbin/xrdp-sesman

exec /usr/sbin/xrdp --nodaemon
